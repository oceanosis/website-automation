#!/bin/bash
#
# Create AWS VPC by using CloudFormation templates 
# Using bash script instead of using nested templates.

log () 
{ TIME=`date "+%Y-%m-%d %H:%M:%S"`
  echo $TIME" "$1 
}

# Be careful on changing variables
# Variables
if [ -n "$1" ]; then
echo "REGION parameter is missing"
exit 1
fi

region=$1
basedir="/usr/local/src/website-automation/RunWithBash"
cf="cloudformation"

create-stack()
{
	aws cloudformation create-stack --stack-name $1 --template-body file://$basedir/$cf/$2 --region="$region"  2>&1
}
delete-stack()
{
	aws cloudformation delete-stack --stack-name $1 --region="$region" 2>&1
}
check-stack-status()
{
	while true; do
	
		RUNSTAT=$(aws cloudformation describe-stacks --region="$region" --stack-name="$1" --query 'Stacks[*].[StackStatus]' --output text)
		# log "INFO $1 Creation Status: $RUNSTAT"
		if [[ $RUNSTAT == *CREATE_COMPLETE* ]]; then
        		log "INFO $1 Creation completed"
			break
		elif [[ $RUNSTAT == *ROLLBACK* ]]; then
        			log "ERROR Creation Stopped. Stack creation error for $1"
        			log "ERROR $2"
        			delete-stack $1
        			exit 1
		else
			sleep 5
		fi
	done
}


# Script starting from now on...
log "INFO Environment creation started."

# Run VPC Creation
STACK=myVPC
TEMPLATE=vpc.json
OUTPUT=$(create-stack $STACK $TEMPLATE)
check-stack-status $STACK $OUTPUT


VPCID=$(aws ec2 describe-vpcs --region="$region" --filter Name=tag:Name,Values=CF-TEST --query 'Vpcs[*].[VpcId]' --output text)

if [[ $VPCID == vpc* ]]; then
	log "INFO VPC-ID found. Moving on with $VPCID"
else
	log "ERROR VPC-ID not found. Check coding."
	exit 1
fi


# Update vpcid on subnet json 
sed -i 's/.*VpcId":.*/"VpcId": "'$VPCID'",/g' $basedir/$cf/subnet.json

# Run Subnet Creation
STACK=mySubnetStack
TEMPLATE=subnet.json
OUTPUT=$(create-stack $STACK $TEMPLATE)
check-stack-status $STACK $OUTPUT

SUBNETID=$(aws ec2 describe-subnets --region="$region" --filter Name=tag:Name,Values=CF-TEST --query 'Subnets[*].[SubnetId]' --output text)

if [[ $SUBNETID == subnet* ]]; then
       log "INFO SUBNET-ID found. Moving on with $SUBNETID"
else
        log "ERROR SUBNET-ID not found. Check coding."
        exit 1
fi

# Update vpcid and subnetid
sed -i 's/.*VpcId":.*/"VpcId": "'$VPCID'",/g' $basedir/$cf/igw-route.json
sed -i 's/.*SubnetId":.*/"SubnetId": "'$SUBNETID'",/g' $basedir/$cf/igw-route.json
log "INFO igw and routing templates are updated with VPCID and SubnetID"


# Run myGWRoutestack Creation
STACK=myGWRoutestack
TEMPLATE=igw-route.json
OUTPUT=$(create-stack $STACK $TEMPLATE)
check-stack-status $STACK $OUTPUT

# Update security
sed -i 's/.*VpcId":.*/"VpcId": "'$VPCID'",/g' $basedir/$cf/security.json
sed -i 's/.*SubnetId":.*/"SubnetId": "'$SUBNETID'",/g' $basedir/$cf/security.json
log "INFO security templates are updated with VPCID and SubnetID"


# Run Security Creation
STACK=mySecurityStack
TEMPLATE=security.json
OUTPUT=$(create-stack $STACK $TEMPLATE)
check-stack-status $STACK $OUTPUT

log "INFO Whole VPC processes are done. Now create EC2 instances... "

SGID=$(aws ec2 describe-security-groups --region="$region" --filter Name=tag:Name,Values=CF-TEST --query 'SecurityGroups[*].[GroupId]' --output text)

# Update SGID and SubnetID on EC2 json
sed -i 's/.*SecurityGroupIds":.*/"SecurityGroupIds": ["'$SGID'"],/g' $basedir/$cf/ec2.json
sed -i 's/.*SubnetId":.*/"SubnetId": "'$SUBNETID'",/g' $basedir/$cf/ec2.json
log "INFO EC2 templates are updated with SGID and SubnetID"

# Run Security Creation
STACK=myEC2Stack
TEMPLATE=ec2.json
OUTPUT=$(create-stack $STACK $TEMPLATE)
check-stack-status $STACK $OUTPUT

log "INFO EC2 instance has created. DONE"

PUBLICIP=$(aws ec2 describe-instances --region="us-east-1" --filter Name=tag:Name,Values=CF-TEST --query "Reservations[*].Instances[*].PublicIpAddress"  --output=text)
echo "[webservers]" > $basedir/ansible/hosts
echo $PUBLICIP >> $basedir/ansible/hosts


exit 0
