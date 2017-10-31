#!/bin/bash
################################################# 
# Bootstrap script for Amazon Linux.		#
# This server will automatically retrieve  	#
# all environment cloudformation templates and 	#
# ansible playbooks from GitHub repo		#
# Ufuk Dumlu - 21 Oct				#
# Install apache and necessary other apps 	#
#################################################

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
export PATH=$PATH:/usr/local/bin
echo "export PATH=$PATH:/usr/local/bin" >> /root/.bash_profile
source /root/.bash_profile

# create aws environment
cd /usr/local/src
git clone https://github.com/oceanosis/website-automation
WEB=/usr/local/src/website-automation
cd $WEB

###################################################################
# Type of automation: Bash, Ansible, Pyhton : change medhodology  #
###################################################################
# >>> RunWithBash <<<
REGION="us-east-1"
DATE=$(date "+%Y-%m-%d-%H-%M-%S")
cd RunWithBash
./createEnvironment.sh $REGION >> /usr/local/src/automation-$DATE.log
if [ $? -ne 0 ];then
exit 1
fi
#Environment Creation is over, now deployment
# For only one server... ( will be changed )
NEWWEBSERVERIP=$(aws ec2 describe-instances --region="$REGION" --filter Name=tag:Server,Values=Web1  --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

# Copy Automation-Test.pem and use ssh agent forwarding
aws s3 cp s3://automation-test-dumlu/Automation-Test.pem /root/.ssh/
chmod 400 /root/.ssh/Automation-Test.pem
eval $(ssh-agent)
ssh-add -k /root/.ssh/Automation-Test.pem

# Install apps and deploy website via ansible
cd ansible
export PATH=$PATH:/usr/local/bin
export ANSIBLE_HOST_KEY_CHECKING=False
echo "[webservers]" > ./hosts
echo $NEWWEBSERVERIP >> ./hosts
ansible webservers -a "cat /etc/hostname" -i hosts
DATE=$(date "+%Y-%m-%d-%H-%M-%S")
ansible-playbook web-automation.yml -i hosts >> /usr/local/src/ansible-$DATE.log
# 
