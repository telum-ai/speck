#!/usr/bin/env bash
# canonical-routing.test.sh
#
# THE DEFECT this pins: AGENTS.md's always-on gate says "Never invent filenames
# under `specs/`; read `.speck/reference/canonical-routing.md` when writing an
# artifact." That makes this file the filename authority. Artifacts that
# shipped skills/executables actually read or write were missing from their
# level's routing table, so an agent obeying the gate would find no canonical
# home, stall per this file's own line 48 ("ask the user before creating
# anything bespoke"), or invent a bespoke filename:
#   - story-analysis-report.md   (written by analyze/references/reports/story.md;
#                                  hard-required by check-story-prereqs.sh's
#                                  UNANALYZED_CORPUS.P1 gate for Build/Platform)
#   - epic-punch-list.md         (written by epic-validate/references/post-write.md)
#   - project-validation-summary.md (written by project-validate/references/post-write.md)
#   - project-roadmap.md         (written by project-roadmap/SKILL.md)
#   - connoisseur-critique.md    (speck_graph.py:780 reads it for verdict extraction;
#                                  speck-larp/references/jobs/taste.md:3 writes it)
#   - epics.md                   (project-plan/SKILL.md:71 writes it; read by
#                                  epic-specify, project-ux, project-roadmap,
#                                  parallel-execution/references/wave-safety.md)
#   - experience-chain-historical.md (speck-migrate/references/scaffold.md:27 and
#                                  .speck/scripts/migrate.sh:250 write it)
#   - seam-contract-*.md         (parallel-execution/references/wave-safety.md:6
#                                  requires it; validate-template.sh has a
#                                  dedicated "seam-contract" validation branch)
#
# A round of adversarial review found the first fix round had only asserted the
# 4 filenames its own test greps for, leaving neighbouring gaps (the last 4
# above) open under a green check. To close the whole class, not just the
# named instances, this test ALSO sweeps every `.speck/templates/**/*-template.md`
# stem and requires it (case-insensitively) somewhere in this file — with a
# documented ALLOWLIST for the template families whose template filename
# stem legitimately differs from the artifact's actual canonical filename
# (verified by tracing each to its writer/reader below). Run directly:
# bash .speck/reference/canonical-routing.test.sh
#
# A SECOND round of adversarial review found the template-stem sweep still
# only covers artifacts scaffolded FROM a `.speck/templates/**/*-template.md`
# file. Artifacts a shipped mechanism writes or designates WITHOUT going
# through a template were invisible to it and survived:
#   - findings-exceptions.md     (the ONE artifact speck_graph.py designates
#                                  as agent-authored — py:1208 comment, py:1245
#                                  read_findings_exceptions(), py:2201
#                                  EXCEPTION_PHANTOM gate code, py:2464 verdict
#                                  text — never templated, never heredoc-written,
#                                  purely a documented read-target)
#   - migration-report.md        (migrate.sh:49,204 heredoc-writes it directly;
#                                  migrate.test.sh:98 asserts its path — no
#                                  template involved)
#   - migration-estimate.md, catch-up-honesty-pass.md, project-catch-up-plan.md
#                                  (speck-migrate/references/scaffold.md:15,32,39
#                                  instruct the agent to author them directly —
#                                  no template, no heredoc)
# To close THIS class too, three more sweeps run below, each keyed to the
# actual signal that names the artifact in shipped code/instructions rather
# than to the template mechanism: a heredoc-write sweep over
# `.speck/scripts/**/*.sh`, a `project_dir` join sweep over `speck_graph.py`,
# and a "Write [and stamp] `X.md`" imperative sweep over `.cursor/skills/**`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
ROUTING="$ROOT/.speck/reference/canonical-routing.md"
TEMPLATES_DIR="$ROOT/.speck/templates"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

[[ -f "$ROUTING" ]] || { echo "  ✗ canonical-routing.md not found at $ROUTING"; exit 1; }

story_table="$(awk '/^### Story-level/{flag=1} /^### /{if (NR>1 && !/Story-level/) flag=0} flag' "$ROUTING")"
epic_table="$(awk '/^### Epic-level/{flag=1} /^### Story-level/{flag=0} flag' "$ROUTING")"
project_table="$(awk '/^### Project-level/{flag=1} /^### Workspace-level/{flag=0} flag' "$ROUTING")"

