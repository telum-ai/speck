#!/usr/bin/env bash
# validate-harden-report.sh — structural validation for the harden report (issues #94, #99, #100 §1).
#
# WHY THIS FILE EXISTS AT ALL — this is the chokepoint, and without it the rest is decoration.
# Until now validate-template.sh routed `*harden-report*.md` to a branch that reads, verbatim:
#     harden-report|story-adjust-report|...)
#       # Passed placeholder check, no additional structural sub-validator needed
#       exit 0
# So a harden report was exempt from ALL structural validation. Any section #99 or #100 adds to
# harden-template.md would therefore have been unenforceable BY CONSTRUCTION: an agent could ship a
# report with §2b and the Mutation-Proof line simply deleted and every gate would stay green. That
# is the same defect these issues were filed about, one altitude up — a rule stated in a template
# cannot fail a build.
#
# It also carries the shared Mutation Record check for story/epic validation reports
# (`--mutation-record-only`), so the ONE primitive has ONE enforcement point rather than a second
# copy that drifts.
#
# VINTAGE BINDING — what is vintage-gated and what is NOT. Read the second paragraph: the base
# section assertions are a DELIBERATE, DISCLOSED break, not an oversight.
#
# NOT vintage-gated: the four base sections (§1 Defect Description, §2 Root Cause Analysis,
# §3 Remediations, §4 Readiness Re-assessment). They bind EVERY vintage, on purpose. Those four
# headings have been byte-identical in harden-template.md since the template was introduced in
# v7.13.0 (6703a4b), so every report any shipped template ever produced satisfies them; the only
# artifact this convicts is a HAND-WRITTEN report that never followed the structure — precisely
# what a validator that did not exist until now was missing. The blast radius is bounded because
# pre-commit-hook.sh validates only STAGED files: a legacy report sitting on disk blocks nothing
# until someone edits and re-stages it. Teams find any affected file with:
#   grep -rLE '^## 1\. Defect Description' --include='*harden-report*.md' specs/
#
# Vintage-gated: the v10 additions only.
# The new sections are required of a report that DECLARES itself v10-vintage (`mutation_record:
# required` or `speck_version: 10`+ in its frontmatter), of a report that CARRIES the v10 sections
# whatever it declares, and — see the next block — of a report that a v10 workspace is producing
# right now. Every report already on disk predates them and is exempt, which is why this change
# needs no data migration (see the report's migration_id justification). The exemption is
# deliberately keyed on a field NO migration backfills: `template_version` is backfilled to the
# current version by the v10 stamp migration, so keying on it would retroactively convict every
# pre-v10 artifact it touched.
#
# VINTAGE IS DERIVED WHERE IT CAN BE — self-declaration alone was trivially exploitable.
# VERIFIED live: deleting the single frontmatter line `mutation_record: required` and the `## 2b.`
# heading dropped a full v10 report to pre-v10, and every v10 rule silently became a NOTICE
# ("pre-v10 harden report … not required of it", EXIT=0). An author under a blocking pre-commit
# finds that in about a minute, and the result is indistinguishable from an honest legacy artifact.
# A vintage an author can delete is not a vintage.
#
# So vintage is also derived, from two facts read out of GIT rather than out of the artifact:
#   (a) the PROJECT's `.speck/VERSION` at the report's repository root — what workspace this is;
#   (b) whether the file is being AUTHORED NOW — untracked, or carrying uncommitted changes.
# Both true ⇒ v10-bound. Neither is a line that can be deleted from the report.
#
# THE EXCEPTION, and it is the one that keeps "no data migration needed" true: a file that is
# TRACKED and UNMODIFIED is an artifact already on disk, and keeps its self-declared vintage. Every
# pre-v10 report in every repo is exactly that, so none is retroactively convicted. It is not an
# escape: reaching tracked-and-unmodified requires having been committed, and at commit time the
# file is staged — authored-now — and therefore bound. (`--no-verify` still escapes, as it escapes
# every gate in the repo; that is a disclosed property of the hook boundary, not of this rule.)
#
# SECOND EXCEPTION, disclosed: outside a git repository neither fact is knowable, so the derivation
# is skipped and self-declaration stands. Leaving version control is not a quiet one-line edit, and
# an artifact outside git is not one the pre-commit boundary is ever asked about.
#
# This is the same break already taken for the base sections, extended consistently: editing and
# re-staging a legacy report brings it into scope. That was already true of §1–§4 above.
#
# Portable bash 3.2 / macOS.

