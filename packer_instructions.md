# PACKER

**This document is divided into three main parts:**  
- **Start**: Contains all basic files.  
- **First Packer Phase**: Contains everything installed in the first checkpoint.  
- **Second Packer Phase**: Contains everything installed after that.  

## Start

First, run `Permissions.sh` to set the correct file permissions. Then run `dependencies.sh` to install all required dependencies.

If you want faster build times and your machine supports it, add the supported accelerator to the Packer files.

The main file is always the Python script `create_arch.py`.  
It first asks:
- Which operating system you want to use for the build (recommended: **Ubuntu**)
- Which virtualization backend to use (recommended: **QEMU**)

The script always resumes from the latest checkpoint.  
If you want to start the whole build from scratch, you need to delete the folders and the disk files inside them.

The script also:
- Runs the intermediate build phase (see: Phase 2)
- Checks if the pool is configured
  - If yes: it pushes the virtual machine there
  - If no: it stores it locally

## First Packer Phase

You should avoid modifying the first Packer file (`packer_phase1.pkr.hcl`) unless you need to change core base programs.  
**Any extra software installations should be done in Build Phase 2** (`packer_phase2.pkr.hcl`).

Build Phase 1 includes the following files that should not be modified (example: QEMU builder):

- `packer_phase1.pkr.hcl` – controls everything
- `create_partitions_qemu.yml` – creates the disks
- `Install_arch1_qemu.yml` – installs the required base system
- `prepare_export.yml` – prepares the machine to be captured

These install the basic requirements for the machine so that Phase 2 can begin.

## Second Packer Phase

Before running Phase 2, capture the disk’s checksum using `checksum.sh`.  
This ensures the file is safe for Packer to run. The checksum is temporarily saved to a text file.

Once Packer has the checksum, it will proceed with the build.

The order of execution in this phase doesn’t matter much. If you want to install your preferred software, either:

- Modify `install_packages.yml`, or
- Create your own YML file and add it to `packer_phase2.pkr.hcl` by copying the existing reference and renaming it.

Included files:

- `install_arch2.yml` – installs Zsh and the BlackArch repository
- `install_packages.yml` – installs all additional desired packages
- `set_time_fi.yml` – sets the timezone to Finland  
  *(This is also done earlier during Arch setup, but is repeated here to ensure persistence)*
