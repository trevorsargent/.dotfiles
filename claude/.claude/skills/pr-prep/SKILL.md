---
name: pr-prep
description: >
  Use this skill whenever the user is getting a branch ready for a pull request — "prep this
  PR", "get this ready to merge", "prep for PR", "make a PR", "finalize this branch", "open a
  PR for this", or any variation of preparing/finishing a branch so it can be reviewed. It runs
  the full pre-PR checklist: syncs the branch with origin and the base branch, runs
  `cargo flux run check` and `cargo flux run test` (fixing failures where it can), closes any
  levi tasks the branch addressed (anchored at the closing commit), and then opens or updates
  the GitHub PR. Reach for this even when the user only mentions one piece ("run the checks and
  open a PR") — the point is to do the whole prep in the right order rather than a single step.
---

# PR Prep

Take a working branch from "code is written" to "PR is open and clean." The steps are
interdependent and order-sensitive, which is the whole reason this is a skill and not five
separate commands:

- **Sync before you check.** Running checks and tests against a stale branch tells you nothing
  about whether the *merged* result is green. Pull in origin and the base branch first so
  everything downstream reflects what will actually land.
- **Checks before you close tasks.** A levi task is only "done" if the work actually passes.
  Closing tasks before the build is green risks marking broken work as complete.
- **Everything before the PR.** The PR should reflect a synced, green, task-closed branch — so
  the description and the diff a reviewer sees are the real final state.

Work through the phases in order. Each phase has a gate: if it can't be completed cleanly, stop
and hand back to the user rather than plowing ahead — a half-prepped PR is worse than a clear
report of what's blocking.

## Phase 0: Orient

Gather state before touching anything. Run these together and read the results:

```bash
git rev-parse --is-inside-work-tree        # confirm we're in a repo
git branch --show-current                  # the branch being prepped
git status --porcelain                     # is the tree dirty?
git remote -v                              # is there an origin?
test -f .levi/config.toml && echo "levi:yes" || echo "levi:no"
gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null   # PR target
```

Determine the **base branch** — the branch this will merge into. In order of preference:
1. If a PR already exists for this branch, use its base: `gh pr view --json baseRefName -q .baseRefName`.
2. Otherwise the repo default: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` (usually `main`).
3. If neither resolves, ask the user.

**Dirty tree:** if there are uncommitted changes, stop and tell the user. Don't sync, rebase, or
open a PR on top of uncommitted work — offer to commit first (that's what the commit skill is
for) or let them stash. The rest of the prep assumes a clean tree.

Report the picture back in one line — branch, base, dirty/clean, levi yes/no, PR exists/not —
so the user can course-correct before anything mutates.

## Phase 1: Sync

Bring the branch up to date. There are two potential updates — from origin and from the base
branch. **Only act on the ones that actually have something to integrate**, and because that
means rewriting history, **ask the user rebase vs. merge before each integration you actually
perform** — don't assume. Different teams and branches have different conventions, and getting
it wrong forces an unpleasant undo.

The key nuance: don't ask when there's nothing to ask about. If the branch is already level with
its remote and already on top of the base, this whole phase is a no-op — say "already up to
date" and move straight to Phase 2. Prompting for a rebase-vs-merge choice that resolves to
zero commits is pure friction.

1. **Fetch first**, always: `git fetch --all --prune`.

2. **Measure divergence** before touching anything, so you know which integrations are even live:
   ```bash
   git rev-list --left-right --count origin/<branch>...HEAD   # behind/ahead of own remote
   git rev-list --left-right --count origin/<base>...HEAD     # behind/ahead of base
   ```

3. **Update from origin** — only if the "behind own remote" count is > 0. Integrate via the
   user's chosen style:
   - rebase: `git rebase origin/<branch>`
   - merge: `git merge origin/<branch>`

4. **Update from the base branch** — only if the "behind base" count is > 0, so the branch sits
   on top of the latest base:
   - rebase: `git rebase origin/<base>`
   - merge: `git merge origin/<base>`

**Conflicts are a hard stop.** If a rebase or merge conflicts, do not guess at resolutions —
surface the conflicted files and hand back to the user. They know the intended semantics; a
wrong auto-resolution is exactly the kind of silent error that poisons a PR.

## Phase 2: Check and test

Run the project's checks, then its tests:

```bash
cargo flux run check
cargo flux run test
```

These are the literal commands for this workflow — `flux` is the project's task runner. If
`cargo flux` isn't available in a given repo, say so and ask how the user wants checks/tests run
rather than substituting `cargo check`/`cargo test` silently.

**`cargo flux run test` is the source of truth for what "the tests" means.** It orchestrates a
broader set than a bare `cargo test` — different crates, workspaces, and languages, run with its
own parallelism. When a failure needs reproducing or narrowing, keep using `cargo flux` (or
reproduce the *exact* binary/filter it ran). Don't quietly fall back to `cargo test -p <crate>
--lib` to "focus" — it can run a different, smaller set that doesn't even include the failing
test, which will fool you into thinking the failure vanished.

**On failure: try to fix, then stop.** Read the actual error output and attempt a genuine fix —
a real compile error, a broken test, a lint. Re-run to confirm. But bound your effort: if it's
not clearly fixable (the failure is in unfamiliar territory, needs a product decision, or two or
three focused attempts haven't cleared it), **stop and report** with the failing output. Do not
paper over failures — never `#[ignore]` a test, loosen an assertion, or `--no-verify` your way
past a gate to make the phase "pass." A green build that lies is the worst possible outcome
here. The gate to advance is: check passes AND test passes, honestly.

**Watch for flaky / race failures — they're a distinct animal.** A test that fails once and
passes on re-run is usually an isolation or ordering problem (shared temp dir, global state,
parallel writers), not a stable bug. Don't just re-run until it goes green — a passing re-run
*hides* the flake; it doesn't fix it, and it'll resurface in CI. Instead diagnose: is the
failure intermittent under parallelism? Does the branch's own diff introduce the shared-state
contention (a good tell: `git log origin/<base>..HEAD -- <failing file's area>`)? A
branch-introduced flake is a legitimate **stop-and-report** — the fix is usually a judgment call
about test architecture (widen a lock, serialize the writers, make the operation
race-tolerant), which is the user's to make. Report the root cause and your proposed fix rather
than guessing at it or retrying past it.

## Phase 3: Close levi tasks

Skip this phase entirely if Phase 0 found no `.levi/config.toml`.

Levi is a git-aware issue tracker: `levi close <ID>` records the closure *anchored at a commit*
(HEAD by default, or `--anchor <sha>`), so a closed task carries a permanent reference to the
commit that resolved it. The goal here is to make sure every task this branch actually addressed
gets closed against the right commit — no more, no less.

1. **List what's open** on this checkout:
   ```bash
   levi ls --json          # open tasks resolvable here
   levi ls --mine --json   # narrower: tasks you claimed
   ```

2. **Find the candidates** two ways, and take the union:
   - **By commit reference** — scan the branch's own commits for task IDs:
     ```bash
     git log origin/<base>..HEAD --format='%H%n%B'
     ```
     Match task IDs mentioned in commit messages against the open list, and note *which*
     commit references each (that commit is the anchor).
   - **By judgment** — read the open tasks (`levi show <ID>`) against what the branch actually
     changed (`git diff origin/<base>..HEAD`). A task can be resolved by a branch that never
     names it. Include those, anchored at HEAD (or the specific commit that did the work, if
     you can pinpoint it).

3. **Confirm before closing.** Present the candidate list — task ID, title, and the anchor
   commit you'd use — and ask the user to confirm or trim it. Closing propagates to a shared hub
   and is visible to the team, so treat it as an outward-facing action that deserves a check
   rather than a silent batch. Err toward showing your reasoning ("closing #42 because commit
   abc123 implements the retry logic it asked for").

4. **Close the confirmed tasks**, each anchored at its resolving commit:
   ```bash
   levi close <ID> --anchor <sha>      # or plain `levi close <ID>` for HEAD
   ```
   Optionally add a one-line `levi comment <ID> "<what landed>"` when the closure isn't
   self-explanatory from the commit.

## Phase 4: Open or update the PR

Push the branch, then create the PR (or update it if one already exists):

```bash
git push -u origin <branch>            # push the synced/closed-out branch
gh pr view >/dev/null 2>&1 && echo exists || echo new
```

- **New PR:** `gh pr create --base <base> --head <branch>` with a generated title and body.
- **Existing PR:** it updates automatically on push. Refresh the description if the scope
  changed: `gh pr edit --body-file <file>`.

**Title:** a single conventional-commit-style summary of the branch's net change
(`feat(auth): add JWT refresh flow`), not a list of commits.

**Body:** write for the reviewer. A short **Summary** of what changed and why, a **Testing**
line stating that `cargo flux run check` and `cargo flux run test` pass, and — if levi tasks
were closed — a **Closes** section listing them by ID. Keep it tight; a reviewer should grasp
the change in fifteen seconds.

Finish by printing the PR URL so the user can jump straight to it.

## When to stop and report instead of finishing

This skill is allowed — expected — to not reach Phase 4. Stop and hand back a clear status when:
the tree is dirty, a sync conflicts, checks or tests can't be honestly made green, or the levi
candidate list needs the user's judgment. In every case, say exactly which phase you reached,
what's blocking, and what you'd do next. A precise stop is a successful run.
