# Guide to build virtual machines

note that if you decide to use qemu it will not use hardware acceleration by default. this may make the builds take forever to complete but it makes this work in virtual machines.

## step 1. permissions for files.

you need to give .hcl .py and .sh files in this current directory and its sub directories permissions to run on your operating system. easiest way is "chmod 755 permissions.sh" but this can also be done manually.

## step2 dependencies

packer
python3
python3-pip
python-passlib
ansible
ansible community general
virtualbox/qemu (qemu is recommended and comes with the base dependencies.sh file)

working versions as of now

ansible [core 2.17.10]

python [3.10.12]

packer [1.12.0]

qemu-system-x86_64 [6.2.0]

dependencies.sh file will always install the newest possible version so keep that in mind.

if you want some of these to be installed on your computer automatically please run dependencies.sh and skip to step 4
note that this may not work for all computers since configurations may vary. script will not install virtualbox and its dependencies.

## step 3 initialize files (if you ran dependencies.sh it should have done it for you)

you have to run "packer init packer_phase1.pkr.hcl" and "packer init packer_phase2.pkr.hcl"

this will install reguired plugins for packer to run the files

## step 4 running the project

there are two ways you can do this. first is to run create_arch.py with "./create_arch.py" this will run both packer files one after the other and reguires no user input unless errors occur. If errors do occur it starts from the second one if the first one finished succesfully.

the other option is to run the .hcl files yourself manually by doing

for qemu
"packer build -only=qemu.archlinux_qemu packer_phase1.pkr.hcl" then running "./checksum.sh" and for ubuntu base OS "packer build -only=qemu.archlinux_qemu_ubuntu packer_phase2.pkr.hcl" and for arch base OS "packer build -only=qemu.archlinux_qemu_arch packer_phase2.pkr.hcl"

for virtualbox
"packer build -only=virtualbox-iso.archlinux_vbox packer_phase1.pkr.hcl" and "packer build -only=virtualbox-ovf.archlinux_vbox packer_phase2.pkr.hcl"

step 5 finished

once finished the final file will be in the second output directory.
