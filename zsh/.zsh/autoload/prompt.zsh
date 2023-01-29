parse_git_branch() {
    git branch &>/dev/null
    if [ $? -eq 0 ]; then
        echo "%F{008}[%f $(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/') %F{008}]%f"
    fi

}

node_version() {
    nvm use &>/dev/null
    if [ $? -eq 0 ]; then
        echo " %F{002}$(node --version)%f"
    fi
}

set_prompt() {
    nvm use >/dev/null 2>/dev/null
    PROMPT="%F{008}[%f %~ %F{008}]%f %(!.#.)"
    RPROMPT=" $(parse_git_branch)$(node_version)"
}

set_prompt
