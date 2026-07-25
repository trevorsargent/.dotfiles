# rustup only writes its PATH setup into ~/.profile and ~/.bashrc, so zsh never
# picked it up — leaving ~/.cargo/bin off PATH and cargo-installed binaries
# (marshal-shim, cargo-flux, …) unresolvable in every zsh session.
#
# Sourcing rustup's own env script rather than hardcoding the path keeps this
# correct if rustup ever relocates CARGO_HOME. It's plain POSIX sh, so zsh reads
# it fine, and it's guarded on existence for machines without a rust toolchain.
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