set -euo pipefail

strict=false
mode="full"
file_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=true; shift ;;
    --mutation-record-only) mode="mutation-record"; shift ;;
    *)
      if [[ -z "$file_path" ]]; then file_path="$1"; else
        echo "ERROR: unknown or duplicate argument: $1" >&2; exit 64
      fi
      shift ;;
  esac
done

if [[ -z "$file_path" || ! -f "$file_path" ]]; then
  echo "Error: File path not specified or file does not exist." >&2
  exit 1
fi

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
errors=0

log_error() {
  echo -e "${RED}ERROR:${NC} $1" >&2
  [[ -n "${2:-}" ]] && echo -e "${BLUE}Fix:${NC} $2" >&2
  echo "" >&2
  errors=$((errors + 1))
}
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_notice()  { echo -e "${YELLOW}NOTICE:${NC} $1"; }

content="$(cat "$file_path")"

# --- vintage --------------------------------------------------------------------------------
# Frontmatter only (the first `---` block), so a report that merely QUOTES the field in prose
# does not opt itself in or out.
frontmatter="$(awk 'NR==1 && $0 ~ /^---[[:space:]]*$/ {inf=1; next} inf && $0 ~ /^---[[:space:]]*$/ {exit} inf {print}' "$file_path")"

bound=false
if grep -qE '^mutation_record:[[:space:]]*required[[:space:]]*$' <<<"$frontmatter"; then
  bound=true
fi
speck_major="$(grep -E '^speck_version:' <<<"$frontmatter" | head -n1 | sed -E 's/^speck_version:[[:space:]]*"?v?([0-9]+).*/\1/' || true)"
if [[ "$speck_major" =~ ^[0-9]+$ ]] && [[ "$speck_major" -ge 10 ]]; then
  bound=true
fi

# A report that carries the section headings but not the declaration cannot buy its way out by
# deleting one frontmatter line: having the section means being held to it.
if [[ "$bound" == false ]]; then
  if grep -qE '^## 2b\.|^## 🧬 Mutation Record' <<<"$content"; then
    bound=true
    log_notice "no v10 vintage declared, but the v10 sections are present — enforcing them anyway"
  fi
fi

# --- vintage DERIVED from the workspace (see VINTAGE BINDING above for why, and for the two
# --- exceptions this deliberately keeps).
file_dir="$(cd "$(dirname "$file_path")" && pwd)"
file_base="$(basename "$file_path")"
repo_root="$(git -C "$file_dir" rev-parse --show-toplevel 2>/dev/null || true)"

project_major=""
authored_now=false
if [[ -n "$repo_root" ]]; then
  if [[ -f "$repo_root/.speck/VERSION" ]]; then
    project_major="$(head -n1 "$repo_root/.speck/VERSION" | sed -E 's/^[[:space:]]*v?([0-9]+).*/\1/')"
  fi
  # Untracked = newly added, i.e. produced by THIS workspace. `ls-files --error-unmatch` is the
  # tracked/untracked question stated directly; `status --porcelain` on the same single pathspec
  # then answers "modified or staged". Both are scoped to the one file — a dirty sibling must never
  # change this file's vintage.
  if ! git -C "$file_dir" ls-files --error-unmatch -- "$file_base" >/dev/null 2>&1; then
    authored_now=true
  elif [[ -n "$(git -C "$file_dir" status --porcelain -- "$file_base" 2>/dev/null || true)" ]]; then
    authored_now=true
  fi
fi

if [[ "$bound" == false ]] \
   && [[ "$project_major" =~ ^[0-9]+$ ]] && [[ "$project_major" -ge 10 ]] \
   && [[ "$authored_now" == true ]]; then
  bound=true
  log_notice "no v10 vintage declared in the frontmatter, but .speck/VERSION says this is a v10 workspace (major $project_major) and this file is untracked or modified — it is being authored now, so its vintage is derived rather than self-declared"
fi

VERDICT_CODES='GUARD_MUTATION_PROVEN|GUARD_MUTATION_GREEN\.P2|GUARD_UNMUTATED\.P2'
CLASS_CODES='DEFECT-PINNING|DECISION-RECORD|SCOPE-NARROWING'

# A required field is FILLED when its line still carries none of the bracket placeholders the
# template ships. (The placeholder scanner in validate-template.sh catches those independently;
# this is the belt so a hand-written report is held to the same bar.)
line_for() {
  grep -nE "$1" <<<"$content" | head -n1 | cut -d: -f2- || true
}

