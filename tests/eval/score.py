#!/usr/bin/env python3
"""Fail-closed A1-lite scorecard with an immutable comparison baseline."""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from collections import defaultdict
from pathlib import Path


def pct(numerator: int, denominator: int) -> float:
    return round(100.0 * numerator / max(denominator, 1), 1)


def _load_fixture_gate(eval_dir: Path):
    """Load fixture_gate.py from the CANDIDATE root being scored (--root), not
    from wherever score.py itself happens to live. A module-level `import
    fixture_gate` resolves via sys.path[0] (score.py's own directory), which is
    the SCORER's tree — so `score.py --root <other-tree> --check` (the exact
    invocation ADR-0011 documents, and what score.sh forwards "$@" into) would
    silently score the candidate's corpus against the scorer's own fixture
    rules, making any sabotage of the candidate's own fixture_gate.py (e.g.
    defect_present patched to always return True) invisible (v11 audit L7
    finding 4 repair, round 2). Loading by path off `eval_dir` (which is
    itself computed from `--root`) restores that: it is always the candidate
    tree's own rules being exercised against the candidate tree's own corpus."""
    module_path = eval_dir / "fixture_gate.py"
    if not module_path.is_file():
        print(f"A1_ERROR: fixture_gate.py not found under candidate root: {module_path}", file=sys.stderr)
        raise SystemExit(2)
    spec = importlib.util.spec_from_file_location("fixture_gate", module_path)
    if spec is None or spec.loader is None:
        print(f"A1_ERROR: cannot import fixture_gate.py from {module_path}", file=sys.stderr)
        raise SystemExit(2)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# Test-introspection hook: main() records the fixture_gate module it actually
# loaded from the candidate root here, so a caller running score.main() in-process
# (as score.test.sh's finding-7 cache-count test does) can inspect its
# skill_variants.cache_info() without racing a second, independently-cached load
# via a plain `import fixture_gate` (which would resolve a DIFFERENT module object
# via sys.path, not the candidate-rooted one main() used).
_LAST_FIXTURE_GATE = None


