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

# Not fatal under `set -e`: sync.sh exits non-zero if any single package fails to
# stow, and the shell setup below is unrelated to that. Letting one bad package
# abort the run silently skipped the shell change.
./sync.sh || echo "install: sync.sh reported errors, continuing with system setup" >&2

# The remaining steps are here rather than in sync.sh because they need sudo, and
# sync.sh has to stay safe to run unattended from a shell hook.

# add zsh as a login shell. The guard is the point: a bare `tee -a` appends
# another copy on every run, and one box had accumulated nine before it was
# noticed.
ZSH_PATH=$(command -v zsh)
grep -qxF "$ZSH_PATH" /etc/shells || printf '%s\n' "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null

# use zsh as default shell, unless it already is — chsh prompts for a password
# unconditionally, so re-running the installer otherwise asks for one to make no
# change at all.
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "$ZSH_PATH" ]] || chsh -s "$ZSH_PATH"