check_mutation_record_section() {
  if ! grep -qE '^## 🧬 Mutation Record' <<<"$content"; then
    log_error "Missing the '## 🧬 Mutation Record' section" \
      "A guard is not evidence until someone watched it fail. Add the section from the template and fill one row per guard cited in the Evidence column, produced by .speck/scripts/validation/mutate-guard.sh."
    return 0
  fi
  log_success "Mutation Record section present"
  local body rows row last_cell n_rows bad_rows
  body="$(awk '/^## 🧬 Mutation Record/{f=1; next} f && /^## /{exit} f {print}' <<<"$content")"

  # READ THE ROWS, NEVER THE SECTION BODY.
  # A body-wide grep for the verdict codes was vacuous by construction: both validation-report
  # templates ship a prose paragraph INSIDE this section that names all three codes —
  #   **Verdicts.** `GUARD_MUTATION_PROVEN` · `GUARD_MUTATION_GREEN.P2` … `GUARD_UNMUTATED.P2` …
  # — so the check passed on every report the shipped template produces, whatever the author wrote
  # in the table. A row reading `| n/a | n/a | n/a | n/a | n/a | looks fine to me |` was accepted.
  # A verdict is a CELL a script printed, so a cell is what gets read: the LAST cell of every DATA
  # row (header rows and the `|---|` separator excluded; prose lines ignored entirely).
  rows="$(awk '
    /^[[:space:]]*\|/ {
      if ($0 ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/) { sep = 1; next }
      if (sep) print
      next
    }
    { sep = 0 }
  ' <<<"$body")"

  n_rows=0
  bad_rows=0
  while IFS= read -r row; do
    [[ -z "${row//[[:space:]]/}" ]] && continue
    n_rows=$((n_rows + 1))
    last_cell="$(awk -F'|' '{ for (i = NF; i >= 1; i--) { c = $i; gsub(/^[[:space:]`*]+|[[:space:]`*]+$/, "", c); if (c != "") { print c; exit } } }' <<<"$row")"
    if ! grep -qE "^($VERDICT_CODES)$" <<<"$last_cell"; then
      bad_rows=$((bad_rows + 1))
    fi
  done <<<"$rows"

  if [[ "$n_rows" -eq 0 ]]; then
    log_error "The Mutation Record has no rows" \
      "The section is the table, not the prose around it. Add one row per guard cited in the Evidence column, produced by .speck/scripts/validation/mutate-guard.sh."
  elif [[ "$bad_rows" -gt 0 ]]; then
    log_error "$bad_rows Mutation Record row(s) do not end in a verdict code" \
      "Every row's LAST cell is a code TRANSCRIBED from mutate-guard.sh: GUARD_MUTATION_PROVEN, GUARD_MUTATION_GREEN.P2 or GUARD_UNMUTATED.P2. A hand-typed judgement is not a verdict, and the codes named in the section's own Verdicts paragraph are documentation, not evidence."
  else
    log_success "every Mutation Record row ends in a machine-emitted verdict code ($n_rows row(s))"
  fi
  return 0
}

if [[ "$mode" == "mutation-record" ]]; then
  if [[ "$bound" == false ]]; then
    log_notice "pre-v10 validation report — the Mutation Record section is not required of it"
  else
    check_mutation_record_section
  fi
