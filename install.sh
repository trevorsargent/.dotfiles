/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install stow
brew install autojump
brew install nvm

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k

# stow dotfiles
stow git
stow zsh
stow osx

# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
sudo chsh -s $(which zsh) $USER
