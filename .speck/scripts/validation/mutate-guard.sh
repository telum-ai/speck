#!/usr/bin/env bash
# mutate-guard.sh — CP-6, the mutation-as-evidence chokepoint (issues #94, #99, #100 §1).
#
# WHY THIS EXISTS
# A guard test is not evidence until someone watched it fail. Three separate issues asked for
# that in three vocabularies — a mutation record (#94), a counter-test sweep (#99), a class
# recurrence check (#100 §1) — and if each had been built separately they would have drifted
# into three half-truths. They are all ONE operation: change the production line the claim is
# about, and observe what the suite does. This script is that operation, and the other two are
# call sites of it.
#
# WHY A THROWAWAY WORKTREE (the #88 / canary-lib.sh idiom, deliberately reused)
# The obvious implementation edits the real file and reverts it. That implementation has two
# failure modes this one cannot have:
#   (1) an interrupted run leaves a MUTATED production file in the working tree, where a Stop
#       hook, a watch task or a well-meaning `git commit -a` ships the defect the mutation was
#       simulating;
#   (2) "I reverted it" is itself an unverified claim.
# Here there is nothing to revert. Every write lands in a detached worktree the script owns and
# removes, and $ROOT is snapshot-verified before and after (INVARIANT-ZERO). A changed $ROOT is
# exit 2, loud, always — never a warning.
#
# WHY A GREEN CONTROL IS REQUIRED
# "The suite went red" has two causes that look identical: the mutation hit the predicate the
# guard is about, or the mutation broke the file so nothing in it runs. Only a test that must
# STAY green tells them apart. A run with no --green control cannot distinguish them, so it is
# refused rather than reported.
#
# WHY --expect-count RATHER THAN "exactly one test goes red"
# A real defence-in-depth fix is watched by several tests, and a real predicate change reddens
# a variable number of them. Assuming one would push authors to narrow the mutation until the
# count matched — tuning the evidence, which is the exact failure #94 §5(e) names.
#
# VERDICTS (the single set of codes — registered in .cursor/skills/speck-recheck/SKILL.md so a
# pipeline can consume them, instead of a markdown cell no pipeline can read):
#   GUARD_MUTATION_PROVEN   the mutation happened at a real, executable production line; at
#                           least --expect-count of the --red tests went red; every --green
#                           control stayed green.               exit 0
#   GUARD_MUTATION_GREEN.P2 the mutation provably happened and the suite did not notice. This is
#                           an HONEST, NON-BLOCKING verdict on purpose: making it a failure is
#                           what creates the incentive to tune a mutation until it reddens.
#                           Record it green and write the scope onto the test.   exit 0
#   GUARD_UNMUTATED.P2      nothing was measured — the pattern did not match exactly, the target
#                           is a test/fixture file, the matched line is a comment or docstring,
#                           a --red test was already red, or a control reddened (the file broke
#                           rather than the predicate).          exit 1
#   GUARD_UNMUTATED_HARNESS.P2
#                           nothing was measured, and THE HARNESS IS WHY — the probe worktree could
#                           not run the guard at all (a build tool that rejects the node_modules
#                           symlink, a missing binary). Split out from GUARD_UNMUTATED.P2 in v10.5
#                           (#114 §3) because the two read identically and mean opposite things:
#                           one says "we could not measure your guard", the other invites the reader
#                           to conclude the guard is worthless and delete it.  exit 1
#   GUARD_MUTATION_UNOBSERVABLE.P2
#                           the mutation provably happened, and the --red invocation STRUCTURALLY
#                           could not observe it — no applier was supplied for a guard whose subject
#                           is not the source tree (a DB schema, RLS, a grant posture), so the tests
#                           looked at a system the mutation never reached. Split from
#                           GUARD_MUTATION_GREEN.P2 in v10.5 (#114 §2.3): that code is documented as
#                           "the mutation provably happened and the suite did not notice — write the
#                           honest scope onto the test", and a reader who trusts that wording
#                           concludes the guard is blind. Here the guard is not blind at all.  exit 0
#
# RECEIPTS — AND THE LIMIT OF WHAT A RECEIPT CAN PROVE (read this before trusting one)
# Every run that resolves a real site drops a receipt in .speck/mutation-receipts/ pinning
# SHA + file:line + a content hash of the line AS IT STOOD AT THAT SHA. `--verify-receipt <report>`
# cross-checks the sites a validation report CITES against those receipts, recomputing each hash
# from `git show <sha>:<file>`.
#
# What that buys, precisely: a CITED SITE can no longer be invented. The documented failure was an
# auditor filling the Mutation Record with a fabricated site, a fabricated match count, a fabricated
# red count and GUARD_MUTATION_PROVEN — and passing. A cited site must now resolve to a real line
# whose content hashes to the pinned value at the pinned SHA, so the fabricated-site half of that is
# dead and machine-checkable.
#
# What it does NOT buy, stated plainly rather than implied away: this is a local file written by a
# local script, so it CANNOT prove a mutation was actually run. An agent with shell access can
# always synthesise a receipt. The cost of the forgery rises from "type 22 characters into a
# markdown cell" to "construct a receipt whose hash recomputes against the real line at the real
# SHA" — real, bounded, and NOT a proof of execution. Unforgeability needs a signer or a producer
# the agent cannot write as (CI), and neither exists here. Treat RECEIPT_VERIFIED as "the citation
# refers to something real", never as "the mutation happened".
#
# Adoption gradient (deliberate): a repo with no receipts at all degrades to RECEIPT_MISSING.P2 and
# does NOT block — projects predating receipts must not be held to them. A repo that DOES emit
# receipts is held to them, so a citation with no receipt there is RECEIPT_MISMATCH.P1. An absence
# is a degrade; a contradiction is a finding.
#
# Portable bash 3.2 / macOS. No associative arrays, no mapfile.
#
# Usage:
#   mutate-guard.sh --file <path-relative-to-root> --pattern <fixed-string> --replacement <str> \
#                   --red '<test invocation>' [--red ...] --green '<control invocation>' [--green ...] \
#                   [--expect-count N] [--match-count N] [--cwd <subdir>] [--root <dir>] \
#                   [--require-proven]
#   mutate-guard.sh --verify-receipt <validation-report.md> [--root <dir>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./canary-lib.sh
. "$SCRIPT_DIR/canary-lib.sh"
# shellcheck source=../lib/text.sh
. "$SCRIPT_DIR/../lib/text.sh"

