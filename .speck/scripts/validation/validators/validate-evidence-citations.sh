#!/usr/bin/env bash
# validate-evidence-citations.sh — TYPED evidence citations (issue #101, the upstream half of §11a).
#
# WHY THIS EXISTS
# #101 asks for a §11a Standard Probe Library whose validator emits PROBE_SUBSTRATE_MISMATCH.P1
# "when the cited artifact's type is on the 'does NOT count' side of §2's table". That verdict is
# NOT COMPUTABLE from the citation format #101 assumes. `path@sha` carries a location and a
# freshness stamp and nothing else: it does not say whether it points at a green suite, a live read
# as a real principal, or a screenshot. Admissibility is a property of the PAIR (claim type,
# citation type) and half the pair was never written down.
#
# So the first buildable increment is not the registry — it is the TYPE. A registry built on
# untyped citations would be another section of prose that cannot fail a build, which is exactly
# what #100 filed and what harden-report was until v10.
#
# WHAT THIS DOES
#   • defines the CLOSED, Speck-owned citation-type vocabulary (10 tokens, each derived from
#     something the evidence contract or the validation-report template already cites in practice —
#     no invented taxonomy);
#   • defines the ADMISSIBILITY TABLE: claim type -> admissible citation types, whitelist-shaped,
#     with every exclusion earned by a shipped defect in #101;
#   • scans an artifact for citation sites and resolves each citation against that table.
#
# VERDICTS
#   PROBE_SUBSTRATE_MISMATCH.P1  a claim is discharged by a citation type the table says is
#                                structurally incapable of observing it.
#   CITATION_UNTYPED.P3          a legacy untyped citation. P3, DELIBERATELY, and this is the
#                                load-bearing severity decision in the file: every artifact
#                                downstream of v10.0 is untyped by construction, so a P1 here
#                                would brick every project on upgrade day. A nudge, never a block.
#   CITATION_TABLE_DRIFT.P2      (--check-contract) the contract's §2b table and the Speck-owned
#                                table compiled in here disagree.
#   CLAIM_TYPE_UNROUTED          NOTE, not a finding. An unrecognised claim type is reported and
#                                skipped: a wrong routing produces a confident wrong admissibility
#                                verdict, which is worse than an admitted gap.
#
# THE UPGRADE-DAY GUARANTEE IS STRUCTURAL, NOT A PROMISE.
# A citation site is any table with an evidence/citation column; a `Claim type` column is optional.
# P3 needs only the citation (is it typed?), so it reaches every artifact that exists today. P1
# needs the PAIR, so it can only fire on a table that has declared a claim type — a shape no
# pre-v10.1 artifact has. A legacy artifact is therefore INCAPABLE of raising a P1 from this
# validator, which is what makes shipping the rule on upgrade day safe.
#
# WHAT COUNTS AS A CITATION AT ALL (see is_citation_like).
# A token is a citation when it carries a file extension, sits under one of §9's reserved evidence
# directories, or is an absolute path that resolves. "Contains a slash or an @" is a PUNCTUATION
# test, not a path test: it reported API routes, slash commands, npm scopes and ordinary English
# (`try/catch`, `Terms/Privacy`, `4/4`) as untyped citations at a 26% rate over two real projects,
# and a P3 that noisy is a P3 that gets suppressed project-wide on first contact.
#
# THE WRITE IS NARROWER THAN THE READ (see the stamp-scope guard in process_file).
# --stamp-types rewrites only tables that carry BOTH a `Claim` column and an evidence column — the
# only shape from which a stamped type can ever be read back (§2b). Scanning stays wider, because
# the P3 must reach the legacy evidence-only shape.
#
# Usage:
#   validate-evidence-citations.sh [--strict] <file|dir>        scan and report
#   validate-evidence-citations.sh --print-vocabulary           the closed token list
#   validate-evidence-citations.sh --print-table                claim<TAB>admissible types
#   validate-evidence-citations.sh --check-contract <file>      §2b <-> compiled-table parity
#   validate-evidence-citations.sh --stamp-types [--write] <f>  the migration body (see below)
#
# Exit: 0 = no P1 (or no --strict), 1 = P1 under --strict / drift under --strict, 2 = invocation error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/text.sh
. "$SCRIPT_DIR/../../lib/text.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ── Gate output contract (#98 §4) ────────────────────────────────────────────────────────────
# Three lines on EVERY exit path. SUBJECT is citations examined; PREDICATES is admissibility rows
# consulted. Both matter here: this gate can run over an artifact with no citation site at all
# (SUBJECT=0, honest) and it can run with an empty table (PREDICATES=0), which would report a
# clean green while checking nothing.
GATE_SCOPE=""
GATE_SUBJECT=0
GATE_PREDICATES=0
GATE_MODE="scan"
TELEMETRY_EMITTED=false

