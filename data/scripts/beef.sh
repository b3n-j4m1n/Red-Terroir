#!/bin/bash

sudo apt-get install -y ruby ruby-dev
sudo git clone https://github.com/beefproject/beef /opt/beef
sudo sed -i 's/get_permission$/# get_permission$/' /opt/beef/install
sudo sed -i 's/sudo apt-get/sudo apt -y/g' /opt/beef/install
cd /opt/beef/
sudo ./install
