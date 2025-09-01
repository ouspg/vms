packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    virtualbox = {
      version = " >= 1.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
    ansible = {
      version = "~> 1.1.2"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "output_dir_qemu" {
  type    = string
  default = "output_archlinux2_qemu"
}

variable "output_dir_vbox" {
  type    = string
  default = "output_archlinux2_vbox"
}

variable "disk_size" {
  type    = string
  default = "60000"
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
  default = "hvf"
}

source "qemu" "archlinux_qemu_arch" {
  disk_image = true
  headless = true
  output_directory  = "${var.output_dir_qemu}"
  disk_size  = "${var.disk_size}"
  iso_url    = "${path.cwd}/output_archlinux_qemu/archlinux-x86_64"
  iso_checksum = "sha256:${file("${path.cwd}/output_archlinux_qemu/checksum.txt")}"
  ssh_username = "arch"
  ssh_password = "arch"
  vm_name      = "archlinux-x86_64"
  format       = "qcow2"
  boot_wait    = "200s"
  accelerator = "none"
  efi_firmware_code = "/usr/share/OVMF/x64/OVMF_CODE.4m.fd"
  efi_firmware_vars = "/usr/share/OVMF/x64/OVMF_VARS.4m.fd"
  qemu_binary = "/usr/bin/qemu-system-x86_64"
}

source "qemu" "archlinux_qemu_ubuntu" {
  disk_image = true
  headless = true
  output_directory  = "${var.output_dir_qemu}"
  disk_size  = "${var.disk_size}"
  iso_url    = "${path.cwd}/output_archlinux_qemu/archlinux-x86_64"
  iso_checksum = "sha256:${file("${path.cwd}/output_archlinux_qemu/checksum.txt")}"
  ssh_username = "arch"
  ssh_password = "arch"
  vm_name      = "archlinux-x86_64"
  format       = "qcow2"
  boot_wait    = "200s"
  accelerator = "none"
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  qemu_binary = "/usr/bin/qemu-system-x86_64"
}

source "virtualbox-ovf" "archlinux_vbox" {
  source_path = "${path.cwd}/output_archlinux_vbox/archlinux-x86_64.ovf"
  ssh_username = "arch"
  ssh_password = "arch"
  vm_name = "archlinux-x86_64"
  output_directory  = "${var.output_dir_vbox}"
  format = "ova"
  boot_wait = "10s"
  headless = true
}

build {
  sources = ["source.qemu.archlinux_qemu_ubuntu", "source.qemu.archlinux_qemu_arch", "source.virtualbox-ovf.archlinux_vbox"]

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/ansible/install_arch2.yml"
    user = "arch"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/ansible/install_packages.yml"
    user = "arch"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }

  provisioner "ansible" {
    command = "ansible-playbook"
    playbook_file = "${path.cwd}/ansible/set_time_fi.yml"
    user = "arch"
    inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
    extra_arguments = [
      "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
    ]
  }
}
