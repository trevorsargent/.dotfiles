# Keep the stowed dotfiles current without taxing shell startup.
#
# Every terminal launch runs this, so the hot path is two builtin file tests and
# nothing else: no forks, no network, no `git` call. Real work happens only when
# the repo has actually moved, and even then it is detached into the background so
# the prompt never waits on it.
#
# `.git` is the change signal — its mtime moves on pull, commit, and checkout,
# which covers every way the packages here change. The daily floor catches drift
# the repo can't see, like a symlink deleted by hand or a package that failed to
# stow last time.

# Deliberately no `(( $+commands[stow] ))` guard here: each $commands lookup walks
# $PATH, which measured at ~2ms — more than the rest of this file costs put
# together. sync.sh checks for stow itself, and the worst case is one background
# process that exits immediately, on the rare launch where the repo has moved.
[[ -o interactive ]] || return

: ${DOTFILES:=$HOME/.dotfiles}
[[ -d $DOTFILES/.git ]] || return

dotsync() {
    "$DOTFILES/sync.sh" "$@"
}

# Anonymous function so the locals don't leak into the interactive shell.
() {
    local stamp=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-sync.stamp
    local -a stale

    if [[ -e $stamp ]]; then
        # -nt is a builtin comparison, so this costs a stat and no process.
        if [[ ! $DOTFILES/.git -nt $stamp ]]; then
            stale=( $stamp(N.mh+24) )
            (( ${#stale} )) || return
        fi
    fi

    # &! detaches fully: no job-table entry, and immune to the shell exiting.
    # Output goes to a log rather than the terminal so a sync can never scribble
    # over a prompt that has already been drawn.
    "$DOTFILES/sync.sh" --quiet >|${TMPDIR:-/tmp}/dotfiles-sync.log 2>&1 &!
}
