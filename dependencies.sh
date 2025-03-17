#!/bin/bash

# installs most dependencies WARNING: NOT GUARANTEED TO WORK ON ALL SYSTEMS OR AT ALL

sudo pacman -S packer

sudo pacman -S python3

sudo pacman -S python3-pip

sudo pacman -S passlib

sudo pacman -S ansible

ansbile-galaxy collection install community.general
