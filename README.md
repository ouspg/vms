# Custom UEFI-based Arch Linux builds for AArch64 and x86_64 architectures

The popularity of ARM-based Macbooks has increased the need for multi-architecture virtual machines in teaching.

This repository contains automated build instructions for custom Arch Linux for multi-platform and multi-architecture.
Supported builds include Arch Linux with Black Arch repositories for 
    
* AAarch64 with UTM/QEMU support (Arch Linux ARM)
* x86_64 with VirtualBox/VMware support (Arch Linux x86_64)

> **Note**
> There is a slight difference in the packages between ARM and x86_64, because repositories are different.

The publishing process for the `csc.fi` platform is also documented.

As an alternative to popular Kali Linux, Parrot OS and Black Arch virtual machines, we have a bit more lightweight and opinionated virtual machine for teaching purposes.

## Build process

```mermaid
flowchart LR
    A[build.sh] -->|Get EFI firmware| B(Launch Packer)
    B --> |Get ISOs|C(Packer builds with archinstall)
```



### Build dependencies (MacOS)
 
 * QEMU
 * wget
 * [Packer](https://www.packer.io/)
 * [UTM](https://mac.getutm.app/) (optional, for improved testing experience)
 * (indirect) [archinstall](https://github.com/archlinux/archinstall)
 * p7zip (for compression)

 Install with Nix:
 ```console
 nix-env -iA nixpkgs.qemu nixpkgs.wget nixpkgs.packer nixpkgs.p7zip
 ```
Applications with GUI might be more reasonable to install as `brew casks` instead to save some mental health.

```console
brew install --cask utm
```


### Pre-processor

Building QEMU images requires the use of corresponding EFI reference implementation.
We will use the EFI Development Kit by the TianoCore community, aka EDK2 releases.
EDK2 release binary must be downloaded for AARCH64 before the Archboot version of the Arch Linux ARM can be booted.

Unofficial releases have been used: https://retrage.github.io/edk2-nightly/

The build ARM [script](build_arm.sh) automates this process, but likely the checksum needs to be changed manually once per day.

### Archinstall

Archinstall automates most of the installation process.
Currently, there is no need to offer other distributions as custom virtual machines, so Ansible et. al. might be a bit overkill.

Configuration files are found in the [archinstall](archinstall) directory.

### ARM limitations

Archinstall is meant for x86_64 architecture. 
There are some caveats; the GRUB bootloader is installed with hardcoded parameters for x86_64, but systemd-bootctl works well enough.
We only need to rename the Kernel image from `/boot/loader/entries/` configurations to make the ARM machine UEFI bootable.

### Building


For ARM builds, use [build_arm.sh](build_arm.sh).
```
bash build_arm.sh # Bash must be used
```

For `x86_64` builds, use packer directly, for now.
```console
packer build -var="output_dir=$OUTPUT_DIR" -only=virtualbox-iso.archlinux archlinux.pkr.hcl 
```

## Deployment

### Deploy dependencies

Publishing into the [Allas object storage](http://ouspg.org/archlinuxarm) requires some additional tools

  * rclone
  * [allas-cli-utils](https://github.com/CSCfi/allas-cli-utils)

Install `rclone` with Nix, for example:
```console
nix-env -iA nixpkgs.rclone
```

Configuration, [based on docs](https://docs.csc.fi/data/Allas/using_allas/rclone_local/):

```console
wget https://raw.githubusercontent.com/CSCfi/allas-cli-utils/master/allas_conf
source allas_conf -u your-csc-username -p your-csc-project-name

```
Rclone usage: https://docs.csc.fi/data/Allas/using_allas/rclone/

### Signing

To sign builds manually:
```console
gpg --output archlinuxarm.sig --detach-sig archlinuxarm.7zip
```

To verify:
```console
gpg --verify archlinuxarm.sig archlinuxarm.7zip
```

### Allas URL shortening

Currently, [ouspg.org](https://github.com/ouspg/ouspg.github.io) is a bit abused as a URL shortener with client-side redirects.

See for ARM
  * [Arch Linux ARM shortened](https://github.com/ouspg/ouspg.github.io/blob/main/content/archlinuxarm.md)
  * [Arch Linux ARM sig. shortened](https://github.com/ouspg/ouspg.github.io/blob/main/content/archlinuxarm.sig.md)

## Testing and running

### UTM

To get the best out of UTM, enable `retina` support, select GPU accelerated display driver, e.g. `virtio-gpu-gl-pci`, and scale Gnome to 200% for an improved GUI experience. 

However, GPU acceleration should be disabled (use `virtio-gpu-pci`) if the browser must be used inside the guest VM, for now.
  * https://github.com/utmapp/UTM/issues/4983
  * https://github.com/utmapp/UTM/issues/4941

### Linux & Windows


## Customisation

The virtual machines will include all regular Arch Linux repositories,
including `AUR` and `Black Arch` repositories. 
Any package should be straightforward to install if needed.

Click below to see brief summary of the modifications.

Gnome setting changes cannot be applied automatically at the moment.

<details><summary>Customisations &darr;</summary>

To include Black Arch sources:

```console
curl https://blackarch.org/strap.sh | sh
````

### Gnome tweaks

Finnish as the first keyboard layout:
```console
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'fi'), ('xkb', 'us')]"
```

Print the favourites from desktop

 ```console
 gsettings get org.gnome.shell favorite-apps
 ```
 Set custom apps (string array)
 ```
gsettings set org.gnome.shell favorite-apps

['org.gnome.Nautilus.desktop', 'org.wezfurlong.wezterm.desktop', 'firefox.desktop', 'codium.desktop', 'org.gnome.Settings.desktop']
 ```


 [yay](https://github.com/Jguer/yay) is included in `blackarch-misc`. 
 Hurray! -> `pacman -S yay`


AUR packages
```
yay -S vscodium-bin
```

Codium
`~/.config/VSCodium/User/settings.json`
```
{
    "workbench.colorTheme": "Default Dark+",
    "window.titleBarStyle": "custom"
}
```

### Future ideas

If there is ever a switch for Ansible, seems good tutorial  https://github.com/diffy0712/arch-boot

</details>

