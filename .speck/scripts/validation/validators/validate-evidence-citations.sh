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
# (`try/catch`, `Terms/Privacy`, `4/4`) as citations.
#
# MEASURED ONCE, HERE — every other mention in this file points back to this paragraph instead of
# re-quoting its own number. Two real Speck projects' specs/** (brightstance, streb), same corpus,
# before/after this file's fix: the bare punctuation test reported 1,240 "citations" combined
# (brightstance 609, streb 631); requiring an extension, a reserved evidence directory, or a
# resolving absolute path instead reports 947 (brightstance 535, streb 412) — a 23.6% drop. All of
# the removed 293 were extension-less punctuation matches (brightstance 74 -> 0, streb 222 -> 4),
# and the 4 streb survivors are genuine directory citations, not false positives. The 947-side of
# this is reproducible on demand: `validate-evidence-citations.sh <specs-dir>` prints
# SPECK_GATE_SUBJECT. The absolute counts above pin a LIVE corpus and drift with every commit those
# repos take — do not re-assert them as current. The durable claim is the RATIO and the direction:
# ~24% fewer, and every removed match was extension-less punctuation. A P3 with the punctuation
# test's false-positive rate is a P3 that gets suppressed project-wide on first contact.
#
# THE WRITE IS NARROWER THAN THE READ (see the stamp-scope guard in process_file).
# --stamp-types rewrites only tables that carry BOTH a `Claim` column and an evidence column — the
# only shape from which a stamped type can ever be read back (§2b). Scanning stays wider, because
# the P3 must reach the legacy evidence-only shape.
#
# THE §11a STANDARD PROBE LIBRARY (v10.2) — WHY IT LIVES IN THIS FILE.
# #101's §11a was unbuildable at v10.0 because PROBE_SUBSTRATE_MISMATCH.P1 "the cited artifact's
# type is on the 'does NOT count' side of §2's table" cannot be computed from `path@sha`. v10.1
# shipped the type vocabulary and the admissibility table above, so §11a is now a LOOKUP over that
# table — claim type -> citation type -> admissible? — rather than an inference over a string. The
# lookup and the table must not be two files: a registry whose admissibility rule could drift from
# the table it cites is the vacuity #100 filed. So the library is compiled in HERE, beside the
# table it reads, and the contract's rendering of it is parity-checked exactly like §2b.
#
# UNKNOWN NEVER CONVICTS, and it is a decision rather than an omission. Admissibility is a property
# of the PAIR (claim type, citation type). An unknown citation type means the pair is INCOMPLETE,
# not that it is inadmissible — and a validator that resolved incomplete to inadmissible would turn
# every un-stamped project red on upgrade day while claiming to have proved something it never
# computed. So an untyped/unknown discharge artifact is PROBE_SUBSTRATE_UNKNOWN.P3, the same
# severity and the same reason as CITATION_UNTYPED.P3.
#
# Usage:
#   validate-evidence-citations.sh [--strict] <file|dir>        scan and report
#   validate-evidence-citations.sh --print-vocabulary           the closed token list
#   validate-evidence-citations.sh --print-table                claim<TAB>admissible types
#   validate-evidence-citations.sh --check-contract <file>      §2b <-> compiled-table parity
#   validate-evidence-citations.sh --stamp-types [--write] <f>  the migration body (see below)
#   validate-evidence-citations.sh --print-probe-library        the closed §11a class list
#   validate-evidence-citations.sh --check-probe-library <f>    §11a discharge / exception / drift
#   validate-evidence-citations.sh --scaffold-probe-library [--write] <f>   add §11a to a contract
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

# ── The §11a Standard Probe Library (Speck-owned, CLOSED) ────────────────────────────────────
# Eight recurring defect classes, each routed to an admissible substrate BY RULE rather than by
# whoever's imagination ran that week. This is deliberately NOT §11: §11's own P4 says its list
# "prompts the adversary's imagination — it is not the definition of done", and growing it is the
# failure mode it warns about. §11a is the differently-shaped second section — closed, recurring,
# discharge-REQUIRED — and a project extends it exactly as much as it extends CITATION_TYPES: not
# at all.
#
# ONE COLUMN LIST, like GATE_REGISTRY_COLUMNS. The header, the separator and the scaffolded rows
# are all derived from it, so a column insert cannot land in one and not the others — the exact
# drift that made three §6a readers disagree before v9.6.
PROBE_LIBRARY_COLUMNS=("Probe ID" "Class" "Claim type" "Admissible substrate" "Required negative controls" "Discharge artifact" "Exception")
PROBE_IDX_ID=0; PROBE_IDX_CLASS=1; PROBE_IDX_CLAIM=2; PROBE_IDX_SUBSTRATE=3; PROBE_IDX_CONTROLS=4
PROBE_IDX_DISCHARGE=5; PROBE_IDX_EXCEPTION=6

