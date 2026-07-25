---
name: new-myko-project
description: >
  Use this skill whenever the user wants to spin up a new Rust project/repo/workspace built on
  the myko framework — "set up a new repo", "bootstrap a workspace", "scaffold a new myko
  project", "start a project like levi", "new crate workspace with flux and levi", or any
  variation of creating a fresh multi-crate Rust workspace in the house style. It generates the
  full skeleton: a cargo-flux config, a levi-tracked repo, a `<name>-core` entity crate on the
  myko framework, and — optionally — a CLI binary, a myko-server hub, and a Leptos dashboard,
  shaped exactly like ~/Code/levi. Reach for this even when the user only says "new project" in a
  context where the house stack (myko / flux / levi) is the obvious default.
---

# New myko project

Bootstrap a fresh Rust workspace shaped like `~/Code/levi` — the house pattern for a myko-based
project: a cargo-flux build config, levi task-tracking, a core entity crate on the myko
framework, and optional CLI / hub / dashboard crates.

The heavy lifting is done by a **deterministic generator** (`scripts/bootstrap.py`) rather than
by writing files freehand, because this layout has several invariants that are easy to get
subtly wrong and annoying to debug later:

- the wasm-only dash must be excluded from `default-members` so native `build`/`test` skip it;
- the hub must call `<core>::link()` or myko's inventory registrations get dead-stripped;
- each crate's `[package.metadata.flux]` task list is what gates which flux tasks touch it;
- `mullion` (levi's pane library) must never be a crates.io dependency — the name is squatted.

Your job is to interview for the few real choices, run the generator, wire up levi, and prove it
compiles. Work in this order.

## Step 1: Gather the choices

Ask the user (or infer from what they already said) — keep it to one quick round:

1. **Project name** — kebab-case, e.g. `acme`. This names the workspace dir and the crate prefix
   (`acme-core`, `acme`, `acme-hub`, `acme-dash`).
2. **Where** — parent directory (default: `~/Code`). The workspace lands in `<dir>/<name>`.
3. **Which optional crates** — the `<name>-core` library is always generated. Confirm which of
   these to add:
   - **CLI** (`<name>`) — a clap binary. Include when the project has a command-line entry point.
   - **hub** (`<name>-hub`) — a myko `CellServer` aggregation server (optional Postgres).
   - **dashboard** (`<name>-dash`) — a Leptos CSR wasm UI, built with trunk.

Baked-in defaults (only revisit if the user pushes back): myko pinned to the **latest crates.io
release**, license **AGPL-3.0-or-later**, and levi initialized against the **shared hub**
(`levi-hub-01.lucid.host:7377`). If the user wants a myko *path* dependency (developing in
lockstep with `~/Code/myko`) or a different license, note it — you'll adjust after generation.

## Step 2: Generate the skeleton

Resolve the latest myko version first so the pin is real, then run the generator. The
`--license-file` points at the AGPL text bundled with this skill so the new repo gets a full,
correct LICENSE rather than a stub.

```bash
MYKO_VER=$(cargo search myko 2>/dev/null | sed -nE 's/^myko = "([^"]+)".*/\1/p' | head -1)
MYKO_VER=${MYKO_VER:-5.0.0}

python3 "$SKILL_DIR/scripts/bootstrap.py" \
  --name <name> \
  --dir <parent-dir> \
  --myko-version "$MYKO_VER" \
  --license-file "$SKILL_DIR/assets/LICENSE-AGPL-3.0.txt" \
  [--with-cli] [--with-hub] [--with-dash] \
  [--repository https://github.com/<org>/<name>]
```

Pass only the `--with-*` flags for the crates the user chose. `$SKILL_DIR` is this skill's
directory. The generator refuses to write into a non-empty directory, so a stray existing folder
surfaces as a clear error rather than a silent clobber.

If the user wanted **path deps to `~/Code/myko`** instead of crates.io, edit the generated root
`Cargo.toml` afterward: change the `myko`/`myko-server`/`myko-leptos` lines under
`[workspace.dependencies]` to `{ path = "…/myko/libs/myko/<crate>" }`.

## Step 3: Initialize levi

From inside the new workspace, adopt it into levi so it tracks its own tasks. `levi init` mints or
adopts the project on the hub, writes `.levi/config.toml`, and appends a task-tracking section to
`CLAUDE.md`:

```bash
cd <dir>/<name>
levi init --hub levi-hub-01.lucid.host:7377
```

If the user opted out of levi, skip this. If `levi` isn't installed, note it and move on rather
than failing the whole bootstrap.

## Step 4: Prove it compiles

A scaffold that doesn't build is worse than useless — it looks done but wastes the user's next
hour. Verify before handing back:

```bash
cargo flux run check
```

If a dashboard was included, also run the wasm target, since `check` only exercises native:

```bash
cargo flux run check-wasm
```

**If the build fails, fix it before continuing** — a scaffold is supposed to be a known-good
starting point. The likeliest culprits are dependency-version drift (a newer myko releasing a
breaking change, or `leptos`/`myko-leptos` versions that need aligning). Read the actual error,
adjust the offending version pin in the workspace `Cargo.toml`, and re-run. If it's genuinely
not resolvable in a couple of focused attempts (e.g. an upstream crate is mid-release), stop and
report exactly what won't resolve — don't hand over a broken skeleton claiming success.

## Step 5: First commit

Initialize git and make a clean initial commit so the user starts from a versioned baseline
(this also gives levi a HEAD to anchor future task closures against):

```bash
cd <dir>/<name>
git init -q
git add -A
git commit -qm "chore: scaffold <name> workspace"
```

Use a plain conventional-commit message; do not add AI/Claude attribution (this house style
forbids it, and the release workflow parses commit messages for versioning).

## Step 6: Report

Tell the user what was created — the crate list, where it lives, that it builds, and the obvious
next moves:

- add real entities in `<name>-core/src/entities/` (the generated `Note` is a template to copy);
- `cargo flux run test` runs the suite; `trunk serve` in `<name>-dash/` runs the UI (if present);
- `levi next --claim --json` to pull the first task once you've filed some.

If the user asked for a GitHub repo, offer to `gh repo create` and push — but confirm before
creating anything remote.
