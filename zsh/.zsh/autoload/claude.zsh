# marshal: launch Codex through Marshal's bridge so direct messages can wake an
# idle session instead of waiting for the next prompt or tool boundary.
alias marshal='marshal-shim codex-run'

# SecondBrain vault: cd into the Syncthing-synced vault and launch Claude.
# Any args pass through to claude (e.g. `vault --resume`, `vault -p "..."`).
# The canonical copy lives on LXC 111 (10.0.1.50:/opt/SecondBrain); this is the local mirror.
vault() {
  builtin cd "$HOME/Obsidian/SecondBrain" && claude "$@"
}