# id <TAB> class <TAB> claim type <TAB> admissible substrate <TAB> required negative controls.
# The last two columns (Discharge artifact / Exception) are the PROJECT's to fill — they are the
# only two cells §11a leaves open, and the whole registry exists to make leaving BOTH of them empty
# a finding instead of a silence.
#
# The claim type on each row is the load-bearing field: it is what turns PROBE_SUBSTRATE_MISMATCH
# into a lookup into claim_admissible_types() above. `named-clock` and `substrate` are typed
# `correctness` HONESTLY — a lint rule plus a dual-TZ suite run genuinely is the right instrument
# for them, so those two rows can never raise a mismatch. A registry that manufactured a stricter
# claim type than the class deserves, just to make every row able to fire, would be theater.
probe_library() {
  printf '%s\n' \
"PROBE:provenance	P1	behaviour	render site + generator stamp + the prompt's own exemplars, judged control-vs-treatment on the composed prompt with the shipped model	rendered-with-degraded-provenance · exemplar re-read (deleting the exemplar must not leave the test green)" \
"PROBE:honest-label	P2	persistence	the write's observed outcome read back out of the datastore against a pre-walk baseline	total-failure render · partial-failure render · the three renders differ" \
"PROBE:second-actor	P3	visibility	A writes, teardown, B signs in on the same install, offline — once per enumerated persistence layer	signOut vs deleteAccount compared field-for-field · launch-with-data-and-no-owner-record" \
"PROBE:money-path	P4	acceptance	the real engine as the applying principal, one run per revenue path	entitlement gate flipped and every revenue path goes red · vendor fixture cited to the vendor's field reference · per-user serialized claim write · one declared fail-posture · bounded worst case per tap" \
"PROBE:named-clock	P5	correctness	an AST/lint rule over write handlers, cache fills and fixtures, plus the date-sensitive suites run under two timezones	a non-UTC TZ run · allowlist entries that name the audience" \
"PROBE:geometry-ax	P6	fit	a baked build: platform AX dump plus container-vs-content geometry at 3 or more widths, numbers in the artifact	adjacent-target overlap · expected-cell presence · page overflow" \
"PROBE:substrate	P7	correctness	§2b parity of this contract against Speck's compiled admissibility table	the parity run reports CITATION_TABLE_PARITY over a non-empty row set" \
"PROBE:migration-dirt	P8	acceptance	the migration applied forward on a throwaway seeded to the target's real dirty shape	pre-state REJECTED · boundary cases still refuse · one migration head after the merge"
}

probe_ids() { probe_library | cut -f1; }

# probe_field <probe-id> <1-based field> — empty when the id is not in the closed library.
probe_field() {
  probe_library | awk -F'\t' -v id="$1" -v n="$2" '$1 == id { print $n; exit }'
}

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
    --print-probe-library) mode="print-probe-library"; shift ;;
    --check-probe-library) mode="check-probe-library"; shift ;;
    --scaffold-probe-library) mode="scaffold-probe-library"; shift ;;
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

if [[ "$mode" == "print-probe-library" ]]; then
  probe_library
  GATE_PREDICATES="$(probe_ids | grep -c .)"
  GATE_SUBJECT="$GATE_PREDICATES"
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
# gate could not be wired anywhere (the measurement is above, under WHAT COUNTS AS A CITATION AT
# ALL — not repeated here, so there is exactly one number for this in the file). It reported API
# routes (`/model`, `/suggest`), slash commands (`/audit`), npm scopes (`@streb/web`), CI refs
# (`pnpm/action-setup@v4`) and ordinary English written with a solidus (`try/catch`,
# `before/after`, `sets/week`, `A/B/C/D`, `4/4`, `Terms/Privacy`, `988/741741`) as citations just
# as readily as a real path. A P3 that noisy is a P3 that gets suppressed project-wide on first
# contact.
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

