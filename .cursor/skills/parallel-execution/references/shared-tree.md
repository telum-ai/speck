# Shared-tree concurrency

Read when parallel work runs in ONE working tree rather than separate worktrees — the default when
an epic session dispatches story agents, and the case `epic-breakdown.md` invites by establishing
file-disjointness and stopping there.

**File-disjointness is necessary and not sufficient.** It constrains which files a story *intends*
to touch. It constrains nothing about a command whose scope is the repository, a gate whose subject
is the whole index, or a reader who cannot tell a half-written file from a finished one.

## Rules for a worker in a shared tree

| Rule | What | Why |
|---|---|---|
| **No whole-tree mutations** | Never run a repo-wide formatter, codemod, or `--fix` across `.`. Format and lint only the paths this story owns. | A command scoped to `.` does not care which files your story owns; one run reformatted every file of a sibling story, uncommitted. |
| **Attribution is established, never assumed** | A whole-tree gate failure may not be blamed on a sibling session without `git log --oneline -3 -- <file>` and `git diff HEAD -- <file>`. An empty `git diff HEAD` means it is committed, and therefore yours to explain. | One git command separates "green" from "green for something else". |
| **Scoped-green is not whole-tree evidence** | A scoped run may be cited for the paths it covered and nothing else. A guard living in a third directory is outside it by construction. | Scoped-green plus whole-tree attribution manufactures a false all-clear on exactly the gate the story broke. |
| **Declare the isolation mode** | `epic-breakdown.md`'s Execution Strategy states, per parallel group, whether members run in a shared tree or separate worktrees — and if shared, that these rules bind. | Establishing file-disjointness and stopping implies a sufficiency it does not have. |

The shared `.git/index` is the other consequence: a pre-commit hook validates the whole index, so an
in-flight agent's half-written artifact can reject an unrelated commit from another session. Agents
then either wait on each other or reach for `--no-verify`, and the second is how a gate quietly
stops running. Prefer separate worktrees whenever commits will overlap in time.

## Reading a tree you do not own

The same tree is being written while you read it, which makes some conclusions unavailable rather
than merely uncertain.

- **A snapshot supports an observation, never a structural conclusion.** "Missing", "inconsistent",
  and "half-finished" are indistinguishable from "mid-write" in a single read. Two reads separated
  in time tell them apart; one never can. Check mtime before concluding, and say "as of <time>"
  when reporting.
- **Repair is the conductor's job.** A worker that finds the tree broken, reset, or missing STOPS
  and reports. It does not clone, checkout, reset, stash, or move anything to fix it. The
  destroying act is almost always a well-meant repair: a fresh clone moved over a shared tree
  discards every uncommitted change in it, including work the repairer cannot see.
- **Uncommitted fan-out results are one bad actor away from gone.** Checkpoint-commit before
  dispatch and commit each wave as it lands. On a feature branch this costs nothing and is the only
  real backup.

## For the conductor

Put the prohibition in the worker's instructions rather than trusting convention: no
`clone/checkout/reset/restore/clean/stash/revert/rebase/merge`, and no `rm`/`mv`/`cp` targeting the
repository or its parent. Read-only git — `show`, `diff`, `log`, `cat-file`, `archive` — is enough
for every legitimate worker need. When a worker needs a pristine tree to experiment in, hand it the
recipe rather than letting it invent one:

```
SCRATCH=$(mktemp -d) && git -C <repo> archive HEAD | tar -x -C "$SCRATCH"
```
