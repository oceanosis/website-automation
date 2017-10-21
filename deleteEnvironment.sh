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
basefld="/usr/local/src"
subfld="website-automation/cloudformation"

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
#OUTPUT=$(delete-stack $LIST)

IFS='
'
for item in $LIST
do
  OUTPUT=$(delete-stack $item) 
  log "INFO Stack deletion request is sent for $item"

done

log "INFO deletion of stacks are done. "

exit 0
