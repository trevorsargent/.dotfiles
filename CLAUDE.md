# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal cross-platform dotfiles repository managed with **GNU Stow**: a Hyprland-based desktop environment on Arch Linux, plus the shell (`zsh`), `git`, and `osx` packages shared with macOS. Shell config must stay portable across both — guard platform-specific paths (`/snap/bin`, Homebrew prefixes) on existence rather than hardcoding, and never hardcode `/home/trevor` or `/Users/trevor` (use `$HOME`).

## Installation & Deployment

**Installation**: Run `./install.sh` to stow all configurations. This creates symlinks from this repo to their target locations. On Arch it installs the full desktop; on macOS it installs deps via Homebrew and stows only `git`, `zsh`, and `osx`.

**Key commands**:
```bash
stow <package>              # Deploy a package (creates symlinks)
stow -D <package>           # Remove a package's symlinks
stow -R <package>           # Restow (remove then deploy)
sudo stow keyd -t /etc/keyd # System-level configs need sudo
```

Packages come in two flavors:
- **`~/.config` packages** (`alacritty`, `eww`, `hypr`, `mako`, `spotifyd`, `wofi`): flat directories — files sit at the package root and are stowed with an explicit target, e.g. `stow eww -t ~/.config/eww` (`mkdir -p` the target first)
- **Home-directory packages** (`git`, `zsh`, `osx`): mirror the home directory layout and are stowed plainly, e.g. `zsh/.zshrc` → `~/.zshrc`

Special targets:
- `keyd`: stows to `/etc/keyd` (requires sudo)

## Architecture

### Modular Structure
Each top-level directory is an independent Stow package containing configuration for one application.

### Key Components

#### Hyprland (Window Manager)
- **Location**: `hypr/`
- **Architecture**: Modular configuration split across focused files
  - `hyprland.conf` - Entry point that sources all other configs
  - Split configs: `monitor.conf`, `binds.conf`, `autostart.conf`, `general.conf`, `decoration.conf`, `animations.conf`, `windowrules.conf`, `input.conf`, `cursor.conf`, `environments.conf`
  - `scripts/` - Helper scripts for app launching, window switching
- **Background**: solid black everywhere — desktop via `misc:background_color` in `conf/misc.conf` (no wallpaper daemon), lock screen via `background { color }` in `hyprlock.conf`
- **Plugins**: Uses `hyprsplit` (install via hyprpm)
- **Bindings**: Includes custom PS4 controller bindings in `binds.conf`

#### Eww (Widget System)
- **Location**: `eww/`
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
- Hyprland, stow, keyd, zoxide
- Hyprland plugins: hyprsplit (via `hyprpm add https://github.com/shezdy/hyprsplit`)

**Dev tools** (configured in zsh):
- Node.js/pnpm (npm is aliased to pnpm), bun, deno, go, pyenv, nvm
- zoxide (cd replacement), fzf (fuzzy finder integration with `fcd`, `cc` aliases)

**Optional**:
- GTK Theme: Fluent-gtk-theme (https://github.com/vinceliuice/Fluent-gtk-theme.git)

## Important Patterns

**Adding new zsh functionality**: Create a new file in `zsh/.zsh/autoload/` (it will be auto-sourced by `init.zsh`)

**Adding new eww widgets**: Create `eww/modules/<name>/` with `<name>.yuck` and `<name>.scss`, then include in `eww.yuck`

**Hyprland config changes**: Edit the appropriate config file in `hypr/conf/` rather than the main `hyprland.conf`

**Machine-specific settings**: Use `*.local.zsh` files (gitignored) for secrets or local overrides
