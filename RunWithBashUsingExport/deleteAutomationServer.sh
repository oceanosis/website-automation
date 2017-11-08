#!/bin/bash
# Kill yourself bitch.

# Be careful on changing variables
# Variables
if [ -z "$1" ]; then
echo "REGION parameter is missing"
exit 1
fi

region=$1


InstanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

aws ec2 terminate-instances --instance-ids="$InstanceID" --region=$1
