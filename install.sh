# stow dotfiles
stow git
stow zsh
stow osx
stow conky
stow rofi
stow hypr
stow waybar
stow eww
sudo stow keyd -t /etc/keyd
stow code -t ~/.config/Code\ -\ OSS --adopt
# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
chsh -s $(which zsh)

