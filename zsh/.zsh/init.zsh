export ZSH="$HOME/.zsh"

source $ZSH/utils.zsh
source $ZSH/autoload/homebrew.zsh

# Bring up the completion system once, up front — before the tool completion
# fragments (bun's ~/.bun/_bun, zoxide, etc.) each try to bootstrap it. Doing
# it here means zsh/computil is always wired up, so comptags/comptry exist when
# _tags fires. The guard rebuilds ~/.zcompdump at most once a day; the rest of
# the time it trusts the existing dump (compinit -C), which also keeps the many
# concurrently-starting shells from racing to rewrite the shared dump file.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

for file in $ZSH/autoload/*; do
    source "$file"
done