FILE=""
PATTERN=""
REPLACEMENT=""
EXPECT_COUNT=""
MATCH_COUNT=1
SUBDIR=""
ROOT=""
REQUIRE_PROVEN=false
VERIFY_REPORT=""
RED_CMDS=()
GREEN_CMDS=()

# --applier <cmd> — "bring the system to the mutated state", run AFTER the mutation and BEFORE the
# --red invocations (#114 §2.2). The v10.4 model — mutate text, run tests — silently assumes the
# guard's subject IS the source tree. For a guard whose subject is a DATABASE that assumption is
# false: editing a migration nobody applies changes nothing the smoke can see, so the run produced
# GUARD_MUTATION_GREEN.P2 — "the mutation happened and the suite did not notice" — for a guard that
# reddens hard the moment the mutated migration actually reaches a database. Correct, and useless.
# The applier is the missing step, and it is a real one: schema, RLS and grant posture are exactly
# the guards that most need mutation evidence.
#
# It carries its own safety rule rather than inheriting --red's, because its job IS to change state.
# A local, disposable-stack applier (`supabase db reset`, `docker compose up`) classifies safe or
# unknown after #114 §2's verb-scoping and runs; anything that still trips the destructive denylist
# requires an explicit --applier-ack, which is a decision the author records rather than a default
# the tool grants.
APPLIER=""
APPLIER_ACK=false

RECEIPT_DIR_NAME=".speck/mutation-receipts"

die_usage() {
  echo "ERROR: $1" >&2
  echo "Usage: mutate-guard.sh --file <path> --pattern <str> --replacement <str> --red '<cmd>' --green '<cmd>' [--applier '<cmd>' [--applier-ack]] [--expect-count N] [--match-count N] [--cwd <subdir>] [--root <dir>] [--require-proven]" >&2
  echo "       mutate-guard.sh --verify-receipt <validation-report.md> [--root <dir>]" >&2
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify-receipt) VERIFY_REPORT="${2:-}"; shift 2 ;;
    --file)         FILE="${2:-}"; shift 2 ;;
    --pattern)      PATTERN="${2:-}"; shift 2 ;;
    --replacement)  REPLACEMENT="${2:-}"; shift 2 ;;
    --applier)      APPLIER="${2:-}"; shift 2 ;;
    --applier-ack)  APPLIER_ACK=true; shift ;;
    --red)          RED_CMDS+=("${2:-}"); shift 2 ;;
    --green)        GREEN_CMDS+=("${2:-}"); shift 2 ;;
    --expect-count) EXPECT_COUNT="${2:-}"; shift 2 ;;
    --match-count)  MATCH_COUNT="${2:-}"; shift 2 ;;
    --cwd)          SUBDIR="${2:-}"; shift 2 ;;
    --root)         ROOT="${2:-}"; shift 2 ;;
    --require-proven) REQUIRE_PROVEN=true; shift ;;
    -h|--help)      die_usage "help" ;;
    *)              die_usage "unknown argument: $1" ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[[ -n "$ROOT" && -d "$ROOT/.git" ]] || {
  # A worktree checkout has .git as a FILE, not a dir — accept either.
  [[ -n "$ROOT" && -e "$ROOT/.git" ]] || die_usage "--root must be a git repository (got '${ROOT:-<none>}')"
}

SHA_PINNED="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo UNKNOWN)"

# --- receipts ---------------------------------------------------------------------------------

# The pinned identity of a mutation site: the path, the line NUMBER, and the line's CONTENT as it
# stood at $SHA_PINNED. Content is what makes it non-trivial to fabricate — a made-up `file:999`
# cannot produce a hash that recomputes from `git show <sha>:<file>`.
site_hash_of() { cl_digest "$1:$2:$3"; }