# ── §11a: the Standard Probe Library check ───────────────────────────────────────────────────
# Shaped on §6a's precedent, which is the only gate-registry pattern in this repo that has been
# proven load-bearing: a Speck-owned closed set, rendered into the project's contract, read back
# HEADER-KEYED, with the project-authored cells the only ones a project may write.
#
# `## 11a.` and never `### 11a.`: §11a is a SIBLING of §11, not a subsection of it. #101's P4
# constraint is that §11 must not grow, and a subsection heading is exactly how a "second, differently
# shaped section" quietly becomes a longer §11.
probe_section() {
  awk '/^##[[:space:]]*11a\./ { ins=1; next } ins && /^##[[:space:]]/ { ins=0 } ins { print }' "$1"
}

# Whitespace/backtick-insensitive comparison of a Speck-owned cell. A project re-wrapping a long
# cell or dropping the code ticks off a claim type is not drift; changing the WORDS is.
norm_cell() {
  local s
  s="$(printf '%s' "$1" | tr -d '`' | tr '\n\t' '  ' | tr -s ' ')"
  printf '%s' "$(sp_trim "$s")"
}

PCOL_ID=-1; PCOL_CLASS=-1; PCOL_CLAIM=-1; PCOL_SUBSTRATE=-1; PCOL_CONTROLS=-1; PCOL_DISCHARGE=-1; PCOL_EXCEPTION=-1
resolve_probe_columns() {
  split_row "$1"
  PCOL_ID=-1; PCOL_CLASS=-1; PCOL_CLAIM=-1; PCOL_SUBSTRATE=-1; PCOL_CONTROLS=-1; PCOL_DISCHARGE=-1; PCOL_EXCEPTION=-1
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(printf '%s' "${ROW_CELLS[$i]}" | tr '[:upper:]' '[:lower:]')"
    case "$lc" in
      "probe id"*)   PCOL_ID=$i ;;
      class*)        PCOL_CLASS=$i ;;
      claim*)        PCOL_CLAIM=$i ;;
      admissible*)   PCOL_SUBSTRATE=$i ;;
      required*)     PCOL_CONTROLS=$i ;;
      discharge*)    PCOL_DISCHARGE=$i ;;
      exception*)    PCOL_EXCEPTION=$i ;;
    esac
  done
  [[ $PCOL_ID -ge 0 && $PCOL_DISCHARGE -ge 0 && $PCOL_EXCEPTION -ge 0 ]]
}

# Where a `waived DEC-####` must resolve. Same convention as validate-gate-liveness.sh: the log
# sits beside the contract, or one level up in a project dir. Not findable => the waiver is
# recorded as unverified rather than convicted — degrade-to-honest, never a false P2.
find_decisions_log() {
  local d; d="$(cd "$(dirname "$1")" 2>/dev/null && pwd)" || return 1
  local p
  for p in "$d/project-decisions-log.md" "$d/../project-decisions-log.md"; do
    [[ -f "$p" ]] && { printf '%s' "$p"; return 0; }
  done
  return 1
}

