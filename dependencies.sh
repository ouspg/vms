if [ -f /etc/arch-release ]; then
    # Arch Linux commands
    sudo pacman -S packer --noconfirm
    sudo pacman -S python3 --noconfirm
    sudo pacman -S python3-pip --noconfirm
    sudo pacman -S passlib --noconfirm
    sudo pacman -S ansible --noconfirm
    ansible-galaxy collection install community.general
    
    packer init packer_phase1.pkr.hcl
    packer init packer_phase1.pkr.hcl

elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
    # Ubuntu (or Debian-based) commands
    sudo apt update
    sudo apt install -y packer python3 python3-pip python3-passlib ansible -y
    ansible-galaxy collection install community.general

    packer init packer_phase1.pkr.hcl
    packer init packer_phase1.pkr.hcl

else
    echo "Unsupported OS"
fi