verdict_rank() {
  case "$1" in
    GUARD_MUTATION_PROVEN)          echo 3 ;;
    GUARD_MUTATION_GREEN.P2)        echo 2 ;;
    GUARD_MUTATION_UNOBSERVABLE.P2) echo 2 ;;
    GUARD_UNMUTATED.P2)             echo 1 ;;
    GUARD_UNMUTATED_HARNESS.P2)     echo 1 ;;
    *)                              echo 0 ;;
  esac
}

receipt_dir() { printf '%s' "$ROOT/$RECEIPT_DIR_NAME"; }

# True when this repo emits receipts at all. Drives the adoption gradient: an un-adopted repo
# degrades, an adopted one is held to what it produces.
# `if` bodies rather than `[[ ]] && return 0`: an unmatched glob leaves $f as the literal pattern,
# and the failing AND-list would abort the function under errexit instead of falling through to
# `return 1`. That it currently cannot is only because the sole caller happens to run under
# `set +e` — a coupling that is invisible at this site and would break on the next caller.
receipts_adopted() {
  local d f
  d="$(receipt_dir)"
  if [[ ! -d "$d" ]]; then return 1; fi
  for f in "$d"/*.receipt; do
    if [[ -e "$f" ]]; then return 0; fi
  done
  return 1
}

receipt_field() { awk -v k="$2" -F= '$1 == k { sub(/^[^=]*=/, "", $0); print; exit }' "$1"; }

# --- verify mode ------------------------------------------------------------------------------
# Cross-checks the sites a validation report CITES against the receipts on disk. Read the header
# note on what this does and does not prove before treating RECEIPT_VERIFIED as assurance.
verify_report() {
  local report="$1" body rows dir adopted=false
  local n_cited=0 n_ok=0 have_mismatch=false have_missing=false
  local findings=""

  add_finding() { findings="${findings}SPECK_RECEIPT_FINDING=$1"$'\n'; }

  if [[ ! -f "$report" ]]; then
    echo "SPECK_RECEIPT_VERDICT=RECEIPT_MISSING.P2"
    echo "SPECK_RECEIPT_REASON=report not found: $report"
    echo "SPECK_RECEIPT_CITED=0"
    return 0
  fi
  dir="$(receipt_dir)"
  if receipts_adopted; then adopted=true; fi

  # ONLY table rows are citations. Restricting to lines that begin with `|` is load-bearing: the
  # shipped template's own "**Verdicts.**" paragraph names all three codes in PROSE, and a scan
  # over the whole section body would be satisfied by that boilerplate on an untouched template —
  # the exact "the rule passes on every report the template produces" defect this cluster exists
  # to kill. A row is a citation only when it names a verdict code in a CELL.
  body="$(awk '/^## 🧬 Mutation Record/{f=1; next} f && /^## /{exit} f {print}' "$report")"
  rows="$(awk -F'|' '
    /^[[:space:]]*\|/ {
      v = ""
      if      (index($0, "GUARD_MUTATION_PROVEN")   > 0) v = "GUARD_MUTATION_PROVEN"
      else if (index($0, "GUARD_MUTATION_GREEN.P2") > 0) v = "GUARD_MUTATION_GREEN.P2"
      else if (index($0, "GUARD_MUTATION_UNOBSERVABLE.P2") > 0) v = "GUARD_MUTATION_UNOBSERVABLE.P2"
      else if (index($0, "GUARD_UNMUTATED_HARNESS.P2") > 0) v = "GUARD_UNMUTATED_HARNESS.P2"
      else if (index($0, "GUARD_UNMUTATED.P2")      > 0) v = "GUARD_UNMUTATED.P2"
      if (v == "") next
      # $1 is empty (leading pipe) and $2 is the guard-test cell, which can itself hold a
      # path — start at the mutation-site cell so a test path is never mistaken for a site.
      s = ""
      for (i = 3; i <= NF; i++) {
        if (match($i, /[A-Za-z0-9_@.\/-]+\.[A-Za-z0-9]+:[0-9]+/)) { s = substr($i, RSTART, RLENGTH); break }
      }
      # US (0x1f), never a tab: tab is an IFS *whitespace* character, so `read` collapses a leading
      # empty field and a site-less row would arrive as site=<verdict>, verdict="" — silently
      # `continue`d, which made the "cites a verdict but names no site" branch below unreachable.
      printf "%s\037%s\n", s, v
    }' <<<"$body")"

  local site verdict rf rec_sha rec_hash rec_verdict rec_file rec_line actual recomputed
  while IFS=$'\037' read -r site verdict; do
    [[ -n "$verdict" ]] || continue
    n_cited=$((n_cited + 1))

    if [[ -z "$site" ]]; then
      have_mismatch=true
      add_finding "row cites $verdict but names no <path>:<line> mutation site — a verdict without a site is unverifiable by construction"
      continue
    fi

    rf="$(grep -Fxl "SPECK_MUTATION_SITE=$site" "$dir"/*.receipt 2>/dev/null | head -n1 || true)"
    if [[ -z "$rf" ]]; then
      if [[ "$adopted" == true ]]; then
        have_mismatch=true
        add_finding "$site: this repo emits mutation receipts, but no receipt names this site — the citation contradicts the evidence the repo itself produces"
      else
        have_missing=true
        add_finding "$site: no receipt on disk and this repo has never emitted one — not adopted, degraded rather than blocked"
      fi
      continue
    fi

    rec_sha="$(receipt_field "$rf" SPECK_MUTATION_SHA)"
    rec_hash="$(receipt_field "$rf" SPECK_MUTATION_SITE_HASH)"
    rec_verdict="$(receipt_field "$rf" SPECK_MUTATION_VERDICT)"
    rec_file="${site%:*}"
    rec_line="${site##*:}"

    if ! git -C "$ROOT" cat-file -e "$rec_sha:$rec_file" 2>/dev/null; then
      have_missing=true
      add_finding "$site: receipt pins SHA $rec_sha, which no longer resolves in this repo — cannot recompute, degraded rather than blocked"
      continue
    fi

    actual="$( { git -C "$ROOT" show "$rec_sha:$rec_file" 2>/dev/null || true; } \
                | awk -v ln="$rec_line" 'NR == ln { print; exit }' )"
    recomputed="$(site_hash_of "$rec_file" "$rec_line" "$actual")"

    # THE control point. The pinned content hash is the only thing standing between a cited site
    # and an invented one; if this comparison stops discriminating, a fabricated site verifies.
    if [[ "$recomputed" != "$rec_hash" ]]; then
      have_mismatch=true
      add_finding "$site: the receipt's pinned site content does not recompute at $rec_sha (receipt=$rec_hash recomputed=$recomputed) — the cited line is not the line that was measured"
      continue
    fi

    if [[ "$(verdict_rank "$verdict")" -gt "$(verdict_rank "$rec_verdict")" ]]; then
      have_mismatch=true
      add_finding "$site: the report claims $verdict but the receipt records $rec_verdict — a report may never claim a stronger verdict than the run produced"
      continue
    fi

    n_ok=$((n_ok + 1))
  done <<<"$rows"

  local verdict_out reason_out rc=0
  if [[ "$n_cited" -eq 0 ]]; then
    verdict_out="RECEIPT_NO_CITATIONS.P2"
    reason_out="the Mutation Record names no verdict code in any TABLE ROW — an untouched template is not a record (its Verdicts prose is boilerplate, not a citation)"
  elif [[ "$have_mismatch" == true ]]; then
    verdict_out="RECEIPT_MISMATCH.P1"
    reason_out="$((n_cited - n_ok)) of $n_cited cited site(s) contradict the receipts on disk"
    rc=1
  elif [[ "$have_missing" == true ]]; then
    verdict_out="RECEIPT_MISSING.P2"
    reason_out="$n_ok of $n_cited cited site(s) verified; the rest have no resolvable receipt (receipts not adopted here) — degraded, not blocked"
  else
    verdict_out="RECEIPT_VERIFIED"
    reason_out="all $n_cited cited site(s) resolve to a real line whose pinned content recomputes at the receipt SHA. This proves the CITATION is real; it does not prove the mutation ran"
  fi

  echo "SPECK_RECEIPT_VERDICT=$verdict_out"
  echo "SPECK_RECEIPT_REASON=$reason_out"
  echo "SPECK_RECEIPT_CITED=$n_cited"
  echo "SPECK_RECEIPT_VERIFIED=$n_ok"
  echo "SPECK_RECEIPT_ADOPTED=$adopted"
  # `if`, not `[[ ]] && printf` — under errexit a false AND-list here would abort the function
  # before `return "$rc"` and silently turn every clean verify into an exit-1.
  if [[ -n "$findings" ]]; then printf '%s' "$findings"; fi
  return "$rc"
}

if [[ -n "$VERIFY_REPORT" ]]; then
  set +e; verify_report "$VERIFY_REPORT"; VRC=$?; set -e
  exit "$VRC"
fi

[[ -n "$FILE" ]] || die_usage "--file is required"
[[ -n "$PATTERN" ]] || die_usage "--pattern is required"
[[ ${#RED_CMDS[@]} -gt 0 ]] || die_usage "at least one --red test invocation is required"
[[ "$MATCH_COUNT" =~ ^[0-9]+$ ]] || die_usage "--match-count must be an integer"
if [[ -n "$EXPECT_COUNT" ]]; then
  [[ "$EXPECT_COUNT" =~ ^[0-9]+$ ]] || die_usage "--expect-count must be an integer"
else
  EXPECT_COUNT="${#RED_CMDS[@]}"
fi

VERDICT=""
REASON=""
SITE=""
BEFORE_LINE=""
AFTER_LINE=""
FOUND_COUNT=0
RED_OBSERVED=0
WT=""
ROOT_SNAP=""
LINENO_HIT=""
SITE_HASH=""
RECEIPT_PATH=""

emit() {
  echo "SPECK_MUTATION_VERDICT=$VERDICT"
  echo "SPECK_MUTATION_REASON=$REASON"
  echo "SPECK_MUTATION_FILE=$FILE"
  echo "SPECK_MUTATION_SITE=$SITE"
  echo "SPECK_MUTATION_MATCH_COUNT=$FOUND_COUNT"
  echo "SPECK_MUTATION_EXPECT_COUNT=$EXPECT_COUNT"
  echo "SPECK_MUTATION_RED_COUNT=$RED_OBSERVED"
  echo "SPECK_MUTATION_CONTROLS=${#GREEN_CMDS[@]}"
  echo "SPECK_MUTATION_SHA=$SHA_PINNED"
  if [[ -n "$SITE_HASH" ]];    then echo "SPECK_MUTATION_SITE_HASH=$SITE_HASH"; fi
  if [[ -n "$RECEIPT_PATH" ]]; then echo "SPECK_MUTATION_RECEIPT=$RECEIPT_PATH"; fi
  [[ -n "$BEFORE_LINE" ]] && echo "SPECK_MUTATION_BEFORE=$BEFORE_LINE"
  [[ -n "$AFTER_LINE" ]] && echo "SPECK_MUTATION_AFTER=$AFTER_LINE"
  return 0
}

# Written by finish(), STRICTLY AFTER the INVARIANT-ZERO comparison. The ordering is load-bearing:
# a receipt is a deliberate write by this script into $ROOT, so taking the after-snapshot first
# keeps INVARIANT-ZERO a statement about a MUTATION escaping the worktree rather than about our own
# bookkeeping. A breached run exits before this and leaves no receipt — a run that lost control of
# the tree has nothing to attest.
write_receipt() {
  [[ -n "$SITE" && -n "$LINENO_HIT" ]] || return 0
  local dir id
  dir="$(receipt_dir)"
  mkdir -p "$dir" 2>/dev/null || return 0
  # A SELF-IGNORING directory (`*` ignores the .gitignore itself too). Receipts are local evidence,
  # so they must never appear in a consumer's `git status`: an untracked directory materialising
  # after every run would dirty the tree that INVARIANT-ZERO, the Stop hooks and every clean-tree
  # precondition are watching — a probe that makes the repo look mutated is its own defect. This
  # also means receipts do NOT travel to CI, which is consistent with what they are: an
  # authoring-time check on the machine that ran the mutation, not a transferable proof.
  [[ -f "$dir/.gitignore" ]] || printf '*\n' > "$dir/.gitignore" 2>/dev/null || true
  SITE_HASH="$(site_hash_of "$FILE" "$LINENO_HIT" "$BEFORE_LINE")"
  id="$(cl_digest "$SHA_PINNED|$FILE|$LINENO_HIT")"
  RECEIPT_PATH="$RECEIPT_DIR_NAME/$id.receipt"
  {
    echo "SPECK_RECEIPT_VERSION=1"
    echo "SPECK_MUTATION_SHA=$SHA_PINNED"
    echo "SPECK_MUTATION_FILE=$FILE"
    echo "SPECK_MUTATION_SITE=$SITE"
    echo "SPECK_MUTATION_SITE_HASH=$SITE_HASH"
    echo "SPECK_MUTATION_VERDICT=$VERDICT"
    echo "SPECK_MUTATION_MATCH_COUNT=$FOUND_COUNT"
    echo "SPECK_MUTATION_EXPECT_COUNT=$EXPECT_COUNT"
    echo "SPECK_MUTATION_RED_COUNT=$RED_OBSERVED"
    echo "SPECK_MUTATION_CONTROLS=${#GREEN_CMDS[@]}"
  } > "$dir/$id.receipt" 2>/dev/null || { RECEIPT_PATH=""; return 0; }
  return 0
}

# INVARIANT-ZERO: $ROOT must be byte-identical after the run. A changed $ROOT means a mutation
# escaped the worktree, which is the one failure this design exists to make impossible — so it
# outranks every verdict and is never downgraded to a warning.
finish() {
  local rc="$1"
  rm -f "${RUN_OUT_FILE:-}" 2>/dev/null || true
  if [[ -n "$WT" ]]; then cl_worktree_remove "$ROOT" "$WT" || true; fi
  if [[ -n "$ROOT_SNAP" ]]; then
    local after; after="$(cl_root_snapshot "$ROOT")"
    if [[ "$after" != "$ROOT_SNAP" ]]; then
      VERDICT="GUARD_UNMUTATED.P2"
      REASON="INVARIANT-ZERO BREACH: \$ROOT changed during the run (before=$ROOT_SNAP after=$after)"
      emit
      echo "FATAL: mutate-guard.sh modified the real working tree. Inspect \`git status\` NOW." >&2
      exit 2
    fi
  fi
  write_receipt
  emit
  exit "$rc"
}

ROOT_SNAP="$(cl_root_snapshot "$ROOT")"

# --- refusals that need no worktree ---------------------------------------------------------

# A mutation applied to a test or a fixture measures nothing about the shipped path (#94 §5d).
is_test_path() {
  case "$1" in
    */__tests__/*|__tests__/*|*/tests/*|tests/*|*/test/*|test/*|\
    */fixtures/*|fixtures/*|*/fixture/*|*/__fixtures__/*|*/__mocks__/*|*/mocks/*|\
    */spec/*|spec/*|*.test.*|*.spec.*|*_test.*|test_*.*|*/conftest.py|conftest.py) return 0 ;;
  esac
  case "$(basename "$1")" in
    test_*|*_test.*|*.test.*|*.spec.*) return 0 ;;
  esac
  return 1
}

