#!/usr/bin/env python3
"""Always-on skill-routing evaluator for ADR-0008/0009."""
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
REPORTS_ROOT = ROOT / "tests/eval/skill-routing/reports"
FLOW_CONTRACT_PATH = ROOT / "tests/eval/skill-routing/baseline.json"
FLOW_START = "<!-- SPECK:FLOW:START -->"
FLOW_END = "<!-- SPECK:FLOW:END -->"


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


def load_flow_contract(path: Path = FLOW_CONTRACT_PATH) -> dict[str, Any]:
    return json.loads(path.read_text())


def load_agents(root: Path = ROOT) -> str:
    return (root / "AGENTS.md").read_text()


def load_flow(root: Path = ROOT, agents_text: str | None = None) -> str:
    text = agents_text if agents_text is not None else load_agents(root)
    if text.count(FLOW_START) != 1 or text.count(FLOW_END) != 1:
        return ""
    return text.split(FLOW_START, 1)[1].split(FLOW_END, 1)[0].strip()


def flow_has_skill(flow: str, name: str) -> bool:
    return bool(re.search(rf"(?<![A-Za-z0-9-]){re.escape(name)}(?![A-Za-z0-9-])", flow))


def flow_lines(flow: str) -> tuple[list[str], dict[str, str]]:
    order: list[str] = []
    lines: dict[str, str] = {}
    for raw in flow.splitlines():
        if not raw.strip():
            continue
        label, separator, body = raw.partition(":")
        if not separator:
            continue
        label = label.strip()
        order.append(label)
        lines[label] = body.strip()
    return order, lines


def route_is_ordered(line: str, skills: list[str]) -> bool:
    cursor = 0
    for name in skills:
        pattern = rf"(?<![A-Za-z0-9-]){re.escape(name)}(?![A-Za-z0-9-])"
        match = re.search(pattern, line[cursor:])
        if not match:
            return False
        cursor += match.end()
    return True


