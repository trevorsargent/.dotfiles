---
name: monorepo-commit
description: >
  Use this skill ANY time the user asks to commit their work. This includes "commit",
  "commit this", "commit everything", "make commits", "commit my changes", "commit and push",
  or any variation of asking to create git commits. This skill handles both simple single-repo
  commits and complex multi-submodule commits — it surveys the repo, groups changes into
  scoped conventional commits by feature, handles submodule ordering when needed, and prompts
  before pushing. Always use this skill instead of raw git commit commands.
---

# Monorepo Commit

Commit changes across a parent repo and its submodules in the correct order, grouped
into clean conventional commits, then optionally push everything.

The core problem this solves: submodule references in the parent repo point at specific
commits. If you commit the parent first, its submodule pointer is stale. Submodules
must be committed and (optionally) pushed before the parent records their new state.

## Workflow

### Phase 1: Survey

Gather the full picture before touching anything.

1. **Parent repo status**
   ```bash
   git status
   git diff          # unstaged
   git diff --cached # staged
   ```

2. **Submodule status** — identify which submodules have changes:
   ```bash
   git submodule foreach --quiet 'if [ -n "$(git status --porcelain)" ]; then echo "$name"; fi'
   ```
   For each dirty submodule, run `git -C <path> status` and `git -C <path> diff` to
   understand what changed.

3. **Unstaged vs staged** — if there is a mix of staged and unstaged changes in
   either the parent or any submodule, present the situation to the user and ask
   whether to include everything or only staged changes. Do not assume.

4. **Show the user a summary** — list every changed file grouped by repo (parent
   vs each submodule) with a short description of the change.

### Phase 2: Plan Commits

Group changes into logical, feature-scoped commits using conventional commit format:
`<type>(<scope>): <description>`

Grouping principles:
- **By concern, not by file.** A bug fix that touches three files is one commit.
  Two unrelated features in the same file are two commits.
- **Cross-repo coherence.** If a submodule change and a parent change are part of
  the same logical feature, note the relationship — but they will be separate commits
  (one per repo) because git requires it. Use consistent scopes/descriptions so the
  connection is obvious in the log.
- **Small over large.** When in doubt, split. A commit should be revertable without
  collateral damage.

Present the plan to the user:
```
Submodule: libs/hyphae
  1. fix(cell): correct lifetime tracking in switch_map

Parent repo:
  1. feat(entities): add complete_build lifecycle nodes
  2. fix(engine): stabilize scene dispatch timing
  3. chore: update hyphae submodule ref
```

Wait for the user to approve, adjust, or regroup before proceeding.

### Phase 3: Commit Submodules

For each submodule with changes (one at a time):

```bash
cd <submodule-path>
git add <specific-files>           # only files for this commit
git commit -m "<type>(<scope>): <description>"
```

If a submodule needs multiple commits, execute them in logical order.

After all submodule commits are done, return to the parent repo root.

### Phase 4: Commit Parent

1. **Update submodule references** — stage the submodule pointer updates:
   ```bash
   git add <submodule-path>   # for each committed submodule
   ```

2. **Commit parent changes** — execute each planned parent commit:
   ```bash
   git add <specific-files>
   git commit -m "<type>(<scope>): <description>"
   ```

   If the only parent change for a submodule is its pointer update, fold that into
   the most relevant parent commit rather than making a standalone "update submodule"
   commit — unless the submodule update is genuinely independent.

3. If there are multiple parent commits, stage and commit each group separately in
   the planned order.

### Phase 5: Push

After all commits are made, ask the user:

> Ready to push? This will push:
> - libs/hyphae (2 commits to main)
> - parent repo (3 commits to fix/engine-timing)
>
> Proceed? [y/n]

If yes, push submodules first, then parent — same order as commits:

```bash
git -C <submodule-path> push    # for each submodule
git push                         # parent
```

If any push fails (e.g., remote rejection), stop and report — don't continue pushing
other repos with a broken dependency chain.

## Commit Message Rules

- Conventional commits: `<type>(<scope>): <description>`
- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
- Imperative mood, lowercase, no period, under 72 chars
- Add a body (second `-m`) only when the "why" isn't obvious from the description
- Never reference AI, Claude, or automation
- Never add Co-authored-by trailers
- Check the repo's CLAUDE.md for any project-specific commit conventions (e.g.,
  initials in comments, specific scopes) and follow them

## Edge Cases

- **No submodule changes**: Skip phases 3 and the submodule parts of phase 5.
  Just do scoped parent commits.
- **Only submodule changes**: Commit the submodule, then commit the pointer update
  in the parent.
- **Detached HEAD in submodule**: Alert the user — they likely need to checkout a
  branch before committing. Do not commit on a detached HEAD without asking.
- **Merge conflicts**: Stop and surface the conflict. Do not attempt to resolve
  automatically.
- **Pre-commit hooks fail**: Report the failure, fix the issue, and create a new
  commit (do not amend).
