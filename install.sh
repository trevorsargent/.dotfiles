#!/bin/bash
set -e

cd "$(dirname "$0")"

# MCP servers are the one piece of Claude Code config that can't be stowed: they
# are read only from ~/.claude.json, which also holds machine-local state (session
# history, credentials) and so is deliberately not in this repo. Registering them
# from the synced definitions in claude/.claude/mcp/ gets them onto a new machine
# anyway. Idempotent — `mcp get` exits non-zero only when the server is missing.
register_mcp_servers() {
  command -v claude >/dev/null || { echo "claude not installed — skipping MCP registration"; return 0; }
  local f name
  for f in ~/.claude/mcp/*.json; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f" .json)
    if claude mcp get "$name" >/dev/null 2>&1; then
      echo "MCP server '$name' already registered"
    else
      claude mcp add-json -s user "$name" "$(cat "$f")"
    fi
  done
}

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
  register_mcp_servers
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
register_mcp_servers

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
