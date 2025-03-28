#!/bin/bash

dir="$(dirname "$(realpath "$0")")/output_archlinux_qemu"
file="$dir/archlinux-x86_64"
checksum_file="$dir/checksum.txt"

if [[ ! -f "$file" ]]; then
    echo "Error: $file not found!"
    exit 1
fi


if [[ ! -f "$checksum_file" ]]; then
    touch "$checksum_file"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create $checksum_file!"
        exit 1
    fi
fi


sha256sum "$file" | awk '{print $1}' | tr -d '\n' > "$checksum_file"

echo "Checksum written to $checksum_file"