check_probe_library() {
  local file="$1"
  local block line in_table=false is_probe_table=false seen="" declog=""
  local pid claim discharge exception ex tok first_cite ty adm dec
  local exp_class exp_claim exp_substrate exp_controls got pair idx rest label want
  local has_discharge has_exception

  block="$(probe_section "$file")"
  if [[ -z "$(printf '%s' "$block" | tr -d '[:space:]')" ]]; then
    emit_p3 "PROBE_LIBRARY_ABSENT.P3" "$file — no '## 11a. Standard Probe Library' section. The eight recurring defect classes are neither discharged nor declared inapplicable here, which is indistinguishable from a project that has none of those surfaces. Fix: \`.speck/scripts/validation/validators/validate-evidence-citations.sh --scaffold-probe-library --write $file\`, then fill Discharge artifact or Exception on every row."
    return
  fi
  declog="$(find_decisions_log "$file" || true)"

  while IFS= read -r line; do
    if [[ "$line" != \|* ]]; then in_table=false; is_probe_table=false; continue; fi
    if [[ "$in_table" == false ]]; then
      in_table=true
      if resolve_probe_columns "$line"; then is_probe_table=true; else is_probe_table=false; fi
      continue
    fi
    is_separator_row "$line" && continue
    [[ "$is_probe_table" == false ]] && continue

    split_row "$line"
    pid="$(norm_cell "$(cell_at "$PCOL_ID")")"
    [[ -z "$pid" ]] && continue
    if ! in_list "$pid" "$(probe_ids | tr '\n' ' ')"; then
      emit_p2 "PROBE_LIBRARY_DRIFT.P2" "$file — '$pid' is not one of Speck's eight §11a classes [$(probe_ids | tr '\n' ' ' | sed 's/ $//')]. §11a is CLOSED: a project adds probes to its own §11 (the adversary's imagination), never to the library. Fix: remove the row, or open an issue against Speck to add the class."
      continue
    fi
    seen="$seen $pid"
    GATE_SUBJECT=$((GATE_SUBJECT + 1))

    # --- Speck-owned cells must not have been edited. Without this, weakening a row's claim type
    # to `correctness` silently dissolves every mismatch it could ever raise. Same law as §2b's
    # parity check: the human-readable half and the machine-readable half are ONE rule.
    exp_class="$(probe_field "$pid" 2)"
    exp_claim="$(probe_field "$pid" 3)"
    exp_substrate="$(probe_field "$pid" 4)"
    exp_controls="$(probe_field "$pid" 5)"
    for pair in "$PCOL_CLASS|Class|$exp_class" "$PCOL_CLAIM|Claim type|$exp_claim" \
                "$PCOL_SUBSTRATE|Admissible substrate|$exp_substrate" "$PCOL_CONTROLS|Required negative controls|$exp_controls"; do
      idx="${pair%%|*}"; rest="${pair#*|}"; label="${rest%%|*}"; want="${rest#*|}"
      [[ "$idx" -lt 0 ]] && continue
      got="$(norm_cell "$(cell_at "$idx")")"
      GATE_PREDICATES=$((GATE_PREDICATES + 1))
      if [[ "$got" != "$(norm_cell "$want")" ]]; then
        emit_p2 "PROBE_LIBRARY_DRIFT.P2" "$file — $pid's Speck-owned '$label' cell reads '$got' but the compiled library says '$want'. Fix: re-sync §11a from .speck/templates/project/evidence-contract-template.md (only Discharge artifact and Exception are yours to write)."
      fi
    done

    # --- the claim type used for the lookup is the COMPILED one, never the cell. A drifted cell is
    # already reported above; routing off it as well would let an edit change the verdict.
    claim="$exp_claim"
    discharge="$(cell_at "$PCOL_DISCHARGE")"
    exception="$(cell_at "$PCOL_EXCEPTION")"

    first_cite=""
    while IFS= read -r tok; do
      [[ -z "$tok" ]] && continue
      is_citation_like "$tok" || continue
      first_cite="$tok"; break
    done <<< "$(citation_tokens "$discharge")"
    has_discharge=false; [[ -n "$first_cite" ]] && has_discharge=true

    ex="$(norm_cell "$exception")"
    has_exception=true
    case "$ex" in
      ""|"—"|"-"|"–")
        has_exception=false ;;
      "n/a"|"N/A"|"n/a:"|"na")
        emit_p2 "PROBE_NA_UNBACKED.P2" "$file — $pid declares the class inapplicable with no reason. 'n/a' alone is indistinguishable from 'nobody looked'. Fix: \`n/a:<reason>\` (e.g. \`n/a:no revenue path\`)." ;;
      n/a:*)
        emit_note "PROBE_EXCEPTION_DECLARED" "$file — $pid: $ex" ;;
      waived*)
        dec="$(printf '%s' "$ex" | grep -oE 'DEC-[0-9]+' | head -n1 || true)"
        if [[ -z "$dec" ]]; then
          emit_p2 "PROBE_NA_UNBACKED.P2" "$file — $pid is waived with no DEC. A dark spot we accept is a logged decision, not a dash. Fix: \`waived DEC-####\`, with the DEC in project-decisions-log.md."
        elif [[ -n "$declog" ]] && grep -qF "$dec" "$declog" 2>/dev/null; then
          emit_note "PROBE_EXCEPTION_DECLARED" "$file — $pid: waived $dec (resolves in $(basename "$declog"))"
        elif [[ -n "$declog" ]]; then
          emit_p2 "PROBE_NA_UNBACKED.P2" "$file — $pid cites $dec but it is not found in $(basename "$declog")."
        else
          emit_note "PROBE_EXCEPTION_UNVERIFIED" "$file — $pid: waived $dec, but no project-decisions-log.md was found beside the contract — recorded, not verified."
        fi ;;
      *)
        emit_p2 "PROBE_NA_UNBACKED.P2" "$file — $pid's Exception cell reads '$ex', which is neither \`n/a:<reason>\` nor \`waived DEC-####\`. An exception Speck cannot parse is a silence with extra words." ;;
    esac

    if [[ "$has_discharge" == false ]]; then
      if [[ "$has_exception" == false ]]; then
        emit_p1 "PROBE_UNDECLARED.P1" "$file — $pid ($exp_class) has neither a discharge artifact nor a declared exception. Absence and inapplicability must be distinguishable — the same law as GATE_EMPTY_LEGITIMATE vs GATE_VACUOUS. Fix: cite a typed artifact admissible for '$claim' [$(claim_admissible_types "$claim")], or declare \`n/a:<reason>\` / \`waived DEC-####\`."
      fi
      continue
    fi

    GATE_PREDICATES=$((GATE_PREDICATES + 1))
    ty="$(citation_type_of "$first_cite")"
    adm="$(claim_admissible_types "$claim")"
    if [[ -z "$ty" ]]; then
      # UNKNOWN NEVER CONVICTS. See the header: admissibility is a property of the PAIR, and an
      # unknown type means the pair is incomplete, not that it is inadmissible.
      emit_p3 "PROBE_SUBSTRATE_UNKNOWN.P3" "$file — $pid discharges a '$claim' claim with '$first_cite', whose citation type is unknown, so admissibility could not be computed (not: was computed and failed). Fix: \`--stamp-types --write $file\`, or prefix it by hand from §2b's vocabulary [$CITATION_TYPES]."
    elif in_list "$ty" "$adm"; then
      ok=$((ok + 1))
      emit_note "PROBE_DISCHARGED" "$file — $pid: \`$ty\` is admissible for '$claim'"
    else
      emit_p1 "PROBE_SUBSTRATE_MISMATCH.P1" "$file — $pid discharges a '$claim' claim with a \`$ty\` citation ($first_cite). §2b admits only [$adm] for '$claim': a \`$ty\` is structurally incapable of observing this claim, however green it is. Re-collect on an admissible substrate."
    fi
  done <<< "$block"

  # --- the closed-set completeness check. A class deleted from the table is the SAME sin as a
  # blank row: silence where a declaration was required. §6a hunts exactly this third case.
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    in_list "$pid" "$seen" && continue
    emit_p1 "PROBE_UNDECLARED.P1" "$file — $pid ($(probe_field "$pid" 2)) is absent from §11a entirely. The library is closed: a deleted row is an undeclared class, not an inapplicable one. Fix: restore the row from .speck/templates/project/evidence-contract-template.md and fill Discharge artifact or Exception."
  done <<< "$(probe_ids)"
}

