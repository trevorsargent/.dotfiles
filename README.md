# .dotfiles

Cross-platform dotfiles: full Hyprland desktop on Arch Linux, shell + git config on macOS.

# one step install for arch

`curl https://raw.githubusercontent.com/trevorsargent/.dotfiles/refs/heads/main/bootstrap.sh | sh`

# manual install (arch or macos)

1. Clone this repository
2. `cd` into `.dotfiles`
3. Run `./install.sh` — on Arch this installs the full desktop; on macOS it stows just the `zsh`, `git`, `osx`, and `claude` packages (Homebrew required)
4. Open up new window to initiate `zsh` shell

Re-running `./install.sh` is safe. Day to day you shouldn't need to: every interactive shell checks whether the repo has moved and re-syncs in the background when it has, so a `git pull` on one machine lands everywhere you open a terminal. Force it with `dotsync`, and see what happened in `$TMPDIR/dotfiles-sync.log`.

If a machine already had config where a symlink belongs, sync moves it to `~/.dotfiles-backup/<timestamp>/` rather than clobbering it — worth a look after the first run on a new box.

`dotsync` also installs what's missing: `stow` via the system package manager, and `marshal-shim` (statusline + MCP server) via `cargo`. The automatic background sync deliberately doesn't — it only notes them in the log — since installing means sudo prompts and long compiles that have no business running behind a shell start. Neither is auto-upgraded; `cargo install marshal-shim` when you want a newer one.

## Colors

if youd like to override the colors, check out the colors.base.zsh. Make a copy of it into colors.local.zsh and change anything you'd like

## Claude Code

The `claude` package syncs Claude Code's config — `CLAUDE.md`, `settings.json`, `agents/`, and hand-written `skills/` — into `~/.claude`. It deliberately leaves out everything else that lives there (session transcripts, credentials, plugin caches), which is the bulk of the directory.

MCP servers can't be symlinked into place, because Claude Code only reads them from `~/.claude.json`, which isn't synced. Each one gets a definition file in `claude/.claude/mcp/` instead, and `./install.sh` registers them — so adding a server is a matter of dropping a `<name>.json` in that directory and re-running the installer.

Machine-specific settings go in `~/.claude/settings.local.json`; it stays untracked, same idea as `colors.local.zsh`.

# GTK Theme

https://github.com/vinceliuice/Fluent-gtk-theme.git

# Requirements

hyprland (arch)
stow
keyd (arch)
zoxide, fzf

### Hyprland Plugins

hyprpm update
hyprpm add https://github.com/shezdy/hyprsplit
hyprpm enable hyprsplit
