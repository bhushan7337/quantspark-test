#!/bin/bash
apt update
apt upgrade -y
apt install apache2 -y
echo "<h1>Hello QuantSpark <br /> I am running in auto scaled EC2 instances</h1>" > /var/www/html/index.html
systemctl start apache2
systemctl enable apache2