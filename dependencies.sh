#!/bin/bash


echo "installing required packages please wait for install to finish. MANUAL CONFIG REGUIRED"
read -p "Enter username for used for allas:" username

sudo apt update && sudo apt install -y wget gpg
sudo add-apt-repository universe
wget -O- https://apt.releases.hashicorp.com/gpg | sudo tee /etc/apt/trusted.gpg.d/hashicorp.asc
echo "deb [signed-by=/etc/apt/trusted.gpg.d/hashicorp.asc] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo add-apt-repository universe -y
sudo apt update
 
sudo apt install -y packer python3 python3-pip python3-passlib ansible -y
 
ansible-galaxy collection install community.general
 
sudo apt-get install qemu-system

packer init packer_phase1.pkr.hcl
packer init packer_phase1.pkr.hcl


sudo pip3 install python-openstackclient
sudo apt install restic
curl https://rclone.org/install.sh | sudo bash
sudo pip3 install s3cmd

wget https://raw.githubusercontent.com/CSCfi/allas-cli-utils/master/allas_conf

source allas_conf --mode S3 --user ${username}
