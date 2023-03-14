

variable "memory" {
  type    = string
  default = "4096"
}

variable "efi_release_file" {
  type    = string
  default = "RELEASEAARCH64_QEMU_EFI.fd"
}

variable "vm_password" {
  type    = string
  default = "arch"
}

variable "vm_username" {
  type    = string
  default = "arch"
}

variable "vram" {
  type    = string
  default = "32"
}

locals {
}
locals {
  qemu_edk2_aarch64  = "${path.cwd}/${var.efi_release_file}"
  root           = path.root
  vm_name = "archlinux-teaching-${formatdate("YYYYMMDD", timestamp())}"
}


source "qemu" "arch-aarch64" {
  qemu_binary       = "qemu-system-aarch64" // 
  iso_url           = "archboot-2023-aarch64.iso"
  iso_checksum      = "sha256:5bc28c54c8d8df9ad515e2df9f995ac6e3409a5921974d6ebce71abc4e1f09b9"
  output_directory  = "output_archlinuxarm"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = "30720M"
  memory            = "${var.memory}" // Build-time memory
  use_default_display = true
  format            = "qcow2"
  accelerator       = "hvf" // Does not work for some reason in Mac!
  http_directory    = "http"
  ssh_username      = "root"
  ssh_password      = ""
  ssh_timeout       = "20m"
  vm_name           = "archlinuxarm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "5s"
  // boot_command      = ["<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/enable-ssh.sh<enter><wait>"]
  // Archboot initiates sshd automatically
  boot_command      = ["<enter>"] // Select GRUB first entry
  qemuargs = [
    [ "-cpu", "host" ],
    [ "-accel", "hvf" ], // Apple virtualisation framework, change for kvm on Linux
    [ "-smp", "2" ],
    [ "-display", "cocoa,show-cursor=on" ], // cocoa for MacOS, change for default on Linux
    [ "-monitor", "stdio" ],
    [ "-machine", "virt,highmem=on" ],
    [ "-bios", "${local.qemu_edk2_aarch64}" ],
    [ "-boot", "strict=off" ],
    [ "-device", "virtio-gpu-pci" ],
    [ "-device", "nec-usb-xhci" ],
    [ "-device", "qemu-xhci" ],
    [ "-device", "usb-tablet" ],
    [ "-device", "usb-kbd" ],
  ]
}


build {
  sources = ["source.qemu.arch-aarch64"]

  provisioner "shell-local" {
    inline = ["echo hi"]
  }
  provisioner "file" {
    source = "files/mirrorlist" # Select closes server to Finland (Denmark)
    destination = "/etc/pacman.d/mirrorlist"
  }
  provisioner "shell" {
    inline = ["pacman -Sy --noconfirm ansible-core"]
  }
  provisioner "breakpoint" {
    disable = false
    note    = "this is a breakpoint"
  }
  provisioner "shell-local" {
    inline = ["echo hi 2"]
  }
}

# spice-vdagent