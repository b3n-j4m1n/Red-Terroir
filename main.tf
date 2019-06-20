# ---http_redirector---

resource "aws_instance" "http_redirector" {
  count                       = var.http_redirector_instance_count
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.http_redirector.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "http_redirector_${count.index}"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # apache install
      "sudo apt install -y apache2",
      "sudo a2enmod proxy proxy_http ssl",
      "sudo a2ensite default-ssl.conf",
      "sudo apt install -y libapache2-mod-security2",
      "sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf",
      "sudo timedatectl set-timezone Australia/Melbourne",
      # https redirection
      "sudo head -n -5 /etc/apache2/sites-available/default-ssl.conf > /tmp/default-ssl.conf.tmp",
      "sudo cat << EOF >> /tmp/default-ssl.conf.tmp",
      "                SSLProxyEngine On",
      "                ProxyPass / https://${aws_instance.http_c2.private_ip}/",
      "                ProxyPassReverse / https://${aws_instance.http_c2.private_ip}/",
      "                SSLProxyCheckPeerCN off",
      "                SSLProxyCheckPeerName off",
      "                SSLProxyCheckPeerExpire off",
      "        </VirtualHost>",
      "</IfModule>",
      "EOF",
      "sudo mv /tmp/default-ssl.conf.tmp /etc/apache2/sites-available/default-ssl.conf",
      # http redirection
      "sudo head -n -3 /etc/apache2/sites-available/000-default.conf > /tmp/000-default.conf.tmp",
      "sudo cat << EOF >> /tmp/000-default.conf.tmp",
      "        ProxyPass / http://${aws_instance.http_c2.private_ip}/",
      "        ProxyPassReverse / http://${aws_instance.http_c2.private_ip}/",
      "</VirtualHost>",
      "EOF",
      "sudo mv /tmp/000-default.conf.tmp /etc/apache2/sites-available/000-default.conf",
      "sudo systemctl restart apache2",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-http-redirector-${count.index}.sh; chmod 777 ./data/ssh/connect-http-redirector-${count.index}.sh"
  }
}

# ---http_c2---

resource "aws_instance" "http_c2" {
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.small"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.http_c2.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "http_c2"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
      "./data/scripts/cobalt_strike.sh",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-http-c2.sh; chmod 777 ./data/ssh/connect-http-c2.sh"
  }
}

# ---dns_redirector---

resource "aws_instance" "dns_redirector" {
  count                       = var.dns_redirector_instance_count
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.dns_redirector.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "dns_redirector_${count.index}"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # iptables redirection
      "echo \"127.0.0.1 $(hostname)\" | sudo tee -a /etc/hosts",
      "sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT",
      "sudo iptables -I INPUT -p udp -m udp --dport 53 -j ACCEPT",
      "sudo iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination ${aws_instance.dns_central_redirector.private_ip}:53",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination ${aws_instance.dns_central_redirector.private_ip}:80",
      "sudo iptables -t nat -A POSTROUTING -j MASQUERADE",
      "sudo iptables -I FORWARD -j ACCEPT",
      "sudo iptables -P FORWARD ACCEPT",
      "sudo sysctl net.ipv4.ip_forward=1",
      # Ubuntu Server 18.04 LTS resolve.conf
      "sudo systemctl disable systemd-resolved",
      "sudo systemctl stop systemd-resolved",
      "echo \"nameserver 8.8.8.8\" | sudo tee /etc/resolv.conf",
      "echo \"nameserver 8.8.4.4\" | sudo tee -a /etc/resolv.conf",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-dns-redirector-${count.index}.sh; chmod 777 ./data/ssh/connect-dns-redirector-${count.index}.sh"
  }
}

# ---dns_central_redirector---

resource "aws_instance" "dns_central_redirector" {
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.dns_central_redirector.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "dns_central_redirector"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # iptables redirection
      "echo \"127.0.0.1 $(hostname)\" | sudo tee -a /etc/hosts",
      "sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT",
      "sudo iptables -I INPUT -p tcp -m tcp --dport 50050 -j ACCEPT",
      "sudo iptables -I INPUT -p udp -m udp --dport 53 -j ACCEPT",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination ${aws_instance.dns_c2.private_ip}:80",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 50050 -j DNAT --to-destination ${aws_instance.dns_c2.private_ip}:50050",
      "sudo iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination ${aws_instance.dns_c2.private_ip}:53",
      "sudo iptables -t nat -A POSTROUTING -j MASQUERADE",
      "sudo iptables -I FORWARD -j ACCEPT",
      "sudo iptables -P FORWARD ACCEPT",
      "sudo sysctl net.ipv4.ip_forward=1",
      # Ubuntu Server 18.04 LTS resolve.conf
      "sudo systemctl disable systemd-resolved",
      "sudo systemctl stop systemd-resolved",
      "echo \"nameserver 8.8.8.8\" | sudo tee /etc/resolv.conf",
      "echo \"nameserver 8.8.4.4\" | sudo tee -a /etc/resolv.conf",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-dns-central-redirector.sh; chmod 777 ./data/ssh/connect-dns-central-redirector.sh"
  }
}