echo "── canonical-routing.md: story-level table carries story-analysis-report.md"
if grep -Fq 'story-analysis-report.md' <<<"$story_table"; then
  pass "story-analysis-report.md has a row in the story-level table"
else
  fail "story-analysis-report.md is missing from the story-level table (blocks UNANALYZED_CORPUS.P1 route)"
fi

echo "── canonical-routing.md: epic-level table carries epic-punch-list.md"
if grep -Fq 'epic-punch-list.md' <<<"$epic_table"; then
  pass "epic-punch-list.md has a row in the epic-level table"
else
  fail "epic-punch-list.md is missing from the epic-level table"
fi

echo "── canonical-routing.md: project-level table carries project-validation-summary.md and project-roadmap.md"
if grep -Fq 'project-validation-summary.md' <<<"$project_table"; then
  pass "project-validation-summary.md has a row in the project-level table"
else
  fail "project-validation-summary.md is missing from the project-level table"
fi

if grep -Fq 'project-roadmap.md' <<<"$project_table"; then
  pass "project-roadmap.md has a row in the project-level table"
else
  fail "project-roadmap.md is missing from the project-level table"
fi

echo "── canonical-routing.md: story-level table carries connoisseur-critique.md"
if grep -Fq 'connoisseur-critique.md' <<<"$story_table"; then
  pass "connoisseur-critique.md has a row in the story-level table"
else
  fail "connoisseur-critique.md is missing from the story-level table (speck_graph.py:780 reads it for verdicts)"
fi

echo "── canonical-routing.md: project-level table carries epics.md"
if grep -Fq 'epics.md' <<<"$project_table"; then
  pass "epics.md has a row in the project-level table"
else
  fail "epics.md is missing from the project-level table (project-plan writes it; 4+ shipped skills read it)"
fi

echo "── canonical-routing.md: epic-level table carries experience-chain-historical.md"
if grep -Fq 'experience-chain-historical.md' <<<"$epic_table"; then
  pass "experience-chain-historical.md has a row in the epic-level table"
else
  fail "experience-chain-historical.md is missing from the epic-level table (speck-migrate writes it)"
fi

echo "── canonical-routing.md: project-level table carries seam-contract"
if grep -Fq 'seam-contract' <<<"$project_table"; then
  pass "seam-contract has a row in the project-level table"
else
  fail "seam-contract is missing from the project-level table (wave-safety.md requires it; validate-template.sh validates it)"
fi

echo "── canonical-routing.md: project-level table carries findings-exceptions.md"
if grep -Fq 'findings-exceptions.md' <<<"$project_table"; then
  pass "findings-exceptions.md has a row in the project-level table"
else
  fail "findings-exceptions.md is missing from the project-level table (speck_graph.py:1245 designates it the only agent-authored findings artifact)"
fi

echo "── canonical-routing.md: project-level table carries the speck-migrate artifact family"
for mig_file in migration-report.md migration-estimate.md catch-up-honesty-pass.md project-catch-up-plan.md; do
  if grep -Fq "$mig_file" <<<"$project_table"; then
    pass "$mig_file has a row in the project-level table"
  else
    fail "$mig_file is missing from the project-level table (migrate.sh / speck-migrate scaffold.md write it into specs/projects/<id>/)"
  fi
done

# ── Generalized sweep: every shipped template's stem must resolve somewhere
# in this file, or be an explicitly justified exception below. This is the
# same probe an adversarial reviewer will run again — enumerate templates,
# case-insensitive grep each stem — so it must stay green against the WHOLE
# template set, not just the names above.
echo "── canonical-routing.md: template-stem sweep (every .speck/templates/**/*-template.md)"

# ALLOWLIST: template filename stem legitimately differs from the artifact's
# actual canonical filename, which IS routed (verified by tracing writer/reader):
#   epics-list       -> writes epics.md (routed above, project-level table)
#   primitives-registry -> writes design-system/primitives.md (routed:
#                          "Live UI primitives registry" row, project-level)
#   persona-larp      -> content merged into personas/<id>.md (routed:
#                          "Per-persona detection + LARP script" row); no
#                          separate persona-larp.md file is ever written
#   sprint-prd        -> writes PRD.md for Sprint play level (routed:
#                          "Requirements/features delivered" row); same
#                          canonical file as Build/Platform, sprint-specific
#                          template content only
#   orchestration-ledger -> its own template header declares it explicitly
#                          "Coordination-only file (not a truth artifact):
#                          keep it on `main` (or the conductor's branch)" —
#                          self-documented placement, no fixed path any
#                          executable validates or gates on (confirmed: no
#                          case for it in validate-template.sh), unlike the
#                          artifacts pinned above
ALLOWLIST="epics-list primitives-registry persona-larp sprint-prd orchestration-ledger"

