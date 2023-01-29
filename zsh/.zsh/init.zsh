export ZSH="$HOME/.zsh"

source $ZSH/utils.zsh

for file in $ZSH/autoload/*; do
    source "$file"
done