else
  # --- full harden-report structure ----------------------------------------------------------
  # The four pre-existing sections, asserted for the first time (this artifact had no structural
  # validator at all until now).
  for sec in '^## 1\. Defect Description' '^## 2\. Root Cause Analysis' '^## 3\. Remediations' '^## 4\. Readiness Re-assessment'; do
    if grep -qE "$sec" <<<"$content"; then
      log_success "section present: $(sed -E 's/[\^$\\]//g; s/\.\*//g' <<<"$sec")"
    else
      log_error "Missing required harden-report section matching: $sec" \
        "Regenerate the report from .speck/templates/project/harden-template.md — do not hand-write around the structure."
    fi
  done

  if [[ "$bound" == false ]]; then
    log_notice "pre-v10 harden report (no 'mutation_record: required' and speck_version < 10) — §2b and the Mutation-Proof line are not required of it. Regenerate from the current template to opt in."
  else
    # §2b — the counter-test sweep (#99). The sweep is a STEP THAT CALLS the primitive, so what is
    # enforced here is the evidence it produces, not the intention to run it.
    if grep -qE '^## 2b\.' <<<"$content"; then
      log_success "section present: 2b. Counter-Tests"
      local_body="$(awk '/^## 2b\./{f=1; next} f && /^## /{exit} f {print}' <<<"$content")"
      for label in 'Pre-Fix Grep' 'Pre-Existing Tests That Went Red' 'If None Went Red'; do
        if ! grep -qiE "\*\*$label\*\*" <<<"$local_body"; then
          log_error "§2b is missing the required field: **$label**" \
            "All three fields are required. The sweep is: before writing the fix, grep the suite for assertions naming the OLD behaviour; after the fix, list every PRE-EXISTING test that went red."
        fi
      done
      # Either at least one counter-test is classified, or the zero-red sentence is answered.
      # #99's second law: a fix that turns nothing red is suspect — so the honest reason is
      # mandatory, and the honest exception (a genuinely uncovered path) is itself a finding.
      #
      # READ THE AUTHORED CELL, NEVER THE SECTION BODY.
      # A body-wide grep for the class literals was vacuous by construction: §2b of
      # harden-template.md explains the three classes in its own bullets —
      #   - `DEFECT-PINNING` — the assertion encodes the bug. …
      # — so has_class was true on EVERY template-derived report regardless of what the author
      # wrote. A report whose cells read `none` / `n/a` passed. Line-scoped exactly like the
      # **Guardrail Mutation-Proof** check below, which is why that one is not vacuous.
      red_line="$(grep -iE '\*\*Pre-Existing Tests That Went Red\*\*' <<<"$local_body" | head -n1 || true)"
      red_cell="${red_line#*:}"
      # NOTHING-SYNONYM MATCHING, DELIBERATELY FORGIVING.
      # The old list matched only exact tokens (none / n-a / nil / nothing / - / not applicable), so
      # an honest author writing `Pre-Existing Tests That Went Red: None went red` was CONVICTED
      # with "names pre-existing tests but classifies none of them" — VERIFIED live. A gate that
      # convicts an honest author teaches people to game it, which costs more than the leniency it
      # was buying. So: normalise, drop a trailing "went red"-shaped predicate that adds no claim,
      # then match the nothing-tokens WITH their natural qualifiers.
      # ASCII-only deletions: a bracket expression containing a multibyte glyph splits into its
      # bytes under LC_ALL=C and would chew unrelated UTF-8. The dash synonyms below are matched as
      # whole literals in an alternation, never inside a bracket expression, for the same reason.
      red_cell_norm="$(tr -d '`*_' <<<"$red_cell" | tr '[:upper:]' '[:lower:]')"
      red_cell_norm="$(sed -E 's/[[:space:]]+/ /g; s/^ +//; s/ +$//; s/[.!]+$//' <<<"$red_cell_norm")"
      red_cell_norm="$(sed -E 's/ ?(that )?(went|were|was|are|is|turned|came back) red$//' <<<"$red_cell_norm")"
      red_cell_norm="$(sed -E 's/^(no|none|nil|nothing|n\/a|na|not applicable|-|—|–)( of (them|these))?( (pre-existing|preexisting|existing))?( tests?)?$/NOTHING/' <<<"$red_cell_norm")"
      # The cell is a CLAIM unless it is empty or an explicit nothing — only then does the
      # zero-red sentence become the thing that answers §2b. Anything left unmatched stays a CLAIM,
      # which is the safe direction: it demands a classification rather than granting an exemption.
      claims_red=true
      case "$red_cell_norm" in
        ''|NOTHING) claims_red=false ;;
      esac
      has_class=false
      if [[ "$claims_red" == true ]] && grep -qE "($CLASS_CODES)" <<<"$red_cell"; then
        has_class=true
      fi
      zero_red_line="$(grep -iE '\*\*If None Went Red\*\*' <<<"$local_body" | head -n1 || true)"
      zero_red_answered=false
      because_words=0
      if [[ -n "$zero_red_line" ]] && ! grep -qE '\[[A-Z][A-Z0-9_ ]+\]' <<<"$zero_red_line"; then
        # "answered" = the line says WHY, in prose, with no bracket placeholder left on it. The
        # word `because` is not the sentence: VERIFIED live, `**If None Went Red**: because` PASSED,
        # because the whole check was `grep -qiE 'because'` plus the placeholder scan. Count what
        # actually FOLLOWS the first `because`; three real words is the floor at which the line can
        # carry a reason at all, and it is the control point for this rule.
        because_words="$(awk '
          { l = tolower($0); i = index(l, "because"); if (i == 0) next; $0 = substr($0, i + 7) }
          { for (j = 1; j <= NF; j++) if ($j ~ /[[:alnum:]]/) n++ }
          END { print n + 0 }' <<<"$zero_red_line")"
        if [[ "$because_words" -ge 3 ]]; then
          zero_red_answered=true
        fi
      fi
      if [[ "$claims_red" == true && "$has_class" == false ]]; then
        log_error "§2b names pre-existing tests that went red but classifies none of them" \
          "Every entry on the **Pre-Existing Tests That Went Red** line carries its class: DEFECT-PINNING, DECISION-RECORD or SCOPE-NARROWING. The class IS the finding — an unclassified red test is the one someone deletes to get green. If nothing went red, say so on this line and answer **If None Went Red**; the accepted forms are 'none', 'nothing', 'nil', 'n/a', 'not applicable', '-', or any of those followed by 'went red' (e.g. 'none went red', 'no pre-existing tests went red')."
      elif [[ "$has_class" == false && "$zero_red_answered" == false ]]; then
        log_error "§2b answers neither branch: no counter-test is classified, and the zero-red sentence is unanswered" \
          "Either classify each pre-existing test that went red as DEFECT-PINNING, DECISION-RECORD or SCOPE-NARROWING, or complete 'No pre-existing test went red, because …' with a real reason — at least three words after 'because', since the bare word is not the sentence. A fix that turns nothing red is suspect: the two causes — a genuinely uncovered path, or a fix that does not do what its author thinks — look identical in a report. The requirement is the sentence, never a hunt for something to break."
      else
        log_success "§2b answers the counter-test sweep"
      fi
    else
      log_error "Missing required section '## 2b. Counter-Tests (The Suite's Shadow)'" \
        "Every defect has a shadow: the tests written against the buggy code. Add §2b from .speck/templates/project/harden-template.md."
    fi

    # §3 — the mutation proof on the guardrail itself (#94).
    sec3="$(awk '/^## 3\. Remediations/{f=1; next} f && /^## /{exit} f {print}' <<<"$content")"
    if ! grep -qE '\*\*Guardrail Mutation-Proof\*\*' <<<"$sec3"; then
      log_error "§3 is missing the required field: **Guardrail Mutation-Proof**" \
        "A guardrail cited as the reason this defect cannot recur is a claim until someone watched it fail. Run .speck/scripts/validation/mutate-guard.sh and transcribe its SPECK_MUTATION_* output."
    else
      proof_line="$(grep -E '\*\*Guardrail Mutation-Proof\*\*' <<<"$sec3" | head -n1)"
      if ! grep -qE "($VERDICT_CODES)" <<<"$proof_line"; then
        log_error "The **Guardrail Mutation-Proof** line carries no verdict code" \
          "The line must end in the code mutate-guard.sh PRINTED: GUARD_MUTATION_PROVEN, GUARD_MUTATION_GREEN.P2 or GUARD_UNMUTATED.P2. GUARD_MUTATION_GREEN.P2 is honest and non-blocking — record it green and write the scope onto the test rather than tuning the mutation until it reddens."
      else
        log_success "§3 carries a machine-emitted mutation verdict"
      fi
    fi

    # §3 — the class-recurrence check (#100 §1). The second instance means the enforcement point
    # is wrong, not that a site was missed.
    if ! grep -qE '\*\*Class Recurrence Check\*\*' <<<"$sec3"; then
      log_error "§3 is missing the required field: **Class Recurrence Check**" \
        "Answer 'is this an instance of a class?' by searching for the syntactic SHAPE, not for the identifier that happened to be wrong. On a second instance the required deliverable becomes a chokepoint gate, not a third instance fix."
    else
      log_success "§3 carries the class-recurrence check"
    fi
  fi
fi

if [[ "$errors" -gt 0 ]]; then
  if [[ "$strict" == true ]]; then
    echo -e "${RED}Validation FAILED with $errors error(s).${NC}" >&2
    exit 1
  fi
  echo -e "${YELLOW}Validation completed with $errors error(s) (ignored without --strict).${NC}"
fi

echo -e "${GREEN}Validation PASSED.${NC}"
exit 0