if is_test_path "$FILE"; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="target is a test/fixture path — a mutation there measures nothing about the shipped path"
  finish 1
fi

if [[ ${#GREEN_CMDS[@]} -eq 0 ]]; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="no --green control supplied — a red suite cannot be attributed to the predicate rather than to a broken file"
  finish 1
fi

# Every invocation is classified before it runs. A mutation probe must never run a gate that
# deploys, migrates or touches prod (canary-lib.sh's shared classifier — one law, one place).
#
# The refusal NAMES THE TOKEN that fired (#114 §1.3). "classified 'unsafe'" alone sent the operator
# to read a 40-alternative regex to discover that a directory called `deploy` in an argument had
# convicted a `vitest` run; `refused: matched destructive token 'deploy'` is diagnosable in one read.
check_safety() {
  local inv="$1" kind="$2" verdictclass
  CL_SAFETY_REASON=""
  verdictclass="$(cl_probe_safety "$inv" "$WT")"
  if [[ "$verdictclass" != "safe" ]]; then
    VERDICT="GUARD_UNMUTATED.P2"
    REASON="$kind invocation classified '$verdictclass' by cl_probe_safety and was refused (${CL_SAFETY_REASON:-no reason recorded}): $inv"
    finish 1
  fi
  return 0
}

# The applier is exempt from check_safety by design — its job IS to change state — but only within
# the same fail-closed frame: an invocation that still trips the destructive denylist after #114 §2's
# verb-scoping needs --applier-ack, so the widening is a decision the author records rather than one
# the tool grants.
check_applier_safety() {
  local inv="$1" verdictclass
  CL_SAFETY_REASON=""
  verdictclass="$(cl_probe_safety "$inv" "$WT")"
  if [[ "$verdictclass" == "unsafe" && "$APPLIER_ACK" != true ]]; then
    VERDICT="GUARD_UNMUTATED.P2"
    REASON="--applier is classified 'unsafe' (${CL_SAFETY_REASON:-no reason recorded}) and no --applier-ack was given: $inv"
    finish 1
  fi
  return 0
}

# --- worktree ------------------------------------------------------------------------------

# `|| true` on the canary-lib calls is load-bearing, not decoration: those helpers were written
# for a probe that does not set `-e`, and each contains an internal pipeline that legitimately
# exits non-zero (e.g. `ls` over a glob that matches nothing during self-heal). Attaching them to
# a `||` list suspends errexit for the whole function body, so an expected internal non-zero stops
# aborting this script before it has emitted a verdict. Every one of them returns 0 by contract.
cl_selfheal "$ROOT" || true
WT="$(cl_worktree_add "$ROOT" "$$" || true)"
if [[ -z "$WT" ]]; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="could not create a throwaway worktree at HEAD (uncommitted mutation target? run \`git worktree prune\`)"
  finish 1
fi
cl_link_node_modules "$ROOT" "$WT" "" || true
if [[ -n "$SUBDIR" ]]; then cl_link_node_modules "$ROOT" "$WT" "$SUBDIR" || true; fi

TARGET="$WT/$FILE"
if [[ ! -f "$TARGET" ]]; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="target file not present at HEAD in the worktree: $FILE (uncommitted?)"
  finish 1
fi

for c in "${RED_CMDS[@]}"; do check_safety "$c" "--red"; done
for c in "${GREEN_CMDS[@]}"; do check_safety "$c" "--green"; done
[[ -n "$APPLIER" ]] && check_applier_safety "$APPLIER"

# --- match accounting (#94 §5a: a pattern that matches zero times changes nothing) ------------

FOUND_COUNT="$(awk -v pat="$PATTERN" '
  { s = $0; while ((i = index(s, pat)) > 0) { tot++; s = substr(s, i + length(pat)) } }
  END { print tot + 0 }' "$TARGET")"

if [[ "$FOUND_COUNT" -ne "$MATCH_COUNT" ]]; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="pattern matched $FOUND_COUNT time(s), required exactly $MATCH_COUNT — a no-op edit produces a green run that reads as proof"
  finish 1
fi

LINENO_HIT="$(awk -v pat="$PATTERN" 'index($0, pat) > 0 { print NR; exit }' "$TARGET")"
SITE="$FILE:$LINENO_HIT"
BEFORE_LINE="$(awk -v ln="$LINENO_HIT" 'NR == ln { print; exit }' "$TARGET")"

# --- the matched line must be EXECUTABLE (#94 §5b: a mutated docstring is a meaningless green) --
# Language-aware by extension, single forward pass: line comments by prefix, block comments and
# Python docstrings by parity of the delimiters seen strictly BEFORE the matched line.
ext="${FILE##*.}"
line_prefix=""
block_open=""
block_close=""
py_doc=false
case "$ext" in
  py)                                   line_prefix="#";  py_doc=true ;;
  sh|bash|zsh|rb|yml|yaml|toml|pl|r|R)  line_prefix="#" ;;
  js|jsx|mjs|cjs|ts|tsx|go|rs|java|kt|kts|swift|c|h|cc|cpp|hpp|cs|php|scala|dart|m|mm)
                                        line_prefix="//"; block_open="/*"; block_close="*/" ;;
  sql|lua|hs|elm|adb|ads)               line_prefix="--" ;;
  *)                                    line_prefix="" ;;
