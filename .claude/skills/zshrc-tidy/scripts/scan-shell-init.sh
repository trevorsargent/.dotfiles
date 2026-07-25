#!/usr/bin/env bash
# Scan shell startup files for installer-appended content.
#
# Read-only: reports state, changes nothing. Three sections —
#   A. zsh/.zshrc     (the git-tracked file ~/.zshrc symlinks to)
#   B. other startup files (NOT in the repo — .zshenv/.zprofile/.profile/.bashrc/...)
#   C. autoload inventory (what modules already exist, so blocks get merged not duplicated)

set -uo pipefail

# Count lines that aren't blank or pure comment. grep -c exits 1 when the count is
# zero, so swallow the status rather than letting it look like a failure.
count_active() {
    local n
    n="$(grep -cv '^[[:space:]]*\(#.*\)\?$' "$1" 2>/dev/null)" || true
    echo "${n:-0}"
}

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
ZSHRC="$DOTFILES/zsh/.zshrc"
AUTOLOAD="$DOTFILES/zsh/.zsh/autoload"
CANONICAL='source $HOME/.zsh/init.zsh'

dirty=0

echo "=== A. zsh/.zshrc ==========================================================="

if [[ ! -e "$ZSHRC" ]]; then
    echo "MISSING: $ZSHRC does not exist. Is DOTFILES set correctly? (got: $DOTFILES)"
    exit 1
fi

# The symlink is what makes appends land in git. If it's gone, the live config has
# drifted out of the repo and the two files need reconciling before anything else.
if [[ -L "$HOME/.zshrc" ]]; then
    target="$(readlink -f "$HOME/.zshrc")"
    if [[ "$target" == "$(readlink -f "$ZSHRC")" ]]; then
        echo "symlink:  ~/.zshrc -> $ZSHRC  [ok]"
    else
        echo "symlink:  ~/.zshrc -> $target  [WRONG TARGET, expected $ZSHRC]"
        dirty=1
    fi
elif [[ -e "$HOME/.zshrc" ]]; then
    echo "symlink:  ~/.zshrc is a REAL FILE, not a symlink into the repo."
    echo "          An installer likely clobbered the link. Live config is untracked."
    echo "          Diff against the repo copy before doing anything else:"
    echo "            diff -u '$ZSHRC' ~/.zshrc"
    dirty=1
else
    echo "symlink:  ~/.zshrc does not exist [zsh package not stowed?]"
    dirty=1
fi

# Anything that isn't the canonical source line (or blank/comment) is suspect.
extra="$(grep -vxF "$CANONICAL" "$ZSHRC" | grep -v '^[[:space:]]*$')"
if [[ -z "$extra" ]]; then
    echo "content:  clean — canonical single source line only"
else
    echo "content:  NON-CANONICAL LINES PRESENT:"
    echo "$extra" | sed 's/^/          | /'
    dirty=1
fi

echo
echo "--- git state of zsh/.zshrc ---"
git -C "$DOTFILES" status --porcelain -- zsh/.zshrc | sed 's/^/  /'
git -C "$DOTFILES" diff -- zsh/.zshrc | sed 's/^/  /'
# Appends may already be committed; the last commit touching the file says which.
echo "  last commit touching it:"
git -C "$DOTFILES" log -1 --format='    %h %ad %s' --date=short -- zsh/.zshrc

echo
echo "=== B. other shell startup files (not tracked in this repo) ================="
echo "    Installers (rustup, conda, sdkman) often write here instead of .zshrc."
echo "    .profile/.bashrc may be serving bash intentionally — confirm before moving."
echo

for f in .zshenv .zprofile .zlogin .zlogout .profile .bashrc .bash_profile; do
    p="$HOME/$f"
    [[ -e "$p" ]] || continue
    if [[ -L "$p" ]]; then
        echo "  $f -> $(readlink "$p")  [symlink]"
        continue
    fi
    lines="$(count_active "$p")"
    echo "  $f  ($lines active lines; full contents below)"
    [[ "$lines" -gt 0 ]] && sed 's/^/      | /' "$p"
done

echo
echo "=== C. existing autoload modules ==========================================="
echo "    Merge into an existing module rather than creating a near-duplicate."
echo "    'all commented' modules are deliberate — ask before reactivating one."
echo

for f in "$AUTOLOAD"/*; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    live="$(count_active "$f")"
    if [[ "$live" -eq 0 ]]; then
        note="ALL COMMENTED OUT"
    else
        note="$live active lines"
    fi
    case "$name" in
        *.local.zsh) note="$note, GITIGNORED (secrets go here)" ;;
    esac
    printf '  %-24s %s\n' "$name" "$note"
done

echo
echo "============================================================================"
if [[ "$dirty" -eq 0 ]]; then
    echo "zsh/.zshrc is clean. Check sections B and C above for anything out of place."
else
    echo "Found issues in section A — see above."
fi
