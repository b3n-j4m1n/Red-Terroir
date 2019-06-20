# providers
variable "aws_access_key" {
}

variable "aws_secret_key" {
}

variable "aws_region" {
}

variable "digitalocean_token" {
}

# restricted access
variable "ip_whitelist" {
  type = list(string)
}

# counts
variable "http_redirector_instance_count" {
  type = number
}

variable "dns_redirector_instance_count" {
  type = number
}

# phishing
variable "mail_domain" {
}
