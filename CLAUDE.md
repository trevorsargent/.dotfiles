# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Linux dotfiles repository for a Hyprland-based desktop environment on Arch Linux, managed using **GNU Stow** for symlink-based configuration management.

## Installation & Deployment

**Installation**: Run `./install.sh` to stow all configurations. This creates symlinks from this repo to their target locations.

**Key commands**:
```bash
stow <package>              # Deploy a package (creates symlinks)
stow -D <package>           # Remove a package's symlinks
stow -R <package>           # Restow (remove then deploy)
sudo stow keyd -t /etc/keyd # System-level configs need sudo
```

Most packages stow to `~/` (which maps to `~/.config/`, `~/.zshrc`, etc.). Some use custom targets:
- `mako`, `wofi`, `alacritty`: stow to `~/.config/<name>`
- `code`: stows to `~/.config/Code - OSS` with `--adopt` flag
- `keyd`: stows to `/etc/keyd` (requires sudo)

## Architecture

### Modular Structure
Each top-level directory is an independent Stow package containing configuration for one application. The directory structure inside each package mirrors the target filesystem structure.

Example: `zsh/.zshrc` → `~/.zshrc`, `hypr/.config/hypr/` → `~/.config/hypr/`

### Key Components

#### Hyprland (Window Manager)
- **Location**: `hypr/.config/hypr/`
- **Architecture**: Modular configuration split across focused files
  - `hyprland.conf` - Entry point that sources all other configs
  - Split configs: `monitor.conf`, `binds.conf`, `autostart.conf`, `general.conf`, `decoration.conf`, `animations.conf`, `windowrules.conf`, `input.conf`, `cursor.conf`, `environments.conf`
  - `scripts/` - Helper scripts for waybar toggle, hyprpaper reload, app launching
- **Plugins**: Uses `hyprsplit` (install via hyprpm)
- **Bindings**: Includes custom PS4 controller bindings in `binds.conf`

#### Eww (Widget System)
- **Location**: `eww/.config/eww/`
- **Architecture**: Component-based modular system
  - `eww.yuck` includes modules, `eww.scss` contains global styles
  - Each module in `modules/<name>/`: has `.yuck` (widget definition) and `.scss` (styling)
  - Current modules: bar, clock, cpu, disk, dock, music, music_dock, net, ping, progress, ram, sleep, usage, workspaces
  - `_ref/` directory contains reference implementations for new widgets
  - `scripts/` for workspace management, MPRIS music control, positioning
- **Active**: Currently using `dock` module

#### Zsh (Shell)
- **Location**: `zsh/`
- **Architecture**: Autoload-based modular system
  - `.zshrc` → sources `~/.zsh/init.zsh`
  - `init.zsh` loops through and sources all files in `.zsh/autoload/`
  - Modules include: aliases, colors, prompt, tool configs (node, pnpm, bun, deno, go, pyenv, nvm, homebrew, zoxide, etc.)
- **Customization**: Create `*.local.zsh` files (gitignored) for machine-specific overrides
  - Example: `colors.local.zsh` to override color scheme from `colors.base.zsh`

## Development Workflow

**No build system** - configurations are edited directly and deployed via stow.

**Testing changes**:
- Hyprland: `hyprctl reload` or restart compositor
- Eww: `eww reload` or `eww open <widget>`
- Zsh: `source ~/.zshrc` or open new terminal
- Mako: `makoctl reload`

**Commit style**: Use conventional commits (`feat(component):`, `fix(component):`)

## Requirements

**Core dependencies**:
- Hyprland, hyprpaper, stow, keyd, autojump (AUR)
- Hyprland plugins: hyprsplit (via `hyprpm add https://github.com/shezdy/hyprsplit`)

**Dev tools** (configured in zsh):
- Node.js/pnpm (npm is aliased to pnpm), bun, deno, go, pyenv, nvm
- zoxide (cd replacement), fzf (fuzzy finder integration with `fcd`, `cc` aliases)

**Optional**:
- GTK Theme: Fluent-gtk-theme (https://github.com/vinceliuice/Fluent-gtk-theme.git)

## Important Patterns

**Adding new zsh functionality**: Create a new file in `zsh/.zsh/autoload/` (it will be auto-sourced by `init.zsh`)

**Adding new eww widgets**: Create `eww/.config/eww/modules/<name>/` with `<name>.yuck` and `<name>.scss`, then include in `eww.yuck`

**Hyprland config changes**: Edit the appropriate config file in `hypr/.config/hypr/conf/` rather than the main `hyprland.conf`

**Machine-specific settings**: Use `*.local.zsh` files (gitignored) for secrets or local overrides
