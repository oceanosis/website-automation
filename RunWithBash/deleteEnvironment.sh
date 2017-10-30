#!/bin/bash
#
# Create AWS VPC by using CloudFormation templates 

log () 
{ TIME=`date "+%Y-%m-%d %H:%M:%S"`
  echo $TIME" "$1 
}

# Be careful on changing variables
# Variables
region="eu-central-1"
basedir="/usr/local/src/website-automation/RunWithBash"
cf="cloudformation"

check-stack-status()
{
        while true; do

                aws cloudformation describe-stacks --region="$region" --stack-name="$1" --query 'Stacks[*].[StackStatus]' --output text  > /dev/null 2>$1
		STATUS=$?
                if [ $STATUS -ne 0 ]; then
                        log "INFO $1 Deletion completed"
                        break
                else
                        sleep 5
                fi
        done
}

delete-stack()
{
	aws cloudformation delete-stack --stack-name $1 --region="$region" 2>&1
}

retrieve-stack-list()
{
	aws cloudformation describe-stacks --region="$region" --query 'Stacks[*].[StackName]' --output text

}

# Script starting from now on...
log "INFO Environment deletion started."

LIST=$(retrieve-stack-list)

IFS='
'
for item in $LIST
do
  OUTPUT=$(delete-stack $item) 
  log "INFO Stack deletion request is sent for $item"
  check-stack-status $item
done

log "INFO deletion of stacks are done. "

exit 0
