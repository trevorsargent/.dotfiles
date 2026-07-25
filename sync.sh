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

# Installing tools means sudo prompts and multi-minute compiles, neither of which
# may happen in a shell hook — a prompt there would hang a background job nobody
# can see. So --quiet (the hook) only ever reports what's missing, while a manual
# `dotsync` or install.sh run, which has a terminal attached, can actually fix it.
PROVISION=$(( ! QUIET ))

# Bootstrap the one dependency this script cannot work without.
ensure_stow() {
    command -v stow >/dev/null && return 0
    if (( ! PROVISION )); then
        warn "stow is not installed — run 'dotsync' to install it"
        return 1
    fi
    log "installing stow"
    if [[ $(uname -s) == "Darwin" ]]; then
        command -v brew >/dev/null || { warn "Homebrew is required first: https://brew.sh"; return 1; }
        brew install stow
    elif command -v pacman >/dev/null; then
        sudo pacman -S --needed --noconfirm stow
    else
        warn "no known package manager — install stow manually"
        return 1
    fi
    command -v stow >/dev/null
}

# Print the path to a command, or fail if it isn't installed.
#
# $PATH alone is not enough for anything cargo-installed. Callers don't reliably
# have ~/.cargo/bin on $PATH — a long-lived shell that predates the entry, and
# more sharply, this very script after it has just run `cargo install`, since a
# process can't see a $PATH it didn't start with. Treating those as "missing"
# means redundant network fetches at best and skipped work at worst.
resolve_cmd() {
    local p
    p=$(command -v "$1" 2>/dev/null) && { printf '%s\n' "$p"; return 0; }
    p="${CARGO_HOME:-$HOME/.cargo}/bin/$1"
    [[ -x $p ]] && { printf '%s\n' "$p"; return 0; }
    return 1
}

have_cmd() { resolve_cmd "$1" >/dev/null; }

# marshal-shim backs both the MCP server and the statusline, and ships only via
# cargo. Install when absent, but never auto-upgrade: `cargo install --force`
# would rebuild on every sync for a version bump nobody asked for. Failure is not
# fatal — the rest of the config is still worth deploying without it.
ensure_marshal_shim() {
    have_cmd marshal-shim && return 0
    if (( ! PROVISION )); then
        warn "marshal-shim missing — MCP server and statusline degraded; run 'dotsync'"
        return 0
    fi
    local cargo
    if ! cargo=$(resolve_cmd cargo); then
        warn "cargo not available — skipping marshal-shim"
        return 0
    fi
    log "installing marshal-shim (cargo build, takes a minute)"
    "$cargo" install marshal-shim || warn "marshal-shim install failed"
    return 0
}

ensure_stow || exit 1

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

    local rel src dest
    for rel in "${conflicts[@]}"; do
        src="$target/$rel"
        [[ -e $src || -L $src ]] || continue

        # Mirror the path under $HOME, not under the stow target. Every ~/.config
        # package gets its own -t, and mako and wofi both stow a root-level file
        # named `config` — so a target-relative path puts both at
        # $BACKUP_ROOT/config and the second mv destroys the first, while still
        # reporting it safely backed up. A $HOME-relative path can't collide, and
        # it restores by copying straight back.
        if [[ $src == "$HOME"/* ]]; then
            dest="$BACKUP_ROOT/${src#"$HOME"/}"
        else
            # No package targets outside $HOME today (keyd is stowed by
            # install.sh, which needs sudo). Nest anything that does, so a
            # system path can never collide with a home-relative one.
            dest="$BACKUP_ROOT/_root/${src#/}"
        fi

        mkdir -p "$(dirname "$dest")"
        if mv "$src" "$dest" 2>/dev/null; then
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
    local f name cmd
    for f in "$HOME"/.claude/mcp/*.json; do
        [[ -e $f ]] || continue
        name=$(basename "$f" .json)
        # Skip definitions whose binary isn't on this machine (e.g. marshal-shim
        # on the mac) — registering them would just error on every session start.
        # have_cmd, not `command -v`: marshal-shim lives in ~/.cargo/bin, so a
        # bare $PATH check declares it missing on the box that has it, and skips
        # the one it was just installed on a few lines above.
        cmd=$(sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1)
        if [[ -n $cmd ]] && ! have_cmd "$cmd"; then
            log "  skipped MCP server $name: $cmd not installed"
            continue
        fi
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

ensure_marshal_shim
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
