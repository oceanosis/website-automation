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
git checkout -b stable-2.4 origin/stable-2.4
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
cd RunWithBash
./createEnvironment.sh >> /usr/local/src/cloudformation-$(date "+%Y-%m-%d %H:%M:%S").log

#Environment Creation is over, now deployment
# For only one server... ( will be changed )
NEWWEBSERVERIP=$(aws ec2 describe-instances --region='eu-central-1' --filter Name=tag:Server,Values=Web1  --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

# Copy Automation-Test.pem and use ssh agent forwarding
aws s3 cp s3://automation-test-dumlu/Automation-Test.pem /root/.ssh/
chmod 400 /root/.ssh/Automation-Test.pem
ssh-agent bash
ssh-add -k /root/.ssh/Automation-Test.pem

cat >> /root/.bash_profile <<EOL
if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent bash`
  ssh-add -k /root/.ssh/Automation-Test.pem
fi
EOL

# Install apps and deploy website via ansible
cd ansible
echo "[webservers]" > ./hosts
echo $NEWWEBSERVERIP >> ./hosts
ansible-playbook web-automation.yml -i hosts >> /usr/local/src/ansible-$(date "+%Y-%m-%d %H:%M:%S").log
# 
