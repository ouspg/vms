packer {
  required_plugins {
    virtualbox = {
      version = " >= 1.0.1 "
      source = "github.com/hashicorp/virtualbox"
    }
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      version = "~> 1.1.2"
      source = "github.com/hashicorp/ansible"
    }
  }
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "cpus" {
  type    = string
  default = "4"
}

variable "vram" {
  type    = string
  default = "32"
}

variable "disk_size" {
  type    = string
  default = "40000"
}

variable "efi_release_file" {
  type    = string
  default = "RELEASEAARCH64_QEMU_EFI.fd"
}

variable "output_dir_qemu" {
  type    = string
  default = "output_archlinux_qemu"
}

variable "output_dir_vbox" {
  type    = string
  default = "output_archlinux_vbox"
}

variable "passwd" {
  type    = string
  default = "arch"
}

variable "user" {
  type    = string
  default = "arch"
}

variable "dotfiles_dir" {
  type    = string
  default = "dotfiles"
}

variable "accelerator" {
  type    = string
  default = "kvm"
}

locals {
  qemu_edk2_aarch64  = "${path.cwd}/${var.efi_release_file}"
  root           = path.root
  vm_name = "archlinux-teaching-${formatdate("YYYYMMDD", timestamp())}"
}

source "qemu" "archlinux_qemu" {
  iso_url           = "https://arch.kyberorg.fi/iso/latest/archlinux-x86_64.iso"
  iso_checksum      = "file:https://arch.kyberorg.fi/iso/latest/sha256sums.txt"
  headless = true
  vm_name = "archlinux-x86_64"
  disk_size         = "${var.disk_size}"
  output_directory  = "${var.output_dir_qemu}"
  memory           = "${var.memory}"
  cpus             = "${var.cpus}"
  accelerator      = "none"
  format = "qcow2"
  ssh_username = "root"
  ssh_password = "root"
  boot_wait         = "50s"
  boot_command      = ["<wait60><enter>ip a<enter>date<enter><wait25><enter>echo \"root:root\" | chpasswd <enter>"]
}

source "virtualbox-iso" "archlinux_vbox" {
  guest_os_type = "ArchLinux_64"
  vm_name = "archlinux-x86_64"
  shutdown_command = "shutdown -P"
  headless = true
  format = "ovf"
  output_directory  = "${var.output_dir_vbox}"
  firmware = "efi"
  disk_size = "${var.disk_size}"
  iso_url = "https://arch.kyberorg.fi/iso/latest/archlinux-x86_64.iso"
  iso_checksum = "file:https://arch.kyberorg.fi/iso/latest/sha256sums.txt"
  hard_drive_interface = "sata"
  ssh_username = "root"
  ssh_password = "root"
  boot_wait         = "5s"
  boot_command      = ["<enter><wait25><enter>echo \"root:root\" | chpasswd <enter>"]
  
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{ .Name }}", "--vram", "${var.vram}"]
  ]

  
}

build {
  sources = ["source.qemu.archlinux_qemu"]

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/create_partitions_qemu.yml"
    user = "root"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }

  provisioner "shell" {
    inline = [
      "sleep 10"
    ]
  }

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/Install_arch1_qemu.yml"
    user = "root"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/prepare_export.yml"
    user = "root"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }
}

build {
  sources = ["source.virtualbox-iso.archlinux_vbox"]

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/create_partitions_vbox.yml"
    user = "root"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }

  provisioner "shell" {
    inline = [
      "sleep 10"
    ]
  }

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/Install_arch1_vbox.yml"
    user = "root"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/prepare_export.yml"
    user = "root"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }
}