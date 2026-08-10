#!/usr/bin/env python3
"""Catalog-only skill-routing evaluator for ADR-0008."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
CASES_PATH = ROOT / ".speck/reference/skill-routing-cases.json"
SKILLS_ROOT = ROOT / ".cursor/skills"
REPORTS_ROOT = ROOT / ".speck/eval/skill-routing/reports"


def parse_frontmatter(text: str) -> str:
    match = re.match(r"^---\n(.*?)\n---", text, re.S)
    return match.group(1) if match else ""


def field(frontmatter: str, key: str) -> str:
    match = re.search(rf"^{re.escape(key)}:\s*(.+?)\s*$", frontmatter, re.M)
    return match.group(1) if match else ""


def load_catalog(root: Path = ROOT) -> dict[str, str]:
    catalog: dict[str, str] = {}
    for path in sorted((root / ".cursor/skills").glob("*/SKILL.md")):
        frontmatter = parse_frontmatter(path.read_text())
        if re.search(r"^disable-model-invocation:\s*true\s*$", frontmatter, re.M):
            continue
        name = field(frontmatter, "name")
        description = field(frontmatter, "description")
        if name:
            catalog[name] = description
    return catalog


def load_cases(path: Path = CASES_PATH) -> dict[str, Any]:
    return json.loads(path.read_text())


def validate_suite(catalog: dict[str, str], suite: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if suite.get("schema_version") != 1:
        errors.append("routing suite requires schema_version 1")
    minimum = suite.get("minimum_accuracy")
    if not isinstance(minimum, (int, float)) or not 0 < float(minimum) <= 1:
        errors.append("minimum_accuracy must be in (0, 1]")
    cases = suite.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["routing suite requires a non-empty cases list"]

    seen_ids: set[str] = set()
    covered: set[str] = set()
    for index, case in enumerate(cases):
        if not isinstance(case, dict):
            errors.append(f"case {index} must be an object")
            continue
        case_id = case.get("id")
        prompt = case.get("prompt")
        expect = case.get("expect")
        forbid = case.get("forbid")
        if not isinstance(case_id, str) or not case_id or case_id in seen_ids:
            errors.append(f"invalid or duplicate case id: {case_id!r}")
        else:
            seen_ids.add(case_id)
        if not isinstance(prompt, str) or len(prompt.strip()) < 40:
            errors.append(f"case {case_id!r} prompt must be at least 40 characters")
        if not isinstance(expect, str) or expect not in catalog:
            errors.append(f"case {case_id!r} expects non-automatic skill {expect!r}")
        else:
            covered.add(expect)
            if isinstance(prompt, str) and expect.lower() in prompt.lower():
                errors.append(f"case {case_id!r} leaks expected skill name {expect!r} in its prompt")
        if not isinstance(forbid, list) or not forbid or not all(isinstance(x, str) for x in forbid):
            errors.append(f"case {case_id!r} requires a non-empty forbid list")
        else:
            invalid = sorted(set(forbid) - set(catalog))
            if invalid:
                errors.append(f"case {case_id!r} forbids non-automatic skills: {invalid}")
            if expect in forbid:
                errors.append(f"case {case_id!r} forbids its expected skill")

    missing = sorted(set(catalog) - covered)
    extra = sorted(covered - set(catalog))
    if missing:
        errors.append(f"automatic skills missing routing cases: {missing}")
    if extra:
        errors.append(f"routing cases cover non-catalog skills: {extra}")
    return errors


def output_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "predictions": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "id": {"type": "string"},
                        "skill": {"type": "string"},
                    },
                    "required": ["id", "skill"],
                },
            }
        },
        "required": ["predictions"],
    }


def build_prompt(catalog: dict[str, str], suite: dict[str, Any]) -> str:
    catalog_lines = "\n".join(f"- {name}: {description}" for name, description in sorted(catalog.items()))
    request_lines = "\n".join(
        f"- {case['id']}: {case['prompt']}" for case in suite["cases"]
    )
    return f"""You are evaluating an automatic Agent Skill catalog.

Choose exactly one catalog skill for every request using only each skill's name and description. Select the skill whose advertised trigger best matches the request's intent and lifecycle state. Do not invent skills, use implementation knowledge, or perform the requested work.

Return only the JSON object required by the response schema. Include every request id exactly once and preserve the request order.

CATALOG
{catalog_lines}

