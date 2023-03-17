#! /bin/sh
# Source: https://bbs.archlinux.org/viewtopic.php?id=283075

echo "waiting for pacman keyring init to be done"

while ! systemctl show pacman-init.service | grep SubState=exited; do
    systemctl --no-pager status -n0 pacman-init.service || true
    sleep 1
done