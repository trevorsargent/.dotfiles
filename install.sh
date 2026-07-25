#!/bin/bash
# One-time bootstrap: install system dependencies, then hand off to sync.sh for
# the actual deployment. Everything idempotent and conflict-safe lives in sync.sh
# so that re-running this, or letting the shell hook re-sync later, takes exactly
# the same path.
set -e

cd "$(dirname "$0")"

if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS: shell + git config only — no Hyprland desktop here
  command -v brew >/dev/null || { echo "Homebrew is required first: https://brew.sh"; exit 1; }
  brew install stow git zoxide fzf

  ./sync.sh
  # zsh is already the default login shell on macOS
  exit 0
fi

# Arch Linux
# install dependencies
sudo pacman -Syu --noconfirm hyprland eww mako stow git alacritty zoxide fzf

./sync.sh

# special targets — kept here rather than in sync.sh because they need sudo, and
# sync.sh has to stay safe to run unattended from a shell hook
sudo stow keyd -t /etc/keyd
# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
chsh -s $(which zsh)
