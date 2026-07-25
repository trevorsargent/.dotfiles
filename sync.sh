#!/usr/bin/env bash
# Deploy every stow package. Idempotent, concurrency-safe, and non-destructive.
#
# Two callers with very different contexts share this script: install.sh runs it
# once after installing system dependencies, and zsh/.zsh/autoload/dotfiles.zsh
# fires it in the background whenever the repo has moved. That second caller is
# why it never installs packages, never touches the network, and never prompts —
# it has to be safe to launch from a shell that is still starting up, possibly
# several at once.
#
# Conflicts (a real file sitting where a symlink belongs — typically config that
# predates the repo on a new machine) are moved into a timestamped backup rather
# than overwritten, or left to abort the run the way bare `stow` would.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
DOTFILES=$PWD

QUIET=0
[[ ${1:-} == "--quiet" ]] && QUIET=1
log()  { (( QUIET )) || printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }

# Checked here rather than in the shell hook: a $commands lookup in zsh walks
# $PATH and costs more than the entire hot path it would be guarding.
command -v stow >/dev/null || { warn "stow is not installed"; exit 1; }

# mkdir is atomic, so it doubles as a mutex — several terminals starting at once
# must not race each other through stow.
LOCK="${TMPDIR:-/tmp}/dotfiles-sync.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
    # Reclaim a lock orphaned by a killed run, but only once it's clearly stale.
    if [[ -n $(find "$LOCK" -maxdepth 0 -mmin +10 2>/dev/null) ]]; then
        rmdir "$LOCK" 2>/dev/null
        mkdir "$LOCK" 2>/dev/null || exit 0
    else
        log "another sync is already running"
        exit 0
    fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=0
failed=0

# Stow one package, relocating anything that would block it.
stow_pkg() {
    local pkg=$1 target=${2:-$HOME}
    [[ -d $pkg ]] || { warn "  $pkg: no such package"; return 1; }
    mkdir -p "$target"

    # -R (restow) is the idempotent form: it cleans up links for files that have
    # since been removed from the package, and is a no-op when already correct.
    local out
    if out=$(stow -R -n -t "$target" "$pkg" 2>&1) && [[ -z $out ]]; then
        stow -R -t "$target" "$pkg" 2>/dev/null && return 0
    fi

    local -a conflicts=()
    local line
    while IFS= read -r line; do
        [[ -n $line ]] && conflicts+=("$line")
    done < <(printf '%s\n' "$out" | sed -n 's/.*over existing target \(.*\) since .*/\1/p')

    if (( ${#conflicts[@]} == 0 )); then
        # Dry run had output but no conflicts — normal link churn, just apply it.
        if stow -R -t "$target" "$pkg" 2>/dev/null; then return 0; fi
        warn "  $pkg: stow failed"
        warn "$out"
        return 1
    fi

    local rel src
    for rel in "${conflicts[@]}"; do
        src="$target/$rel"
        [[ -e $src || -L $src ]] || continue
        mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
        if mv "$src" "$BACKUP_ROOT/$rel" 2>/dev/null; then
            log "  moved aside: $src"
            backed_up=1
        else
            warn "  $pkg: could not back up $src"
            return 1
        fi
    done

    stow -R -t "$target" "$pkg" 2>/dev/null && return 0
    warn "  $pkg: still failing after backup"
    return 1
}

# MCP servers are the one piece of Claude Code config that can't be stowed: they
# are read only from ~/.claude.json, which also holds machine-local state (session
# history, credentials) and so is deliberately not in this repo. Registering them
# from the synced definitions gets them onto a new machine anyway. Idempotent —
# `mcp get` exits non-zero only when the server is missing — and parser-free, so
# it needs neither jq nor python on a bare box.
register_mcp_servers() {
    command -v claude >/dev/null || return 0
    local f name
    for f in "$HOME"/.claude/mcp/*.json; do
        [[ -e $f ]] || continue
        name=$(basename "$f" .json)
        claude mcp get "$name" >/dev/null 2>&1 && continue
        if claude mcp add-json -s user "$name" "$(cat "$f")" >/dev/null 2>&1; then
            log "  registered MCP server: $name"
        else
            warn "  failed to register MCP server: $name"
        fi
    done
}

log "syncing $DOTFILES"

for pkg in git zsh osx claude; do
    stow_pkg "$pkg" || failed=1
done

# The desktop lives on Arch only; macOS gets shell + git + claude.
if [[ $(uname -s) != "Darwin" ]]; then
    for pkg in alacritty eww hypr mako spotifyd wofi; do
        stow_pkg "$pkg" "$HOME/.config/$pkg" || failed=1
    done
fi

register_mcp_servers

# Stamp unconditionally, including on failure: the shell hook keys off this file,
# and a persistent failure must not make every new terminal respawn a sync.
STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-sync.stamp"
mkdir -p "$(dirname "$STAMP")"
date +%s > "$STAMP"

(( backed_up )) && log "conflicting files backed up to $BACKUP_ROOT"
(( failed )) && { warn "sync finished with errors"; exit 1; }
log "sync ok"
exit 0