sweep_failed=0
while IFS= read -r tmpl; do
  stem="$(basename "$tmpl" | sed 's/-template\.md$//')"
  skip=0
  for allowed in $ALLOWLIST; do
    [[ "$stem" == "$allowed" ]] && skip=1 && break
  done
  [[ "$skip" == 1 ]] && continue
  if grep -qi -- "$stem" "$ROUTING"; then
    pass "template stem '$stem' resolves in canonical-routing.md"
  else
    fail "template stem '$stem' (from ${tmpl#"$ROOT"/}) has no mention anywhere in canonical-routing.md and is not in the documented ALLOWLIST"
    sweep_failed=1
  fi
done < <(find "$TEMPLATES_DIR" -name '*-template.md' | sort)

if [[ "$sweep_failed" == 1 ]]; then
  FAILED=1
fi

# ── Shipped-script write-target sweep: enumerate every `$PROJECT_DIR/*.md`
# artifact a shipped, non-test `.speck/scripts/**/*.sh` script actually
# heredoc-writes (`cat > "$VAR" <<...` where `$VAR` was assigned from a
# `$PROJECT_DIR/*.md` or `${PROJECT_DIR}/*.md` literal), and require each has
# a routing row. This is a DIFFERENT signal than the template-stem sweep
# above: migration-report.md (migrate.sh:49,204) is written directly by a
# heredoc, not scaffolded from a `.speck/templates/**/*-template.md` file, so
# it was invisible to that sweep and survived a full round of review.
echo "── canonical-routing.md: shipped-script write-target sweep (.speck/scripts/**/*.sh, non-test, heredoc writes)"
script_sweep_failed=0
while IFS= read -r script; do
  while IFS= read -r var; do
    [[ -z "$var" ]] && continue
    target="$(grep -oE "${var}=\"\\\$\{?PROJECT_DIR\}?/[A-Za-z0-9_./*-]+\.md\"" "$script" 2>/dev/null | head -1 | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*="\$\{?PROJECT_DIR\}?\///; s/"$//' || true)"
    [[ -z "$target" ]] && continue
    if grep -Fqi -- "$target" "$ROUTING"; then
      pass "shipped-script write target '$target' (${script#"$ROOT"/}, \$$var) resolves in canonical-routing.md"
    else
      fail "shipped-script write target '$target' (${script#"$ROOT"/}, \$$var) has no row in canonical-routing.md"
      script_sweep_failed=1
    fi
  done < <(grep -oE 'cat > "\$[A-Za-z_][A-Za-z0-9_]*"' "$script" | sed -E 's/^cat > "\$//; s/"$//' | sort -u)
done < <(find "$ROOT/.speck/scripts" -name '*.sh' ! -name '*.test.sh' | sort)
[[ "$script_sweep_failed" == 1 ]] && FAILED=1

# ── speck_graph.py project_dir join sweep: every literal `.md` filename the
# graph joins onto `project_dir` must have a routing row. findings-exceptions.md
# is never *written* by any shipped script or skill instruction (it is
# designated agent-authored purely in a source comment — py:1208), so neither
# the template sweep nor a "Write `X.md`" skill-instruction sweep can find it.
# This is the one signal that does: the graph reads it by exactly this
# construct (py:1245).
echo "── canonical-routing.md: speck_graph.py project_dir join sweep"
py_sweep_failed=0
GRAPH_PY="$ROOT/.speck/scripts/graph/speck_graph.py"
while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  if grep -Fqi -- "$target" "$ROUTING"; then
    pass "speck_graph.py project_dir target '$target' resolves in canonical-routing.md"
  else
    fail "speck_graph.py project_dir target '$target' (os.path.join(project_dir, ...)) has no row in canonical-routing.md"
    py_sweep_failed=1
  fi
done < <(grep -oE 'os\.path\.join\(project_dir, *"[A-Za-z0-9_./*-]+\.md"\)' "$GRAPH_PY" | grep -oE '"[A-Za-z0-9_./*-]+\.md"' | tr -d '"' | sort -u)
[[ "$py_sweep_failed" == 1 ]] && FAILED=1