REQUESTS
{request_lines}
"""


def normalize_predictions(data: Any) -> list[dict[str, str]]:
    if isinstance(data, dict) and isinstance(data.get("structured_output"), dict):
        data = data["structured_output"]
    if isinstance(data, dict) and isinstance(data.get("result"), str):
        try:
            raw = data["result"].strip()
            if raw.startswith("```json") and raw.endswith("```"):
                raw = raw[7:-3].strip()
            elif raw.startswith("```") and raw.endswith("```"):
                raw = raw[3:-3].strip()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                object_match = re.search(r"\{.*\}", raw, re.S)
                if not object_match:
                    raise
                data = json.loads(object_match.group(0))
        except json.JSONDecodeError:
            pass
    rows = None
    if isinstance(data, dict):
        for key in ("predictions", "selections", "results"):
            if isinstance(data.get(key), list):
                rows = data[key]
                break
        if rows is None and isinstance(data.get("details"), list):
            rows = [
                {"id": row.get("id"), "skill": row.get("actual")}
                for row in data["details"]
                if isinstance(row, dict)
            ]
        if rows is None:
            list_values = [value for value in data.values() if isinstance(value, list)]
            if len(list_values) == 1:
                rows = list_values[0]
        if rows is None and data and all(isinstance(key, str) and isinstance(value, str) for key, value in data.items()):
            rows = [{"id": key, "skill": value} for key, value in data.items()]
    return rows if isinstance(rows, list) else []


def score_predictions(
    catalog: dict[str, str], suite: dict[str, Any], prediction_data: Any
) -> dict[str, Any]:
    predictions = normalize_predictions(prediction_data)
    by_id: dict[str, str] = {}
    duplicates: list[str] = []
    malformed = 0
    for row in predictions:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not isinstance(row.get("skill"), str):
            malformed += 1
            continue
        case_id = row["id"]
        if case_id in by_id:
            duplicates.append(case_id)
        by_id[case_id] = row["skill"]

    details: list[dict[str, Any]] = []
    correct = 0
    forbidden = 0
    case_ids = {case["id"] for case in suite["cases"]}
    for case in suite["cases"]:
        actual = by_id.get(case["id"])
        exact = actual == case["expect"]
        is_forbidden = actual in case["forbid"]
        correct += int(exact)
        forbidden += int(is_forbidden)
        details.append(
            {
                "id": case["id"],
                "expected": case["expect"],
                "actual": actual,
                "exact": exact,
                "forbidden": is_forbidden,
            }
        )

    total = len(suite["cases"])
    accuracy = correct / total if total else 0.0
    missing = sorted(case_ids - set(by_id))
    extra = sorted(set(by_id) - case_ids)
    threshold = float(suite["minimum_accuracy"])
    passed = (
        accuracy >= threshold
        and forbidden == 0
        and not missing
        and not extra
        and not duplicates
        and malformed == 0
        and all(skill in catalog for skill in by_id.values())
    )
    return {
        "pass": passed,
        "accuracy": round(accuracy, 6),
        "minimum_accuracy": threshold,
        "correct": correct,
        "total": total,
        "forbidden_selections": forbidden,
        "missing_ids": missing,
        "extra_ids": extra,
        "duplicate_ids": sorted(set(duplicates)),
        "malformed_predictions": malformed,
        "unknown_skills": sorted({skill for skill in by_id.values() if skill not in catalog}),
        "details": details,
    }


def digest(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def verify_reports(
    catalog: dict[str, str], suite: dict[str, Any], reports_dir: Path
) -> list[str]:
    """Re-score checked-in live evidence and reject stale or incomplete receipts."""
    errors: list[str] = []
    paths = sorted(reports_dir.glob("*.json"))
    if not paths:
        return [f"no routing reports found in {reports_dir}"]

    catalog_hash = digest(catalog)
    cases_hash = digest(suite)
    score_keys = (
        "pass", "accuracy", "minimum_accuracy", "correct", "total",
        "forbidden_selections", "missing_ids", "extra_ids", "duplicate_ids",
        "malformed_predictions", "unknown_skills", "details",
    )
    for path in paths:
        try:
            report = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path.name}: unreadable report: {exc}")
            continue
        if not isinstance(report, dict):
            errors.append(f"{path.name}: report must be a JSON object")
            continue
        if report.get("schema_version") != 1:
            errors.append(f"{path.name}: schema_version must be 1")
        if report.get("catalog_sha256") != catalog_hash:
            errors.append(f"{path.name}: catalog hash is stale")
        if report.get("cases_sha256") != cases_hash:
            errors.append(f"{path.name}: cases hash is stale")
        for key in ("provider", "model", "started_at"):
            if not isinstance(report.get(key), str) or not report[key]:
                errors.append(f"{path.name}: missing {key}")
        execution = report.get("execution")
        if not isinstance(execution, dict) or execution.get("exit_code") != 0:
            errors.append(f"{path.name}: execution receipt is missing a zero exit code")

        rescored = score_predictions(catalog, suite, report)
        if not rescored["pass"]:
            errors.append(f"{path.name}: recorded selections no longer pass")
        for key in score_keys:
            if report.get(key) != rescored[key]:
                errors.append(f"{path.name}: stored {key} disagrees with re-score")
    return errors


def run_codex(prompt: str, model: str, effort: str, timeout: int) -> tuple[Any, dict[str, Any]]:
    with tempfile.TemporaryDirectory(prefix="speck-skill-routing-") as tmp_raw:
        tmp = Path(tmp_raw)
        schema_path = tmp / "schema.json"
        output_path = tmp / "response.json"
        schema_path.write_text(json.dumps(output_schema()))
        command = [
            "codex", "exec", "--ignore-user-config", "--ignore-rules", "--ephemeral",
            "--skip-git-repo-check", "-s", "read-only", "-m", model,
            "-c", f"model_reasoning_effort={effort}", "-C", str(tmp),
            "--output-schema", str(schema_path), "-o", str(output_path), "-",
        ]
        proc = subprocess.run(command, input=prompt, text=True, capture_output=True, timeout=timeout)
        if proc.returncode != 0 or not output_path.is_file():
            raise RuntimeError(f"codex routing run failed ({proc.returncode}): {proc.stderr[-2000:]}")
        return json.loads(output_path.read_text()), {
            "command": command[:-1] + ["<prompt-on-stdin>"],
            "exit_code": proc.returncode,
            "stderr_tail": proc.stderr[-2000:],
        }


def run_claude(prompt: str, model: str, effort: str, timeout: int) -> tuple[Any, dict[str, Any]]:
    command = [
        "claude", "-p", "--bare", "--model", model, "--effort", effort,
        "--tools", "", "--no-session-persistence", "--output-format", "json",
        "--json-schema", json.dumps(output_schema()), prompt,
    ]
    proc = subprocess.run(command, text=True, capture_output=True, timeout=timeout)
    if proc.returncode != 0:
        raise RuntimeError(f"claude routing run failed ({proc.returncode}): {(proc.stderr or proc.stdout)[-2000:]}")
    return json.loads(proc.stdout), {
        "command": command[:-1] + ["<catalog-prompt>"],
        "exit_code": proc.returncode,
        "stderr_tail": proc.stderr[-2000:],
    }


def run_cursor(prompt: str, model: str, timeout: int) -> tuple[Any, dict[str, Any]]:
    with tempfile.TemporaryDirectory(prefix="speck-skill-routing-cursor-") as tmp_raw:
        command = [
            "cursor-agent", "-p", prompt, "--model", model, "--output-format", "json",
            "--mode", "ask", "--force", "--trust", "--approve-mcps", "--workspace", tmp_raw,
        ]
        proc = subprocess.run(command, text=True, capture_output=True, timeout=timeout)
        if proc.returncode != 0:
            raise RuntimeError(f"cursor routing run failed ({proc.returncode}): {proc.stderr[-2000:]}")
        data = json.loads(proc.stdout)
        if data.get("subtype") != "success" or data.get("is_error") is True:
            raise RuntimeError(f"cursor routing run did not complete successfully: {proc.stdout[-2000:]}")
        return data, {
            "command": command[:2] + ["<catalog-prompt>"] + command[3:],
            "exit_code": proc.returncode,
            "terminal_event": {"subtype": data.get("subtype"), "is_error": data.get("is_error")},
            "stderr_tail": proc.stderr[-2000:],
        }


def print_report(report: dict[str, Any]) -> None:
    print(
        f"skill-routing: {'PASS' if report['pass'] else 'FAIL'} "
        f"accuracy={report['correct']}/{report['total']} ({report['accuracy']:.1%}) "
        f"forbidden={report['forbidden_selections']}"
    )
    for row in report["details"]:
        if not row["exact"]:
            marker = " FORBIDDEN" if row["forbidden"] else ""
            print(f"  {row['id']}: expected={row['expected']} actual={row['actual']}{marker}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate or run catalog-only Speck skill routing cases.")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("self-test")
    sub.add_parser("emit-prompt")
    verify = sub.add_parser("verify-reports")
    verify.add_argument("--reports-dir", type=Path, default=REPORTS_ROOT)
    score = sub.add_parser("score")
    score.add_argument("--predictions", required=True, type=Path)
    run = sub.add_parser("run")
    run.add_argument("--provider", choices=("codex", "claude", "cursor"), required=True)
    run.add_argument("--model", required=True)
    run.add_argument("--effort", default="low")
    run.add_argument("--timeout", type=int, default=600)
    run.add_argument("--report", type=Path)
    args = parser.parse_args()

    catalog = load_catalog()
    suite = load_cases()
    errors = validate_suite(catalog, suite)
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1

    if args.command == "emit-prompt":
        print(build_prompt(catalog, suite))
        return 0

    if args.command == "verify-reports":
        report_errors = verify_reports(catalog, suite, args.reports_dir)
        if report_errors:
            for error in report_errors:
                print(f"FAIL: {error}", file=sys.stderr)
            return 1
        print(f"skill-routing reports: PASS files={len(list(args.reports_dir.glob('*.json')))}")
        return 0

    if args.command == "self-test":
        perfect = {"predictions": [{"id": c["id"], "skill": c["expect"]} for c in suite["cases"]]}
        if not score_predictions(catalog, suite, perfect)["pass"]:
            print("FAIL: perfect predictions did not pass", file=sys.stderr)
            return 1
        for key in ("selections", "results", "assignments"):
            variant = {key: perfect["predictions"]}
            if not score_predictions(catalog, suite, {"result": f"```json\n{json.dumps(variant)}\n```"})["pass"]:
                print(f"FAIL: {key} transport variant did not normalize", file=sys.stderr)
                return 1
        mapping = {row["id"]: row["skill"] for row in perfect["predictions"]}
        if not score_predictions(catalog, suite, {"result": json.dumps(mapping)})["pass"]:
            print("FAIL: mapping transport variant did not normalize", file=sys.stderr)
            return 1
        report_variant = score_predictions(catalog, suite, perfect)
        if not score_predictions(catalog, suite, report_variant)["pass"]:
            print("FAIL: checked-in report transport did not normalize", file=sys.stderr)
            return 1
        mutant = json.loads(json.dumps(perfect))
        mutant["predictions"][0]["skill"] = suite["cases"][0]["forbid"][0]
        if score_predictions(catalog, suite, mutant)["pass"]:
            print("FAIL: forbidden-selection mutant passed", file=sys.stderr)
            return 1
        missing_case = json.loads(json.dumps(suite))
        missing_case["cases"].pop()
        if not any("missing routing cases" in error for error in validate_suite(catalog, missing_case)):
            print("FAIL: missing-skill case coverage mutant passed", file=sys.stderr)
            return 1
        duplicate_case = json.loads(json.dumps(suite))
        duplicate_case["cases"][1]["id"] = duplicate_case["cases"][0]["id"]
        if not any("duplicate case id" in error for error in validate_suite(catalog, duplicate_case)):
            print("FAIL: duplicate routing case mutant passed", file=sys.stderr)
            return 1
        print(f"skill-routing self-test: PASS cases={len(suite['cases'])} auto_skills={len(catalog)}")
        return 0

    if args.command == "score":
        report = score_predictions(catalog, suite, json.loads(args.predictions.read_text()))
        print_report(report)
        return 0 if report["pass"] else 1

    prompt = build_prompt(catalog, suite)
    started = datetime.now(timezone.utc)
    if args.provider == "codex":
        prediction_data, execution = run_codex(prompt, args.model, args.effort, args.timeout)
    elif args.provider == "claude":
        prediction_data, execution = run_claude(prompt, args.model, args.effort, args.timeout)
    else:
        prediction_data, execution = run_cursor(prompt, args.model, args.timeout)
    if not normalize_predictions(prediction_data):
        preview = json.dumps(prediction_data, ensure_ascii=False)[:4000]
        raise RuntimeError(f"routing provider returned no parseable predictions: {preview}")
    report = score_predictions(catalog, suite, prediction_data)
    report.update(
        {
            "schema_version": 1,
            "provider": args.provider,
            "model": args.model,
            "effort": args.effort,
            "started_at": started.isoformat(),
            "catalog_sha256": digest(catalog),
            "cases_sha256": digest(suite),
            "execution": execution,
        }
    )
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print_report(report)
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
