#!/usr/bin/env python3

import os
import subprocess
import sys
from pathlib import Path

def run_command(cmd):
    try:
        subprocess.run(cmd, check=True, shell=isinstance(cmd, str))
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        sys.exit(1)

def initial_setup():
    print("Running initial setup...")

    run_command("sudo apt update && sudo apt install -y wget gpg")
    run_command("sudo add-apt-repository universe -y")
    run_command("wget -O- https://apt.releases.hashicorp.com/gpg | sudo tee /etc/apt/trusted.gpg.d/hashicorp.asc")
    run_command(
        "echo 'deb [signed-by=/etc/apt/trusted.gpg.d/hashicorp.asc] https://apt.releases.hashicorp.com $(lsb_release -cs) main' "
        "| sudo tee /etc/apt/sources.list.d/hashicorp.list"
    )
    run_command("sudo apt update")
    run_command("sudo apt install -y ovmf packer qemu-system")
    run_command("sudo apt install -y python3 python3-pip python3-passlib ansible")
    run_command("pip3 install --upgrade ansible")
    run_command("ansible-galaxy collection install community.general")

    run_command("packer init packer_phase1.pkr.hcl")
    run_command("packer init packer_phase2.pkr.hcl")

    Path(".setup_done").touch()
    print("Initial setup complete.")

def configure_allas():
    print("configuring allas")

    run_command("sudo apt install restic")
    run_command("curl https://rclone.org/install.sh | bash")
    run_command("wget https://raw.githubusercontent.com/CSCfi/allas-cli-utils/master/allas_conf")
    run_command("source allas_conf --mode s3 --user {username}")