# ── --scaffold-probe-library: the migration body, in the validator ───────────────────────────
# Same shape as --stamp-types --write: the thing that fixes the finding ships beside the finding.
# The section is DERIVED from the compiled library, so a scaffolded contract passes the drift check
# by construction, and it is scaffolded UNDISCHARGED on purpose — a scaffold that pre-filled the
# discharge cells would mint eight green rows nobody proved, which is the failure mode this whole
# registry exists to make impossible.
probe_table_markdown() {
  local out="|" c n i
  for c in "${PROBE_LIBRARY_COLUMNS[@]}"; do out="$out $c |"; done
  printf '%s\n' "$out"
  out="|"
  for c in "${PROBE_LIBRARY_COLUMNS[@]}"; do
    n=${#c}; (( n < 3 )) && n=3
    out="$out$(printf -- '-%.0s' $(seq 1 "$n"))|"
  done
  printf '%s\n' "$out"
  probe_library | while IFS=$'\t' read -r id class claim substrate controls; do
    printf '| %s | %s | `%s` | %s | %s | — | — |\n' "$id" "$class" "$claim" "$substrate" "$controls"
  done
}

probe_section_markdown() {
  cat <<'HDR'
## 11a. Standard Probe Library

*§11 above stays exactly as it is — its P4 says its list prompts the adversary's imagination and must not be grown to close a gap. §11a is the differently-shaped second section: a **closed, Speck-owned registry** of eight recurring defect classes that are discharge-**required**. Each row's claim type routes into §2b's admissibility table, so `PROBE_SUBSTRATE_MISMATCH.P1` is a lookup, not an opinion.*

**How a row is discharged.** Fill **Discharge artifact** with a typed citation (§2b: `<citation-type>:<path>[@<sha>]`) whose type is admissible for that row's claim type — *or* fill **Exception**. Exactly one of the two, never neither.

**Exception is first-class** — `—` (the class applies, discharge required) · `n/a:<reason>` (this product has no such surface) · `waived DEC-####` (it does and we accept the dark spot, with the DEC in `project-decisions-log.md`). A row with neither a discharge artifact nor an exception is `PROBE_UNDECLARED.P1`, and so is deleting the row.

HDR
  probe_table_markdown
  cat <<'FTR'

*Checked by `validate-evidence-citations.sh --check-probe-library <this file>`. Only the last two columns are yours to write; the rest is parity-checked against Speck's compiled library.*
FTR
}

scaffold_probe_library() {
  local file="$1" tmp
  if [[ -n "$(probe_section "$file" | tr -d '[:space:]')" ]]; then
    emit_note "PROBE_LIBRARY_PRESENT" "$file — §11a already present; nothing scaffolded. Run --check-probe-library to see what is undeclared."
    return
  fi
  local sectfile; sectfile="$(mktemp)"
  probe_section_markdown > "$sectfile"
  tmp="$(mktemp)"
  # Insert before §12 when it exists (§11a is a sibling of §11, so it belongs between them);
  # otherwise append. Never rewrites a byte of the surrounding contract.
  #
  # The section is streamed in with getline from a FILE, never passed through `awk -v`: an -v value
  # is scanned for escape sequences and its newline handling is implementation-defined, so a
  # multi-line section through -v is the BSD-vs-GNU shape that reddens a correct implementation on
  # someone else's machine. seed-gate-registry.sh splices its §6a table the same way.
  if grep -qE '^##[[:space:]]*12\.' "$file"; then
    awk -v sectfile="$sectfile" '
      /^##[[:space:]]*12\./ && !done {
        while ((getline l < sectfile) > 0) print l
        close(sectfile); print "---"; print ""; done=1
      }
      { print }
    ' "$file" > "$tmp"
  else
    { cat "$file"; echo ""; cat "$sectfile"; } > "$tmp"
  fi
  rm -f "$sectfile"
  GATE_SUBJECT=$((GATE_SUBJECT + $(probe_ids | grep -c .)))
  if [[ "$write" == true ]]; then
    mv "$tmp" "$file"
    emit_note "PROBE_LIBRARY_SCAFFOLDED" "$file — §11a written with $(probe_ids | grep -c .) undischarged classes. Fill Discharge artifact or Exception on every row, then re-run --check-probe-library."
  else
    rm -f "$tmp"
    emit_note "PROBE_LIBRARY_SCAFFOLD_DRYRUN" "$file — would insert §11a with $(probe_ids | grep -c .) classes (pass --write to apply)."
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
  case "$mode" in
    check-contract)          check_contract "$f" ;;
    check-probe-library)     check_probe_library "$f" ;;
    scaffold-probe-library)  scaffold_probe_library "$f" ;;
    *)                       process_file "$f" ;;
  esac