# ---dns_c2---

resource "aws_instance" "dns_c2" {
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.small"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.dns_c2.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "dns_c2"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
      "./data/scripts/cobalt_strike.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # Ubuntu Server 18.04 LTS resolve.conf
      "echo \"127.0.0.1 $(hostname)\" | sudo tee -a /etc/hosts",
      "sudo systemctl disable systemd-resolved",
      "sudo systemctl stop systemd-resolved",
      "echo \"nameserver 8.8.8.8\" | sudo tee /etc/resolv.conf",
      "echo \"nameserver 8.8.4.4\" | sudo tee -a /etc/resolv.conf",
      "echo \"nameserver $(hostname -I)\" | sudo tee -a /etc/resolv.conf",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-dns-c2.sh; chmod 777 ./data/ssh/connect-dns-c2.sh"
  }
}

# ---phishing_redirector---

resource "aws_instance" "phishing_redirector" {
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.phishing_redirector.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "phishing_redirector"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # apache install
      "sudo apt install -y apache2",
      "sudo a2enmod proxy proxy_http ssl",
      "sudo a2ensite default-ssl.conf",
      "sudo apt install -y libapache2-mod-security2",
      "sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf",
      "sudo timedatectl set-timezone Australia/Melbourne",
      # https redirection
      "sudo head -n -5 /etc/apache2/sites-available/default-ssl.conf > /tmp/default-ssl.conf.tmp",
      "sudo cat << EOF >> /tmp/default-ssl.conf.tmp",
      "                SSLProxyEngine On",
      "                ProxyPass / https://${aws_instance.phishing_host.private_ip}/",
      "                ProxyPassReverse / https://${aws_instance.phishing_host.private_ip}/",
      "                SSLProxyCheckPeerCN off",
      "                SSLProxyCheckPeerName off",
      "                SSLProxyCheckPeerExpire off",
      "        </VirtualHost>",
      "</IfModule>",
      "EOF",
      "sudo mv /tmp/default-ssl.conf.tmp /etc/apache2/sites-available/default-ssl.conf",
      # http redirection
      "sudo head -n -3 /etc/apache2/sites-available/000-default.conf > /tmp/000-default.conf.tmp",
      "sudo cat << EOF >> /tmp/000-default.conf.tmp",
      "        ProxyPass / http://${aws_instance.phishing_host.private_ip}/",
      "        ProxyPassReverse / http://${aws_instance.phishing_host.private_ip}/",
      "</VirtualHost>",
      "EOF",
      "sudo mv /tmp/000-default.conf.tmp /etc/apache2/sites-available/000-default.conf",
      "sudo systemctl restart apache2",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-phishing-redirector.sh; chmod 777 ./data/ssh/connect-phishing-redirector.sh"
  }
}

# ---phishing_host---

resource "aws_instance" "phishing_host" {
  ami                         = "ami-0b76c3b150c6b1423"
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.master.key_name
  vpc_security_group_ids      = [aws_security_group.phishing_host.id]
  subnet_id                   = aws_subnet.default.id
  associate_public_ip_address = true

  tags = {
    Name = "phishing_host"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    scripts = [
      "./data/scripts/apt_update.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # apache install
      "sudo apt install -y apache2",
      "sudo a2enmod proxy proxy_http ssl",
      "sudo a2ensite default-ssl.conf",
      "sudo apt install -y libapache2-mod-security2",
      "sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf",
      "sudo timedatectl set-timezone Australia/Melbourne",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem ubuntu@${self.public_ip}\" > ./data/ssh/connect-phishing-host.sh; chmod 777 ./data/ssh/connect-phishing-host.sh"
  }
}

# ---mail_server---

resource "digitalocean_droplet" "mail_server" {
  image    = "ubuntu-18-04-x64"
  name     = var.mail_domain
  region   = "sgp1"
  size     = "s-1vcpu-2gb"
  ssh_keys = [digitalocean_ssh_key.master.id]

  provisioner "local-exec" {
    command = "echo \"ssh -oStrictHostKeyChecking=no -i master_id_rsa.pem root@${self.ipv4_address}\" > ./data/ssh/connect-mail-server.sh; chmod 777 ./data/ssh/connect-mail-server.sh"
  }
}

resource "aws_route53_zone" "hosted_zone" {
  name = var.mail_domain
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = var.mail_domain
  type    = "A"
  ttl     = "300"
  records = [digitalocean_droplet.mail_server.ipv4_address]
}
