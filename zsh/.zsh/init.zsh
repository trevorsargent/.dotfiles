export ZSH="$HOME/.zsh"

# keep PATH/fpath free of duplicates as the autoload modules prepend to them
typeset -gU path fpath

source $ZSH/utils.zsh
source $ZSH/autoload/homebrew.zsh

# Bring up the completion system once, up front — before the tool completion
# fragments (bun's ~/.bun/_bun, zoxide, etc.) each try to bootstrap it. Doing
# it here means zsh/computil is always wired up, so comptags/comptry exist when
# _tags fires. The guard rebuilds ~/.zcompdump at most once a day; the rest of
# the time it trusts the existing dump (compinit -C), which also keeps the many
# concurrently-starting shells from racing to rewrite the shared dump file.
# Note the array: glob qualifiers only expand during filename generation, so the
# tempting `[[ -n ...(#qN.mh+24) ]]` never globs — it tests a literal string, is
# always true, and silently costs every shell a full rebuild.
autoload -Uz compinit
_zcompdump_stale=( ${ZDOTDIR:-$HOME}/.zcompdump(N.mh+24) )
if (( ${#_zcompdump_stale} )); then
    compinit
else
    compinit -C
fi
unset _zcompdump_stale

for file in $ZSH/autoload/*; do
    source "$file"
done
