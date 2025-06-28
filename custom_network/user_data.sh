#!/bin/bash
apt-get update -y
apt-get install apache2 git -y
systemctl enable apache2
systemctl start apache2

cd /var/www/html
git clone https://github.com/Naveen-cloud-DevOps/E-commerce.git
mv E-commerce/* .
rm -rf E-commerce
