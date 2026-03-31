alias npm="bun"
alias rl="source ~/.zshrc"
alias ca="git commit -am"
alias g="git"
alias gs="git status"
alias gp="git push"
alias ddv="npm run dev"
[[ $- == *i* ]] && alias cd="j"

git_root(){
    # Try to cd to the repo root; fallback to $HOME if not in a git repo
    local root
    if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        builtin cd "$root" || builtin cd ~
    else
        builtin cd ~
    fi
}

git_dirs(){
    local root

    if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        builtin cd "$root"
        git ls-files | xargs -n 1 dirname | uniq
    else
        find . -type d
    fi
}


fcd() {
    j "$(git_dirs | fzf)"
}

alias f="fcd"

fzfcode() {
    local file
    file="$(git ls-files 2>/dev/null | fzf)"
    [ -n "$file" ] && code "$file"
}

alias cc="fzfcode"

alias m="moon"
alias mr="moon run"
