#!/usr/bin/env bash
# text.sh — shared text primitives for Speck's shell validators.
#
# WHY THIS EXISTS
# Five separate Speck defects were one class: a bash text-processing idiom used for
# structured-data work without accounting for `set -euo pipefail` semantics. Each was
# repaired locally, at a different call site, by a different hand. This library is the
# chokepoint — the idioms live here once, tested, and `validate-shell-idioms.sh` fails
# the build when a validator hand-rolls one of them again.
#
# The banned idioms and what they actually do:
#
#   $(echo "$s" | xargs)      as a trim. xargs does shell-style QUOTE PROCESSING, so a
#                             lone apostrophe is an unterminated quote: it exits 1 and
#                             `set -e` kills the validator mid-run (#91). On the success
#                             path it also strips quotes and unescapes backslashes, so a
#                             path or format is silently ALTERED, not merely trimmed.
#                             → sp_trim
#
#   cmd | head -n N           under pipefail. head exits after N lines, SIGPIPEs the
#                             producer, and the pipeline reports 141 — aborting the run
#                             with everything after it unscanned. → sp_head
#
#   split(s, a, /[\/,]/)      splitting a display string on delimiters that also occur
#                             INSIDE its parenthetical, shredding one term into fragments
#                             that can never match anything (#90). → sp_split_toplevel
#
#   grep -q "$needle"         unanchored, unescaped substring match: expected `table:order`
#                             false-PASSES against a catalog holding only `table:orders`,
#                             and any regex metacharacter in $needle is live. → sp_match_exact
#
# Source with:  . "$(dirname "$0")/../lib/text.sh"   (adjust depth to the caller)

# sp_trim <string>
# Strip leading and trailing whitespace. Pure parameter expansion: no subprocess, no
# quote semantics, no backslash interpretation. The string is returned byte-identical
# apart from the outer whitespace.
sp_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# sp_head <n> [string]
# Emit at most <n> lines. Reads the string argument if given, else stdin. Never SIGPIPEs
# its producer, so it is safe as the tail of a pipeline under `set -o pipefail`.
sp_head() {
  local n="$1"
  if [[ $# -ge 2 ]]; then
    awk -v n="$n" 'NR<=n' <<<"$2"
  else
    awk -v n="$n" 'NR<=n'
  fi
}

# sp_split_toplevel <string> [delims]
# Split on any character in <delims> (default "/,") that sits at parenthesis depth 0 and
# outside double quotes. One field per line.
#
# This is the difference between
#     "sett" (Norwegian for rep/set)   →   "sett" (Norwegian for rep  +  set)      [wrong]
# and
#     "sett" (Norwegian for rep/set)   →   "sett" (Norwegian for rep/set)          [right]
sp_split_toplevel() {
  local s="$1" delims="${2:-/,}"
  awk -v s="$s" -v delims="$delims" '
    BEGIN {
      depth = 0; inq = 0; field = ""
      n = length(s)
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "\"") { inq = !inq; field = field c; continue }
        if (!inq && c == "(") depth++
        else if (!inq && c == ")") { if (depth > 0) depth-- }
        if (!inq && depth == 0 && index(delims, c) > 0 && c != "") {
          print field; field = ""; continue
        }
        field = field c
      }
      print field
    }'
}

# sp_strip_qualifier <string>
# Remove ONE trailing parenthetical qualifier, whether or not it is italicised.
# A §7 row is written for a human reader:
#     "therapy" (as a claim)        → therapy
#     "session" (in marketing/UI)   → session
#     *(deprecated)* handled too
# The qualifier explains the ban to a reviewer; it is not part of the term to match.
# Only a BALANCED trailing group is removed — an unbalanced one is left in place so the
# caller's diagnostic can report it as a parse defect rather than silently swallowing it.
sp_strip_qualifier() {
  local s="$1"
  s="$(sp_trim "$s")"
  # italicised form first: *(...)$
  if [[ "$s" =~ ^(.*[^[:space:]])[[:space:]]*\*\([^\(\)]*\)\*$ ]]; then
    printf '%s' "$(sp_trim "${BASH_REMATCH[1]}")"; return
  fi
  # bare form: (...)$
  if [[ "$s" =~ ^(.*[^[:space:]])[[:space:]]*\([^\(\)]*\)$ ]]; then
    printf '%s' "$(sp_trim "${BASH_REMATCH[1]}")"; return
  fi
  printf '%s' "$s"
}

# sp_strip_decoration <string>
# Remove markdown/display decoration that is not part of the term itself: double quotes
# and code backticks. A §7 row writes `host` or "therapy" for the reader's benefit; the
# term to match against prose is the bare word (#83).
sp_strip_decoration() {
  local s="$1"
  s="${s//\"/}"
  s="${s//\`/}"
  printf '%s' "$s"
}

# sp_normalize_term <string>
# The full §7-cell → matchable-term pipeline, composed from the primitives above so every
# caller normalises identically: strip decoration, drop the trailing qualifier, trim.
# Returns the empty string for a cell that carries no term.
sp_normalize_term() {
  local s="$1"
  s="$(sp_strip_qualifier "$s")"
  s="$(sp_strip_decoration "$s")"
  sp_trim "$s"
}

# sp_parens_balanced <string>
# 0 when every "(" has a matching ")", 1 otherwise. An unbalanced term is the tell that a
# split shredded a parenthetical — such a term can never match real prose, and a gate that
# reports its zero hits as compliance is reporting a parse defect as a pass.
sp_parens_balanced() {
  local s="$1" i c depth=0
  for (( i=0; i<${#s}; i++ )); do
    c="${s:i:1}"
    [[ "$c" == "(" ]] && (( depth++ ))
    if [[ "$c" == ")" ]]; then
      (( depth-- ))
      (( depth < 0 )) && return 1
    fi
  done
  (( depth == 0 ))
}

# sp_match_exact <needle> <file>
# Fixed-string, whole-line match. No regex metacharacters, no substring false-positives.
# Use where the haystack holds one normalised token per line (e.g. `table:orders`), so
# `table:order` must NOT match. Where a line legitimately carries surrounding context,
# normalise both sides to a token first rather than reaching for a looser match.
sp_match_exact() {
  local needle="$1" file="$2"
  grep -qxF -- "$needle" "$file"
}
