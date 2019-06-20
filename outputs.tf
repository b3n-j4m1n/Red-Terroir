output "http_redirector_private_ip" {
  value = {
    for instance in aws_instance.http_redirector:
    instance.tags.Name => instance.private_ip
  }
}

output "http_redirector_public_ip" {
  value = {
    for instance in aws_instance.http_redirector:
    instance.tags.Name => instance.public_ip
  }
}

output "http_c2" {
  value = "[\nprivate ip = ${aws_instance.http_c2.private_ip}\npublic ip  = ${aws_instance.http_c2.public_ip}\n]"
}

output "dns_redirector_private_ip" {
  value = {
    for instance in aws_instance.dns_redirector:
    instance.tags.Name => instance.private_ip
  }
}

output "dns_redirector_public_ip" {
  value = {
    for instance in aws_instance.dns_redirector:
    instance.tags.Name => instance.public_ip
  }
}

output "dns_central_redirector" {
  value = "[\nprivate ip = ${aws_instance.dns_central_redirector.private_ip}\npublic ip  = ${aws_instance.dns_central_redirector.public_ip}\n]"
}

output "dns_c2" {
  value = "[\nprivate ip = ${aws_instance.dns_c2.private_ip}\npublic ip  = ${aws_instance.dns_c2.public_ip}\n]"
}

output "phishing_redirector" {
  value = "[\nprivate ip = ${aws_instance.phishing_redirector.private_ip}\npublic ip  = ${aws_instance.phishing_redirector.public_ip}\n]"
}

output "phishing_host" {
  value = "[\nprivate ip = ${aws_instance.phishing_host.private_ip}\npublic ip  = ${aws_instance.phishing_host.public_ip}\n]"
}

output "mail_server" {
  value = "[\npublic ip  = ${digitalocean_droplet.mail_server.ipv4_address}\n]"
}
