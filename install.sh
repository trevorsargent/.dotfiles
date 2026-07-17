#!/bin/bash

# install dependencies
sudo pacman -Syu --noconfirm hyprland waybar eww mako stow git alacritty

# stow home-directory packages (files live at ~)
stow git
stow zsh
stow osx
stow conky

# stow ~/.config packages (flat repo dirs, one per app)
for pkg in alacritty eww hypr mako rofi spotifyd waybar wofi; do
  mkdir -p ~/.config/$pkg
  stow $pkg -t ~/.config/$pkg
done

# special targets
sudo stow keyd -t /etc/keyd
stow code -t ~/.config/Code\ -\ OSS --adopt
# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
chsh -s $(which zsh)
