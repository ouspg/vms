from pathlib import Path
from typing import TYPE_CHECKING, Any, Optional

import archinstall
from archinstall import Installer
from archinstall import profile
from archinstall.default_profiles.minimal import MinimalProfile
from archinstall import disk
from archinstall import models
from archinstall import locale
from archinstall import profile
import platform

fs_type = disk.FilesystemType("ext4")
# Virtual drive from Packer on ARM/MacOS
if platform.machine() == "arm64":
    device_path = Path("/dev/vda")
else:
    device_path = Path("/dev/sda")


# get the physical disk device
device = disk.device_handler.get_device(device_path)

if not device:
    raise ValueError("No device found for given path")

# create a new modification for the specific device
device_modification = disk.DeviceModification(device, wipe=True)

# create a new boot partition
boot_partition = disk.PartitionModification(
    status=disk.ModificationStatus.Create,
    type=disk.PartitionType.Primary,
    start=disk.Size(1, disk.Unit.MiB, device.device_info.sector_size),
    length=disk.Size(512, disk.Unit.MiB, device.device_info.sector_size),
    mountpoint=Path("/boot"),
    fs_type=disk.FilesystemType.Fat32,
    flags=[disk.PartitionFlag.Boot],
)
device_modification.add_partition(boot_partition)

# create a root partition
root_partition = disk.PartitionModification(
    status=disk.ModificationStatus.Create,
    type=disk.PartitionType.Primary,
    start=disk.Size(513, disk.Unit.MiB, device.device_info.sector_size),
    length=disk.Size(30, disk.Unit.GB, device.device_info.sector_size),
    mountpoint=Path("/"),
    fs_type=fs_type,
    mount_options=[],
)
device_modification.add_partition(root_partition)


disk_config = disk.DiskLayoutConfiguration(
    config_type=disk.DiskLayoutType.Default, device_modifications=[device_modification]
)

# initiate file handler with the disk config and the optional disk encryption config
fs_handler = disk.FilesystemHandler(disk_config)

# perform all file operations
# WARNING: this will potentially format the filesystem and delete all data
fs_handler.perform_filesystem_operations(show_countdown=False)

mountpoint = Path("/mnt/archinstall")

testing = []

locale_config = locale.LocaleConfiguration("us", "en_US", "UTF-8")

with Installer(
    mountpoint, disk_config, disk_encryption=None, kernels=["linux"]
) as installation:
    installation.sanity_check()
    installation.mount_ordered_layout()
    installation.minimal_installation(
        testing=None,
        multilib=True,
        hostname="archlinux",
        locale_config=locale_config,
    )
    installation.add_bootloader(models.bootloader.Bootloader.Systemd)
    # ntp:true
    installation.activate_time_synchronization()
    installation.set_timezone("Europe/Helsinki")

    # audio
    audio_config = {"audio": "pipewire"}
    audio_config = models.AudioConfiguration.parse_arg(audio_config)
    audio_config.install_audio_config(installation)
    # Gnome desktop
    profile_config = {
        "gfx_driver": "",
        "greeter": "sddm",
        "profile": {"details": ["KDE Plasma"], "main": "Desktop"},
    }
    profile_config = profile.ProfileConfiguration.parse_arg(profile_config)
    profile.profile_handler.install_profile_config(installation, profile_config)
    installation.set_keyboard_language(locale_config.kb_layout)
    core_packages = [
        # Editors
        "neovim",
        "vim",
        "code",
        # Core
        "firefox",
        "curl",
        "wget",
        "jq",
        "git",
        "base-devel",
        # Terminal-related
        "wezterm",
        "ttf-jetbrains-mono-nerd",  # For wezterm glyphs
        # Virtualization/Containers
        "spice-vdagent",  # UTM/QEMU guest
        "docker",
        "docker-compose",
        "mesa"
    ]
    platform_specific = []
    if platform.machine() == "arm64":
        platform_specific = ["archlinuxarm-keyring"]
    else:
        platform_specific = ["virtualbox-guest-utils"]


    zsh_config = ["grml-zsh-config", "zsh-autosuggestions", "zsh-syntax-highlighting"]

    infosec_tools = [
        "nmap",
        "wireshark-qt",
        "radamsa",
        "afl",
    ]
    crypto_course = [
        "python-pycryptodome",
    ]

    total_packages = core_packages + platform_specific + zsh_config + infosec_tools + crypto_course
    installation.add_additional_packages(total_packages)
    services = ["docker", "systemd-networkd", "systemd-resolved"]
    if platform.machine() == "x86_64":
        services.append("vboxservice")
    installation.enable_service(services)

    # arch:arch sudo
    user = models.User("arch", "arch", True)
    installation.create_users(user)
    custom_commands = [
        # Aur helper
        # "pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si",
        # Permissions
        "usermod -aG docker arch",
        "usermod -aG wireshark arch",
        # Blackarch repos
        "curl https://blackarch.org/strap.sh | sh",
    ]
    archinstall.run_custom_user_commands(custom_commands, installation)
    installation.genfstab()
