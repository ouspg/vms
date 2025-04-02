#!/usr/bin/env python3

import os
import subprocess
import sys

def run_command(cmd):
    """Runs a shell command and exits on failure."""
    try:
        subprocess.run(cmd, check=True, shell=isinstance(cmd, str))
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        sys.exit(1)

def phase1_output_exists(build_type):
    """Checks if phase 1 output exists for the selected build type."""
    if build_type == "1":
        return os.path.exists("output_archlinux_qemu/archlinux-x86_64")
    elif build_type == "2":
        return os.path.exists("output_archlinux_vbox/archlinux-x86_64.ovf")
    return False

def run_packer(build_type, base_os):
    """Runs Packer build commands based on user selection."""
    if base_os == "1":
        qemu_target = "qemu.archlinux_qemu_ubuntu"
    elif base_os == "2":
        qemu_target = "qemu.archlinux_qemu_arch"
    else:
        print("Invalid OS selection. Please enter 1 for Ubuntu or 2 for Arch.")
        sys.exit(1)
    
    if build_type == "1":
        print(f"Building with QEMU ({qemu_target})...")
        if not phase1_output_exists(build_type):
            run_command(["packer", "build", "-only=qemu.archlinux_qemu", "packer_phase1.pkr.hcl"])
        print("Starting phase 2 for QEMU...")
        subprocess.run("./checksum.sh")
        run_command(["packer", "build", "-only=" + qemu_target, "packer_phase2.pkr.hcl"])
    elif build_type == "2":
        print("Building with VirtualBox...")
        if not phase1_output_exists(build_type):
            run_command(["packer", "build", "-only=virtualbox-iso.archlinux_vbox", "packer_phase1.pkr.hcl"])
        print("Starting phase 2 for VirtualBox...")
        run_command(["packer", "build", "-only=virtualbox-ovf.archlinux_vbox", "packer_phase2.pkr.hcl"])
    else:
        print("Invalid choice. Please enter 1 or 2.")
        sys.exit(1)

if __name__ == "__main__":
    base_os = input("Select base OS: 1) Ubuntu  2) Arch: ")
    choice = input("Select build type: 1) QEMU  2) VirtualBox: ")
    run_packer(choice, base_os)
