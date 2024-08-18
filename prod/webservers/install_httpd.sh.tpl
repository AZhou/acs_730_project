#!/bin/bash
yum -y update
yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "My name is Alex! My private IP is $myip in ${env} environment built by Terraform!"  >  /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd


