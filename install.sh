#!/bin/bash
set -e

cd "$(dirname "$0")"

if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS: shell + git config only — no Hyprland desktop here
  command -v brew >/dev/null || { echo "Homebrew is required first: https://brew.sh"; exit 1; }
  brew install stow git zoxide fzf

  stow git
  stow zsh
  stow osx
  # ~/.claude mixes config with runtime state (session transcripts, credentials),
  # so pre-create the directories: that forces stow to link the individual config
  # entries instead of folding the whole tree into one symlink, which would send
  # Claude Code's runtime writes into this repo.
  mkdir -p ~/.claude/skills
  stow claude
  # zsh is already the default login shell on macOS
  exit 0
fi

# Arch Linux
# install dependencies
sudo pacman -Syu --noconfirm hyprland eww mako stow git alacritty zoxide fzf

# stow home-directory packages (files live at ~)
stow git
stow zsh
stow osx
# pre-create the dirs first — see the macOS branch above for why
mkdir -p ~/.claude/skills
stow claude

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
