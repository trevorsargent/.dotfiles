#!/bin/bash

# install dependencies
sudo pacman -Syu --noconfirm hyprland waybar eww mako stow git alacritty

# stow dotfiles
stow git
stow zsh
stow osx
stow conky
stow rofi
stow hypr
stow waybar
stow eww
stow mako -t ~/.config/mako
sudo stow keyd -t /etc/keyd
stow code -t ~/.config/Code\ -\ OSS --adopt
stow alacritty -t ~/.config/alacritty
# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
chsh -s $(which zsh)