esac

#
# `/*` INSIDE A LITERAL IS NOT A COMMENT (#114 §4). This counted `/*` minus `*/` over the raw line
# text, so a doc comment containing the literal `` `@sentry/*` `` opened a "block" that never closed
# — and every subsequent line in the file was classified as prose, with every mutation site in it
# refused, blaming the SITE. Proven by contrast in the reporting project: a balanced copy of the same
# file mutated to GUARD_MUTATION_PROVEN immediately. `strip_literals` blanks quoted and backticked
# spans before the delimiters are counted, so a glob inside a string can no longer open a comment.
#
# And when the file's comment state never closes at the matched line, that is THE TOOL'S parse
# failure, not the site's — it is reported as such rather than refusing sites silently.
is_comment_line() {
  local file="$1" ln="$2"
  awk -v ln="$ln" -v pfx="$line_prefix" -v bo="$block_open" -v bc="$block_close" -v pydoc="$py_doc" \
      -v tdq='"""' -v tsq="'''" '
    function count(s, needle,   n, i) { n = 0; while ((i = index(s, needle)) > 0) { n++; s = substr(s, i + length(needle)) } return n }
    # Blank out "…", ?…? and `…` spans so a delimiter INSIDE a literal cannot open or close a block.
    # Single-line scope only, matching the rest of this pass: a literal that spans lines is rare in
    # the languages that have block comments, and erring toward "unchanged" keeps the old behaviour.
    function strip_literals(s,   out, i, c, q) {
      out = ""; q = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q == "") {
          if (c == "\"" || c == "\047" || c == "`") { q = c; out = out " "; continue }
          out = out c
        } else {
          if (c == "\\") { i++; out = out "  "; continue }
          if (c == q) { q = "" }
          out = out " "
        }
      }
      return out
    }
    NR < ln {
      if (bo != "") { s2 = strip_literals($0); inblock += count(s2, bo) - count(s2, bc); if (inblock < 0) inblock = 0 }
      if (pydoc == "true") { doc = (doc + count($0, tdq) + count($0, tsq)) % 2 }
      next
    }
    NR == ln {
      if (bo != "" && inblock > 0) { print "COMMENT"; exit }
      if (pydoc == "true" && doc % 2 == 1) { print "COMMENT"; exit }
      s = $0; sub(/^[ \t]*/, "", s)
      # A one-line docstring ("""...""") opens and closes on the SAME line, so the
      # before-this-line parity above is still 0 and would call it CODE. That exact miss is the
      # #94 §5b instance — a conductor mutated a docstring and read the green as proof.
      if (pydoc == "true" && (index(s, tdq) == 1 || index(s, tsq) == 1)) { print "COMMENT"; exit }
      if (pfx != "" && index(s, pfx) == 1) { print "COMMENT"; exit }
      if (bo != "" && index(s, bo) == 1) { print "COMMENT"; exit }
      if (s == "") { print "COMMENT"; exit }
      print "CODE"; exit
    }' "$file"
}

