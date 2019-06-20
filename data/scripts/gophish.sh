#!/bin/bash

sudo mkdir /opt/gophish
sudo wget https://github.com/gophish/gophish/releases/download/0.7.1/gophish-v0.7.1-linux-64bit.zip -O /opt/gophish/gophish-v0.7.1-linux-64bit.zip
sudo apt-get install -y unzip
sudo unzip /opt/gophish/gophish-v0.7.1-linux-64bit.zip -d /opt/gophish
