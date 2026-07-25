---
name: zshrc-tidy
description: Detect and relocate installer-appended shell config out of .zshrc and into zsh/.zsh/autoload/ modules in this dotfiles repo. Use this whenever the user asks to check, clean, tidy, or audit their zshrc/shell config, mentions that an installer "added stuff" or "polluted" their shell rc, asks "did anything get appended to my zshrc", or right after they install a tool that is known to append shell snippets (bun, pnpm, nvm, rustup, cargo, conda/mamba, deno, uv, pyenv, rbenv, sdkman, fnm, atuin, starship, google-cloud-sdk, homebrew, opam, ghcup, foundry, flutter, zoxide). Also use it proactively when a diff or git status shows changes to zsh/.zshrc that were not hand-written.
---

# zshrc-tidy

## Why this matters here

`~/.zshrc` is a **symlink into this repo** (`~/.zshrc → .dotfiles/zsh/.zshrc`). When an
installer runs `echo ... >> ~/.zshrc`, it writes straight through the symlink into
git-tracked `zsh/.zshrc`. So installer sludge doesn't just clutter a local file — it shows
up as a dirty working tree in the dotfiles repo and rides along into commits.

The repo's design is that `zsh/.zshrc` stays exactly one line:

```zsh
source $HOME/.zsh/init.zsh
```

Everything else lives as a focused module in `zsh/.zsh/autoload/<tool>.zsh`, which
`init.zsh` sources in a glob loop. Your job is to move each appended block into the right
module, rewritten to fit the house conventions, and leave `zsh/.zshrc` at its one line.

## Workflow

### 1. Scan

Run the bundled scanner — it reports the state of `zsh/.zshrc`, the other shell startup
files, and the existing autoload inventory in one shot:

```bash
bash .claude/skills/zshrc-tidy/scripts/scan-shell-init.sh
```

Read its output before touching anything. Three failure modes it distinguishes, which
need different responses:

- **Appended lines in `zsh/.zshrc`** — the common case. Proceed to step 2.
- **`~/.zshrc` is no longer a symlink** — an installer replaced the link with a real file.
  The repo version is now stale and the live config is untracked. Diff the two, merge the
  real content in via steps 2–4, then restore the link (`stow -D zsh && stow zsh` from the
  repo root) so future appends land back in git.
- **Content in `~/.zshenv` / `~/.zprofile` / `~/.profile` / `~/.bashrc`** — these are *not*
  in the repo, and zsh is the only shell in use here, so nothing routinely reads
  `.profile`/`.bashrc`/`.bash_profile` at all. Treat what you find there as a **gap, not as
  bash config to preserve**: installers like rustup write to those files by default, which
  means the setting never reached zsh and the tool is quietly missing from `$PATH` in every
  session. Don't skip these because they "belong to bash."

  The tell is a tool that's installed but unresolvable: `ls ~/.cargo/bin/foo` succeeds while
  `zsh -i -c 'command -v foo'` fails. Before adding a module, check whether one already
  covers it (`path.zsh` handles `$HOME/.local/bin`, which is what uv's `~/.local/bin/env`
  does) — otherwise you'll add a redundant module. Leave the bash files themselves in place;
  copying the setting into an autoload module is the fix, deleting their lines isn't.

If the scan comes back clean, say so plainly and stop. Don't invent work.

### 2. Classify each block

Group the appended lines into blocks by tool — installers usually bracket their additions
with comments (`# bun`, `# pnpm end`, `>>> conda initialize >>>`). For each block, decide
its destination:

- **A module already exists** (`bun.zsh`, `pnpm.zsh`, `pyenv.zsh`, …) → merge into it.
  Check first whether the module already covers the same thing. Some modules are
  *deliberately commented out* — at time of writing `pnpm.zsh`, `deno.zsh`, and `nvm.zsh`,
  but run the scan rather than trusting that list. A commented-out module is a decision,
  not an oversight, so if the installer re-added what one has disabled, ask the user
  whether they want it live now rather than silently uncommenting it.
- **No module exists** → create `autoload/<tool>.zsh`, named after the command the user
  actually types (`fnm.zsh`, not `node-version-manager.zsh`).
- **The block contains a secret** (API key, token, license key) → it goes in a
  `*.local.zsh` file, which is gitignored. `secrets.local.zsh` already exists; append there.
  Never commit a credential that an installer wrote into the rc.

`references/installers.md` has the known-installer table: what each one appends, where it
belongs, and the house-style rewrite. Read it when you hit a block you don't recognize on
sight.

