export ZSH="$HOME/.zsh"

source $ZSH/utils.zsh
source $ZSH/autoload/homebrew.zsh

for file in $ZSH/autoload/*; do
    source "$file"
done