if [[ "$(is_comment_line "$TARGET" "$LINENO_HIT")" == "COMMENT" ]]; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="matched line $SITE is a comment, a docstring or blank — mutating prose proves nothing about behaviour"
  finish 1
fi

# --- baseline: every cited test must be GREEN before the mutation ----------------------------

# run_one is called inside `$( … )`, so it runs in a SUBSHELL and cannot hand a variable back. The
# output has to travel through a FILE at a stable path (#114 §3.2 — a baseline red must be
# attributable to the harness rather than to the guard, and that needs the invocation's own output).
# The path is deliberately OUTSIDE the worktree: a scratch file inside $WT would be swept into the
# `git add -A` that makes the mutated tree coherent.
RUN_OUT_FILE="${TMPDIR:-/tmp}/speck-mutate-out-$$"
last_run_output() { cat "$RUN_OUT_FILE" 2>/dev/null || true; }
run_one() {
  local inv="$1" rc
  : > "$RUN_OUT_FILE"
  rc="$(cl_run_gate "$WT" "$SUBDIR" "$inv" "$RUN_OUT_FILE")"
  printf '%s' "$rc"
  return 0
}

i=0
for c in "${RED_CMDS[@]}"; do
  i=$((i + 1))
  if [[ "$(run_one "$c")" != "0" ]]; then
    harness_sig="$(cl_harness_failure_signature "$(last_run_output)" || true)"
    if [[ -n "$harness_sig" ]]; then
      VERDICT="GUARD_UNMUTATED_HARNESS.P2"
      REASON="the PROBE HARNESS could not run --red invocation #$i in the throwaway worktree — this says nothing about the guard. Signature: '$harness_sig'. Invocation: $c"
    else
      VERDICT="GUARD_UNMUTATED.P2"
      REASON="--red invocation #$i was ALREADY red before the mutation — nothing observed after it can be attributed to the mutation: $c"
    fi
    finish 1
  fi
