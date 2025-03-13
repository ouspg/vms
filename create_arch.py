#!/usr/bin/env python3

import os
import subprocess

def run_packer(file_path):
    """Runs a Packer file and exits the script if it fails."""
    try:
        subprocess.run(["packer", "build", file_path], check=True)
    except subprocess.CalledProcessError:
        print(f"Error: Packer build failed for {file_path}")
        exit(1)

def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    phase1_file = os.path.join(current_dir, "packer_phase1.pkr.hcl")
    phase2_file = os.path.join(current_dir, "packer_phase2.pkr.hcl")
    final_output_ovf = os.path.join(current_dir, "output-archlinux", "archlinux-x86_64.ovf")
    
    if not os.path.exists(final_output_ovf):
        print("Running Phase 1...")
        run_packer(phase1_file)
    else:
        print("OVF file exists, skipping Phase 1...")
    
    print("Running Phase 2...")
    run_packer(phase2_file)

if __name__ == "__main__":
    main()