done <<< "$(collect_files)"

echo ""
case "$mode" in
  check-probe-library)
    echo "§11a probe library: $(probe_ids | grep -c .) Speck-owned class(es) · ${GATE_SUBJECT} declared in the contract · ${ok} discharged on an admissible substrate · ${errors} undeclared-or-mismatched(P1) · ${warnings} drift/unbacked/unknown(P2,P3) · ${notes} note(s)"
    ;;
  scaffold-probe-library)
    echo "§11a scaffold: $(probe_ids | grep -c .) class(es) · $( [[ "$write" == true ]] && echo "WRITTEN" || echo "dry-run (pass --write to apply)" )"
    ;;
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
  if [[ "$mode" == "check-probe-library" ]]; then
    echo -e "${RED}§11a check FAILED: $errors probe class(es) undeclared or discharged by an inadmissible substrate.${NC}" >&2
  else
    echo -e "${RED}Evidence-citation check FAILED: $errors claim(s) discharged by an inadmissible substrate.${NC}" >&2
  fi
  exit 1
fi
if [[ "$mode" == "check-contract" && "$warnings" -gt 0 && "$strict" == true ]]; then
  echo -e "${RED}Evidence-citation check FAILED: §2b has drifted from Speck's compiled table.${NC}" >&2
  exit 1
fi
echo -e "${GREEN}Evidence-citation check complete.${NC}"
exit 0
