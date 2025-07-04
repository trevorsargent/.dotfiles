

parse_git_branch() {
    git branch &>/dev/null
    if [ $? -eq 0 ]; then
        echo "%F{008}[%f $(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/') %F{008}]%f"
    fi

}

node_version() {
    nvm use &>/dev/null
    if [ $? -eq 0 ]; then
        echo " %F{$NODE_COLOR}$(node --version)%f"
    fi
}

set_prompt() {
    # nvm use >/dev/null 2>/dev/null
    PROMPT="%F{$HOST_COLOR}[%f %~ %F{$HOST_COLOR}]%f %(!.#.)"
    # RPROMPT="$(parse_git_branch)$(node_version) %F{$HOST_COLOR}%m%f"
    RPROMPT="$(parse_git_branch) %F{$HOST_COLOR}%m%f"
}

# set_prompt

autoload -U add-zsh-hook
add-zsh-hook -Uz precmd set_prompt

# set_prompt