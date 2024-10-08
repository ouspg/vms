#!/bin/env/bash
# -x for printing commands and variables, -v for commands-only
set -e

OUTPUT_DIR="output_archlinux"

# Downloading unofficial EDK2 release to be used in build system (no other good option on Mac without self build)
EFI_BASE_URL="https://retrage.github.io/edk2-nightly/bin/"

EFI_RELEASE_FILE="RELEASEAARCH64_QEMU_EFI.fd"
EFI_RELEASE_SHA256="2b77642151be6a303232d2bcee071a868758a10caa313d99c8f94a26ff60a347"

err_report() {
    echo "Build failure on line $1 $2"
}
trap 'err_report $LINENO $ERR' ERR
# Can be triggered simply with 'false' command

unameOut="$(uname -s)"
echo "Current platform: $unameOut"
if [ "$unameOut" == "Darwin" ]; then
    true
elif [ "$unameOut" == "Linux" ]; then
    true
else
    echo "Unsupported machine: $unameOut, (Darwin and Linux are supported)"
    exit 125
fi


if [ ! -f $EFI_RELEASE_FILE ]; then
    wget "$EFI_BASE_URL$EFI_RELEASE_FILE"
    echo "EFI downloaded and verified successfully for AARCH64"
else
    echo "Using cached EFI file."
fi


if [ "$unameOut" == "Darwin" ]; then
    echo -n "$EFI_RELEASE_SHA256  $EFI_RELEASE_FILE" | shasum -ca 256 -
elif [ "$unameOut" == "Linux" ]; then
    echo -n "$EFI_RELEASE_SHA256  $EFI_RELEASE_FILE" | sha256sum -c -
fi



# export PACKER_LOG=1 # Enable logging of packer
packer build -only="qemu.arch-aarch64" -on-error=ask -var="efi_release_file=$EFI_RELEASE_FILE" -var="output_dir=$OUTPUT_DIR" archlinux.pkr.hcl

7z a "$OUTPUT_DIR/archlinuxarm.7zip" "$OUTPUT_DIR/archlinuxarm"

# Get signature of the build
# gpg --output archlinuxarm.sig --detach-sig archlinuxarm.7zip
# gpg --verify archlinuxarm.sig archlinuxarm.7zip

# Publish into Allas in csc.fi
# source ./allas_conf -u "$CSC_USER" -p "$UNIX_PROJECT"
# rclone lsd allas:
# rclone mkdir allas:archlinuxvms
# rclone copy --progress archlinuxarm.7zip allas:archlinuxvms/
# rclone copy --progress archlinuxarm.sig allas:archlinuxvms/

# For x86_64

# rclone copy --progress archlinux-x86_64.ova allas:archlinuxvms/
# rclone copy --progress archlinux-x86_64.sig allas:archlinuxvms/
