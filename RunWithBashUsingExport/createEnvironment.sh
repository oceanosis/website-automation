#!/bin/bash
#
# Create AWS VPC by using CloudFormation templates 
# Using bash script instead of using nested templates.

log () 
{ TIME=`date "+%Y-%m-%d %H:%M:%S"`
  echo "$TIME $1"
}

# Be careful on changing variables
# Variables
if [ -n "$1" ]; then
echo "REGION parameter is missing"
exit 1
fi

region=$1

basedir="/usr/local/src/website-automation/RunWithBashUsingExport"
cf="cloudformation"

create-stack()
{
	aws cloudformation create-stack --stack-name $1 --template-body file://$basedir/$cf/$2 --region="$region" --output text 2>&1
}
delete-stack()
{
	aws cloudformation delete-stack --stack-name $1 --region="$region" --output text 2>&1
}
check-stack-status()
{
	while true; do
	
		RUNSTAT=$(aws cloudformation describe-stacks --region="$region" --stack-name="$1" --query 'Stacks[*].[StackStatus]' --output text)
		log "INFO $1 Creation Status: $RUNSTAT"
		if [[ $RUNSTAT == *CREATE_COMPLETE* ]]; then
        		log "INFO $1 Creation completed"
			break
		elif [[ $RUNSTAT == *ROLLBACK* ]]; then
        			log "ERROR Creation Stopped. Stack creation error for $1"
        			log "ERROR "$2
        			delete-stack $1
        			exit 1
		else
			sleep 5
		fi
	done
}


# Script starting from now on...
log "INFO Environment creation started."

# StackName:TemplateName Dictionary
# If you change stack names, go and change export names in json files
STACK=( "myVPC:vpc.json"
	"mySubnetStack:subnet.json"
	"myGWRoutestack:igw-route.json"
	"mySecurityStack:security.json"
	"myEC2Stack:ec2.json" )

for VAL in "${STACK[@]}" ; do
    KEY="${VAL%%:*}"
    VALUE="${VAL##*:}"
    OUTPUT=$(create-stack $KEY $VALUE)
    check-stack-status $KEY $OUTPUT
    log "INFO $KEY stack has run with $VALUE template"
done

log "INFO All processes are over."


exit 0
