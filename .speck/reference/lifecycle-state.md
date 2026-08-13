# Lifecycle state and stop-gates

Where a story or epic currently is, and which gates may never be skipped to move it forward.

**Why this is a reference and not orchestrator-internal.** Two different drivers need these
answers: `/story` and `/epic` when a human invokes them, and any autonomous loop (native `/goal`,
or the manual `check` → `gap` → repair loop) that is told to "resume the flow at its first missing
step". The orchestrator skills are user-only entry points, so a driver that is not the user cannot
load them. If the state ladder and the stop-gates lived only inside those skills, the autonomous
path — the one that most needs a stop-gate — would be the one path structurally unable to reach
them. One source, both readers.

`AGENTS.md` owns the canonical ORDER. This file owns STATE DETECTION and STOP-GATES. Neither
restates the other, and no skill carries a second copy of what is below.

## Story states

Read `spec.md` first; each rule below is evaluated in order and the first match wins.

| Detected condition | State |
|---|---|
| no `spec.md`, or it reads `**Current State**: Draft` | Draft — needs `story-specify` |
| `spec.md` reads `**Current State**: Specified`, no `plan.md` | Specified — needs `story-plan` |
| `plan.md` exists, no `tasks.md` | Planned — needs `story-tasks` |
| `tasks.md` exists, status `pending`/`in_progress` | Tasked — needs `story-implement` |
| `tasks.md` status `completed`, no `audit-report.md` | Implemented — needs `speck-audit` |
| `audit-report.md` exists, no `validation-report.md` | Audited — needs `story-validate` |
| `validation-report.md` exists, no `story-retro.md` | Validated — needs `story-retrospective` |
| `story-retro.md` exists | Done |

Build and Platform insert one more state between Tasked and Implemented: analysis is required, and
`story-analysis-report.md` must exist and be clear before implementation. Sprint skips it
explicitly. `check-story-prereqs.sh` is the enforcing gate; a tasks artifact that does not declare
`analysis_required` in a readable form fails closed rather than falling through to advisory.

## Epic states

| Detected condition | State |
|---|---|
| no `epic.md`, or it reads `**Current State**: Draft` | Draft — needs `epic-specify` |
| `epic.md` reads `**Current State**: Specified`, no `epic-tech-spec.md` | Specified — needs `epic-plan` |
| `epic-tech-spec.md` exists, no story directories implemented | Planned — needs `epic-breakdown` then the story loop |
| stories in progress | In progress |
| every story in `epic-breakdown.md` has a `validation-report.md`, no epic `audit-report.md` | Stories complete — needs `speck-audit` |
| epic `audit-report.md` exists, no `epic-validation-report.md` | Audited — needs `epic-validate` |
| `epic-validation-report.md` exists and is stamped | Validated |

## Stop-gates — binding on every driver

These hold whether a human typed the command, an orchestrator advanced the state, or an autonomous
loop routed to the step. None of them is waived by the driver being automated; an unattended run is
where they matter most.

1. **A state advances on verified work, never on artifact presence.** A file existing is not
   evidence its producing skill ran. Require the artifact to be template-compliant AND its
   producing skill to have actually run.
2. **Open `[NEEDS CLARIFICATION]` markers stop progression** until they are resolved.
3. **A P0/CRITICAL finding from `analyze` or `speck-audit` halts immediately.** Fix before
   continuing. `ANALYSIS_GRANDFATHERED.P2` is not a stop — surface it and continue.
4. **Prerequisite gates are not advisory.** `check-story-prereqs.sh` and `check-epic-prereqs.sh`
   exiting non-zero stops the step they guard. An epic may not start on a planning corpus no
   decorrelated lens has read.
5. **A delegated result is verified from its transcript and tool evidence before it counts.** A
   self-reported pass is not a pass; "stories complete" counts verified stories only.
6. **A skipped step needs an explicit `--skip` and a logged rationale**, never silent omission.

## Anti-patterns — what a driver does wrong when it hand-rolls the flow

Each of these is the shortcut an automated driver reaches for when it knows the sequence but has
not loaded the skill that owns the step:

- Writing `spec.md`, `plan.md`, or `tasks.md` inline instead of loading `story-specify`,
  `story-plan`, or `story-tasks`.
- Skipping `speck-audit` or `story-validate` because the outcome seems already known.
- Editing code without `story-implement`, so its prerequisite gates never run.
- Treating the flow as a checklist of FILENAMES rather than a checklist of SKILLS to invoke.

The correction is the same in every case: read and fully execute the owning skill's `SKILL.md`
(and the template its first action names) before advancing. Progression and stop-gate enforcement
are the driver's job; re-implementing a step from memory is not.
