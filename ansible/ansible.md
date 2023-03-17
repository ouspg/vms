 ## Ansible backups (not used anymore)

HCL backups just in case

```yaml
  provisioner "shell" {
    inline = [
    // "yes | pacman -Sy --noconfirm archlinuxarm-keyring",
    "pacman-key --init",
    "pacman-key --populate archlinuxarm",
    # We need locales for Ansible..
    "sed -i \"/^#en_US\\.UTF-8 /s/^#//\" /etc/locale.gen && mkdir -p /usr/lib/locale",
    "locale-gen",
    "localectl set-locale LANG=en_US.UTF-8",
    "localectl set-locale LC_TIME=en_US.UTF-8",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "LANG=en_US.UTF-8",
  ]
    inline = [
      // "unset LANG && source /etc/profile.d/locale.sh",
      // For minimal image
      // "pacman -Sy --noconfirm openssl ansible-core parted util-linux pciutils util-linux-libs",
      "pacman -Sy --noconfirm ansible-core",
      "ansible-galaxy collection install community.general ansible.posix",
      "ansible --help"
      ]
  }
```
 Installation of the required models

 ```console
 ansible-galaxy collection install community.general ansible.posix
 ```
