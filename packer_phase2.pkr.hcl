packer {
  required_plugins {
    virtualbox = {
      version = " >= 1.0.1"
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


variable "output_dir" {
  type    = string
  default = "output_archlinux2"
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

source "virtualbox-ovf" "archlinux2" {
  source_path = "${path.cwd}/output-archlinux/archlinux-x86_64.ovf"
  ssh_username = "arch"
  ssh_password = "arch"
  vm_name = "archlinux-x86_64"
  format = "ova"
  boot_wait = "10s"
}



build {
  sources = [ "virtualbox-ovf.archlinux2" ]


  provisioner "ansible" {
  command = "ansible-playbook"
  playbook_file = "${path.cwd}/install_arch2.yml"
  user = "arch"
  inventory_file_template = "controller ansible_host={{ .Host }} ansible_user={{ .User }} ansible_port={{ .Port }}\n"
  extra_arguments = [
    "--extra-vars", "ansible_env={'LC_ALL': 'C.UTF-8'} ansible_become=true ansible_become_method=sudo"
  ]
}


}

