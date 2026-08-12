#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Test: live candidate clears immutable baseline"
bash "$ROOT/tests/eval/score.sh" --check >/dev/null

TMP="$(mktemp -d)"
cleanup_tmp() {
  [[ -d "$TMP" ]] || return 0
  find "$TMP" -depth -mindepth 1 -delete
  rmdir "$TMP"
}
trap cleanup_tmp EXIT

build_scratch_repo() {
  # $1 = destination dir. A minimal but complete copy: everything
  # fixture_gate.py's real-loader delegation (speck_context, _corpus_budget_lib,
  # the three liveness-checked validators) needs to resolve without error.
  local dest="$1"
  mkdir -p "$dest/.speck" "$dest/.cursor" "$dest/tests"
  cp -R "$ROOT/tests/eval" "$dest/tests/eval"
  mkdir -p "$dest/.speck/reference" "$dest/.speck/templates"
  cp "$ROOT/.speck/reference/skill-load-contracts.json" "$dest/.speck/reference/skill-load-contracts.json"
  cp -R "$ROOT/.speck/templates/." "$dest/.speck/templates/"
  cp -R "$ROOT/.speck/scripts" "$dest/.speck/scripts"
  cp -R "$ROOT/.cursor/skills" "$dest/.cursor/skills"
}

build_scratch_repo "$TMP"

before="$(shasum -a 256 "$TMP/tests/eval/reports/baseline.json" | awk '{print $1}')"
bash "$TMP/tests/eval/score.sh" --root "$TMP" >/dev/null
after="$(shasum -a 256 "$TMP/tests/eval/reports/baseline.json" | awk '{print $1}')"
[[ "$before" == "$after" ]] || { echo "FAIL: score run mutated immutable baseline"; exit 1; }

echo "Test: moving a capability to an unreachable node turns the score red"
python3 - "$TMP" <<'PY'
from pathlib import Path
import json, re, sys
root = Path(sys.argv[1])
skill = root / ".cursor/skills/story-validate"
paths = set(skill.rglob("*.md"))
contracts = json.loads((root / ".speck/reference/skill-load-contracts.json").read_text())
for profile in contracts["profiles"].values():
    if profile.get("entrypoint") != ".cursor/skills/story-validate/SKILL.md":
        continue
    paths.update(root / rel for rel in profile.get("required_files", []))
    for selector in profile.get("selectors", {}).values():
        for value in selector.get("values", {}).values():
            paths.update(root / rel for rel in value.get("required_files", []))
for path in paths:
    text = path.read_text()
    text = re.sub(r"IS-IT-GOOD|adjudicat(?:e|ed|ion)?", "quality-check-removed", text, flags=re.I)
    path.write_text(text)
(skill / "references" / "unreachable-anchor.md").write_text("# unreachable\nadjudicate\n")
PY
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score counted a capability outside the router-reachable corpus"
  exit 1
fi

echo "Test: an incorrect fixture verdict is blocking"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
python3 - "$TMP/tests/eval/fixtures/bl-leak/manifest.json" <<'PY'
from pathlib import Path
import json, sys
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data["expect"] = "clean-pass"
path.write_text(json.dumps(data, indent=2) + "\n")
PY
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score exited green with an incorrect fixture verdict"
  exit 1
fi

echo "Test: fabricated-evidence anchor requires a real citation word, not bare 'path' (v11 audit L7 finding 1)"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
python3 - "$TMP" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
targets = list((root / ".cursor/skills/story-validate").rglob("*.md"))
targets += list((root / ".speck/templates/story").glob("*.md"))
pat = re.compile(r"cit(?:e|ation|ed|ing|es)", re.I)
scrubbed = 0
for path in targets:
    text = path.read_text()
    new = pat.sub("REMOVED", text)
    if new != text:
        path.write_text(new)
        scrubbed += 1
assert scrubbed > 0, "expected at least one citation instruction to scrub"
PY
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score stayed green after every citation instruction was scrubbed from story-validate (the bare-'path' loophole regressed)"
  exit 1
fi

echo "Test: blanking a shipped validator body turns the score red (v11 audit L7 findings 2 and 5)"
for rel in ".speck/scripts/banned-language-lint.sh" \
           ".speck/scripts/validation/validators/validate-evidence-citations.sh" \
           ".speck/scripts/validation/validators/validate-traceability-matrix.sh"; do
  cleanup_tmp
  TMP="$(mktemp -d)"
  build_scratch_repo "$TMP"
  : > "$TMP/$rel"
  if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: score stayed green after $rel was blanked"
    exit 1
  fi
