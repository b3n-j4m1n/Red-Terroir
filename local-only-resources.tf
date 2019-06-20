resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.ssh.private_key_pem}\" > ./data/ssh/master_id_rsa.pem; chmod 400 ./data/ssh/master_id_rsa.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm ./data/ssh/master_id_rsa.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm ./data/ssh/connect*"
  }
}

resource "aws_key_pair" "master" {
  key_name   = "master_ssh_key_aws"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "digitalocean_ssh_key" "master" {
  name       = "master_ssh_key_digitalocean"
  public_key = tls_private_key.ssh.public_key_openssh
}
