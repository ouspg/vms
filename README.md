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

WIP


### Dependencies (MacOS)
 
 * QEMU
 * wget
 * [Packer](https://www.packer.io/)
 * [UTM](https://mac.getutm.app/) (For improved testing experience)
 * (indirect) [archinstall](https://github.com/archlinux/archinstall)

 Install with Nix:
 ```sh
 nix-env -iA nixpkgs.qemu nixpkgs.wget nixpkgs.packer
 ```
Applications with GUI might be more reasonable to install as `brew casks` instead to save some mental health.

```sh
brew install --cask utm
```


#### UTM

To get the best out of UTM, enable `retina` support, select GPU accelerated display driver, e.g. `virtio-gpu-gl-pci` scale Gnome to 200% for improved GUI experience. 

### Linux



## Customisation

The virtual machines will include all regular Arch Linux repositories,
including `AUR` and `Black Arch` repositories. 
Any package should be straightforward to install if needed.

Click below to see brief summary of the modifications.


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

['org.gnome.Nautilus.desktop', 'kitty.desktop']700702237.213361@[432737881898125] (UTM):* SLSGetNextEventRecordInternal: loc (601.4, 401.0) conn 0xb1663 KeyUp win 0x0 flags 0x100 set 252 char 99; key 8 data 99 special 0 repeat 0 keybd 91
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


</details>

