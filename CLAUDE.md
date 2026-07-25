# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal cross-platform dotfiles repository managed with **GNU Stow**: a Hyprland-based desktop environment on Arch Linux, plus the shell (`zsh`), `git`, and `osx` packages shared with macOS. Shell config must stay portable across both — guard platform-specific paths (`/snap/bin`, Homebrew prefixes) on existence rather than hardcoding, and never hardcode `/home/trevor` or `/Users/trevor` (use `$HOME`).

## Installation & Deployment

**Installation**: Run `./install.sh` to stow all configurations. This creates symlinks from this repo to their target locations. On Arch it installs the full desktop; on macOS it installs deps via Homebrew and stows only `git`, `zsh`, `osx`, and `claude`.

**Deployment lives in `sync.sh`, not `install.sh`.** `install.sh` only installs system dependencies and handles the sudo-requiring targets (`keyd`, `chsh`); everything else defers to `sync.sh`, so re-running the installer and letting the shell re-sync take an identical path. `sync.sh` is idempotent (`stow -R` throughout), concurrency-safe (an atomic `mkdir` lock, since several terminals can start at once), and non-destructive: a real file sitting where a symlink belongs is moved to `~/.dotfiles-backup/<timestamp>/` at its relative path rather than overwritten or left to abort the run. Run it directly, or `dotsync` from any shell.

**`--quiet` means "no side effects beyond deploying".** It's the mode the shell hook uses, and it draws the line for tool provisioning: `ensure_stow` and `ensure_marshal_shim` will install (via pacman/brew and `cargo install` respectively) on a manual `dotsync` or from `install.sh`, but under `--quiet` they only warn into the log. A `sudo` prompt or a multi-minute compile fired from a background shell hook would hang invisibly, so anything that prompts, compiles, or hits the network belongs behind this gate. Neither ever auto-upgrades — `cargo install --force` on every sync would rebuild for a version bump nobody asked for, so updates stay manual.

Tool checks look in the canonical install location as well as `$PATH` (`${CARGO_HOME:-$HOME/.cargo}/bin`), because a long-lived shell may predate the `$PATH` entry — without that, every run would shell out to `cargo install` just to be told the package is already present, after a network index fetch.

**The shell hook must stay free.** `zsh/.zsh/autoload/dotfiles.zsh` re-syncs automatically, gated on `.git` being newer than `~/.local/state/dotfiles-sync.stamp`, with a 24h floor to catch drift the repo can't see. Measured overhead is 0ms, and keeping it there constrains what may go in that file: no forks, no network, no `git` invocation. In particular **do not add a `(( $+commands[...] ))` guard** — each lookup walks `$PATH` and measured at ~2ms, more than the entire rest of the hot path. Checks like that belong in `sync.sh`. Work is detached with `&!` so the prompt never waits and output can't scribble over it; the log is `$TMPDIR/dotfiles-sync.log`.

**Key commands**:
```bash
stow <package>              # Deploy a package (creates symlinks)
stow -D <package>           # Remove a package's symlinks
stow -R <package>           # Restow (remove then deploy)
sudo stow keyd -t /etc/keyd # System-level configs need sudo
```

Packages come in two flavors:
- **`~/.config` packages** (`alacritty`, `eww`, `hypr`, `mako`, `spotifyd`, `wofi`): flat directories — files sit at the package root and are stowed with an explicit target, e.g. `stow eww -t ~/.config/eww` (`mkdir -p` the target first)
- **Home-directory packages** (`git`, `zsh`, `osx`, `claude`): mirror the home directory layout and are stowed plainly, e.g. `zsh/.zshrc` → `~/.zshrc`

The `claude` package is the one exception worth knowing about: `~/.claude` interleaves config with ~1.4GB of runtime state (session transcripts, credentials, caches), so the package deliberately holds only `CLAUDE.md`, `settings.json`, `agents/`, `mcp/`, and the hand-written `skills/`.

**MCP servers are the exception to the exception.** Claude Code reads them only from `~/.claude.json` — putting `mcpServers` in `settings.json` silently does nothing, and the server won't register. Since `~/.claude.json` is machine-local state that must not be synced, each server instead gets a definition file at `claude/.claude/mcp/<name>.json` holding just its JSON object, and `install.sh`'s `register_mcp_servers` applies them with `claude mcp add-json -s user`. It's idempotent (`claude mcp get` exits non-zero only when a server is missing) and needs no JSON parser, so it works on a bare macOS box. Adding a server means dropping in a new file there — not editing `settings.json`. `install.sh` runs `mkdir -p ~/.claude/skills` first so stow links those entries individually rather than folding the whole tree into one symlink — folding would route Claude Code's runtime writes into this repo. Never add `projects/`, `jobs/`, `plugins/`, or `.credentials.json` (the `.gitignore` guards these). Machine-specific overrides go in `~/.claude/settings.local.json`, which stays untracked — the same split as `*.local.zsh`.

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
