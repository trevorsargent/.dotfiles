# zoxide's startup doctor false-positives in embedded/non-login shells (it
# wants init "at the end of ~/.zshrc"; the autoload loop already runs it last).
export _ZO_DOCTOR=0
if [[ -o interactive ]] && (( $+commands[zoxide] )); then
    eval "$(zoxide init --cmd j zsh)"
    alias jj="zoxide edit"
fi
