# Automating a simple website on AWS by using different approaches
This repo is simply to show how to provision cloud resources with different approaches

Website Automation on AWS by using;
 - Bash Automation Scripts
 - CloudFormation Templates
 - Ansible playbooks 
 - Python/Boto3 
 - Terraform 

## Environment Prerequsites
1. Create repository on GitHub
2. Create folders on repo as WebSite (Php Codes) and Development-Infrastructure 
3. Put CloudFormation templates, Bootstrap and AWS Creation Scripts, Ansible Playbooks and WebSite on GitHub Repos
4. Create a EC2 role that has the admin access for all AWS resources (Attach AdministratorAccess Policy)
5. Create a t2.micro AmazonLinux server (AutomationServer) for all automations in order to trigger creating infrastructure, and use bootstrap script in repo. (keep KeyPair, it will be also be used for automated EC2 Servers)
6. Give created role to EC2 before lauching and add bootscript.sh to UserData
7. Put Pem file to S3 folder ( When automation is over, go delete it. )
8. Launch Automation Server with bootscript.sh

> In this part, in bootscript, choose one of the automation option [ Bash/Ansible - bashWithExport/Ansible - OnlyAnsible - Python/Boto3 ]

> Update region and AMI IDs in templates and bash scripts.

***

## Conclusion
> All infrastructure resource provisioning, service installations and deployments are accomplished while automation server is launching.

### TODO
> Provisioning resources with Phyton/Boto3
> Provisioning resources with Terraform 




