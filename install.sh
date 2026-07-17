#!/bin/bash

# install dependencies
sudo pacman -Syu --noconfirm hyprland eww mako stow git alacritty

# stow home-directory packages (files live at ~)
stow git
stow zsh
stow osx

# stow ~/.config packages (flat repo dirs, one per app)
for pkg in alacritty eww hypr mako spotifyd wofi; do
  mkdir -p ~/.config/$pkg
  stow $pkg -t ~/.config/$pkg
done

# special targets
sudo stow keyd -t /etc/keyd
# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
chsh -s $(which zsh)

