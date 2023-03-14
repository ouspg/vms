#!/bin/env bash
# For debugging and testing purposes
qemu-system-aarch64 \
    -monitor stdio \
    -accel hvf \
    -cpu host \
    -boot strict=off \
    -display cocoa,show-cursor=on \
    -smp 1 \
    -m 3072M \
    -bios RELEASEAARCH64_QEMU_EFI.fd \
    -name archlinuxarm \
    -device virtio-net \
    -device virtio-gpu-pci \
    -device qemu-xhci \
    -device nec-usb-xhci \
    -device usb-kbd \
    -device usb-tablet \
    -drive file=/Users/nicce/teaching/vms/archboot-2023-aarch64.iso,media=cdrom \
    -drive file=archlinux.raw,format=raw,if=virtio,cache=writethrough \
    -machine virt,highmem=on \