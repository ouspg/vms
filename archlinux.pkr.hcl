
packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.1"
      source = "github.com/hashicorp/virtualbox"
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
  default = "30720"
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
  format = "ova"
  firmware = "efi"
  disk_size = "${var.disk_size}"
  iso_url = "https://arch.kyberorg.fi/iso/latest/archlinux-x86_64.iso"
  iso_checksum = "file:https://arch.kyberorg.fi/iso/latest/sha256sums.txt"
  hard_drive_interface = "sata"
  ssh_username = "root"
  ssh_password = "root"
  shutdown_command = "shutdown -P now"
  boot_wait         = "5s"
  boot_command      = ["<enter><wait25><enter>echo \"root:root\" | chpasswd <enter>"] // Select GRUB first entry

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{ .Name }}", "--vram", "${var.vram}"]
 ]

}

source "qemu" "arch-aarch64" {
  qemu_binary       = "qemu-system-aarch64" // 
  iso_url           = "https://pkgbuild.com/~tpowa/archboot/iso/aarch64/latest/archboot-2023.03.17-10.06-aarch64.iso"
  iso_checksum      = "file:https://pkgbuild.com/~tpowa/archboot/iso/aarch64/latest/sha256sum.txt"
  output_directory  = "${var.output_dir}"
  shutdown_command  = "shutdown -P now"
  disk_size         = "${var.disk_size}M"
  memory            = "${var.memory}" // Build-time memory
  use_default_display = true
  format            = "qcow2"
  accelerator       = "hvf" // Does not work for some reason in Mac!
  // http_directory    = "http"
  ssh_username      = "root"
  ssh_password      = ""
  ssh_timeout       = "10m"
  vm_name           = "archlinuxarm"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  firmware          = "${local.qemu_edk2_aarch64}"
  boot_wait         = "5s"
  // Archboot initiates sshd automatically
  boot_command      = ["<enter><wait15><leftCtrlOn>c<leftCtrlOff>"] // Select GRUB first entry
  qemuargs = [
    [ "-cpu", "host" ],
    [ "-accel", "${var.accelerator}" ], // Apple virtualisation framework is hvf, change for kvm on Linux
    [ "-smp", "2" ],
    [ "-display", "cocoa,show-cursor=on" ], // cocoa for MacOS, change for default on Linux
    [ "-monitor", "stdio" ],
    [ "-machine", "virt,highmem=on" ],
    [ "-boot", "strict=off" ],
    [ "-device", "virtio-gpu-pci" ],
    [ "-device", "nec-usb-xhci" ],
    [ "-device", "qemu-xhci" ],
    [ "-device", "usb-tablet" ],
    [ "-device", "usb-kbd" ],
  ]
}


build {
  sources = ["source.qemu.arch-aarch64", "sources.virtualbox-iso.archlinux"]


  provisioner "file" {
    source = "files/mirrorlist" # Select closes server to Finland (Denmark for ARM repos)
    destination = "/etc/pacman.d/mirrorlist"
    only = ["qemu.arch-aarch64"]
  }

  provisioner "file" {
    source = "archinstall/" # Archinstall script configurations
    destination = "/root/"
  }
  provisioner "shell" {
    script = "keyring-update.sh" // Wait for keyring to update before starting anything
  }
  provisioner "shell" {
    only = ["qemu.arch-aarch64"]
    inline = [
      "pacman -Sy archinstall --noconfirm",
      "rm /dev/loop*", // For some reason these loop devices break archinstall on ARM, we don't need them anyway
      "archinstall --creds /root/user_credentials.json --conf /root/user_configuration.json --disk_layout /root/archinstall-disk-layout.json --silent"
      ]
  }
  provisioner "shell" {
    only = ["virtualbox-iso.archlinux"]
    inline = [
      "pacman -Sy --needed archinstall --noconfirm",
      "archinstall --creds /root/user_credentials.json --conf /root/user_configuration.json --disk_layout /root/archinstall-disk-layout-x86-64.json --silent"
      ]
  }

  provisioner "breakpoint" {
    disable = false
    note    = ""
  }
  // Archinstall will mount the filesystem in /mnt/archinstall by default
  provisioner "shell" {
    max_retries = 3 // There is timeout for sudo use, too lazy to make builder use for yay
    inline = [
      "arch-chroot /mnt/archinstall pacman -S yay --noconfirm",
      "arch-chroot /mnt/archinstall bash -c 'su arch -c \"echo arch | yay --sudoflags=-S -S vscodium-bin --noconfirm\"'", // Maybe we need Ansible after all
      "arch-chroot /mnt/archinstall su ${var.user} -c 'touch /home/${var.user}/.zshrc'", //We have grml configuration as we are lazy
      "arch-chroot /mnt/archinstall chsh -s /bin/zsh ${var.user}",
      // "arch-chroot /mnt/archinstall sudo -u arch dbus-launch --exit-with-session gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'fi'), ('xkb', 'us')]\"", // Add Finnish keyboard layout, quotes not allowed around array, dbus use required
      // "arch-chroot /mnt/archinstall sudo -u arch dbus-launch --exit-with-session gsettings set org.gnome.shell favorite-apps \"['org.gnome.Nautilus.desktop', 'org.wezfurlong.wezterm.desktop', 'firefox.desktop', 'codium.desktop', 'org.gnome.Settings.desktop']\"", // Add favorite apps to Gnome Shell
      // Difficult... https://unix.stackexchange.com/questions/687514/how-to-change-dconf-settings-in-chrooted-mode-via-terminal
      // https://askubuntu.com/questions/655238/as-root-i-can-use-su-to-make-dconf-changes-for-another-user-how-do-i-actually/1302886#1302886
      "arch-chroot /mnt/archinstall pacman -Scc --noconfirm", // Delete all cache
      ]
// gsettings set org.gnome.desktop.background picture-options 'centered'
// gsettings set org.gnome.desktop.background picture-uri "${URI}"
  }
  provisioner "shell" {
    inline = [
      "sed -i '/^linux.*/c\\linux /Image' /mnt/archinstall/boot/loader/entries/*_linux.conf" // Fix kernel naming for ARM, archinstall does it for x86_64 
    ]
    only = ["qemu.arch-aarch64"]
  }
  provisioner "shell" {
    inline = [
      "arch-chroot /mnt/archinstall pacman -S --noconfirm virtualbox-guest-utils",
      "arch-chroot /mnt/archinstall modprobe -a vboxguest vboxsf vboxvideo",     // modprobe fails sometimes?
      // https://superuser.com/questions/688733/start-a-systemd-service-inside-chroot-from-a-non-systemd-based-rootfs
      "arch-chroot /mnt/archinstall systemctl enable vboxservice" // ??? https://0pointer.de/blog/projects/changing-roots
    ]
    only = ["virtualbox-iso.archlinux"]
  }
}
