# Red Terroir

<p align="center">
<img src=https://raw.githubusercontent.com/b3n-j4m1n/Red-Terroir/master/data/images/infrastructure_diagram.png>
</p>

### Getting Started

Download Terraform and copy the binary to the Red Terroir directory - https://www.terraform.io/downloads.html

`./terraform init`

`./terraform apply`

The variables in `terraform.tfvars` need to be set, also the `key` `in data/scripts/cobalt_strike.sh` if you intend on using Cobalt Strike.

SSH access to everything uses the same key pair, when an instance or droplet is built a quick connection script will be created in `data/ssh/`

### HTTP Channel

The redirector configures Apache ProxyPass as part of the build, proxying TCP:80,443, certificates can be installed with `data/scripts/lets_encrypt.sh`. The number of redirectors built is determined by the `http_redirector_instance_count` in `terraform.tfvars`.

If a domain or IP is blacklisted, you can simply destroy that specific resource and rebuild, the new instance will be integrated to the infrastructure. To add more instances just edit the count variable and `./terraform apply`.

To build just this channel run the following.

```
./terraform apply -target=aws_instance.http_redirector -target=aws_route_table_association.default
```

##### Domain Host Records

```
---------------------------------------------------------
Type             Host         Value
---------------------------------------------------------
A Record         @            13.239.4.196
CNAME Record     www          example.com
---------------------------------------------------------
```

### DNS Channel

If using Cobalt Strike, launch the teamserver from the DNS C2 specifying the public IP of the central redirector, for any listeners (Cobalt Strike or other) just use the public IPs of the regular DNS redirectors.

To build just this channel run the following.

```
./terraform apply -target=aws_instance.dns_redirector -target=aws_route_table_association.default
```

##### Domain Host Records

```
---------------------------------------------------------
Type             Host         Value
---------------------------------------------------------
A Record         @            13.239.4.196
A Record         ns1          13.239.4.196
NS Record        abc          ns1.example.com
---------------------------------------------------------
```

### Phishing Channel

The phishing channel is intended to host a credential phishing page or a payload for initial access. Apache ProxyPass is configured the same as the HTTP redirector. Create the phishing page and any payloads on the phishing host under `/var/www/html/`

To build just this channel run the following.

```
./terraform apply -target=aws_instance.phishing_redirector -target=aws_route_table_association.default
```
##### Domain Host Records

The A Record is the public IP of the phishing redirector, wait 10 minutes for propagation after updating the host records, test loading the domain in your browser.

```
---------------------------------------------------------
Type             Host         Value
---------------------------------------------------------
A Record         @            13.239.4.196
CNAME Record     www          example.com
---------------------------------------------------------
```

### Apache mod_rewrite

Apache mod_rewrite can be used to redirect traffic, such as filtering out IP ranges, only allowing access between 9am-5pm, redirecting based on OS architecture, or evading IDR.

It can be enabled (and ProxyPass disabled) by running `data/scripts/mod_rewrite`.Create a .htaccess file with redirection rules at `/var/www/html/.htaccess` on the phishing redirector, use the [sample .htaccess file](https://github.com/b3n-j4m1n/Red-Terroir/blob/master/data/apache/htaccess) as a reference.

### Mail Server

The mail server uses Mail-in-a-Box which handles just about everything, including encryption, anti-spam headers, etc. DigitalOcean is used for the reverse DNS as part of the build. Route53 is used due to name server limitations in Namecheap. Check https://www.expireddomains.net/ for a domain with some history, also check it against any online domain reputation service. You can get unlucky with a public IP of bad repute, in which case just destroy and rebuild the droplet. The region is hardcoded to SGP1: Singapore in the `main.tf` file.

To build just this channel run the following.

```
./terraform apply -target=digitalocean_droplet.mail_server -target=aws_route53_record.a_record
```

The Droplet hostname and Route53 hosted zone A record need to match, this is handled by the `mail_domain` variable in `terraform.tfvars`.

##### Route53 Name Servers

The Route53 name servers and glue records need to be updated for the domain, use the public IP of the mail server for the glue records. You don't need to use the ns1.box.domain.com subdomain Mail-in-a-Box suggests. To my knowledge this doesn't have an applicable Terraform resource, so it's done manually. The update takes a minute, you'll get an email when complete.

<p align="center">
<img src=https://raw.githubusercontent.com/b3n-j4m1n/Red-Terroir/master/data/images/registered_domains.png>
</p>

<p align="center">
<img src=https://raw.githubusercontent.com/b3n-j4m1n/Red-Terroir/master/data/images/glue_records.png>
</p>

##### Mail-in-a-Box install

https://mailinabox.email/guide.html

```
cd data/ssh/
./connect-mail-server.sh
curl -s https://mailinabox.email/setup.sh | sudo -E bash
```

The hostname set during installation must match `mail_domain` used in the Droplet creation. When installation is complete you can view the status at https://domain.com/admin, all that should be needed is a reboot and then provisioning the TLS certificate.

You can access the mailbox at https://domain.com/mail and check a test email with https://www.mail-tester.com/

<p align="center">
<img src=https://raw.githubusercontent.com/b3n-j4m1n/Red-Terroir/master/data/images/mail-tester.png>
</p>


### TODO

- Create a better README.md
- Guides on various C2 implants.
- ~~output.tf needs fixing.~~
- Provisioner scripts for other post-exploitation frameworks, and GoPhish.
- Create a resource for adding additional key pairs.
