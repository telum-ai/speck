#!/usr/bin/env bash
# observe-guard.sh — CP-7, the OBSERVATION-side counterpart to mutate-guard.sh (issue #104).
#
# WHY THIS EXISTS
# v10 installed mutation-as-evidence for TESTS: break the production line, watch exactly the
# expected cases redden, keep a control green. That discipline has no counterpart for
# OBSERVATIONS — a grep of a log, a CI verdict, a dashboard, a quiet inbox, a count that did not
# move. And observations are load-bearing in the same way: they get written into findings, they
# close fires, they justify REFUTED.
#
# THE MECHANISM, stated once because everything below is a consequence of it:
#   A GREEN REPORTS ITS VERDICT AND NEVER ITS EXPOSURE — whether the occasion it ran on contained
#   the failing case at all. A hard-won pass and a pass that COULD NOT HAVE FAILED are
#   byte-identical in the artifact. So confidence accumulates on RUN COUNT rather than on CHANCES
#   TO FAIL.
#
# This is NOT #93 class 1 or 2. The check is not shadowed, not vacuous, not forgeable. In the
# instances that produced this script the check was correct, executed, and truthful about itself.
# What was missing was the OCCASION. Keep the two apart when reading a result: re-run the check
# against a real failing case — RED means the guard is broken (class 1); GREEN means nothing is
# broken and this run simply had nothing to catch (this class).
#
# THE TWO QUESTIONS, IN ORDER — this script is those two questions and nothing else.
#
# Q1 — CAN THE FAILING CASE BE MANUFACTURED CHEAPLY?
#   For an observation the analogue of mutation has two legs, and BOTH must hold before a green
#   counts as exposed:
#
#   Leg A — the INSTRUMENT. Confirm it can show the thing AT ALL before believing it showed
#   nothing. `--positive-control '<cmd>'` manufactures the failing case; the needle must then
#   appear. An `--expect-present` green that found its needle is its own positive control and is
#   credited as `self`. Everything else is `none` — an instrument nobody has ever seen work.
#
#   Leg B — the INVOCATION. #104's headline instance: a bearer token carried as a URL PATH
#   SEGMENT, so the access logger writes it before application code runs. The local check found
#   zero hits. The difference was not the code but a FLAG — dev runs `uvicorn --log-level
#   warning`, and the `Dockerfile` CMD passes none, so production defaults to INFO and access
#   logging is on. Re-run under the container's exact invocation, it reproduced in one request.
#   THE OBSERVATION WAS REAL; THE CONFIGURATION IT WAS MADE UNDER WAS THE LIE. So this script
#   diffs the local `--observe` invocation against the SHIPPED one — `Dockerfile` CMD/ENTRYPOINT,
#   `Procfile`, or a literal deploy command — and reports every flag and env divergence.
#
# Q2 — IF IT CANNOT BE EXPOSED, WHAT DOES THIS GREEN LICENSE?
#   The half that matters most and the half nothing currently expresses, which is why
#   `--licenses` is REQUIRED and has no default:
#     waiting        the green authorises only continuing to watch. An unexposed run is harmless
#                    and chasing exposure is waste.            → OBSERVATION_UNEXPOSED.P2, exit 0
#     accumulating   the green feeds a count, a streak, a shadow period that ends.
#     irreversible   the green closes a fire, exits a shadow period, writes REFUTED on a live
#                    credential. It cannot be walked back.
#                    accumulating/irreversible → OBSERVATION_UNEXPOSED_BLOCKING.P1, exit 1:
#                    the unexposed run MUST NOT COUNT toward it.
#
# THE THREE EXCEPTIONS THAT BOUND THIS — they are what make it shippable rather than tyrannical.
#   1. SOME SUBJECTS HAVE NO LEVER. A guard reconciling inbound mail cannot make mail arrive.
#      `--no-lever` declares it. It does NOT excuse the run — its correct move is not to mutate
#      but to REFUSE TO LET AN UNEXPOSED RUN COUNT, so it routes straight to Q2. This is why the
#      script keeps a per-subject ledger: two static passes in a row prove only that neither
#      number moved, and `SPECK_OBSERVATION_STATIC=true` says so out loud.
#   2. EXPOSURE IS BOUGHT, NOT FREE. Buy it where the green authorises something that cannot be
#      walked back, not everywhere. `--accept-divergence <flag>` is that dial made explicit and
#      auditable: a divergence a human decided is irrelevant, named in the record rather than
#      quietly not measured.
#   3. DO NOT CONFUSE THIS WITH CLASS 1 (above).
#
# VERDICTS — the single registered set, mirrored in .cursor/skills/speck-recheck/SKILL.md so a
# pipeline can consume them rather than reading a markdown cell:
#   OBSERVATION_EXPOSED             the green counts. The instrument was shown able to display the
#                                   thing, and the occasion ran under the shipped invocation
#                                   (or no shipped invocation exists to diverge from).    exit 0
#   OBSERVATION_UNEXPOSED.P2        exposure was not established, and this green licenses only
#                                   WAITING. Honest and non-blocking on purpose.          exit 0
#   OBSERVATION_UNEXPOSED_BLOCKING.P1  exposure was not established and this green licenses
#                                   something accumulating or irreversible. The run does not
#                                   count toward it.                                      exit 1
#   OBSERVATION_NOT_GREEN.P1        the observation this guard was asked to certify did not hold —
#                                   the needle was present under --expect-absent (or absent under
#                                   --expect-present). There is no green to license anything.  exit 1
#   OBSERVATION_UNMEASURED.P2       nothing was measured — a destructive invocation was refused,
#                                   or the subject could not be run at all.                exit 1
#
# WHY THE SAFETY CLASSIFIER IS LOOSER HERE THAN IN mutate-guard.sh (deliberate, not an oversight)
# mutate-guard refuses any invocation cl_probe_safety does not positively classify `safe`, because
# it runs inside a throwaway worktree where every command is a test. An OBSERVATION reaches
# outward by nature — `docker logs`, `gh run view`, `curl`, a hosted dashboard — so `unknown` is
# the normal classification for a correct subject. Refusing it would make this script unusable and
# push authors back to the un-instrumented grep. Only `unsafe` (cl_looks_destructive) is refused.
#
# WHAT THIS SCRIPT DOES NOT DO, stated plainly rather than implied away: like mutation receipts, the
# ledger under .speck/observation-receipts/ is a local file written by a local script. It cannot
# prove an observation was run. It raises the cost of a fabricated exposure claim from typing a
# word into a table to constructing a consistent ledger, and it makes a STATIC repeat visible.
# Treat OBSERVATION_EXPOSED as "this run established exposure", never as "this run happened".
#
# Portable bash 3.2 / macOS. No associative arrays, no mapfile.
#
# Usage:
#   observe-guard.sh --subject <name> --observe '<cmd>' \
#                    (--expect-absent <needle> | --expect-present <needle>) \
#                    --licenses waiting|accumulating|irreversible \
#                    [--positive-control '<cmd>'] [--no-lever] \
#                    [--shipped-from <Dockerfile|Procfile|file>] [--shipped-cmd '<literal>'] \
#                    [--accept-divergence <flag>] [--env <KEY>] \
#                    [--cwd <subdir>] [--root <dir>] [--require-exposed]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./canary-lib.sh
. "$SCRIPT_DIR/canary-lib.sh"
# shellcheck source=../lib/text.sh
. "$SCRIPT_DIR/../lib/text.sh"

US=$'\037'

SUBJECT=""
OBSERVE=""
NEEDLE=""
MODE=""            # absent | present
LICENSES=""
POSITIVE_CONTROL=""
NO_LEVER=false
SHIPPED_FROM=""
SHIPPED_CMD=""
SUBDIR=""
ROOT=""
REQUIRE_EXPOSED=false
ACCEPTED_FLAGS=()
ENV_KEYS=()

RECEIPT_DIR_NAME=".speck/observation-receipts"

die_usage() {
  echo "ERROR: $1" >&2
  echo "Usage: observe-guard.sh --subject <name> --observe '<cmd>' (--expect-absent <needle> | --expect-present <needle>) --licenses waiting|accumulating|irreversible [--positive-control '<cmd>'] [--no-lever] [--shipped-from <file>] [--shipped-cmd '<literal>'] [--accept-divergence <flag>] [--env <KEY>] [--cwd <subdir>] [--root <dir>] [--require-exposed]" >&2
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subject)            SUBJECT="${2:-}"; shift 2 ;;
    --observe)            OBSERVE="${2:-}"; shift 2 ;;
    --expect-absent)      NEEDLE="${2:-}"; MODE="absent"; shift 2 ;;
    --expect-present)     NEEDLE="${2:-}"; MODE="present"; shift 2 ;;
    --licenses)           LICENSES="${2:-}"; shift 2 ;;
    --positive-control)   POSITIVE_CONTROL="${2:-}"; shift 2 ;;
    --no-lever)           NO_LEVER=true; shift ;;
    --shipped-from)       SHIPPED_FROM="${2:-}"; shift 2 ;;
    --shipped-cmd)        SHIPPED_CMD="${2:-}"; shift 2 ;;
    --accept-divergence)  ACCEPTED_FLAGS+=("${2:-}"); shift 2 ;;
    --env)                ENV_KEYS+=("${2:-}"); shift 2 ;;
    --cwd)                SUBDIR="${2:-}"; shift 2 ;;
    --root)               ROOT="${2:-}"; shift 2 ;;
    --require-exposed)    REQUIRE_EXPOSED=true; shift ;;
    -h|--help)            die_usage "help" ;;
    *)                    die_usage "unknown argument: $1" ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[[ -n "$ROOT" && -e "$ROOT/.git" ]] || die_usage "--root must be a git repository (got '${ROOT:-<none>}')"

[[ -n "$SUBJECT" ]]  || die_usage "--subject is required (it keys the ledger that makes a static repeat visible)"
[[ -n "$OBSERVE" ]]  || die_usage "--observe is required"
[[ -n "$MODE" ]]     || die_usage "exactly one of --expect-absent / --expect-present is required — an observation that does not state its predicate cannot be exposed or unexposed"
[[ -n "$NEEDLE" ]]   || die_usage "the --expect-${MODE} needle may not be empty"

# REQUIRED, no default, on purpose. Q2 is the half that matters most and the half nothing in the
# toolchain currently expresses; a default would answer it silently and wrongly for every caller.
case "$LICENSES" in
  waiting|accumulating|irreversible) ;;
  "") die_usage "--licenses is required. What does this green license? 'waiting' (only keep watching — an unexposed run is harmless), 'accumulating' (a count, a streak, a shadow period), or 'irreversible' (closing a fire, exiting a shadow period, writing REFUTED on a live credential). An unexposed run must not count toward the last two." ;;
  *)  die_usage "--licenses must be one of: waiting | accumulating | irreversible (got '$LICENSES')" ;;
esac

SHA_PINNED="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo UNKNOWN)"
RUNDIR="$ROOT"
[[ -n "$SUBDIR" ]] && RUNDIR="$ROOT/$SUBDIR"

VERDICT=""
REASON=""
OBSERVED=""            # green | red
OBS_RC=0
LEVER="none"           # self | fired | blind | none | no-lever
SHIPPED_SOURCE="none"
DIVERGENCE_COUNT=0
DIVERGENCE_ACCEPTED=0
DIVERGENCE_DETAIL=""
STATIC="false"
EXPOSED="false"
OUTPUT_DIGEST=""
RECEIPT_PATH=""
TREE_CHANGED="false"
ROOT_SNAP=""

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

emit() {
  echo "SPECK_OBSERVATION_VERDICT=$VERDICT"
  echo "SPECK_OBSERVATION_REASON=$REASON"
  echo "SPECK_OBSERVATION_SUBJECT=$SUBJECT"
  echo "SPECK_OBSERVATION_MODE=$MODE"
  echo "SPECK_OBSERVATION_NEEDLE=$NEEDLE"
  echo "SPECK_OBSERVATION_LICENSES=$LICENSES"
  echo "SPECK_OBSERVATION_OBSERVED=$OBSERVED"
  echo "SPECK_OBSERVATION_RC=$OBS_RC"
  echo "SPECK_OBSERVATION_LEVER=$LEVER"
  echo "SPECK_OBSERVATION_SHIPPED_SOURCE=$SHIPPED_SOURCE"
  echo "SPECK_OBSERVATION_DIVERGENCE=$DIVERGENCE_COUNT"
  echo "SPECK_OBSERVATION_DIVERGENCE_ACCEPTED=$DIVERGENCE_ACCEPTED"
  echo "SPECK_OBSERVATION_EXPOSED=$EXPOSED"
  echo "SPECK_OBSERVATION_STATIC=$STATIC"
  echo "SPECK_OBSERVATION_SHA=$SHA_PINNED"
  echo "SPECK_OBSERVATION_TREE_CHANGED=$TREE_CHANGED"
  if [[ -n "$OUTPUT_DIGEST" ]]; then echo "SPECK_OBSERVATION_OUTPUT_DIGEST=$OUTPUT_DIGEST"; fi
  if [[ -n "$RECEIPT_PATH" ]];   then echo "SPECK_OBSERVATION_RECEIPT=$RECEIPT_PATH"; fi
  if [[ -n "$DIVERGENCE_DETAIL" ]]; then printf '%s' "$DIVERGENCE_DETAIL"; fi
  return 0
}

receipt_dir() { printf '%s' "$ROOT/$RECEIPT_DIR_NAME"; }
receipt_file() { printf '%s/%s.receipt' "$(receipt_dir)" "$(cl_digest "$SUBJECT")"; }

# Written only on a run that actually observed something. A refused run has nothing to attest, and
# writing a receipt for it would let a refusal masquerade as a datapoint in the STATIC comparison.
write_receipt() {
  [[ -n "$OUTPUT_DIGEST" ]] || return 0
  local dir f
  dir="$(receipt_dir)"
  mkdir -p "$dir" 2>/dev/null || return 0
  # A SELF-IGNORING directory (`*` ignores the .gitignore itself too) — the same idiom as
  # .speck/mutation-receipts/. A probe that makes `git status` dirty after every run is its own
  # defect: every clean-tree precondition in the toolchain is watching that tree.
  [[ -f "$dir/.gitignore" ]] || printf '*\n' > "$dir/.gitignore" 2>/dev/null || true
  f="$(receipt_file)"
  RECEIPT_PATH="$RECEIPT_DIR_NAME/$(basename "$f")"
  {
    echo "SPECK_RECEIPT_VERSION=1"
    echo "SPECK_OBSERVATION_SUBJECT=$SUBJECT"
    echo "SPECK_OBSERVATION_SHA=$SHA_PINNED"
    echo "SPECK_OBSERVATION_MODE=$MODE"
    echo "SPECK_OBSERVATION_NEEDLE=$NEEDLE"
    echo "SPECK_OBSERVATION_LICENSES=$LICENSES"
    echo "SPECK_OBSERVATION_OUTPUT_DIGEST=$OUTPUT_DIGEST"
    echo "SPECK_OBSERVATION_VERDICT=$VERDICT"
    echo "SPECK_OBSERVATION_EXPOSED=$EXPOSED"
  } > "$f" 2>/dev/null || { RECEIPT_PATH=""; return 0; }
  return 0
}

finish() {
  local rc="$1"
  if [[ -n "$ROOT_SNAP" ]]; then
    local after; after="$(cl_root_snapshot "$ROOT")"
    # Not a hard invariant the way mutate-guard's INVARIANT-ZERO is: nothing here is DESIGNED to
    # write to the tree, but an observation legitimately may (a log file, a build artifact). So it
    # is reported loudly and never silently swallowed — and never allowed to change the verdict,
    # because a dirty tree is not evidence about exposure.
    if [[ "$after" != "$ROOT_SNAP" ]]; then
      TREE_CHANGED="true"
      echo "WARNING: observe-guard.sh: \$ROOT changed during the run (before=$ROOT_SNAP after=$after). The observation or its positive control wrote to the working tree — inspect \`git status\`." >&2
    fi
  fi
  write_receipt
  emit
  if [[ "$REQUIRE_EXPOSED" == true && "$VERDICT" != "OBSERVATION_EXPOSED" ]]; then exit 1; fi
  exit "$rc"
}

ROOT_SNAP="$(cl_root_snapshot "$ROOT")"

# --- safety ------------------------------------------------------------------------------------
# Only `unsafe` is refused; see the header note on why `unknown` is normal and accepted here.
check_safety() {
  local inv="$1" kind="$2" cls
  cls="$(cl_probe_safety "$inv" "$ROOT")"
  if [[ "$cls" == "unsafe" ]]; then
    VERDICT="OBSERVATION_UNMEASURED.P2"
    REASON="$kind invocation classified 'unsafe' by cl_probe_safety and was refused: $inv"
    finish 1
  fi
  return 0
}
check_safety "$OBSERVE" "--observe"
if [[ -n "$POSITIVE_CONTROL" ]]; then check_safety "$POSITIVE_CONTROL" "--positive-control"; fi

# --- Q1 leg B: the shipped invocation ------------------------------------------------------------

# Join Dockerfile-style backslash continuations so a CMD split over four lines is one directive.
join_continuations() {
  awk '
    { line = $0; sub(/\r$/, "", line)
      if (buf != "") { line = buf " " line; buf = "" }
      if (line ~ /\\[[:space:]]*$/) { sub(/\\[[:space:]]*$/, "", line); buf = line; next }
      print line }
    END { if (buf != "") print buf }' "$1"
}

# One token per line. Handles Docker's JSON exec form (["uvicorn","app:app"]) and the shell form.
directive_tokens() {
  local raw; raw="$(sp_trim "$1")"
  if [[ "$raw" == \[* ]]; then
    raw="${raw#[}"; raw="${raw%]}"
    ( IFS=','
      local part
      for part in $raw; do
        part="$(sp_trim "$part")"
        part="${part#\"}"; part="${part%\"}"
        part="${part#\'}"; part="${part%\'}"
        [[ -n "$part" ]] && printf '%s\n' "$part"
      done ) || true
  else
    ( set -f; IFS=$' \t\n'
      local part
      for part in $raw; do [[ -n "$part" ]] && printf '%s\n' "$part"; done ) || true
  fi
  return 0
}

# ENTRYPOINT + CMD, in Docker's own composition order (CMD supplies the args to an exec-form
# ENTRYPOINT), taking the LAST of each — that is the one that ships.
shipped_tokens_from_dockerfile() {
  local joined="$1" cmd ep
  ep="$(awk -F"$US" '$1=="ENTRYPOINT"{print $2}' "$joined" | tail -n1)"
  cmd="$(awk -F"$US" '$1=="CMD"{print $2}' "$joined" | tail -n1)"
  [[ -n "$ep" ]]  && directive_tokens "$ep"
  [[ -n "$cmd" ]] && directive_tokens "$cmd"
  return 0
}

dockerfile_directives() {
  join_continuations "$1" | awk -v us="$US" '
    { d = $1; rest = $0
      sub(/^[[:space:]]*[^[:space:]]+[[:space:]]+/, "", rest)
      u = toupper(d)
      if (u == "CMD" || u == "ENTRYPOINT" || u == "ENV") printf "%s%s%s\n", u, us, rest }'
}

# `KEY=v` pairs, or the legacy `ENV KEY value` form.
shipped_env_value() {
  local joined="$1" key="$2" line rest first
  while IFS= read -r line; do
    rest="${line#ENV$US}"
    if [[ "$rest" == *=* ]]; then
      local pair
      for pair in $rest; do
        if [[ "$pair" == "$key="* ]]; then printf '%s' "${pair#*=}"; return 0; fi
      done
    else
      first="$(awk '{print $1}' <<<"$rest")"
      if [[ "$first" == "$key" ]]; then
        printf '%s' "$(sp_trim "${rest#"$first"}")"; return 0
      fi
    fi
  done < <(awk -F"$US" -v us="$US" '$1=="ENV"{printf "ENV%s%s\n", us, $2}' "$joined")
  return 1
}

# From a token stream on stdin → "flag<US>value" lines. `--k=v`, `--k v` and bare `-k` all
# normalise to the same shape so the two sides are comparable.
flags_of() {
  awk -v us="$US" '
    { t[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        tok = t[i]
        if (substr(tok, 1, 1) != "-") continue
        if (tok == "-" || tok == "--") continue
        eq = index(tok, "=")
        if (eq > 0) { k = substr(tok, 1, eq - 1); v = substr(tok, eq + 1) }
        else {
          k = tok; v = ""
          if (i < NR && substr(t[i + 1], 1, 1) != "-") v = t[i + 1]
        }
        printf "%s%s%s\n", k, us, v
      }
    }'
}

flag_lookup() { # <key> <file> → "found<US><value>" or "missing"; always exit 0
  awk -F"$US" -v us="$US" -v k="$1" '$1 == k { printf "found%s%s\n", us, $2; f = 1; exit } END { if (!f) print "missing" }' "$2"
}

is_accepted() {
  local f="$1" a
  if [[ ${#ACCEPTED_FLAGS[@]} -eq 0 ]]; then return 1; fi
  for a in "${ACCEPTED_FLAGS[@]}"; do [[ "$a" == "$f" ]] && return 0; done
  return 1
}

record_divergence() { # kind key local shipped
  local kind="$1" key="$2" lv="$3" sv="$4" note=""
  if is_accepted "$key"; then
    DIVERGENCE_ACCEPTED=$((DIVERGENCE_ACCEPTED + 1))
    note=" [ACCEPTED — declared irrelevant by --accept-divergence]"
  else
    DIVERGENCE_COUNT=$((DIVERGENCE_COUNT + 1))
  fi
  DIVERGENCE_DETAIL="${DIVERGENCE_DETAIL}SPECK_OBSERVATION_DIVERGENCE_DETAIL=$kind $key (local='${lv}' shipped='${sv}')$note"$'\n'
}

LOCAL_FLAGS="$TMPD/local.flags"
SHIPPED_FLAGS="$TMPD/shipped.flags"
JOINED="$TMPD/joined.directives"
: > "$LOCAL_FLAGS"; : > "$SHIPPED_FLAGS"; : > "$JOINED"

directive_tokens "$OBSERVE" | flags_of > "$LOCAL_FLAGS"

SHIPPED_RAW=""
if [[ -n "$SHIPPED_CMD" ]]; then
  SHIPPED_SOURCE="literal"
  SHIPPED_RAW="$SHIPPED_CMD"
elif [[ -n "$SHIPPED_FROM" ]]; then
  if [[ -f "$RUNDIR/$SHIPPED_FROM" ]]; then SHIPPED_SOURCE="$SHIPPED_FROM"
  elif [[ -f "$SHIPPED_FROM" ]]; then SHIPPED_SOURCE="$SHIPPED_FROM"
  else
    VERDICT="OBSERVATION_UNMEASURED.P2"
    REASON="--shipped-from names a file that does not exist: $SHIPPED_FROM"
    finish 1
  fi
else
  # Auto-detect. Looking and finding nothing is a DIFFERENT state from not looking, and the
  # difference is what keeps this non-tyrannical: a subject with no separate shipped configuration
  # is not penalised for one it does not have.
  for cand in Dockerfile dockerfile Procfile; do
    if [[ -f "$RUNDIR/$cand" ]]; then SHIPPED_SOURCE="$cand"; break; fi
  done
fi

if [[ "$SHIPPED_SOURCE" != "none" && "$SHIPPED_SOURCE" != "literal" ]]; then
  SRC="$RUNDIR/$SHIPPED_SOURCE"; [[ -f "$SRC" ]] || SRC="$SHIPPED_SOURCE"
  case "$(basename "$SRC" | tr '[:upper:]' '[:lower:]')" in
    procfile)
      # `web:` is the process type an observation of a running service is about; fall back to the
      # first declared type so a worker-only Procfile is still comparable.
      SHIPPED_RAW="$(awk -F: '/^[[:space:]]*web[[:space:]]*:/ { sub(/^[^:]*:[[:space:]]*/, "", $0); print; exit }' "$SRC")"
      [[ -n "$SHIPPED_RAW" ]] || SHIPPED_RAW="$(awk '/^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*:/ { sub(/^[^:]*:[[:space:]]*/, "", $0); print; exit }' "$SRC")"
      directive_tokens "$SHIPPED_RAW" | flags_of > "$SHIPPED_FLAGS"
      ;;
    *)
      dockerfile_directives "$SRC" > "$JOINED"
      shipped_tokens_from_dockerfile "$JOINED" | flags_of > "$SHIPPED_FLAGS"
      ;;
  esac
elif [[ "$SHIPPED_SOURCE" == "literal" ]]; then
  directive_tokens "$SHIPPED_RAW" | flags_of > "$SHIPPED_FLAGS"
fi

if [[ "$SHIPPED_SOURCE" != "none" ]]; then
  while IFS="$US" read -r k v; do
    [[ -n "$k" ]] || continue
    hit="$(flag_lookup "$k" "$SHIPPED_FLAGS")"
    if [[ "$hit" == "missing" ]]; then
      record_divergence "local-only" "$k" "$v" ""
    else
      sv="${hit#found$US}"
      [[ "$v" != "$sv" ]] && record_divergence "value-differs" "$k" "$v" "$sv"
    fi
  done < "$LOCAL_FLAGS"
  while IFS="$US" read -r k v; do
    [[ -n "$k" ]] || continue
    hit="$(flag_lookup "$k" "$LOCAL_FLAGS")"
    [[ "$hit" == "missing" ]] && record_divergence "shipped-only" "$k" "" "$v"
  done < "$SHIPPED_FLAGS"

  if [[ ${#ENV_KEYS[@]} -gt 0 && -s "$JOINED" ]]; then
    for key in "${ENV_KEYS[@]}"; do
      lv="$(printenv "$key" 2>/dev/null || true)"
      if sv="$(shipped_env_value "$JOINED" "$key")"; then
        [[ "$lv" != "$sv" ]] && record_divergence "env-differs" "$key" "$lv" "$sv"
      else
        [[ -n "$lv" ]] && record_divergence "env-local-only" "$key" "$lv" ""
      fi
    done
  fi
fi

# --- run the observation --------------------------------------------------------------------------
# Writes to a FILE and sets RUN_RC in the current shell. The obvious
#     out="$(run_capture "$cmd")"; rc="$RUN_RC"
# is broken by construction: command substitution runs the function in a SUBSHELL, so RUN_RC never
# reaches the caller — and under `set -u` the read of it aborts the script before any verdict is
# emitted. A probe that dies before emitting is indistinguishable from one that was never run.
RUN_RC=0
run_capture() { # <cmd> <outfile>
  set +e
  ( cd "$RUNDIR" && eval "$1" ) > "$2" 2>&1
  RUN_RC=$?
  set -e
  return 0
}

needle_in() { # <needle> <text>
  if grep -qF -- "$1" <<<"$2"; then return 0; fi
  return 1
}

run_capture "$OBSERVE" "$TMPD/obs.out"
OBS_RC="$RUN_RC"
OBS_OUT="$(cat "$TMPD/obs.out")"
OUTPUT_DIGEST="$(cl_digest "$OBS_OUT")"

# A prior run of THIS subject with byte-identical output. Reported, never verdict-changing: it is
# the sentence "two static passes in a row prove only that neither number moved" made mechanical.
PREV="$(receipt_file)"
if [[ -f "$PREV" ]]; then
  prev_digest="$(awk -F= '$1 == "SPECK_OBSERVATION_OUTPUT_DIGEST" { sub(/^[^=]*=/, "", $0); print; exit }' "$PREV")"
  [[ -n "$prev_digest" && "$prev_digest" == "$OUTPUT_DIGEST" ]] && STATIC="true"
fi

HIT=false
if needle_in "$NEEDLE" "$OBS_OUT"; then HIT=true; fi
if [[ "$MODE" == "absent" ]]; then
  [[ "$HIT" == true ]] && OBSERVED="red" || OBSERVED="green"
else
  [[ "$HIT" == true ]] && OBSERVED="green" || OBSERVED="red"
fi

if [[ "$OBSERVED" == "red" ]]; then
  VERDICT="OBSERVATION_NOT_GREEN.P1"
  if [[ "$MODE" == "absent" ]]; then
    REASON="the observation found '$NEEDLE' where it asserted absence — there is no green here to license anything, and the finding is real"
  else
    REASON="the observation did not find '$NEEDLE' where it asserted presence — the result the green was supposed to rest on never arrived. A gate you never saw is not a gate that passed"
  fi
  finish 1
fi

# --- Q1 leg A: the instrument ---------------------------------------------------------------------
if [[ "$MODE" == "present" ]]; then
  # A present-needle green literally displayed the thing. The instrument is its own positive
  # control; nothing cheaper can be manufactured.
  LEVER="self"
elif [[ "$NO_LEVER" == true ]]; then
  LEVER="no-lever"
elif [[ -n "$POSITIVE_CONTROL" ]]; then
  run_capture "$POSITIVE_CONTROL" "$TMPD/ctrl.out"
  # Search the control's own output AND a fresh observation after it: a control either produces
  # the needle itself or plants state the instrument then picks up, and both are legitimate shapes.
  run_capture "$OBSERVE" "$TMPD/reobs.out"
  CTRL_OUT="$(cat "$TMPD/ctrl.out" "$TMPD/reobs.out")"
  if needle_in "$NEEDLE" "$CTRL_OUT"; then LEVER="fired"; else LEVER="blind"; fi
else
  LEVER="none"
fi

# --- the exposure decision ------------------------------------------------------------------------
LEG_A=false
case "$LEVER" in self|fired) LEG_A=true ;; esac
LEG_B=false
if [[ "$SHIPPED_SOURCE" == "none" || "$DIVERGENCE_COUNT" -eq 0 ]]; then LEG_B=true; fi
if [[ "$LEG_A" == true && "$LEG_B" == true ]]; then EXPOSED="true"; fi

why=""
if [[ "$LEG_A" != true ]]; then
  case "$LEVER" in
    blind)    why="the positive control ran and the needle still never appeared — the instrument cannot show the thing, so its zero is not evidence of absence" ;;
    no-lever) why="--no-lever was declared: the failing case cannot be manufactured for this subject. That is a legitimate state and not a defect — but it is exactly why an unexposed run must not be allowed to count" ;;
    *)        why="no --positive-control was supplied and --no-lever was not declared, so the instrument has never been shown able to display '$NEEDLE' at all" ;;
  esac
fi
if [[ "$LEG_B" != true ]]; then
  b="the observation ran under an invocation that diverges from the shipped one in $DIVERGENCE_COUNT place(s) (source: $SHIPPED_SOURCE) — the observation may be real while the configuration it was made under is the lie"
  if [[ -n "$why" ]]; then why="$why; and $b"; else why="$b"; fi
fi
if [[ "$STATIC" == "true" && "$EXPOSED" != "true" ]]; then
  why="$why; the observed output is byte-identical to the previous run recorded for this subject — two static passes in a row prove only that neither number moved"
fi

if [[ "$EXPOSED" == "true" ]]; then
  VERDICT="OBSERVATION_EXPOSED"
  if [[ "$SHIPPED_SOURCE" == "none" ]]; then
    REASON="the instrument was shown able to display '$NEEDLE' (lever=$LEVER) and no shipped-invocation source was found to diverge from — pass --shipped-cmd if this subject does ship under a different command"
  else
    REASON="the instrument was shown able to display '$NEEDLE' (lever=$LEVER) and the invocation matches the shipped one from $SHIPPED_SOURCE ($DIVERGENCE_ACCEPTED declared-irrelevant divergence(s)) — this green had a real chance to fail"
  fi
  finish 0
fi

case "$LICENSES" in
  waiting)
    VERDICT="OBSERVATION_UNEXPOSED.P2"
    REASON="exposure not established: $why. This green licenses only WAITING, so an unexposed run is harmless and buying exposure here would be waste — recorded honestly, not blocked"
    finish 0
    ;;
  *)
    VERDICT="OBSERVATION_UNEXPOSED_BLOCKING.P1"
    REASON="exposure not established: $why. This green licenses something $LICENSES, which cannot be walked back — the run MUST NOT COUNT toward it. Either buy exposure (a --positive-control, or re-run under the shipped invocation) or stop citing this observation as the thing that closes it"
    finish 1
    ;;
esac