### 3. Rewrite to house style

Don't paste installer output verbatim — it's written for a generic single-file rc, and this
repo's `init.zsh` has already handled several of its assumptions. Rewrite each block:

**Strip redundant `compinit`.** `init.zsh` runs `compinit` up front, deliberately, *before*
the autoload loop — with a daily-rebuild guard so concurrent shells don't race on
`~/.zcompdump`. Installer snippets that call `autoload -Uz compinit; compinit` themselves
undo that. Delete those lines and keep only the actual completion sourcing.

**Use `$HOME`, not the literal path.** Installers hardcode `/home/trevor/...`. The `zsh`
package is stowed on macOS too, so a literal Linux path silently breaks there — never
hardcode `/home/trevor` or `/Users/trevor`. Same reasoning applies to platform-specific
directories: guard on existence (`[[ -d /snap/bin ]]`, the brew-prefix loop in
`homebrew.zsh`) rather than assuming the OS.

**Guard anything that can fail.** The autoload loop sources every file in every shell,
including ones on machines where the tool isn't installed. Follow the existing patterns:

```zsh
command -v pyenv >/dev/null && ...     # pyenv.zsh
(( $+commands[some-cli] ))             # pulse-cluster.zsh — faster, zsh-native
[[ -s "$HOME/.bun/_bun" ]] && ...      # bun.zsh — guard on the file
[[ -o interactive ]] && ...            # zoxide.zsh — completions/prompts only
```

Completion and prompt setup should be interactive-guarded specifically because scripts run
with `zsh -c` pay the cost otherwise, and some completion shims misbehave without a tty.

**Don't duplicate PATH entries.** `path.zsh` already appends `$HOME/.local/bin`; if a block
re-adds it, drop the line. Note that `init.zsh` declares `typeset -gU path fpath`, so zsh
dedupes both arrays itself — you don't need the `case ":$PATH:"` guard installers ship, and
removing it is usually the right call. Keep it only where the block also does expensive
work worth skipping, not merely to avoid a duplicate entry.

**Put `fpath` additions before `compinit`, not in an autoload module.** `init.zsh` runs
`compinit` *after* `homebrew.zsh` but *before* the autoload loop. A module that appends a
completion directory to `fpath` therefore does so too late — compinit has already scanned,
and the completions silently never load. This is the one case where a block can't just
become `autoload/<tool>.zsh`: it belongs in `homebrew.zsh` (which exists partly to do
exactly this for brew's `site-functions`) or needs its own explicit source line added to
`init.zsh` ahead of `compinit`. Sourcing a ready-made completion *script* (bun's `_bun`,
`source <(cli completions zsh)`) is fine in a module — that path doesn't involve `fpath`.

**Mind the ordering.** The loop sources `autoload/*` in glob (alphabetical) order, so
`bun.zsh` runs before `zoxide.zsh`. If a block must run before others — a version manager
shimming `node`, say — note it in a comment rather than relying on the filename accident.
`homebrew.zsh` is the escape hatch: `init.zsh` sources it explicitly before the loop.

**Leave a comment saying what it is and why.** Look at `pulse-cluster.zsh` for the tone —
it explains what the shim does and why it's guarded, so future-you doesn't have to
re-derive it. A one-liner is fine for obvious cases; anything subtle deserves a sentence.

### 4. Truncate the rc

Once every block has a home, reset `zsh/.zshrc` to its single canonical line. Don't leave
a "moved to autoload" comment behind — the git history records that.

### 5. Verify

Prove it still works before reporting done. Syntax first, then a real shell:

```bash
zsh -n ~/.zshrc && for f in ~/.zsh/autoload/*; do zsh -n "$f" || echo "FAIL: $f"; done
zsh -i -c 'exit'            # should print no errors or warnings
zsh -i -c 'which <tool>'    # for each tool you moved — confirm it resolves
```

`zsh -n` only catches parse errors, so the interactive run matters: it's what catches a
missing guard blowing up on an unset variable, or a completion shim erroring without its
compinit. If a moved tool no longer resolves, the block needed something you dropped —
go back and figure out which line, don't just paste the original back.

### 6. Report

Tell the user, per block: what tool, where it went, and what you changed about it. Call out
anything you deliberately did *not* move (commented-out modules you didn't uncomment,
`.profile` content left for bash) and why. Then offer to commit — this repo uses
conventional commits, so `chore(zsh): move <tool> installer block into autoload`.
