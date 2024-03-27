#!/bin/bash

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
rm -rf ./get-docker.sh

# install cloudwatch agent and apply configuration from ssm parameter store
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/$(dpkg --print-architecture)/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-agent-config
rm -rf ./amazon-cloudwatch-agent.deb

# install aws cli
apt-get update
apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws ./awscliv2.zip
