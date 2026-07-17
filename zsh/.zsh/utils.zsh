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
    local cd_ret=$?
    set_prompt 2>/dev/null
    return $cd_ret
}
