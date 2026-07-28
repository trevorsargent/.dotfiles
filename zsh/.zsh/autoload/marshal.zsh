# Default daemon address for marshal-shim. The MCP definition
# (claude/.claude/mcp/marshal.json) resolves ${MARSHAL_DAEMON_ADDRESS:-...}
# with this same fallback, but anything running outside that context — the
# statusline, direct marshal-shim invocations — needs it from the environment.
# :- keeps it a default: a value already set (systemd user env, *.local.zsh
# sourced earlier, an ad-hoc override) wins.
export MARSHAL_DAEMON_ADDRESS="${MARSHAL_DAEMON_ADDRESS:-ws://marshal-01.lucid.host:6155}"
