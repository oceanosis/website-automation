#!/bin/bash
################################################# 
# Bootstrap script for Amazon Linux.		#
# This server will automatically retrieve  	#
# all environment cloudformation templates and 	#
# ansible playbooks from GitHub repo		#
# Ufuk Dumlu - 30 Oct				#
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

# create aws environment
cd /usr/local/src
git clone https://github.com/oceanosis/website-automation

###########################################################
# Type of automation: Bootscript + Ansible Cloud Modules  #
###########################################################
cat >> /root/.bash_profile <<EOL
if [ -z "\$SSH_AUTH_SOCK" ] ; then
  eval \$(ssh-agent)
fi
EOL

eval $(ssh-agent)
DIR=/usr/local/src/website-automation/RunAllWithAnsible

REGION="us-east-1"
DATE=$(date "+%Y-%m-%d-%H-%M-%S")

# Run environment creation with Ansible Cloud Modules
# ansible-playbook 

sed -i 's/.*region:.*/region: '$REGION'/g' $DIR/ansible/roles/env/vars/main.yml

export AWS_ACCESS_KEY_ID='AKIAIUUDAC4M5NPYNIEQ'
export AWS_SECRET_ACCESS_KEY='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'

ansible-playbook aws-automation.yml > /usr/local/src/ansible-$DATE.log
if [[ $? -ne 0 ]]; then
echo "Ansible playbook did not completed. Check process and errors in log"
exit 1
fi
# Environment Creation is over, now deployment

###################################################################
# Type of automation: Bash, Ansible, Pyhton : change medhodology  #
###################################################################
cat >> /root/.bash_profile <<EOL
if [ -z "\$SSH_AUTH_SOCK" ] ; then
  eval \$(ssh-agent)
fi
EOL

eval $(ssh-agent)

# For only one server... ( will be changed )
NEWWEBSERVERIP=$(aws ec2 describe-instances --region="$REGION" --filter Name=tag:Server,Values=Web1  --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

# Copy Automation-Test.pem and use ssh agent forwarding
aws s3 cp s3://automation-test-dumlu/Automation-Test.pem /tmp/
#aws s3 rm s3://automation-test-dumlu/Automation-Test.pem
#
chmod 400 /tmp/Automation-Test.pem
ssh-add -k /tmp/Automation-Test.pem
#
## Install apps and deploy website via ansible
cd $DIR/ansible
export PATH=$PATH:/usr/local/bin
export ANSIBLE_HOST_KEY_CHECKING=False
echo "[webservers]" > ./hosts
echo $NEWWEBSERVERIP >> ./hosts
sleep 60 # wait for ssh start
ansible webservers -a "cat /etc/hostname" -i hosts -u ec2-user

ansible-playbook web-automation.yml -i hosts -u ec2-user >> /usr/local/src/ansible-$DATE.log
if [[ $? -ne 0 ]]; then
echo "Ansible playbook did not completed. Check process and errors in log"
exit 1
fi
## 
