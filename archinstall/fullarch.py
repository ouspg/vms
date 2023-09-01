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

fs_type = disk.FilesystemType("ext4")
# Virtual drive from Packer
device_path = Path("/dev/vda")

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
    start=disk.Size(1, disk.Unit.MiB),
    length=disk.Size(512, disk.Unit.MiB),
    mountpoint=Path("/boot"),
    fs_type=disk.FilesystemType.Fat32,
    flags=[disk.PartitionFlag.Boot],
)
device_modification.add_partition(boot_partition)

# create a root partition
root_partition = disk.PartitionModification(
    status=disk.ModificationStatus.Create,
    type=disk.PartitionType.Primary,
    start=disk.Size(513, disk.Unit.MiB),
    length=disk.Size(30, disk.Unit.GB),
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

mountpoint = Path("/mnt")

testing = []
multilib = []

locale_config = locale.LocaleConfiguration("us", "en_US", "UTF-8")

with Installer(
    mountpoint, disk_config, disk_encryption=None, kernels=["linux"]
) as installation:
    installation.sanity_check()
    installation.mount_ordered_layout()
    installation.minimal_installation(
        testing=None,
        multilib=None,
        hostname="archlinux",
        locale_config=locale_config,
    )
    installation.add_bootloader(models.bootloader.Bootloader.Systemd)
    # ntp:true
    installation.activate_time_syncronization()
    installation.set_timezone("Europe/Helsinki")
    installation.minimal_installation(hostname="minimal-arch")
    installation.add_additional_packages(["nano", "wget", "git"])

    # audio
    audio_config = {"audio": "pipewire"}
    audio_config = models.AudioConfiguration.parse_arg(audio_config)
    audio_config.install_audio_config(installation)
    # Gnome desktop
    profile_config = {
        "gfx_driver": "",
        "greeter": "gdm",
        "profile": {"details": ["Gnome"], "main": "Desktop"},
    }
    profile_config = profile.ProfileConfiguration.parse_arg(profile_config)
    profile.profile_handler.install_profile_config(installation, profile_config)
    installation.set_keyboard_language(locale_config.kb_layout)
    core_packages = [
        "vim",
        "curl",
        "wget",
        "jq",
        "wezterm",
        "spice-vdagent",
        "docker",
        "git",
        "base-devel",
        "firefox",
        "grml-zsh-config",
        "mesa",
    ]
    installation.add_additional_packages(core_packages)
    services = ["docker"]
    installation.enable_service(services)

    # arch:arch sudo
    user = models.User("arch", "arch", True)
    installation.create_users(user)
    custom_commands = [
        "usermod -aG docker arch",
        "curl https://blackarch.org/strap.sh | sh",
    ]
    archinstall.run_custom_user_commands(custom_commands, installation)
    installation.genfstab()
