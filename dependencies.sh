#!/bin/bash

if [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
    sudo apt install -y python3 python3-pip python3-passlib ansible
    sudo pip install --upgrade ansible
    sudo pip3 install s3cmd
    sudo pip3 install python-openstackclient
    ansible-galaxy collection install community.general
    echo "essentials for running python installed. please continue setup by running create_arch.py"
else
    echo "Unsupported OS for Python/Ansible installation"
fi
