# pulse-cluster CLI dynamic shell completion.
#
# Registers clap_complete's shim: it re-invokes `pulse-cluster` on each <TAB> to
# ask for candidates — so subcommands/flags AND live cluster names (queried from
# the cell at completion time) stay current with no re-sourcing.
#
# Sourced automatically from ~/.zsh/init.zsh's autoload loop, which runs after
# compinit. Guarded on interactivity + the binary existing, so it's a no-op in
# non-interactive shells or on hosts where the CLI isn't installed.
[[ -o interactive ]] && (( $+commands[pulse-cluster] )) && source <(COMPLETE=zsh pulse-cluster)