emit_telemetry() {
  [[ "$TELEMETRY_EMITTED" == true ]] && return 0
  TELEMETRY_EMITTED=true
  echo "SPECK_GATE_SCOPE=$GATE_SCOPE"
  echo "SPECK_GATE_SUBJECT=$GATE_SUBJECT"
  echo "SPECK_GATE_PREDICATES=$GATE_PREDICATES"
  echo "SPECK_GATE_MODE=$GATE_MODE"
}
trap emit_telemetry EXIT

# ── The closed citation-type vocabulary (Speck-owned) ────────────────────────────────────────
# Derived from what the evidence contract and the validation-report template ALREADY cite — the
# §2/§6/§7/§9 evidence lists, the Gate Criteria table, the Mutation Record, and §2a's five rows.
# A project does not extend this. An unknown prefix reads as UNTYPED (a P3 nudge) rather than as a
# type Speck never reviewed, so inventing a token degrades honestly instead of manufacturing a
# confident admissibility verdict.
CITATION_TYPES="test mutation-guard live-probe db-catalog ax-dump geometry capture device-walk model-eval static"

# ── The reserved evidence directories (Speck-owned, derived from §9) ─────────────────────────
# DERIVED, not invented — exactly like CITATION_TYPES: these are the directory names §9 "Evidence
# Storage" reserves for evidence ARTIFACTS (`screenshots/ larp-recordings/ ax-trees/ transcripts/
# logs/`, plus `personas/<persona-id>.md`), and `specs/` as the tree root. They exist because a
# genuine citation sometimes names a DIRECTORY rather than a file
# (`larp-recordings/phase2-8c09936c/`, `specs/projects/`), which an extension-or-nothing rule drops.
#
# §9's two purely STRUCTURAL segments — `epics/` and `stories/` — are deliberately NOT here. No
# evidence artifact lives directly in either (evidence lives under a story, in one of the five leaf
# dirs), so admitting them buys nothing and costs precision: they are ordinary English words, and
# on the measured corpus `stories/` alone readmitted the prose fragment `stories/week`.
# A project does not extend this list.
CITATION_DIRS="specs personas screenshots larp-recordings ax-trees transcripts logs"

# ── The admissibility table (Speck-owned) ────────────────────────────────────────────────────
# Whitelist-shaped: a type absent from a claim's row is inadmissible for that claim. Every
# exclusion below is one of #101's verified scars, not a preference.
#
#   visibility  a green, mutation-verified suite could not see that an anon-key server client
#               carries no JWT, so `auth.uid() = <col>` returned zero rows for EVERY user, always.
#   acceptance  a mocked client encodes the belief the code was written from, so it can only ever
#               confirm that belief — it cannot contradict what the deployment actually accepts.
#   fit         a props-level a11y assertion reads props, not the platform tree; a rule engine has
#               no model of containment. axe was 0/0/0/0 and a11y 9/9, IDENTICAL before and after
#               a grid amputated a column on every phone for months.
#   persistence a screenshot of a success state is not a written row; a post-walk read with no
#               baseline cannot distinguish a fresh write from a stale seed.
#   behaviour   a source-text assertion that a rule string is present in a prompt is not evidence
#               the composed prompt changed what the shipped model does.
#
# `correctness` admits everything: §2a's standing rule is that a green suite remains the right and
# sufficient instrument for a correctness claim. That row can never fire, by design — the default
# claim type must never be punished.
claim_admissible_types() {
  case "$1" in
    correctness) printf '%s' "$CITATION_TYPES" ;;
    visibility)  printf '%s' "live-probe db-catalog device-walk" ;;
    acceptance)  printf '%s' "live-probe db-catalog device-walk" ;;
    persistence) printf '%s' "live-probe db-catalog" ;;
    fit)         printf '%s' "ax-dump geometry device-walk" ;;
    behaviour)   printf '%s' "model-eval device-walk" ;;
    *)           printf '' ;;
  esac
}
CLAIM_TYPES="correctness visibility acceptance persistence fit behaviour"

in_list() {
  local needle="$1" hay="$2" t
  for t in $hay; do [[ "$t" == "$needle" ]] && return 0; done
  return 1
}

sorted_set() {
  # normalise a space-separated set to a stable, comparable string
  printf '%s' "$1" | tr ' ' '\n' | grep -v '^$' | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//'
}

# ── argument parsing ─────────────────────────────────────────────────────────────────────────
strict=false
mode="scan"
write=false
target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=true; shift ;;
    --write) write=true; shift ;;
    --print-vocabulary) mode="print-vocabulary"; shift ;;
    --print-table) mode="print-table"; shift ;;
    --check-contract) mode="check-contract"; shift ;;
    --stamp-types) mode="stamp-types"; shift ;;
    -h|--help) sed -n '1,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "ERROR: unknown option '$1'" >&2; exit 2 ;;
    *) target="$1"; shift ;;
  esac