done
i=0
for c in "${GREEN_CMDS[@]}"; do
  i=$((i + 1))
  if [[ "$(run_one "$c")" != "0" ]]; then
    VERDICT="GUARD_UNMUTATED.P2"
    REASON="--green control #$i was already red before the mutation — it cannot serve as a control: $c"
    finish 1
  fi
done

# --- apply the mutation, and prove the bytes changed -----------------------------------------

DIGEST_BEFORE="$(cl_digest "$(cat "$TARGET")")"
awk -v pat="$PATTERN" -v rep="$REPLACEMENT" -v ln="$LINENO_HIT" '
  NR == ln { i = index($0, pat); if (i > 0) { $0 = substr($0, 1, i - 1) rep substr($0, i + length(pat)) } }
  { print }' "$TARGET" > "$TARGET.speck-mutated"
mv "$TARGET.speck-mutated" "$TARGET"
DIGEST_AFTER="$(cl_digest "$(cat "$TARGET")")"
AFTER_LINE="$(awk -v ln="$LINENO_HIT" 'NR == ln { print; exit }' "$TARGET")"

if [[ "$DIGEST_BEFORE" == "$DIGEST_AFTER" ]]; then
  VERDICT="GUARD_UNMUTATED.P2"
  REASON="the edit left the file byte-identical (pattern == replacement?) — nothing was mutated"
  finish 1