def competing_flow_errors(catalog: dict[str, str], root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    paths = [root / ".speck/README.md", root / ".speck/reference/command-phases.md"]
    paths.extend(sorted((root / ".cursor/skills").glob("**/*.md")))
    for path in dict.fromkeys(paths):
        if not path.is_file():
            continue
        text = path.read_text()
        rel = path.relative_to(root)
        for line_number, line in enumerate(text.splitlines(), 1):
            named = {name for name in catalog if flow_has_skill(line, name)}
            if line.count("→") >= 2 and len(named) >= 3:
                errors.append(
                    f"{rel}:{line_number} carries a competing skill sequence: {sorted(named)}"
                )
            if "under `##" in line and "The Speck Command Phases" in line:
                errors.append(f"{rel}:{line_number} points to the retired flow section name")
        for block in re.findall(r"```[^\n]*\n(.*?)```", text, re.S):
            named = {name for name in catalog if flow_has_skill(block, name)}
            if "State:" in block and "Run:" in block and len(named) >= 3:
                errors.append(f"{rel} carries a competing state-machine flow")
    return errors


def validate_suite(
    catalog: dict[str, str], suite: dict[str, Any], flow: str,
    contract: dict[str, Any], agents_text: str
) -> list[str]:
    errors: list[str] = []
    if suite.get("schema_version") != 2:
        errors.append("routing suite requires schema_version 2")
    if not flow:
        errors.append("AGENTS.md requires exactly one non-empty SPECK:FLOW block")
    if contract.get("schema_version") != 1:
        errors.append("canonical flow baseline requires schema_version 1")
    expected_line_order = contract.get("line_order")
    routes = contract.get("routes")
    if not isinstance(expected_line_order, list) or not expected_line_order:
        errors.append("canonical flow baseline requires line_order")
        expected_line_order = []
    if not isinstance(routes, list) or not routes:
        errors.append("canonical flow baseline requires routes")
        routes = []

    actual_line_order, actual_lines = flow_lines(flow)
    if actual_line_order != expected_line_order:
        errors.append(
            f"always-on flow line order drifted: {actual_line_order} != {expected_line_order}"
        )

    route_ids: set[str] = set()
    contract_flow_skills: set[str] = set()
    for index, route in enumerate(routes):
        if not isinstance(route, dict):
            errors.append(f"canonical flow route {index} must be an object")
            continue
        route_id = route.get("id")
        line_label = route.get("line")
        skills = route.get("skills")
        if not isinstance(route_id, str) or not route_id or route_id in route_ids:
            errors.append(f"invalid or duplicate canonical flow route id: {route_id!r}")
            continue
        route_ids.add(route_id)
        if not isinstance(line_label, str) or line_label not in actual_lines:
            errors.append(f"canonical flow route {route_id!r} names missing line {line_label!r}")
            continue
        if not isinstance(skills, list) or not skills or not all(isinstance(x, str) and x for x in skills):
            errors.append(f"canonical flow route {route_id!r} requires a non-empty skills list")
            continue
        contract_flow_skills.update(skills)
        if not route_is_ordered(actual_lines[line_label], skills):
            errors.append(f"always-on flow route {route_id!r} omits or misorders {skills}")

    elsewhere: set[str] = set()
    always_on_elsewhere: set[str] = set()
    for key in ("always_on_elsewhere", "event_skills"):
        values = contract.get(key)
        if not isinstance(values, list) or not all(isinstance(x, str) and x for x in values):
            errors.append(f"canonical flow baseline requires a {key} string list")
            continue
        duplicate = elsewhere.intersection(values)
        if duplicate:
            errors.append(f"canonical flow baseline classifies skills twice: {sorted(duplicate)}")
        elsewhere.update(values)
        if key == "always_on_elsewhere":
            always_on_elsewhere.update(values)

    overlap = contract_flow_skills & elsewhere
    if overlap:
        errors.append(f"canonical flow baseline marks flow skills as non-flow: {sorted(overlap)}")
    classified = contract_flow_skills | elsewhere
    unclassified = sorted(set(catalog) - classified)
    invalid_classifications = sorted(classified - set(catalog))
    if unclassified:
        errors.append(f"automatic skills missing canonical flow classification: {unclassified}")
    if invalid_classifications:
        errors.append(f"canonical flow baseline names non-automatic skills: {invalid_classifications}")
    missing_elsewhere = sorted(name for name in always_on_elsewhere if not flow_has_skill(agents_text, name))
    if missing_elsewhere:
        errors.append(f"always-on AGENTS context omits first-action skills: {missing_elsewhere}")

    actual_flow_skills = {name for name in catalog if flow_has_skill(flow, name)}
    missing_from_flow = sorted(contract_flow_skills - actual_flow_skills)
    extra_in_flow = sorted(actual_flow_skills - contract_flow_skills)
    if missing_from_flow:
        errors.append(f"always-on AGENTS flow omits baseline skills: {missing_from_flow}")
    if extra_in_flow:
        errors.append(f"always-on AGENTS flow adds uncontracted skills: {extra_in_flow}")
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


def build_prompt(catalog: dict[str, str], suite: dict[str, Any], flow: str) -> str:
    catalog_lines = "\n".join(f"- {name}: {description}" for name, description in sorted(catalog.items()))
    request_lines = "\n".join(
        f"- {case['id']}: {case['prompt']}" for case in suite["cases"]
    )
    return f"""You are evaluating an automatic Agent Skill catalog with the same canonical flow that is always in the agent's context.

Choose exactly one catalog skill for every request using only the canonical flow plus each skill's name and description. Select the skill whose advertised trigger best matches the request's intent and lifecycle state. Do not invent skills, use implementation knowledge, or perform the requested work.

Return only the JSON object required by the response schema. Include every request id exactly once and preserve the request order.

CANONICAL FLOW
{flow}

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
    catalog: dict[str, str], suite: dict[str, Any], flow: str,
    contract: dict[str, Any], reports_dir: Path
) -> list[str]:
    """Re-score checked-in live evidence and reject stale or incomplete receipts."""
    errors: list[str] = []
    paths = sorted(reports_dir.glob("*.json"))
    if not paths:
        return [f"no routing reports found in {reports_dir}"]

    catalog_hash = digest(catalog)
    cases_hash = digest(suite)
    flow_hash = digest(flow)
    contract_hash = digest(contract)
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
        if report.get("schema_version") != 2:
            errors.append(f"{path.name}: schema_version must be 2")
        if report.get("catalog_sha256") != catalog_hash:
            errors.append(f"{path.name}: catalog hash is stale")
        if report.get("cases_sha256") != cases_hash:
            errors.append(f"{path.name}: cases hash is stale")
        if report.get("flow_sha256") != flow_hash:
            errors.append(f"{path.name}: always-on flow hash is stale")
        if report.get("flow_contract_sha256") != contract_hash:
            errors.append(f"{path.name}: canonical flow baseline hash is stale")
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
    parser = argparse.ArgumentParser(description="Validate or run always-on Speck skill routing cases.")
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
    agents_text = load_agents()
    flow = load_flow(agents_text=agents_text)
    contract = load_flow_contract()
    errors = validate_suite(catalog, suite, flow, contract, agents_text)
    errors.extend(competing_flow_errors(catalog))
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1

    if args.command == "emit-prompt":
        print(build_prompt(catalog, suite, flow))
        return 0

    if args.command == "verify-reports":
        report_errors = verify_reports(catalog, suite, flow, contract, args.reports_dir)
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
        if not any("missing routing cases" in error for error in validate_suite(catalog, missing_case, flow, contract, agents_text)):
            print("FAIL: missing-skill case coverage mutant passed", file=sys.stderr)
            return 1
        duplicate_case = json.loads(json.dumps(suite))
        duplicate_case["cases"][1]["id"] = duplicate_case["cases"][0]["id"]
        if not any("duplicate case id" in error for error in validate_suite(catalog, duplicate_case, flow, contract, agents_text)):
            print("FAIL: duplicate routing case mutant passed", file=sys.stderr)
            return 1
        missing_flow = flow.replace("epic-constitution", "epic_constitution", 1)
        if not any("always-on AGENTS flow omits" in error for error in validate_suite(catalog, suite, missing_flow, contract, agents_text)):
            print("FAIL: missing always-on flow skill mutant passed", file=sys.stderr)
            return 1
        wrong_order = flow.replace("story-tasks → story-implement", "story-implement → story-tasks", 1)
        if not any("omits or misorders" in error for error in validate_suite(catalog, suite, wrong_order, contract, agents_text)):
            print("FAIL: wrong-order always-on flow mutant passed", file=sys.stderr)
            return 1
        incomplete_contract = json.loads(json.dumps(contract))
        for route in incomplete_contract["routes"]:
            route["skills"] = [name for name in route["skills"] if name != "story-extract"]
        if not any("missing canonical flow classification" in error for error in validate_suite(catalog, suite, flow, incomplete_contract, agents_text)):
            print("FAIL: incomplete canonical flow baseline mutant passed", file=sys.stderr)
            return 1
        missing_first_action = agents_text.replace("speck-graph-up", "speck_graph_up")
        if not any("omits first-action skills" in error for error in validate_suite(catalog, suite, flow, contract, missing_first_action)):
            print("FAIL: missing always-on first-action skill mutant passed", file=sys.stderr)
            return 1
        with tempfile.TemporaryDirectory(prefix="speck-competing-flow-") as tmp_raw:
            mutant_root = Path(tmp_raw)
            (mutant_root / ".speck/reference").mkdir(parents=True)
            (mutant_root / ".speck/reference/command-phases.md").write_text("# Gates\n")
            (mutant_root / ".cursor/skills/mutant").mkdir(parents=True)
            (mutant_root / ".cursor/skills/mutant/SKILL.md").write_text(
                "Flow: story-plan → story-tasks → story-implement → speck-audit\n"
            )
            if not competing_flow_errors(catalog, mutant_root):
                print("FAIL: competing-flow detector mutant passed", file=sys.stderr)
                return 1
        print(f"skill-routing self-test: PASS cases={len(suite['cases'])} auto_skills={len(catalog)}")
        return 0

    if args.command == "score":
        report = score_predictions(catalog, suite, json.loads(args.predictions.read_text()))
        print_report(report)
        return 0 if report["pass"] else 1

    prompt = build_prompt(catalog, suite, flow)
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
            "schema_version": 2,
            "provider": args.provider,
            "model": args.model,
            "effort": args.effort,
            "started_at": started.isoformat(),
            "catalog_sha256": digest(catalog),
            "cases_sha256": digest(suite),
            "flow_sha256": digest(flow),
            "flow_contract_sha256": digest(contract),
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
