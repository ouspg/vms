#!/usr/bin/env python3

import os
import subprocess
import sys
import time

QEMU_OUTPUT_FILE = "output_archlinux_qemu/archlinux-x86_64"
VBOX_OUTPUT_FILE = "output_archlinux_vbox/archlinux-x86_64.ovf"


MAX_RETRIES = 3

def run_command(cmd, retries=0):
    """Runs a shell command and retries if certain errors occur."""
    attempts = 0
    while attempts < retries:  # Change here from <= to <
        try:
            subprocess.run(cmd, check=True, shell=isinstance(cmd, str))
            return
        except subprocess.CalledProcessError as e:

            error_message = str(e)
            if ("key" in error_message or "Less than 1 bytes/sec transferred" in error_message) and attempts < retries:
                attempts += 1
                print(f"Retrying... (Attempt {attempts}/{retries})")
                time.sleep(2)
                print(f"Error: {error_message}")
            else:
                print(f"Error: {error_message}")
                sys.exit(1)
    print(f"Failed after {retries} retries.")
    sys.exit(1)


def phase1_output_exists(build_type):
    """Checks if phase 1 output exists for the selected build type."""
    if build_type == "1":
        return os.path.exists(QEMU_OUTPUT_FILE)
    elif build_type == "2":
        return os.path.exists(VBOX_OUTPUT_FILE)
    return False

def run_packer(build_type, retries_enabled):
    """Runs Packer build commands based on user selection."""
    
    if build_type == "1":
        print("Building with QEMU...")

        if not phase1_output_exists(build_type):
            run_command(["packer", "build", "-only=qemu.archlinux_qemu", "packer_phase1.pkr.hcl"], retries=MAX_RETRIES if retries_enabled else 0)

        print("Starting phase 2 for QEMU...")
        subprocess.run("./checksum.sh")
        run_command(["packer", "build", "-only=qemu.archlinux_qemu", "packer_phase2.pkr.hcl"], retries=MAX_RETRIES if retries_enabled else 0)

    elif build_type == "2":
        print("Building with VirtualBox...")

        if not phase1_output_exists(build_type):
            run_command(["packer", "build", "-only=virtualbox-iso.archlinux_vbox", "packer_phase1.pkr.hcl"], retries=MAX_RETRIES if retries_enabled else 0)

        print("Starting phase 2 for VirtualBox...")
        run_command(["packer", "build", "-only=virtualbox-ovf.archlinux_vbox", "packer_phase2.pkr.hcl"], retries=MAX_RETRIES if retries_enabled else 0)

    else:
        print("Invalid choice. Please enter 1 or 2.")
        sys.exit(1)

if __name__ == "__main__":
    choice = input("Select build type: 1) QEMU  2) VirtualBox: ")
    
    retries_choice = input("Do you want to enable retries for key-related issues and network-related issues? Retries 3 times. 1) Yes  2) No: ")
    retries_enabled = retries_choice == "1"
    
    run_packer(choice, retries_enabled)