def main() -> int:
    global _LAST_FIXTURE_GATE
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--check", action="store_true", help="do not rewrite latest.md")
    args = parser.parse_args()

    root = args.root.resolve()
    eval_dir = root / "tests" / "eval"
    baseline_path = eval_dir / "reports" / "baseline.json"
    latest_path = eval_dir / "reports" / "latest.md"
    fixture_gate = _load_fixture_gate(eval_dir)
    _LAST_FIXTURE_GATE = fixture_gate

    try:
        baseline = json.loads(baseline_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        print(f"A1_ERROR: immutable baseline unavailable: {exc}", file=sys.stderr)
        return 2

    rows: list[dict[str, object]] = []
    by_class: dict[str, list[bool]] = defaultdict(list)
    harness_errors = 0
    expected_catches = caught_defects = 0
    expected_clean = clean_passes = 0

    for manifest_path in sorted((eval_dir / "fixtures").glob("*/manifest.json")):
        fixture = manifest_path.parent
        try:
            manifest = json.loads(manifest_path.read_text())
            fixture_id = manifest["id"]
            defect_class = manifest["class"]
            expect = manifest["expect"]
        except (OSError, KeyError, json.JSONDecodeError) as exc:
            print(f"A1_ERROR: invalid manifest {manifest_path}: {exc}", file=sys.stderr)
            return 2

        # In-process, not a subprocess spawn: the 12 fixtures share only 3
        # owning skills, and fixture_gate.skill_variants is memoized, so this
        # collapses 12 interpreter spawns + 12 corpus rebuilds per run to 0
        # spawns + 3 rebuilds.
        try:
            caught, harness_detail = fixture_gate.evaluate_fixture(fixture.resolve(), root)
        except Exception as exc:  # a harness crash is still a harness error, never a silent MISS
            caught, harness_detail = None, f"unexpected fixture_gate crash: {exc}"

        if caught is None:
            result = "ERROR"
            harness_errors += 1
        elif caught:
            result = "CATCH"
        else:
            result = "MISS"

        ok = (expect == "catch" and result == "CATCH") or (
            expect == "clean-pass" and result == "MISS"
        )
        by_class[defect_class].append(ok)
        if expect == "catch":
            expected_catches += 1
            caught_defects += int(result == "CATCH")
        elif expect == "clean-pass":
            expected_clean += 1
            clean_passes += int(result == "MISS")
        else:
            print(f"A1_ERROR: unknown expectation {expect!r} in {manifest_path}", file=sys.stderr)
            return 2

        detail = harness_detail.strip().replace("\n", " ") if result == "ERROR" else ""
        rows.append(
            {
                "id": fixture_id,
                "class": defect_class,
                "expect": expect,
                "result": result,
                "ok": ok,
                "detail": detail,
            }
        )

    correct = sum(int(row["ok"]) for row in rows)
    metrics = {
        "fixtures": len(rows),
        "correct": correct,
        "catch_rate_pct": pct(caught_defects, expected_catches),
        "clean_rate_pct": pct(clean_passes, expected_clean),
        "by_class_pct": {name: pct(sum(values), len(values)) for name, values in sorted(by_class.items())},
    }

    regressions: list[str] = []
    for key in ("correct", "catch_rate_pct", "clean_rate_pct"):
        if metrics[key] < baseline[key]:
            regressions.append(f"{key} {metrics[key]} < baseline {baseline[key]}")
    for defect_class, floor in baseline.get("by_class_pct", {}).items():
        actual = metrics["by_class_pct"].get(defect_class, 0.0)
        if actual < floor:
            regressions.append(f"{defect_class} {actual} < baseline {floor}")

    report = [
        "# A1-lite scorecard",
        "",
        "Candidate: current working tree (fixture rules + executable skill corpus)",
        "Baseline: immutable `reports/baseline.json`",
        "",
        "| Fixture | Class | Expect | Result | Verdict |",
        "|---------|-------|--------|--------|---------|",
    ]
    for row in rows:
        verdict = "PASS" if row["ok"] else "FAIL"
        if row["detail"]:
            verdict += f" ({row['detail']})"
        report.append(
            f"| {row['id']} | {row['class']} | {row['expect']} | {row['result']} | {verdict} |"
        )
    report.extend(
        [
            "",
            "## Summary",
            "",
            f"- fixtures: {metrics['fixtures']}",
            f"- correct: {metrics['correct']}",
            f"- incorrect: {metrics['fixtures'] - metrics['correct']}",
            f"- catch_rate_pct: {metrics['catch_rate_pct']}",
            f"- clean_rate_pct: {metrics['clean_rate_pct']}",
            f"- harness_errors: {harness_errors}",
            f"- regressions: {len(regressions)}",
        ]
    )
    report.extend(f"  - {item}" for item in regressions)
    report.extend(
        [
            "",
            "## Coverage (what this gate does and does not prove)",
            "",
            "- Every class's verdict is fixture_gate.py's own per-class regex"
            " (defect_present), never a shipped Speck validator's real exit code.",
            "- assert_corpus_anchor requires the instruction each class names to"
            " still be present in the real, router+contract-reachable skill text"
            " (checked per real session, not a flattened cross-session union).",
            "- assert_validator_alive additionally runs the shipped validator itself"
            " against a known-bad and a known-clean fixture and requires the real,"
            " behavior-appropriate exit code from both (not just a non-empty file) for:"
            f" {', '.join(sorted(fixture_gate.VALIDATOR_LIVENESS))}.",
            "- NOT validator-backed (corpus-anchor + fixture regex only, no"
            " shipped-script liveness check exists for these):"
            f" {', '.join(sorted(fixture_gate.NOT_VALIDATOR_BACKED))}.",
        ]
    )
    report.append("")
    rendered = "\n".join(report).rstrip() + "\n"
    print(rendered, end="")
    if not args.check:
        latest_path.write_text(rendered)

    if harness_errors or correct != len(rows) or regressions:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