# ── Skill authoring-instruction sweep: every `Write [and stamp] \`X.md\``
# imperative under `.cursor/skills/**` names an artifact a skill instructs an
# agent to author. This catches the speck-migrate scaffold family
# (migration-estimate.md, catch-up-honesty-pass.md, project-catch-up-plan.md)
# that neither the template sweep nor the shipped-script sweep can see,
# because the scaffold phases are agent-authored prose steps, not template
# copies or heredoc writes.
echo "── canonical-routing.md: skill authoring-instruction sweep (Write [and stamp] \`X.md\`)"
skill_sweep_failed=0
while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  if grep -Fqi -- "$target" "$ROUTING"; then
    pass "skill-authored target '$target' resolves in canonical-routing.md"
  else
    fail "skill-authored target '$target' (a 'Write [and stamp] \`$target\`' instruction under .cursor/skills/) has no row in canonical-routing.md"
    skill_sweep_failed=1
  fi
done < <(grep -rhoE '\bWrite( and stamp)? `[a-zA-Z0-9_./*-]+\.md`' "$ROOT/.cursor/skills/" | grep -oE '`[a-zA-Z0-9_./*-]+\.md`' | tr -d '`' | sort -u)
[[ "$skill_sweep_failed" == 1 ]] && FAILED=1

# ── Project-dir REFERENCE sweep. The sweeps above are direction- and verb-specific: they see an
# artifact only if a script heredoc-WRITES it, a template carries its stem, or a skill says the exact
# words "Write `X.md`". Two whole classes slip through that net — an artifact a shipped script only
# READS as an input (value-defensibility.md, gating COMMERCIAL-RC), and one a skill creates with any
# other verb ("Preserve `sprint-log.md` as `sprint-log-history.md`"). Both were live gaps. This sweep
# is direction-agnostic and verb-agnostic: any `.md` named against the project dir by shipped code,
# read or written, needs a canonical home, because the always-on gate forbids inventing one.
echo "── canonical-routing.md: project-dir reference sweep (any \$PROJECT_DIR/*.md a shipped script names)"
ref_sweep_failed=0
while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  if grep -Fqi -- "$target" "$ROUTING"; then
    pass "project-dir reference '$target' resolves in canonical-routing.md"
  else
    fail "project-dir reference '$target' is named against \$PROJECT_DIR by a shipped script but has no row in canonical-routing.md"
    ref_sweep_failed=1
  fi
done < <(
  find "$ROOT/.speck/scripts" -name '*.sh' ! -name '*.test.sh' -print0 2>/dev/null \
    | xargs -0 grep -hoE '\$\{?PROJECT_DIR\}?/[a-zA-Z0-9_-]+\.md' 2>/dev/null \
    | sed -E 's#.*/##' | sort -u
)
[[ "$ref_sweep_failed" == 1 ]] && FAILED=1

# Same net over skill prose, but for every authoring verb rather than "Write" alone.
echo "── canonical-routing.md: skill authoring sweep, any verb (Preserve/Create/Emit/Append \`X.md\`)"
verb_sweep_failed=0
while IFS= read -r target; do
  [[ -z "$target" ]] && continue
  if grep -Fqi -- "$target" "$ROUTING"; then
    pass "skill-authored target '$target' resolves in canonical-routing.md"
  else
    fail "skill-authored target '$target' (named by an authoring instruction under .cursor/skills/) has no row in canonical-routing.md"
    verb_sweep_failed=1
  fi
done < <(
  # Take EVERY backticked .md on an authoring line, not just the first: "Preserve `a.md` as
  # `b.md`" names two artifacts and it is the second one that is easy to leave unrouted.
  grep -rhE '\b(Write|Preserve|Create|Emit|Append|Record|Produce)\b[^|]*`[a-zA-Z0-9_./*-]+\.md`' "$ROOT/.cursor/skills/" 2>/dev/null \
    | grep -oE '`[a-zA-Z0-9_./*-]+\.md`' | tr -d '`' \
    | grep -v 'templates/' | grep -v -- '-template\.md$' \
    | sed -E 's#.*/##' | sort -u
)
[[ "$verb_sweep_failed" == 1 ]] && FAILED=1

if [[ "$FAILED" == 0 ]]; then
  echo "✅ canonical-routing.md: all tests passed"
else
  echo "❌ canonical-routing.md: FAILURES"
  exit 1
fi
