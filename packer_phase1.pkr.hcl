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

// affects disk size and if changed NEEDS TO BE CHANGED IN create_partitions.yml TOO!
variable "disk_size" {
  type    = string
  default = "60000"
}

variable "efi_release_file" {
  type    = string
  default = "RELEASEAARCH64_QEMU_EFI.fd"
}

variable "output_dir" {
  type    = string
  default = "output_archlinux"
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

variable "accelerator" { // Modify on Linux builders to kvm
  type    = string
  default = "hvf"
}

locals {
}

locals {
  qemu_edk2_aarch64  = "${path.cwd}/${var.efi_release_file}"
  root           = path.root
  vm_name = "archlinux-teaching-${formatdate("YYYYMMDD", timestamp())}"
}

source "virtualbox-iso" "archlinux" {
  guest_os_type = "ArchLinux_64" // Arch Linux 64-bit
  vm_name = "archlinux-x86_64"
  shutdown_command = "shutdown -P"
  format = "ovf"
  firmware = "efi"
  disk_size = "${var.disk_size}"
  iso_url = "https://arch.kyberorg.fi/iso/latest/archlinux-x86_64.iso"
  iso_checksum = "file:https://arch.kyberorg.fi/iso/latest/sha256sums.txt"
  hard_drive_interface = "sata"
  ssh_username = "root"
  ssh_password = "root"
  boot_wait         = "5s"
  boot_command      = ["<enter><wait25><enter>echo \"root:root\" | chpasswd <enter>"] // Select GRUB first entry

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{ .Name }}", "--vram", "${var.vram}"]
 ]

}


build {
  sources = ["sources.virtualbox-iso.archlinux"]

  provisioner "ansible" {
  command = "ansible-playbook"
  playbook_file = "${path.cwd}/create_partitions.yml"
  user = "root"
  inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
  extra_arguments = [
    "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
  ]
}

// needs time to think for about 10 seconds before next step. Doesnt work without 
provisioner "shell" {
  inline = [
    "sleep 10"
  ]
}

provisioner "ansible" {
  command = "ansible-playbook"
  playbook_file = "${path.cwd}/Install_arch1.yml"
  user = "root"
  inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
  extra_arguments = [
    "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
  ]
}

provisioner "shell" {
  inline = [
    "arch-chroot /mnt mkinitcpio -P",
    "sync"
  ]
}

provisioner "shell" {
  inline = [
    "umount -R /mnt"
  ]
}

}