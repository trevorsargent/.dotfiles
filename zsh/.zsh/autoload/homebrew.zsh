# Put Homebrew on PATH and its completions on fpath before compinit runs
# (init.zsh sources this file ahead of the autoload loop for that reason).
# Checks Apple Silicon, Intel mac, and Linuxbrew locations; on Arch everything
# comes from pacman, so this is a no-op.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x $_brew ]]; then
        eval "$($_brew shellenv)"
        # shellenv no-ops when brew is already on PATH (e.g. login shell ran it),
        # but fpath isn't inherited by subshells — add site-functions explicitly.
        _brew_sf="${_brew:h:h}/share/zsh/site-functions"
        [[ -d $_brew_sf ]] && (( ! ${fpath[(I)$_brew_sf]} )) && fpath=($_brew_sf $fpath)
        break
    fi
done
unset _brew _brew_sf
