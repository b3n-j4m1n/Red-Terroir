#!/bin/bash

domain_1='example.com'
domain_2='www.example.com'
redirector_public_ip='54.206.39.13'

echo
echo "[*] Domain --------------- $domain_1"
echo "[*] Domain --------------- $domain_2"
echo "[*] redirector_public_ip - $redirector_public_ip"
echo

printf "Is this correct (Y/N)?"
read input_variable

case $input_variable in
  [yY]|[yY][eE][sS]) ;;
  *) echo exit 0 ;;
esac

echo
echo "----------------------------------------------------"
echo "Type             Host         Value"
echo "----------------------------------------------------"
echo "A Record         @            $redirector_public_ip"
echo "CNAME Record     www          $domain_1"
echo "----------------------------------------------------"
echo
printf "Have you updated the host records (Y/N)?"
read input_variable

case $input_variable in
  [yY]|[yY][eE][sS]) ;;
  *) echo exit 0 ;;
esac

ssh -i ../ssh/master_id_rsa.pem ubuntu@$redirector_public_ip "sudo service apache2 stop"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$redirector_public_ip "sudo apt -y install certbot"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$redirector_public_ip "sudo certbot certonly --standalone -d $domain_1 -d $domain_2 -n --register-unsafely-without-email --agree-tos"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$redirector_public_ip "sudo sed -i -e \"s/\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/\/etc\/letsencrypt\/live\/$domain_1\/cert.pem/g\" /etc/apache2/sites-available/default-ssl.conf"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$redirector_public_ip "sudo sed -i -e \"s/\/etc\/ssl\/private\/ssl-cert-snakeoil.key/\/etc\/letsencrypt\/live\/$domain_1\/privkey.pem/g\" /etc/apache2/sites-available/default-ssl.conf"
ssh -i ../ssh/master_id_rsa.pem ubuntu@$redirector_public_ip "sudo systemctl restart apache2"
echo | openssl s_client -showcerts -servername $domain_1 -connect $domain_1:443 2>/dev/null | openssl x509 -inform pem -noout -text
