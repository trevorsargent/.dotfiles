# install nix
curl -L https://nixos.org/nix/install | sh

if [ "$(uname -s)" != "Darwin" ]; then
	export PATH=$PATH:/nix/var/nix/profiles/default/bin
fi

# source nix
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi

# install packages
nix-env -iA \
	nixpkgs.zsh \
	nixpkgs.antibody \
	nixpkgs.git \
	nixpkgs.tmux \
	nixpkgs.stow \
	nixpkgs.yarn \
	nixpkgs.fzf \
	nixpkgs.ripgrep \
	nixpkgs.bat \
	nixpkgs.gnumake \
	nixpkgs.gcc \
	nixpkgs.direnv \
	nixpkgs.vim

# stow dotfiles
stow git
stow zsh

# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
sudo chsh -s $(which zsh) $USER

# bundle zsh plugins 
antibody bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.sh