fi

# Untracked-but-present files matter to some runners; stage so the worktree is coherent.
git -C "$WT" add -A >/dev/null 2>&1 || true

# --- bring the system to the mutated state (#114 §2.2) ---------------------------------------
# For a guard whose subject is the source tree this step is a no-op and no --applier is supplied.
# For a guard whose subject is a DATABASE it is the whole ballgame: without it the --red invocation
# observes the live catalog, which the mutated migration never reached.
APPLIER_RAN=false
if [[ -n "$APPLIER" ]]; then
  if [[ "$(run_one "$APPLIER")" != "0" ]]; then
    VERDICT="GUARD_UNMUTATED.P2"
    REASON="--applier failed after the mutation, so the system never reached the mutated state and no --red result can be attributed to it: $APPLIER"
    finish 1
  fi
  APPLIER_RAN=true
fi

# --- post-mutation: count the reds, and require every control to survive ---------------------

RED_OBSERVED=0
for c in "${RED_CMDS[@]}"; do
  [[ "$(run_one "$c")" != "0" ]] && RED_OBSERVED=$((RED_OBSERVED + 1))
done

i=0
for c in "${GREEN_CMDS[@]}"; do
  i=$((i + 1))
  if [[ "$(run_one "$c")" != "0" ]]; then
    VERDICT="GUARD_UNMUTATED.P2"
    REASON="--green control #$i went RED too — the mutation broke the file rather than hitting the predicate, so the red tests prove nothing specific: $c"
    finish 1
  fi
done

if [[ "$RED_OBSERVED" -ge "$EXPECT_COUNT" ]]; then
  VERDICT="GUARD_MUTATION_PROVEN"
  REASON="$RED_OBSERVED of ${#RED_CMDS[@]} cited test invocation(s) went red at $SITE (required $EXPECT_COUNT); ${#GREEN_CMDS[@]} control(s) stayed green"
  finish 0
fi

# The mutation happened and nobody noticed. TWO different facts wear that shape, and conflating them
# is #114 §2.3: the guard is blind, OR the --red invocation could not observe the mutation at all
# because the mutated artifact was never applied to the system it inspects. A guard whose subject is
# a migration file, a schema or an infra manifest, run with NO --applier, is the second — and the
# reader of GUARD_MUTATION_GREEN.P2 ("write the honest scope onto the test") would draw exactly the
# wrong conclusion about a guard that reddens hard the moment the mutation actually lands.
NEEDS_APPLIER=false
case "$FILE" in
  *migrations/*|*migration/*|*.sql|*.tf|*.tfvars|*/k8s/*|*/helm/*|*.hcl) NEEDS_APPLIER=true ;;
esac
if [[ "$NEEDS_APPLIER" == true && "$APPLIER_RAN" == false ]]; then
  VERDICT="GUARD_MUTATION_UNOBSERVABLE.P2"
  REASON="the mutation provably happened at $SITE, but the subject is a file that must be APPLIED to a system before any test can see it, and no --applier was supplied — so the cited test(s) inspected a system the mutation never reached. This is NOT evidence that the guard is blind. Re-run with --applier '<bring the system to the mutated state>'"
  if [[ "$REQUIRE_PROVEN" == true ]]; then
    finish 1
  fi
  finish 0
fi

VERDICT="GUARD_MUTATION_GREEN.P2"
REASON="the mutation provably happened at $SITE and only $RED_OBSERVED of the required $EXPECT_COUNT cited test(s) noticed. Report this GREEN and write the honest scope onto the test — never tune the mutation until it reddens"
if [[ "$REQUIRE_PROVEN" == true ]]; then
  finish 1
fi
finish 0
