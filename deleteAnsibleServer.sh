#!/bin/bash

InstanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

aws ec2 terminate-instances instance-ids=$InstanceID
