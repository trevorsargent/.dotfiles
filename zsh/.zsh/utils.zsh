function copy_function {
    test -n "$(declare -f "$1")" || return
    eval "${_/$1/$2}"
}

function rename_function {
    copy_function "$@" || return
    unset -f "$1"
}

function cd {
    builtin cd "$@"
    set_prompt
}
