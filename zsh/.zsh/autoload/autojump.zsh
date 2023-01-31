# load autojump
[ -f $(brew --prefix autojump)/etc/profile.d/autojump.sh ] && . $(brew --prefix autojump)/etc/profile.d/autojump.sh

# make it so that autojump doesn't print out anythin
rename_function j jj

j() {
    jj $@ >/dev/null
}