done

echo "Test: a contract schema_version bump errors instead of silently resolving stale files (v11 audit L7 finding 3)"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
python3 - "$TMP/.speck/reference/skill-load-contracts.json" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data["schema_version"] = 2
path.write_text(json.dumps(data, indent=2) + "\n")
PY
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score stayed green against a schema_version=2 contract the real loader refuses"
  exit 1
fi

echo "Test: fixture_gate.py delegates router reachability instead of a second definition (v11 audit L7 finding 4)"
if grep -q "def router_owns_ref" "$ROOT/tests/eval/fixture_gate.py"; then
  echo "FAIL: fixture_gate.py re-defines router_owns_ref instead of reusing _corpus_budget_lib's"
  exit 1
fi
if ! grep -q "_corpus_budget_lib" "$ROOT/tests/eval/fixture_gate.py"; then
  echo "FAIL: fixture_gate.py no longer imports _corpus_budget_lib"
  exit 1
fi

echo "Test: score.py builds each owning skill's corpus once per run, not once per fixture (v11 audit L7 finding 7)"
python3 - "$ROOT" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "tests" / "eval"))
import score

sys.argv = ["score.py", "--root", str(root), "--check"]
rc = score.main()
# score.py loads fixture_gate.py off the CANDIDATE root itself (--root), not via a
# plain `import fixture_gate` resolved against this test's own sys.path — those are
# two DIFFERENT module objects with two different lru_caches, so cache_info() has to
# come from the module score.main() actually used (v11 audit L7 finding 4 repair,
# round 2 introduced this hook; see score._LAST_FIXTURE_GATE).
fixture_gate = score._LAST_FIXTURE_GATE
info = fixture_gate.skill_variants.cache_info()
try:
    assert rc == 0, f"score.sh --check failed against the live repo: rc={rc}"
    assert info.misses == 3, f"expected 3 real corpus builds (one per owning skill), got {info}"
    assert info.hits == 9, f"expected 9 cache hits (12 fixtures - 3 owning skills), got {info}"
except AssertionError as exc:
    print(f"FAIL: {exc}")
    sys.exit(1)
print(f"OK: skill_variants {info} (12 fixtures -> {info.misses} real builds, was 12 subprocess spawns before)")
PY

echo "Test: a NEUTERED validator (padded 'exit 0' stub, not truncated to zero bytes) turns the score red (v11 audit L7 finding 2/5 repair, round 2)"
for rel in ".speck/scripts/banned-language-lint.sh" \
           ".speck/scripts/validation/validators/validate-evidence-citations.sh" \
           ".speck/scripts/validation/validators/validate-traceability-matrix.sh"; do
  cleanup_tmp
  TMP="$(mktemp -d)"
  build_scratch_repo "$TMP"
  {
    echo '#!/usr/bin/env bash'
    echo '# padding padding padding padding padding padding padding padding padding'
    echo '# padding padding padding padding padding padding padding padding padding'
    echo '# padding padding padding padding padding padding padding padding padding'
    echo 'exit 0'
  } > "$TMP/$rel"
  bytes="$(wc -c < "$TMP/$rel" | tr -d ' ')"
  [[ "$bytes" -gt 200 ]] || { echo "FAIL: neuter fixture for $rel is not >200 bytes (got $bytes)"; exit 1; }
  if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: score stayed green after $rel was neutered to a padded no-op (still >MIN_VALIDATOR_CHARS)"
    exit 1
  fi
done

echo "Test: an 'always fail' validator stub also turns the score red, not just an 'always pass' one (neighbouring input to the above)"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
{
  echo '#!/usr/bin/env bash'
  echo '# padding padding padding padding padding padding padding padding padding'
  echo '# padding padding padding padding padding padding padding padding padding'
  echo '# padding padding padding padding padding padding padding padding padding'
  echo 'exit 1'
} > "$TMP/.speck/scripts/banned-language-lint.sh"
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score stayed green with an 'always fail' banned-language-lint.sh stub (liveness probe must check the clean-fixture direction too)"
  exit 1
fi

