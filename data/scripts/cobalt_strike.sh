#!/bin/bash

key='xxxx-xxxx-xxxx-xxxx'

sudo apt install -y default-jdk
token=$(curl -s https://www.cobaltstrike.com/download -d "dlkey=${key}" | grep 'href="/downloads/' | cut -d '/' -f3)
curl -s https://www.cobaltstrike.com/downloads/${token}/cobaltstrike-trial.tgz -o /tmp/cobaltstrike.tgz
sudo mkdir /opt/cobaltstrike
sudo tar zxf /tmp/cobaltstrike.tgz -C /opt/
sudo bash -c "echo ${key} > /opt/cobaltstrike/.cobaltstrike.license"
rm /tmp/cobaltstrike.tgz
