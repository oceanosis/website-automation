#!/bin/bash
# Bootstrap script for Amazon Linux.
# This server will automatically retrieve all environment cloudformation templates and
# ansible playbooks from GitHub repo
# Ufuk Dumlu - 21 Oct
# Install nesessary apps

yum update -y
yum install epel-release -y
yum-config-manager --enable epel
yum install gcc git python python-devel python-pip make -y
yum install python-jinja2 python-paramiko PyYAML MySQL-python -y 

# install ansible for deployments
cd /usr/local/src
git clone git://github.com/ansible/ansible.git
cd ansible
git checkout -b stable-2.0 origin/stable-2.0
git submodule update --init --recursive
make install
echo "export PATH=$PATH:/usr/local/bin" >> /root/.bash_profile
source /root/.bash_profile

# create aws environment
cd /usr/local/src
git clone https://github.com/oceanosis/website-automation
cd website-automation
/usr/local/src/website-automation/createEnvironment.sh >> /usr/local/src/website-automation/automation.log

NEWWEBSERVERIP=$(aws ec2 describe-instances --region='eu-central-1' --filter Name=tag:Server,Values=Web1  --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

# install apps and deploy website via ansible

