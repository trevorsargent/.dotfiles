# pctl dynamic shell completion. compinit is initialized before autoload modules.
[[ -o interactive ]] && (( $+commands[pctl] )) && source <(COMPLETE=zsh pctl)
