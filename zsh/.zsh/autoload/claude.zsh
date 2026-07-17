# marshal: enable cross-session push notifications via the channels feature.
# `--dangerously-load-development-channels` alone is enough — it registers the
# server in the listening list with dev:true. Adding `--channels` separately
# duplicates the entry as dev:false, which (because the lookup returns the
# first match) shadows the dev entry and channels skip with an allowlist error.
alias marshal='claude --dangerously-load-development-channels server:marshal'

# SecondBrain vault: cd into the Syncthing-synced vault and launch Claude.
# Any args pass through to claude (e.g. `vault --resume`, `vault -p "..."`).
# The canonical copy lives on LXC 111 (10.0.1.50:/opt/SecondBrain); this is the local mirror.
vault() {
  builtin cd "$HOME/Obsidian/SecondBrain" && claude "$@"
}