done
GATE_MODE="$mode"

if [[ "$mode" == "print-vocabulary" ]]; then
  GATE_PREDICATES="$(printf '%s' "$CITATION_TYPES" | wc -w | tr -d ' ')"
  printf '%s\n' $CITATION_TYPES
  exit 0
fi

if [[ "$mode" == "print-table" ]]; then
  n=0
  for c in $CLAIM_TYPES; do
    printf '%s\t%s\n' "$c" "$(sorted_set "$(claim_admissible_types "$c")")"
    n=$((n + 1))
  done
  GATE_PREDICATES="$n"
  exit 0
fi

[[ -n "$target" ]] || { echo "ERROR: pass a markdown file or a directory" >&2; exit 2; }
[[ -e "$target" ]] || { echo "ERROR: not found: $target" >&2; exit 2; }
GATE_SCOPE="$target"

errors=0; warnings=0; notes=0; ok=0; stamped=0; left_untyped=0; untyped_claim=0; skipped_tables=0

emit_p1() { echo -e "${RED}$1${NC}  $2" >&2; errors=$((errors + 1)); }
emit_p2() { echo -e "${YELLOW}$1${NC}  $2"; warnings=$((warnings + 1)); }
emit_p3() { echo -e "${YELLOW}$1${NC}  $2"; warnings=$((warnings + 1)); }
emit_note() { echo -e "${BLUE}$1${NC}  $2"; notes=$((notes + 1)); }

# ── markdown table plumbing (header-keyed, per the v10 §6a precedent) ────────────────────────
# ROW_CELLS holds the TRIMMED cell text (what every verdict is computed from); ROW_RAW holds the
# same cells byte-for-byte, padding included. The rewrite path reads ROW_RAW and only ROW_RAW —
# see splice_cell for why that distinction is the difference between a reviewable migration diff
# and an unreviewable one.
ROW_CELLS=(); ROW_RAW=()
split_row() {
  local line="$1" i
  local -a raw=()
  IFS='|' read -r -a raw <<< "$line" || true
  ROW_CELLS=(); ROW_RAW=()
  for (( i=1; i<${#raw[@]}; i++ )); do
    ROW_RAW+=("${raw[$i]}")
    ROW_CELLS+=("$(sp_trim "${raw[$i]}")")
  done
}

# Replace exactly ONE cell's raw text in a markdown row, leaving every other byte of the line
# untouched — including the authored column padding, the trailing `|`, and any cell this rewrite
# has no business touching.
#
# The obvious implementation — rebuild the row by joining the TRIMMED cells with ` | ` — is what
# shipped, and a single `--stamp-types --write` over a real project rewrote 24 files, collapsing
# the authored alignment of every table it passed through. The types it wrote were correct; the
# diff was unreviewable, and an unreviewable migration gets reverted wholesale, taking the correct
# half with it. Reviewability is a property of the rewrite, not of the reviewer.
#
# Offsets, not string substitution: the row begins with `|` (guaranteed by the caller's `!= \|*`
# test), so cell i starts at 1 + Σ(len(ROW_RAW[0..i-1]) + 1).
splice_cell() {
  local line="$1" idx="$2" new="$3" i off=1
  for (( i=0; i<idx; i++ )); do off=$(( off + ${#ROW_RAW[$i]} + 1 )); done
  printf '%s%s%s' "${line:0:off}" "$new" "${line:off + ${#ROW_RAW[$idx]}}"
}

is_separator_row() { [[ "$1" =~ ^\|[[:space:]:*-]+\|[[:space:]|:-]*$ ]]; }

# A CITATION SITE is any table with an evidence/citation column. A Claim type column is OPTIONAL,
# and which verdicts are computable follows directly from whether it is there:
#
#   evidence column ONLY      -> the citation's TYPE is computable (it is a property of the
#                                citation alone), so CITATION_UNTYPED.P3 fires. Admissibility is
#                                NOT computable — there is no claim to route — so no P1 is
#                                possible. This is the shape of every artifact that exists today.
#   evidence + Claim type     -> the PAIR is present, so admissibility is computable and
#                                PROBE_SUBSTRATE_MISMATCH.P1 fires. This is the shape §11a adds.
#
# That asymmetry is the whole upgrade-day safety story, and it is mechanical rather than a
# promise: a legacy artifact is structurally incapable of raising a P1 from this validator, so
# v10.1 cannot block a project that has not adopted the claim column yet.
#
# Header-STARTS-WITH matching, deliberately: §2a's table is `Claim type (the verb) | Admissible |
# Does NOT count` and §2b's are `Token | …` and `Claim type | Admissible citation types | …` —
# none has a column starting with evidence/citation/discharge/proof/substrate, so the contract can
# never report findings against its own documentation.
COL_CLAIM=-1; COL_EV=-1
resolve_citation_site() {
  split_row "$1"
  COL_CLAIM=-1; COL_EV=-1
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(printf '%s' "${ROW_CELLS[$i]}" | tr '[:upper:]' '[:lower:]')"
    case "$lc" in
      claim*) [[ $COL_CLAIM -lt 0 ]] && COL_CLAIM=$i ;;
      evidence*|citation*|"discharge artifact"*|proof*|substrate*)
        [[ $COL_EV -lt 0 ]] && COL_EV=$i ;;
    esac
  done
  [[ $COL_EV -ge 0 ]]
}

cell_at() {
  local idx="$1"
  [[ "$idx" -ge 0 && "$idx" -lt ${#ROW_CELLS[@]} ]] && printf '%s' "${ROW_CELLS[$idx]}" || printf ''
}

normalize_claim() {
  local s
  s="$(sp_normalize_term "$1")"
  s="${s//\*/}"
  printf '%s' "$s" | tr '[:upper:]' '[:lower:]'
}

# Strip the markdown decoration around one whitespace-separated field, leaving the bare path.
# Sets THREE GLOBALS rather than echoing, deliberately: `core="$(strip_decor "$t")"` would run the
# function in a subshell, so the recorded decoration would be discarded and the rewrite would strip
# every backtick and comma out of the cell it was only supposed to prefix.
STRIP_PRE=""; STRIP_POST=""; STRIP_CORE=""
strip_decor() {
  local t="$1" c
  STRIP_PRE=""; STRIP_POST=""; STRIP_CORE=""
  while [[ -n "$t" ]]; do
    c="${t:0:1}"
    case "$c" in '`'|'['|'('|'<'|'*'|'"') STRIP_PRE+="$c"; t="${t:1}" ;; *) break ;; esac
  done
  while [[ -n "$t" ]]; do
    c="${t: -1}"
    case "$c" in '`'|']'|')'|'>'|'*'|'"'|','|';'|'.'|':') STRIP_POST="$c$STRIP_POST"; t="${t%?}" ;; *) break ;; esac
  done
  STRIP_CORE="$t"
}

# Tokenise an evidence cell into candidate citations.
citation_tokens() {
  local cell="$1" t
  for t in $cell; do
    strip_decor "$t"
    [[ -z "$STRIP_CORE" ]] && continue
    printf '%s\n' "$STRIP_CORE"
  done
}

# Rebuild an evidence cell with inferred types stamped onto the citations that have one.
#
# FIELD-WISE, never a substring substitution: `${cell//$tok/...}` corrupts a cell holding both
# `foo/bar.png` and `x/foo/bar.png` (the shorter one matches inside the longer), and treats any
# glob metacharacter in the path as a pattern.
#
# And WHITESPACE-PRESERVING: it walks the RAW cell as alternating (whitespace run, token) pairs
# and re-emits every whitespace run verbatim, so the ONLY bytes this function can change are the
# `<type>:` prefixes it adds. `for t in $cell` — the shipped version — silently reflowed the cell
# (leading pad, trailing pad, and every internal run collapsed to one space) on every row it
# visited, whether or not it stamped anything there.
STAMP_CELL_OUT=""; STAMP_CELL_CHANGED=false
stamp_cell() {
  # NOT `local cell="$1" rest="$cell"` — bash 3.2 (the macOS system bash) expands every RHS in a
  # `local` statement BEFORE binding any of the names, so the self-reference dies under `set -u`.
  local cell="$1" file="$2" lineno="$3"
  local rest ws tok core ty inferred out=""
  rest="$cell"
  STAMP_CELL_OUT=""; STAMP_CELL_CHANGED=false
  while [[ -n "$rest" ]]; do
    ws="${rest%%[![:space:]]*}"
    if [[ "$ws" == "$rest" ]]; then out+="$rest"; break; fi   # trailing all-whitespace run
    rest="${rest#"$ws"}"; out+="$ws"
    tok="${rest%%[[:space:]]*}"
    rest="${rest#"$tok"}"

    strip_decor "$tok"; core="$STRIP_CORE"
    if [[ -n "$core" ]] && is_citation_like "$core"; then
      GATE_SUBJECT=$((GATE_SUBJECT + 1))
      ty="$(citation_type_of "$core")"
      if [[ -z "$ty" ]]; then
        inferred="$(infer_citation_type "$core")"
        if [[ -n "$inferred" ]]; then
          out+="${STRIP_PRE}${inferred}:${core}${STRIP_POST}"
          stamped=$((stamped + 1))
          STAMP_CELL_CHANGED=true
          emit_note "CITATION_STAMPED" "$file:$lineno — $core -> $inferred:$core"
          continue
        fi
        left_untyped=$((left_untyped + 1))
        emit_note "CITATION_LEFT_UNTYPED" "$file:$lineno — '$core' has no unambiguously inferable type; left untyped on purpose (a wrong type is a confident false verdict)"
      fi
    fi
    out+="$tok"
  done
  STAMP_CELL_OUT="$out"
}

# Does this token look like a citation at all? Placeholders (`—`, `n/a`, `TBD`) and prose must
# not become findings: a validator that reports every English word as an untyped citation is
# noise, and noise is how a P3 gets globally suppressed.
#
# "CONTAINS A SLASH OR AN @" WAS NOT A PATH TEST — IT WAS A PUNCTUATION TEST, and it is why this
# gate could not be wired anywhere. Measured over two real projects' `specs/**` (1,646 markdown
# files), 407 of 1,199 reported "citations" — 34% — carried no file extension at all. They were
# API routes (`/model`, `/suggest`), slash commands (`/audit`), npm scopes (`@streb/web`), CI
# refs (`pnpm/action-setup@v4`) and ordinary English written with a solidus (`try/catch`,
# `before/after`, `sets/week`, `A/B/C/D`, `4/4`, `Terms/Privacy`, `988/741741`). A P3 with a 34%
# false-positive rate is a P3 that gets suppressed project-wide on first contact.
#
# So a token is a citation only when it carries one of THREE facts about a filesystem:
#   1. a file extension on its basename — the strongest available signal that it names an artifact;
#   2. a path segment that is one of §9's reserved evidence directories — which is what keeps a
#      directory citation (`larp-recordings/<sha>/`) admissible while `Terms/Privacy` is not;
#   3. an ABSOLUTE path that actually resolves on disk — the only admission path open to
#      `/health`, `/audit`, `/api/v1/coach/chat`, and the only one they all fail.
#
# The disk probe is deliberately NOT extended to relative tokens: the validator's cwd has no fixed
# relationship to the project being scanned, so a relative `-e` test would make the verdict depend
# on where the gate was invoked from. An absolute probe is the same answer everywhere.
#
# The failure mode is deliberately asymmetric: a rejected token raises no finding at all, so a
# false negative costs one missing nudge, while a false positive costs the whole rule.
is_citation_like() {
  local t="$1" alnum core base probe seg ty
  local -a segs=()
  case "$t" in
    —|-|–|n/a|N/A|TBD|tbd|none|None|not-run) return 1 ;;
  esac
  # A path separator alone is not a path. `[real completion logs / traces]` tokenises to a bare
  # `/`, which satisfied "contains a slash" and was reported as an untyped citation. Demand at
  # least two alphanumerics of substance.
  alnum="${t//[^A-Za-z0-9]/}"
  [[ "${#alnum}" -ge 2 ]] || return 1

  # Drop the `@<sha>` freshness stamp before asking path questions. A token that is NOTHING but a
  # stamp (`@89468af1`) or an npm scope (`@streb/web`) has an empty core and is not a citation.
  core="${t%%@*}"
  [[ -n "$core" ]] || return 1
  # …and the `<type>:` prefix, because the rules below ask questions about a PATH. Without this a
  # typed citation naming a directory (`test:larp-recordings/<sha>/`) or an absolute file
  # (`live-probe:/srv/run.log`) fails every rule and vanishes from the scan entirely — and a
  # citation that is not seen is a citation whose PROBE_SUBSTRATE_MISMATCH.P1 can never fire, which
  # is the exact failure this validator exists to prevent, in the one place it is invisible.
  ty="$(citation_type_of "$core")"
  [[ -n "$ty" ]] && core="${core#"$ty":}"
  [[ -n "$core" ]] || return 1
  # …and a trailing `:<line>` / `:<start>-<end>` anchor, which real artifacts use heavily
  # (`.github/workflows/ci.yml:59-63`). Anchored on a DIGIT so it can never eat a `type:` prefix.
  probe="${core%:[0-9]*}"
  base="${probe##*/}"

  # 1. `.` + 2–6 alnum, with at least one character before the dot: matches `.md .sh .png .ts .sql
  #    .json .swift`, and rejects a bare `.speck`, a version (`v10.1`), and an abbreviation (`e.g`).
  [[ "$base" =~ .\.[A-Za-z0-9]{2,6}$ ]] && return 0

  # 2. a reserved evidence directory anywhere in the path.
  if [[ "$core" == */* ]]; then
    # `IFS=` scoped to this one `read`, never `local IFS` — a function-scoped IFS is visible to
    # every callee in bash, and in_list splits ITS list on IFS.
    IFS='/' read -r -a segs <<< "$core"
    for seg in "${segs[@]}"; do
      in_list "$seg" "$CITATION_DIRS" && return 0
    done
  fi

  # 3. an absolute path that resolves.
  [[ "$core" == /* && -e "$probe" ]] && return 0
  return 1
}

# Split `type:path` when and only when the prefix is a vocabulary token spelled exactly.
# `https://x` and `C:\x` therefore read as untyped paths, never as a bogus type.
citation_type_of() {
  local t="$1" ty
  for ty in $CITATION_TYPES; do
    [[ "$t" == "$ty":* ]] && { printf '%s' "$ty"; return 0; }
  done
  printf ''
}

# ── --check-contract: §2b <-> compiled table parity ──────────────────────────────────────────
# The template is the human-readable half and this file is the machine-readable half. They are
# one rule, so a diff between them is a defect in whichever was edited alone. Without this the
# template's §2b tables would be decoration — editable to say anything, with no effect on any
# verdict, which is the exact vacuity #100 filed.
check_contract() {
  local file="$1" block drift=0 line
  # Keep the WHOLE §2b body, blank lines included: table boundaries are what separate the
  # vocabulary table from the admissibility table from any illustrative citation-site table, and
  # pre-filtering to `|` lines destroys exactly that. (Found by this gate running on its own
  # template: a loose "any row whose first cell is a claim key" parse read the §2b example
  # citation-site row as an admissibility row and reported a drift that did not exist.)
  block="$(awk '/^### 2b\./ { ins=1; next } ins && /^#{2,3} / { ins=0 } ins { print }' "$file" || true)"
  if [[ -z "$(printf '%s' "$block" | tr -d '[:space:]')" ]]; then
    emit_p2 "CITATION_TABLE_DRIFT.P2" "$file — no §2b typed-citation section found. Fix: copy §2b from .speck/templates/project/evidence-contract-template.md, then re-run \`validate-evidence-citations.sh --check-contract $file\`."
    return
  fi

  local in_table=false kind="" declared_vocab="" c declared expected h0 h1
  while IFS= read -r line; do
    if [[ "$line" != \|* ]]; then in_table=false; kind=""; continue; fi
    if [[ "$in_table" == false ]]; then
      in_table=true; kind=""
      split_row "$line"
      h0="$(printf '%s' "$(cell_at 0)" | tr '[:upper:]' '[:lower:]')"
      h1="$(printf '%s' "$(cell_at 1)" | tr '[:upper:]' '[:lower:]')"
      case "$h0" in
        token*) kind="vocab" ;;
        claim*) [[ "$h1" == admissible* ]] && kind="admissibility" ;;
      esac
      continue
    fi
    is_separator_row "$line" && continue
    [[ -z "$kind" ]] && continue
    split_row "$line"
    if [[ "$kind" == "vocab" ]]; then
      declared_vocab="$declared_vocab $(printf '%s' "$(cell_at 0)" | tr -d '` ')"
      continue
    fi
    c="$(printf '%s' "$(cell_at 0)" | tr -d '` ')"
    in_list "$c" "$CLAIM_TYPES" || continue
    declared="$(sorted_set "$(printf '%s' "$(cell_at 1)" | tr -d '`')")"
    expected="$(sorted_set "$(claim_admissible_types "$c")")"
    GATE_PREDICATES=$((GATE_PREDICATES + 1))
    if [[ "$declared" != "$expected" ]]; then
      emit_p2 "CITATION_TABLE_DRIFT.P2" "$file — §2b says \`$c\` admits [$declared]; Speck's compiled table says [$expected]. Fix: re-sync §2b from .speck/templates/project/evidence-contract-template.md."
      drift=1
    fi
  done <<< "$block"

  declared_vocab="$(sorted_set "$declared_vocab")"
  if [[ "$declared_vocab" != "$(sorted_set "$CITATION_TYPES")" ]]; then
    emit_p2 "CITATION_TABLE_DRIFT.P2" "$file — §2b vocabulary is [$declared_vocab] but Speck's compiled vocabulary is [$(sorted_set "$CITATION_TYPES")]. Fix: re-sync §2b from .speck/templates/project/evidence-contract-template.md."
    drift=1
  fi

  if [[ "$GATE_PREDICATES" -eq 0 ]]; then
    emit_p2 "CITATION_TABLE_DRIFT.P2" "$file — §2b declares NO admissibility row Speck recognises. A table with no rows validates nothing. Fix: re-sync §2b from .speck/templates/project/evidence-contract-template.md."
    drift=1
  elif [[ "$drift" -eq 0 ]]; then
    emit_note "CITATION_TABLE_PARITY" "$file — §2b matches Speck's compiled admissibility table ($GATE_PREDICATES claim rows, $(printf '%s' "$CITATION_TYPES" | wc -w | tr -d ' ') citation types)"
  fi
}

# ── type inference for --stamp-types ─────────────────────────────────────────────────────────
# THE ONLY RULE THAT MATTERS HERE: guessing is worse than leaving it untyped. A wrong type
# produces a confident FALSE admissibility verdict — a `test` stamped onto a Playwright geometry
# spec would make a `fit` claim read as a substrate mismatch that is not one, or (worse, in the
# other direction) launder a real one. So the inference set is small and each rule is a fact
# about the path, never a convention about the repo:
#
#   *-human-attestation.md / *-felt-attestation.md  the contract itself defines these as the
#                                                   human record (§8 Verifiability Tiering).
#   ax-trees/ or an *ax-tree* basename              §9 reserves this directory for the platform tree.
#   an image or video extension                     a .png cannot be anything but a capture.
#   screenshots/ or larp-recordings/                §9 reserves both for captured runs.
#   *.test.<ext> / test_*.py / *_test.{py,go}       a unit-harness naming convention...
#
# ...EXCEPT under an e2e/playwright/cypress/a11y/browser path segment, where the same suffix is
# routinely a live browser run measuring real geometry (#101's own geometry reference
# implementation is `frontend/tests/a11y/availability-target-size.spec.ts`). `.spec.*` is never
# inferred at all for the same reason: Vitest and Playwright share it.
infer_citation_type() {
  local p="$1" base
  base="$(basename "$p")"
  base="${base%%@*}"
  p="${p%%@*}"

  case "$base" in
    *-human-attestation.md|*-felt-attestation.md|*human-attestation*|*device-walk*) printf 'device-walk'; return 0 ;;
  esac
  case "$p" in
    */ax-trees/*|ax-trees/*) printf 'ax-dump'; return 0 ;;
  esac
  case "$base" in
    *ax-tree*|*ax_tree*) printf 'ax-dump'; return 0 ;;
  esac
  case "$base" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.mp4|*.mov|*.webm|*.PNG|*.JPG) printf 'capture'; return 0 ;;
  esac
  case "$p" in
    */screenshots/*|screenshots/*|*/larp-recordings/*|larp-recordings/*) printf 'capture'; return 0 ;;
  esac
  case "/$p" in
    */e2e/*|*/playwright/*|*/cypress/*|*/a11y/*|*/browser/*) printf ''; return 0 ;;
  esac
  case "$base" in
    *.test.*) printf 'test'; return 0 ;;
    test_*.py|*_test.py|*_test.go) printf 'test'; return 0 ;;
  esac
  printf ''
}

# ── the scan ─────────────────────────────────────────────────────────────────────────────────
process_file() {
  local file="$1"
  local in_table=false site=false line lineno=0
  local claim ctype cites tok ty adm rewritten="" changed=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    if [[ "$line" != \|* ]]; then
      in_table=false; site=false
      rewritten+="$line"$'\n'
      continue
    fi
    if [[ "$in_table" == false ]]; then
      in_table=true
      if resolve_citation_site "$line"; then site=true; else site=false; fi
      # THE WRITE IS NARROWER THAN THE READ, and the asymmetry is the point.
      #
      # A P3 needs only the citation, so the SCAN reaches any table with an evidence column —
      # which is every legacy artifact, and is what stops the P3 being vacuous. A stamped type is
      # only ever READ back on a table that also declares a `Claim` column (§2b: admissibility is
      # computable only where the claim and the citation sit in the same row), so stamping one
      # into a plan.md acceptance table or an audit-report.md finding table writes a type that
      # nothing can consume — pure churn in a diff a human has to review. The shipped rewrite did
      # exactly that across 24 files on one project.
      if [[ "$mode" == "stamp-types" && "$site" == true && $COL_CLAIM -lt 0 ]]; then
        site=false
        skipped_tables=$((skipped_tables + 1))
      fi
      rewritten+="$line"$'\n'
      continue
    fi
    if is_separator_row "$line" || [[ "$site" == false ]]; then
      rewritten+="$line"$'\n'
      continue
    fi

    split_row "$line"
    claim=""
    [[ $COL_CLAIM -ge 0 ]] && claim="$(normalize_claim "$(cell_at "$COL_CLAIM")")"
    cites="$(cell_at "$COL_EV")"
    [[ -z "$cites" ]] && { rewritten+="$line"$'\n'; continue; }

    # `undeclared` is NOT a claim type — it is the absence of one, and it is why this row can
    # only ever produce a P3. Keeping it distinct from an unrecognised value matters: a legacy
    # artifact has no claim column at all, which is honest; `vibes` in a claim column is a typo.
    local routed=true declared=true
    [[ -z "$claim" ]] && { declared=false; claim="undeclared"; }
    $declared && { in_list "$claim" "$CLAIM_TYPES" || routed=false; }
    adm="$(claim_admissible_types "$claim")"

    if [[ "$mode" == "stamp-types" ]]; then
      # The RAW cell in, a splice of the raw line out: no other cell on this row is re-emitted,
      # so a row where nothing was stamped is byte-identical and a row where something was is a
      # one-cell diff.
      stamp_cell "${ROW_RAW[$COL_EV]}" "$file" "$lineno"
      if [[ "$STAMP_CELL_CHANGED" == true ]]; then
        changed=true
        rewritten+="$(splice_cell "$line" "$COL_EV" "$STAMP_CELL_OUT")"$'\n'
      else
        rewritten+="$line"$'\n'
      fi
      continue
    fi

    while IFS= read -r tok; do
      [[ -z "$tok" ]] && continue
      is_citation_like "$tok" || continue
      GATE_SUBJECT=$((GATE_SUBJECT + 1))
      ty="$(citation_type_of "$tok")"

      if [[ -z "$ty" ]]; then
        emit_p3 "CITATION_UNTYPED.P3" "$file:$lineno — '$tok' has no citation type (claim: $claim). Fix: \`.speck/scripts/validation/validators/validate-evidence-citations.sh --stamp-types --write $file\`, then type the rest by hand from §2b's vocabulary."
        continue
      fi

      if [[ "$declared" == false ]]; then
        # Type known, claim type not declared: nothing to route against. Never a finding — this
        # is every artifact authored before §11a, and punishing it is what would brick upgrade day.
        untyped_claim=$((untyped_claim + 1))
        continue
      fi

      if [[ "$routed" == false ]]; then
        emit_note "CLAIM_TYPE_UNROUTED" "$file:$lineno — claim type '$claim' is not one of [$CLAIM_TYPES]; admissibility not computed for '$tok'"
        continue
      fi
      GATE_PREDICATES=$((GATE_PREDICATES + 1))
      if in_list "$ty" "$adm"; then
        ok=$((ok + 1))
      else
        emit_p1 "PROBE_SUBSTRATE_MISMATCH.P1" "$file:$lineno — claim '$claim' is discharged by a \`$ty\` citation ($tok). §2b admits only [$adm] for '$claim': a \`$ty\` is structurally incapable of observing this claim, however green it is. Re-collect on an admissible substrate."
      fi
    done <<< "$(citation_tokens "$cites")"

    rewritten+="$line"$'\n'
  done < "$file"

  if [[ "$mode" == "stamp-types" && "$write" == true && "$changed" == true ]]; then
    printf '%s' "$rewritten" > "$file"
  fi
}

collect_files() {
  if [[ -d "$target" ]]; then
    find "$target" -type f -name '*.md' | LC_ALL=C sort
  else
    printf '%s\n' "$target"
  fi
}

echo -e "${BLUE}🔖 Evidence-citation admissibility — $GATE_MODE — $target${NC}"
echo ""

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$mode" == "check-contract" ]]; then
    check_contract "$f"
  else
    process_file "$f"
  fi
done <<< "$(collect_files)"

echo ""
case "$mode" in
  stamp-types)
    echo "Citations: ${GATE_SUBJECT} examined · ${stamped} stamped · ${left_untyped} left untyped (ambiguous) · ${skipped_tables} table(s) skipped (evidence column but no \`Claim\` column — a type written there can never be read) · $( [[ "$write" == true ]] && echo "WRITTEN" || echo "dry-run (pass --write to apply)" )"
    ;;
  check-contract)
    echo "Contract parity: ${GATE_PREDICATES} claim row(s) checked · ${warnings} drift(P2)"
    ;;
  *)
    echo "Citations: ${GATE_SUBJECT} examined · ${ok} admissible · ${untyped_claim} typed-but-unrouted (no claim column) · ${errors} substrate mismatch(P1) · ${warnings} untyped(P3) · ${notes} note(s)"
    ;;
esac

if [[ "$errors" -gt 0 && "$strict" == true ]]; then
  echo -e "${RED}Evidence-citation check FAILED: $errors claim(s) discharged by an inadmissible substrate.${NC}" >&2
  exit 1
fi
if [[ "$mode" == "check-contract" && "$warnings" -gt 0 && "$strict" == true ]]; then
  echo -e "${RED}Evidence-citation check FAILED: §2b has drifted from Speck's compiled table.${NC}" >&2
  exit 1
fi
echo -e "${GREEN}Evidence-citation check complete.${NC}"
exit 0
