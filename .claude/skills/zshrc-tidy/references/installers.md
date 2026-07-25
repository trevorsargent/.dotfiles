# Known installer snippets → where they belong

Lookup table for classifying appended blocks. Each entry gives the marker the installer
leaves, the target autoload module, and the house-style rewrite. When a tool isn't listed,
fall back on the general rules in SKILL.md — the patterns here are the point, not the
coverage.

Two things bite repeatedly across almost all of these, so check them every time:

1. **`compinit` duplication.** `init.zsh` already runs `compinit` before the autoload loop,
   with a daily-rebuild guard. Any `autoload -Uz compinit` / `compinit` the installer added
   must go, or it re-runs (and can race the shared `~/.zcompdump`).
2. **Hardcoded `/home/trevor`.** Rewrite to `$HOME`.

---

## Node / JS

### bun
Marker: `# bun completions`, `BUN_INSTALL`
Target: `bun.zsh` (exists)

```zsh
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

### pnpm
Marker: `# pnpm` … `# pnpm end`
Target: `pnpm.zsh` (exists, **currently commented out in full**)
The installer's own block is already idempotent; keep its `case` guard. Since the module is
deliberately disabled, confirm with the user before uncommenting.

### nvm / fnm / volta
Marker: `NVM_DIR`, `eval "$(fnm env)"`, `VOLTA_HOME`
Target: `nvm.zsh` (exists) / new `fnm.zsh` / new `volta.zsh`
These shim `node`, so they must run before anything that calls `node` at startup. Glob
order puts `fnm.zsh` before `nvm.zsh` and `node.zsh` — fine, but say so in a comment.
Guard nvm's slow lazy-load path on the file existing:

```zsh
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
```

### deno
Marker: `DENO_INSTALL`
Target: `deno.zsh` (exists)

---

## Rust

### rustup / cargo
Marker: `. "$HOME/.cargo/env"`
Target: new `cargo.zsh`
Note: rustup writes to `.profile`, `.bashrc`, **and** `.zshenv` — check section B of the
scan output, not just `.zshrc`. Removing it from `.profile` will break `bash -l`, so ask.

```zsh
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
```

### foundry / rustup completions
Completion output belongs behind an interactive guard, same shape as `pulse-cluster.zsh`:

```zsh
[[ -o interactive ]] && (( $+commands[forge] )) && source <(forge completions zsh)
```

---

## Python

### pyenv
Marker: `PYENV_ROOT`, `eval "$(pyenv init -)"`
Target: `pyenv.zsh` (exists, already correctly guarded on `command -v pyenv`)

### conda / mamba
Marker: `# >>> conda initialize >>>` … `# <<< conda initialize <<<`
Target: new `conda.zsh`
Keep the whole generated block intact — it's a fragile `if/elif` that handles the
`conda.sh` vs `PATH` fallback. Wrap the hardcoded prefix in `$HOME` where it appears, and
guard the whole thing on the install dir existing. Conda prepends to `PATH` aggressively;
if `base` auto-activating is unwanted, `conda config --set auto_activate_base false` is the
fix rather than editing the block.

### uv / pipx / poetry
Marker: `$HOME/.local/bin` on PATH
Target: usually **nothing to do** — `path.zsh` already adds `$HOME/.local/bin`. Drop the
duplicate. Completions go in a new `uv.zsh` behind an interactive guard.

---

## Version / env managers

### sdkman
Marker: `SDKMAN_DIR`, `sdkman-init.sh`
Target: new `sdkman.zsh`. Must be last-ish; its own comment says so.

### rbenv / jenv / asdf / mise
Marker: `eval "$(rbenv init -)"`, `. "$HOME/.asdf/asdf.sh"`, `eval "$(mise activate zsh)"`
Target: new `<tool>.zsh`, guarded on `command -v`, same shape as `pyenv.zsh`.

### direnv
Target: new `direnv.zsh` — interactive guard; the hook is only useful with a prompt.

```zsh
[[ -o interactive ]] && (( $+commands[direnv] )) && eval "$(direnv hook zsh)"
```

---

## Prompt / shell UX

### starship, atuin, zoxide, fzf, thefuck
All interactive-only. Target: `<tool>.zsh` (`zoxide.zsh` exists and is the reference shape):

```zsh
[[ -o interactive ]] && eval "$(zoxide init --cmd j zsh)"
```

`fzf --zsh` and atuin both try to bootstrap completion; strip their `compinit` calls.
Note this repo binds zoxide to `j`, not `z` — preserve custom flags when merging.

---

## Cloud / vendor SDKs

### google-cloud-sdk
Marker: `path.zsh.inc`, `completion.zsh.inc`
Target: new `gcloud.zsh`. Two separate lines; the completion one gets the interactive guard,
the path one does not.

### aws / azure / kubectl / helm
Completions only. One module per tool, interactive-guarded `source <(kubectl completion zsh)`.
These shell out on every startup — if several pile up and shell start gets slow, that's the
cause, and caching to a file under `$XDG_CACHE_HOME` is the fix worth proposing.

### homebrew
Marker: `eval "$(brew shellenv)"`
Target: `homebrew.zsh` (exists, **currently commented out in full**)
Special: `init.zsh` sources this explicitly *before* the autoload loop, because it sets up
`PATH` that later modules depend on. It's the right home for anything that must run first.

---

## Secrets

Any `export *_API_KEY=`, `*_TOKEN=`, `*_SECRET=`, license keys, or telemetry IDs:
Target: `secrets.local.zsh` (exists, gitignored via `*.local.zsh`).

If a secret was already committed to `zsh/.zshrc`, moving it to a gitignored file does not
remove it from history. Say so explicitly and recommend rotating the credential — that's
the only real fix, and it's the user's call to make.
