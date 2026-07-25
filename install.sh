#!/bin/bash
# One-time bootstrap: install system dependencies, then hand off to sync.sh for
# the actual deployment. Everything idempotent and conflict-safe lives in sync.sh
# so that re-running this, or letting the shell hook re-sync later, takes exactly
# the same path.
set -e

cd "$(dirname "$0")"

# Rust comes from rustup's own installer, never a package manager. `brew install
# rust` (and `pacman -S rust`) is a whole second toolchain rather than a fallback:
# alongside a rustup-managed one it leaves two rustc/cargo pairs on the box and
# lets PATH order decide which wins. rustup is also the thing that manages
# toolchain versions and targets, so it has to be the one in charge.
#
# sync.sh needs cargo only to build marshal-shim, and it resolves cargo out of
# ~/.cargo/bin itself rather than trusting $PATH — so this only has to put a
# toolchain on disk. The current process never needs to see it.
#
# --no-modify-path because zsh/.zsh/autoload/cargo.zsh already sources
# ~/.cargo/env; letting rustup append its own block to ~/.profile and ~/.bashrc
# would just be the shell-rc pollution this repo works to keep out.
#
# Never fatal. Under `set -e` a network blip here would otherwise abort an
# install that has nothing else to do with Rust.
ensure_rustup() {
  command -v cargo >/dev/null && return 0
  [[ -x "${CARGO_HOME:-$HOME/.cargo}/bin/cargo" ]] && return 0
  echo "install: cargo not found, installing rustup (needed for marshal-shim)"

  # Download to a file and run it as a second step, rather than `curl | sh`. A
  # pipeline reports the exit status of `sh`, not of `curl`, so a failed download
  # feeds sh an empty script that exits 0 and the failure reads as success — and
  # a connection dropped mid-transfer would have sh executing half an installer.
  local script
  script=$(mktemp) || { echo "install: mktemp failed — skipping rustup" >&2; return 0; }
  if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$script"; then
    sh "$script" -y --no-modify-path \
      || echo "install: rustup failed — marshal-shim will be skipped, rerun 'dotsync'" >&2
  else
    echo "install: could not download rustup — marshal-shim will be skipped" >&2
  fi
  rm -f "$script"
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS: shell + git config only — no Hyprland desktop here
  command -v brew >/dev/null || { echo "Homebrew is required first: https://brew.sh"; exit 1; }
  brew install stow git zoxide fzf

  # Before sync.sh, so ensure_marshal_shim finds a toolchain on a fresh box.
  ensure_rustup

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
