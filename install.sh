# stow dotfiles
stow git
stow zsh
stow osx
stow conky
stow rofi
stow hypr
stow waybar
stow eww

# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
chsh -s $(which zsh)
