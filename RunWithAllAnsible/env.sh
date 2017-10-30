#!/bin/bash


NEWSERVERIP=$(aws ec2 describe-instances --region='eu-central-1' --filter Name=tag:Server,Values=Web1  --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

mkdir -p /etc/ansible/
touch /etc/ansible/hosts
chmod 744 /etc/ansible/hosts

echo $NEWSERVERIP > /etc/ansible/hosts

export ANSIBLE_INVENTORY=/etc/ansible/hosts
