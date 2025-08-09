#/bin/sh

# this script assumes: 
# 1. archlinux
# 2. you have sudo rights


# this script will:
# 1. update the system
# 2. install git and base-devel
# 3. install hyprland

# 4. clone the dotfiles repository
# 5. run the install script in the dotfiles repository

sudo pacman -Syu --noconfirm git

git clone https://github.com/trevorsargent/.dotfiles.git

cd .dotfiles

./install.sh