# .dotfiles

Cross-platform dotfiles: full Hyprland desktop on Arch Linux, shell + git config on macOS.

# one step install for arch

`curl https://raw.githubusercontent.com/trevorsargent/.dotfiles/refs/heads/main/bootstrap.sh | sh`

# manual install (arch or macos)

1. Clone this repository
2. `cd` into `.dotfiles`
3. Run `./install.sh` — on Arch this installs the full desktop; on macOS it stows just the `zsh`, `git`, and `osx` packages (Homebrew required)
4. Open up new window to initiate `zsh` shell

## Colors

if youd like to override the colors, check out the colors.base.zsh. Make a copy of it into colors.local.zsh and change anything you'd like

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