echo "Test: fabricated-evidence anchor still requires a real citation word when the escape word is 'excited', not 'path' (v11 audit L7 finding 1 repair, round 2)"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
python3 - "$TMP" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
targets = list((root / ".cursor/skills/story-validate").rglob("*.md"))
targets += list((root / ".speck/templates/story").glob("*.md"))
pat = re.compile(r"cit(?:e|ation|ed|ing|es)", re.I)
scrubbed = 0
for path in targets:
    text = path.read_text()
    new = pat.sub("REMOVED", text)
    if new != text:
        path.write_text(new)
        scrubbed += 1
assert scrubbed > 0, "expected at least one citation instruction to scrub"
skill_md = root / ".cursor/skills/story-validate/SKILL.md"
skill_md.write_text(skill_md.read_text() + "\n<!-- We are excited to close this story. -->\n")
PY
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score stayed green after every real citation instruction was scrubbed and only an incidental 'excited' word remained"
  exit 1
fi

echo "Test: the fabricated-evidence anchor is checked per SINGLE session, not as an OR across mutually exclusive sessions (v11 audit L7 finding 3 repair, round 2)"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
# references/visual.md is required_files ONLY for the story-validate-ui contract
# profile (7 of the 14 sessions); references/backend-skip.md is required_files
# ONLY for story-validate-backend (the other 7). No session ever loads both. Scrub
# every real 'evidence'/citation-word instance from the whole reachable corpus
# (story-validate/** + all templates/**, matching the reviewer's exact scope) and
# put 'evidence' back ONLY in the ui-only file and a citation word back ONLY in
# the backend-only file, so the two anchors are satisfiable only by DIFFERENT,
# mutually exclusive sessions -- never by any one real session together.
python3 - "$TMP" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
targets = list((root / ".cursor/skills/story-validate").rglob("*.md"))
targets += list((root / ".speck/templates").rglob("*.md"))
evidence_pat = re.compile(r"evidence", re.I)
cite_pat = re.compile(r"\bcit(?:e|ed|es|ing|ation|ations)\b", re.I)
for path in targets:
    text = path.read_text()
    new = evidence_pat.sub("REDACTED", text)
    new = cite_pat.sub("REDACTED", new)
    if new != text:
        path.write_text(new)
visual = root / ".cursor/skills/story-validate/references/visual.md"
visual.write_text(visual.read_text() + "\nThis screen shows solid evidence of quality.\n")
backend = root / ".cursor/skills/story-validate/references/backend-skip.md"
backend.write_text(backend.read_text() + "\nThe fact above is cited from the API log.\n")
PY
if bash "$TMP/tests/eval/score.sh" --check --root "$TMP" >/dev/null 2>&1; then
  echo "FAIL: score stayed green with 'evidence' only in a UI-profile-only session and a citation word only in a mutually exclusive backend-profile-only session"
  exit 1
fi

echo "Test: score.py --root <candidate> scores the CANDIDATE's own fixture_gate.py, not the caller's (v11 audit L7 finding 4 repair, round 2)"
cleanup_tmp
TMP="$(mktemp -d)"
build_scratch_repo "$TMP"
python3 - "$TMP/tests/eval/fixture_gate.py" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
marker = "def defect_present(fixture: Path, defect_class: str) -> bool:"
assert marker in text, "defect_present signature not found to sabotage"
text = text.replace(marker, marker + "\n    return True  # SABOTAGE: liveness-probe regression test", 1)
path.write_text(text)
PY
# (a) the candidate's own score.sh (cwd inside the candidate, or --root pointing at
# itself) must catch its own sabotage: every clean-pass fixture is now misjudged CATCH.
if bash "$TMP/tests/eval/score.sh" --root "$TMP" --check >/dev/null 2>&1; then
  echo "FAIL: candidate's own score.sh did not catch a sabotaged defect_present"
  exit 1
fi
# (b) score.py run from THIS repo with --root pointing at the sabotaged candidate tree
# must ALSO catch it. Before the fix, a module-level `import fixture_gate` resolved
# THIS repo's own (honest) fixture_gate.py regardless of --root, so the sabotage never
# reached the scorer and this exited 0 — invisible.
if python3 "$ROOT/tests/eval/score.py" --root "$TMP" --check >/dev/null 2>&1; then
  echo "FAIL: score.py --root <sabotaged-tree> used its own fixture_gate.py instead of the candidate's (sabotage invisible)"
  exit 1
fi

echo "A1-lite score tests passed"
