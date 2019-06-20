#!/bin/bash

host_ip='54.79.108.195'

echo
echo "[*] Host IP --------- $host_ip"
echo

printf "Is this correct (Y/N)?"
read input_variable

case $input_variable in
  [yY]|[yY][eE][sS]) ;;
  *) echo exit 0 ;;
esac

ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "sudo a2enmod rewrite"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "sudo gawk -i inplace '/AllowOverride None/{c++;if(c==3){sub(\"AllowOverride None\",\"AllowOverride All\");c=0}}1' /etc/apache2/apache2.conf"
SSLCertificateFile=$(ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "grep '\.pem' /etc/apache2/sites-available/default-ssl.conf")
SSLCertificateKeyFile=$(ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "grep '\.key' /etc/apache2/sites-available/default-ssl.conf")
cp ../apache/default-ssl.conf ../apache/default-ssl.conf.tmp
sudo sed -i "s|pem_file|$SSLCertificateFile|g" ../apache/default-ssl.conf.tmp
sudo sed -i "s|key_file|$SSLCertificateKeyFile|g" ../apache/default-ssl.conf.tmp
scp -i ../ssh/master_id_rsa.pem ../apache/default-ssl.conf.tmp ubuntu@$host_ip:/tmp/default-ssl.conf.tmp
scp -i ../ssh/master_id_rsa.pem ../apache/000-default.conf ubuntu@$host_ip:/tmp/000-default.conf
ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "sudo mv /tmp/default-ssl.conf.tmp /etc/apache2/sites-available/default-ssl.conf"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "sudo mv /tmp/000-default.conf /etc/apache2/sites-available/000-default.conf"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$host_ip "sudo systemctl restart apache2"
