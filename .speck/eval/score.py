#!/usr/bin/env python3
"""Fail-closed A1-lite scorecard with an immutable comparison baseline."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


def pct(numerator: int, denominator: int) -> float:
    return round(100.0 * numerator / max(denominator, 1), 1)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--check", action="store_true", help="do not rewrite latest.md")
    args = parser.parse_args()

    root = args.root.resolve()
    eval_dir = root / ".speck" / "eval"
    fixture_gate = eval_dir / "fixture_gate.py"
    baseline_path = eval_dir / "reports" / "baseline.json"
    latest_path = eval_dir / "reports" / "latest.md"

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

        run = subprocess.run(
            [sys.executable, str(fixture_gate), "--root", str(root), str(fixture)],
            text=True,
            capture_output=True,
            check=False,
        )
        if run.returncode == 0:
            result = "CATCH"
        elif run.returncode == 1:
            result = "MISS"
        else:
            result = "ERROR"
            harness_errors += 1

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

        detail = run.stderr.strip().replace("\n", " ") if result == "ERROR" else ""
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
        "Candidate: current working tree (fixture rules + owning skill corpus)",
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
    report.append("")
    rendered = "\n".join(report) + "\n"
    print(rendered, end="")
    if not args.check:
        latest_path.write_text(rendered)

    if harness_errors or correct != len(rows) or regressions:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
