#!/usr/bin/env python3
"""Run, judge, and report the pinned Speck v10-v11 behavioral tournament."""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import math
import os
import random
import re
import shutil
import statistics
import subprocess
import sys
import tarfile
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from cases import CASES, CASE_BY_ID, Case, score_case, self_test


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
RUNS = HERE / ".runs"
REPORTS = HERE / "reports"
WORK_ROOT = Path(tempfile.gettempdir()) / "speck-behavioral-workspaces"
REVISIONS = {
    "v10": "51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6",
    "v11": "8ff081f1436024e5315fd68a3c2af505bd09ab83",
}
VERSIONS = {"v10": "10.5.0", "v11": "11.0.0"}
DEFAULT_RUN_ID = "2026-08-10-v10-v11-terra-isolated"
DEFAULT_MODEL = "gpt-5.6-terra"
DEFAULT_EFFORT = "medium"
DEFAULT_SEED = 127110
FORBIDDEN_JUDGE_PATTERNS = (
    r"(?i)\bv10\b", r"(?i)\bv11\b", r"\b10\.5\.0\b", r"\b11\.0\.0\b",
    r"(?i)speck[_ ]version", r"51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6",
    r"8ff081f1436024e5315fd68a3c2af505bd09ab83",
)


def run_command(
    args: list[str],
    *,
    cwd: Path,
    input_text: str | None = None,
    timeout: int = 1200,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=cwd,
        input=input_text,
        capture_output=True,
        text=True,
        timeout=timeout,
        env=env,
    )


def git(*args: str, cwd: Path = REPO, check: bool = True) -> str:
    proc = run_command(["git", *args], cwd=cwd, timeout=120)
    if check and proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed:\n{proc.stderr}")
    return proc.stdout


def path_exists_at(revision: str, path: str) -> bool:
    proc = run_command(["git", "cat-file", "-e", f"{revision}:{path}"], cwd=REPO, timeout=30)
    return proc.returncode == 0


def export_methodology(revision: str, destination: Path) -> None:
    candidates = ["AGENTS.md", "CLAUDE.md", ".cursor/skills", ".speck", ".agents", ".codex", ".claude"]
    paths = [path for path in candidates if path_exists_at(revision, path)]
    destination.parent.mkdir(parents=True, exist_ok=True)
    archive = destination.parent / f"{destination.name}.tar"
    with archive.open("wb") as handle:
        proc = subprocess.run(["git", "archive", "--format=tar", revision, *paths], cwd=REPO, stdout=handle, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode(errors="replace"))
    destination.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive) as bundle:
        for member in bundle.getmembers():
            resolved = (destination / member.name).resolve()
            if destination.resolve() not in resolved.parents and resolved != destination.resolve():
                raise RuntimeError(f"unsafe archive member: {member.name}")
        bundle.extractall(destination, filter="fully_trusted")
    archive.unlink()
    shutil.rmtree(destination / ".speck/eval/behavioral", ignore_errors=True)


def write_fixture(case: Case, condition: str, destination: Path) -> None:
    for relative, content in case.files.items():
        path = destination / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        rendered = content.replace("BENCHMARK_CONDITION", VERSIONS[condition])
        path.write_text(rendered)
    demo = destination / "scripts/open_demo.sh"
    if demo.exists():
        demo.chmod(0o755)
    git("init", "-q", cwd=destination)
    git("config", "user.name", "Speck Behavioral Benchmark", cwd=destination)
    git("config", "user.email", "benchmark@localhost", cwd=destination)
    git("add", "-A", cwd=destination)
    git("commit", "-qm", "benchmark seed", cwd=destination)


def subject_prompt(case: Case) -> str:
    return f"""You are a subject in a controlled software-methodology benchmark.

Work to completion in this isolated repository. Read AGENTS.md first. Enter the requested method through `.cursor/skills/{case.skill}/SKILL.md` and follow every load-DAG instruction relevant to the task.

Task: {case.task}

Rules:
- Use only evidence in this workspace. Make reasonable reversible assumptions instead of asking the operator questions.
- Do not read outside the workspace, use network services, or communicate with other agents.
- Do not edit methodology sources under `.cursor/`, `.agents/`, `.codex/`, `.claude/`, or `.speck/`; `.speck/project.json` may be updated only when the invoked skill requires it.
- Do not commit. Run relevant local checks. Write every canonical artifact the method requires for this task, but stop at the requested phase.
- In the final response, state the outcome, readiness if applicable, and concrete evidence. Do not describe this as a benchmark.
"""


def parse_events(raw: str) -> dict[str, Any]:
    usage = {"input_tokens": 0, "cached_input_tokens": 0, "output_tokens": 0}
    commands: list[str] = []
    completed = False
    tool_events = 0
    errors: list[str] = []
    for line in raw.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "turn.completed":
            completed = True
            for key in usage:
                usage[key] = int(event.get("usage", {}).get(key, usage[key]) or 0)
        if event.get("type") in {"turn.failed", "error"}:
            errors.append(str(event.get("error") or event.get("message") or event))
        item = event.get("item") or {}
        if item.get("type") in {"command_execution", "mcp_tool_call", "file_change", "collab_tool_call"}:
            tool_events += 1
        if item.get("type") == "command_execution":
            commands.append(str(item.get("command", "")))
            output = str(item.get("aggregated_output", ""))
            if "DEMO-URL" in output:
                commands.append(output)
    return {"usage": usage, "commands": "\n".join(commands), "turn_completed": completed, "tool_events": tool_events, "errors": errors}


def anonymous_map(seed: int) -> dict[str, dict[str, str]]:
    rng = random.Random(seed)
    mapping: dict[str, dict[str, str]] = {}
    for case in CASES:
        labels = ["A", "B"]
        rng.shuffle(labels)
        mapping[case.case_id] = {"v10": labels[0], "v11": labels[1]}
    return mapping


def result_paths(run_id: str, case_id: str, label: str) -> tuple[Path, Path, Path]:
    subjects = REPORTS / run_id / "subjects"
    stem = subjects / f"{case_id}-{label}"
    return stem.with_suffix(".json"), stem.with_suffix(".patch"), stem.with_suffix(".final.md")


def workspace_path(run_id: str, case_id: str, label: str) -> Path:
    return WORK_ROOT / run_id / "workspaces" / f"{case_id}-{label}"


def harness_fingerprint() -> dict[str, str]:
    paths = [HERE / "README.md", HERE / "cases.py", HERE / "runner.py"]
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.name.encode())
        digest.update(path.read_bytes())
    dirty = git("status", "--short", "--", *(str(path.relative_to(REPO)) for path in paths)).strip()
    if dirty:
        raise RuntimeError(f"benchmark harness is not frozen in git:\n{dirty}")
    return {"git_revision": git("rev-parse", "HEAD").strip(), "sha256": digest.hexdigest()}


def isolation_evidence(run_id: str) -> dict[str, Any]:
    root = (WORK_ROOT / run_id / "workspaces").resolve()
    repo = REPO.resolve()
    if root == repo or repo in root.parents or root in repo.parents:
        raise RuntimeError(f"workspace root is not isolated from repository: {root}")
    ancestor_packages = [str(parent / "package.json") for parent in (root, *root.parents) if (parent / "package.json").exists()]
    if ancestor_packages:
        raise RuntimeError(f"workspace root inherits package metadata: {ancestor_packages}")
    return {"workspace_root": str(root), "outside_repository_tree": True, "ancestor_package_json": []}


def run_subject(
    *,
    run_id: str,
    case: Case,
    condition: str,
    label: str,
    model: str,
    effort: str,
    force: bool,
) -> dict[str, Any]:
    result_file, patch_file, final_file = result_paths(run_id, case.case_id, label)
    if result_file.exists() and not force:
        return json.loads(result_file.read_text())
    work = workspace_path(run_id, case.case_id, label)
    raw_dir = RUNS / run_id / "raw"
    if work.exists():
        shutil.rmtree(work)
    raw_dir.mkdir(parents=True, exist_ok=True)
    result_file.parent.mkdir(parents=True, exist_ok=True)
    export_methodology(REVISIONS[condition], work)
    write_fixture(case, condition, work)
    final_path = raw_dir / f"{case.case_id}-{label}.final.txt"
    command = [
        "codex", "exec", "--ignore-user-config", "--ephemeral", "--json",
        "--skip-git-repo-check", "-s", "workspace-write", "-m", model,
        "-c", f"model_reasoning_effort={effort}", "-C", str(work),
        "-o", str(final_path), "-",
    ]
    started = time.monotonic()
    try:
        proc = run_command(command, cwd=work, input_text=subject_prompt(case), timeout=1800, env=os.environ.copy())
        timeout_hit = False
    except subprocess.TimeoutExpired as exc:
        proc = subprocess.CompletedProcess(command, 124, exc.stdout or "", exc.stderr or "subject timeout")
        timeout_hit = True
    wall = time.monotonic() - started
    raw = proc.stdout or ""
    raw_path = raw_dir / f"{case.case_id}-{label}.events.jsonl"
    raw_path.write_text(raw)
    (raw_dir / f"{case.case_id}-{label}.stderr.txt").write_text(proc.stderr or "")
    parsed = parse_events(raw)
    final = final_path.read_text(errors="replace") if final_path.exists() else ""
    status = git("status", "--short", cwd=work, check=False)
    git("add", "-A", cwd=work, check=False)
    patch = git("diff", "--cached", "--binary", cwd=work, check=False)
    scoring = score_case(case.case_id, work, final, parsed["commands"], patch)
    usage = parsed["usage"]
    result: dict[str, Any] = {
        "case_id": case.case_id,
        "label": label,
        "condition": condition,
        "revision": REVISIONS[condition],
        "model": model,
        "effort": effort,
        "exit_code": proc.returncode,
        "timeout": timeout_hit,
        "turn_completed": parsed["turn_completed"],
        "tool_events": parsed["tool_events"],
        "errors": parsed["errors"],
        "wall_seconds": round(wall, 3),
        "usage": usage,
        "required_corrections": sum(1 for check in scoring["checks"] if not check["ok"]),
        "score": scoring,
        "git_status": status.splitlines(),
        "events_sha256": hashlib.sha256(raw.encode()).hexdigest(),
        "patch_sha256": hashlib.sha256(patch.encode()).hexdigest(),
        "valid_run": proc.returncode == 0 and parsed["turn_completed"] and parsed["tool_events"] > 0 and bool(status.strip()),
    }
    result_file.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    patch_file.write_text(patch)
    final_file.write_text(final)
    return result


def load_manifest(run_id: str) -> dict[str, Any]:
    path = RUNS / run_id / "manifest.json"
    if not path.exists():
        raise RuntimeError(f"missing manifest: {path}")
    return json.loads(path.read_text())


def command_run(args: argparse.Namespace) -> int:
    run_root = RUNS / args.run_id
    run_root.mkdir(parents=True, exist_ok=True)
    mapping = anonymous_map(args.seed)
    manifest_path = run_root / "manifest.json"
    frozen = harness_fingerprint()
    isolation = isolation_evidence(args.run_id)
    manifest = {
        "run_id": args.run_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "revisions": REVISIONS,
        "model": args.model,
        "effort": args.effort,
        "seed": args.seed,
        "case_ids": [case.case_id for case in CASES],
        "anonymous_mapping": mapping,
        "harness": frozen,
        "isolation": isolation,
        "primary_endpoint": "paired deterministic hidden-check score",
        "secondary_endpoints": ["false greens", "required corrections", "blinded judge score", "input tokens", "wall time"],
    }
    if manifest_path.exists():
        existing = json.loads(manifest_path.read_text())
        frozen_keys = ("revisions", "model", "effort", "seed", "anonymous_mapping", "harness", "isolation")
        for key in frozen_keys:
            if existing[key] != manifest[key]:
                raise RuntimeError(f"run manifest mismatch for {key}; use a new run id")
        manifest = existing
    else:
        manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    selected_ids = [x.strip() for x in args.cases.split(",") if x.strip()]
    if selected_ids == ["all"]:
        selected = list(CASES)
    else:
        unknown = sorted(set(selected_ids) - set(CASE_BY_ID))
        if unknown:
            raise RuntimeError(f"unknown cases: {', '.join(unknown)}")
        selected = [CASE_BY_ID[x] for x in selected_ids]
    jobs = [(case, condition, mapping[case.case_id][condition]) for case in selected for condition in ("v10", "v11")]
    random.Random(args.seed + 1).shuffle(jobs)
    print(f"run={args.run_id} jobs={len(jobs)} model={args.model} effort={args.effort} workers={args.workers}", flush=True)
    failures = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(
                run_subject,
                run_id=args.run_id,
                case=case,
                condition=condition,
                label=label,
                model=args.model,
                effort=args.effort,
                force=args.force,
            ): (case, condition, label)
            for case, condition, label in jobs
        }
        for future in concurrent.futures.as_completed(futures):
            case, condition, label = futures[future]
            try:
                result = future.result()
                score = result["score"]["score"]
                valid = result["valid_run"]
                print(f"{case.case_id:24s} {label} valid={valid!s:5s} score={score:6.2f} wall={result['wall_seconds']:7.1f}s", flush=True)
                failures += 0 if valid else 1
            except Exception as exc:
                failures += 1
                print(f"{case.case_id:24s} {label} ERROR {exc}", file=sys.stderr, flush=True)
    return 1 if failures else 0


def scrub_for_judge(text: str) -> str:
    text = re.sub(r"(?i)^.*speck[_ ]version.*$", "[condition metadata removed]", text, flags=re.M)
    text = re.sub(r"(?i)\(\s*speck\s+\d+(?:\.\d+)*\s*\)", "(Speck condition)", text)
    text = re.sub(r"(?i)\bspeck\s+v?\d+(?:\.\d+)*\b", "Speck condition", text)
    text = re.sub(r"\b(?:10\.5\.0|11\.0\.0)\b", "[condition-version]", text)
    text = text.replace(REVISIONS["v10"], "[condition-revision]").replace(REVISIONS["v11"], "[condition-revision]")
    text = re.sub(r"(?i)\bv(?:ersion\s*)?(?:10|11)(?:\.\d+)*\b", "condition", text)
    return text


def assert_judge_blind(text: str) -> None:
    hits = [pattern for pattern in FORBIDDEN_JUDGE_PATTERNS if re.search(pattern, text)]
    if hits:
        raise RuntimeError(f"judge prompt leaked condition identity: {hits}")


def extract_json_payload(stdout: str) -> dict[str, Any]:
    try:
        outer = json.loads(stdout)
        if isinstance(outer, dict):
            for key in ("result", "text", "message", "output"):
                if isinstance(outer.get(key), str):
                    return extract_json_payload(outer[key])
            if "cases" in outer:
                return outer
    except json.JSONDecodeError:
        pass
    fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", stdout, re.S)
    candidate = fenced.group(1) if fenced else stdout[stdout.find("{"): stdout.rfind("}") + 1]
    value = json.loads(candidate)
    if not isinstance(value, dict):
        raise ValueError("judge payload is not an object")
    return value


def judge_prompt(bundle: list[Case], run_id: str, mapping: dict[str, dict[str, str]]) -> str:
    blocks: list[str] = []
    for case in bundle:
        outputs: list[str] = []
        condition_by_label = {label: condition for condition, label in mapping[case.case_id].items()}
        for label in ("A", "B"):
            condition = condition_by_label[label]
            result_file, patch_file, final_file = result_paths(run_id, case.case_id, label)
            result = json.loads(result_file.read_text())
            patch = scrub_for_judge(patch_file.read_text(errors="replace"))
            final = scrub_for_judge(final_file.read_text(errors="replace"))
            if len(patch) > 30000:
                patch = patch[:30000] + "\n[patch truncated]\n"
            outputs.append(f"### Output {label}\nFinal response:\n{final}\n\nArtifact patch:\n```diff\n{patch}\n```\nRun completed: {result['valid_run']}")
        blocks.append(
            f"""## Case {case.case_id}
Task: {case.task}
Rubric:
{chr(10).join(f'- {item}' for item in case.rubric)}

{chr(10).join(outputs)}
"""
        )
    prompt = f"""You are the blinded, adversarial quality judge for a paired methodology tournament. Two anonymous conditions produced each pair. Do not infer identities or reward verbosity, formatting, process recitation, or confident claims. Judge the actual changed artifacts against the task and rubric. Penalize invented facts, phase overreach, false readiness, missing failure paths, and outputs that would require correction before use.

For each output assign an integer quality score from 0 to 100. Then select A, B, or tie. A 90 means directly usable and unusually strong; 70 means usable with modest corrections; 50 means material rework; below 30 means task failure. Be skeptical and concrete.

Return JSON only, exactly:
{{"cases":[{{"case_id":"...","A":{{"score":0,"critical_failure":false}},"B":{{"score":0,"critical_failure":false}},"winner":"A|B|tie","reason":"one concise sentence"}}]}}

{chr(10).join(blocks)}
"""
    assert_judge_blind(prompt)
    return prompt


def command_judge(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.run_id)
    mapping = manifest["anonymous_mapping"]
    missing: list[str] = []
    for case in CASES:
        for condition in ("v10", "v11"):
            label = mapping[case.case_id][condition]
            if not result_paths(args.run_id, case.case_id, label)[0].exists():
                missing.append(f"{case.case_id}-{label}")
    if missing:
        raise RuntimeError(f"subject results missing: {', '.join(missing)}")
    judge_dir = RUNS / args.run_id / "judge"
    judge_dir.mkdir(parents=True, exist_ok=True)
    bundles = [list(CASES[i:i + args.bundle_size]) for i in range(0, len(CASES), args.bundle_size)]
    all_cases: list[dict[str, Any]] = []
    blind_checks: list[dict[str, Any]] = []
    for index, bundle in enumerate(bundles, 1):
        prompt = judge_prompt(bundle, args.run_id, mapping)
        prompt_path = judge_dir / f"bundle-{index}.prompt.md"
        raw_path = judge_dir / f"bundle-{index}.raw.json"
        prompt_path.write_text(prompt)
        blind_checks.append({"bundle": index, "forbidden_hits": [], "output_order": "A-then-B", "prompt_sha256": hashlib.sha256(prompt.encode()).hexdigest()})
        if raw_path.exists() and not args.force:
            raw = raw_path.read_text()
        else:
            cmd = [
                "cursor-agent", "-p", prompt, "--force", "--trust", "--approve-mcps",
                "--mode", "ask", "--model", args.model, "--output-format", "json",
                "--workspace", str(judge_dir),
            ]
            proc = run_command(cmd, cwd=judge_dir, timeout=1800)
            if proc.returncode != 0:
                raise RuntimeError(f"judge bundle {index} failed:\n{proc.stderr}\n{proc.stdout}")
            raw = proc.stdout
            raw_path.write_text(raw)
        payload = extract_json_payload(raw)
        judged = payload.get("cases")
        if not isinstance(judged, list) or len(judged) != len(bundle):
            raise RuntimeError(f"judge bundle {index} returned wrong case count")
        all_cases.extend(judged)
        print(f"judge bundle {index}/{len(bundles)} complete", flush=True)
    output = REPORTS / args.run_id / "judge.json"
    output.write_text(json.dumps({"model": args.model, "blinded": True, "cases": all_cases}, indent=2, sort_keys=True) + "\n")
    (REPORTS / args.run_id / "judge-blinding.json").write_text(json.dumps({"checks": blind_checks, "patterns": FORBIDDEN_JUDGE_PATTERNS}, indent=2) + "\n")
    return 0


def command_rescore(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.run_id)
    mapping = manifest["anonymous_mapping"]
    count = 0
    for case in CASES:
        for condition in ("v10", "v11"):
            label = mapping[case.case_id][condition]
            result_file, patch_file, final_file = result_paths(args.run_id, case.case_id, label)
            work = workspace_path(args.run_id, case.case_id, label)
            raw = (RUNS / args.run_id / "raw" / f"{case.case_id}-{label}.events.jsonl").read_text(errors="replace")
            result = json.loads(result_file.read_text())
            scoring = score_case(
                case.case_id,
                work,
                final_file.read_text(errors="replace"),
                parse_events(raw)["commands"],
                patch_file.read_text(errors="replace"),
            )
            result["score"] = scoring
            result["required_corrections"] = sum(1 for check in scoring["checks"] if not check["ok"])
            result["rescored_at"] = datetime.now(timezone.utc).isoformat()
            result_file.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
            count += 1
    print(f"rescored {count} frozen subject artifacts without rerunning subjects")
    return 0


def percentile(values: list[float], probability: float) -> float:
    values = sorted(values)
    if not values:
        return float("nan")
    position = (len(values) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return values[lower]
    return values[lower] * (upper - position) + values[upper] * (position - lower)


def bootstrap_ci(differences: list[float], seed: int, draws: int = 20000) -> tuple[float, float]:
    rng = random.Random(seed)
    means = [statistics.mean(rng.choice(differences) for _ in differences) for _ in range(draws)]
    return percentile(means, 0.025), percentile(means, 0.975)


def sign_test_p(wins: int, losses: int) -> float:
    n = wins + losses
    if n == 0:
        return 1.0
    tail = sum(math.comb(n, k) for k in range(0, min(wins, losses) + 1)) / (2 ** n)
    return min(1.0, 2 * tail)


def fmt(value: float, digits: int = 1) -> str:
    return f"{value:.{digits}f}"


def command_report(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.run_id)
    mapping = manifest["anonymous_mapping"]
    judge_path = REPORTS / args.run_id / "judge.json"
    judge_data = json.loads(judge_path.read_text()) if judge_path.exists() else {"model": "not run", "cases": []}
    judge_by_case = {entry["case_id"]: entry for entry in judge_data.get("cases", [])}
    rows: list[dict[str, Any]] = []
    for case in CASES:
        pair: dict[str, Any] = {"case": case}
        for condition in ("v10", "v11"):
            label = mapping[case.case_id][condition]
            result = json.loads(result_paths(args.run_id, case.case_id, label)[0].read_text())
            judge_entry = judge_by_case.get(case.case_id, {})
            judge_score = judge_entry.get(label, {}).get("score")
            pair[condition] = {**result, "judge_score": judge_score}
        rows.append(pair)
    def values(condition: str, getter) -> list[float]:
        return [float(getter(row[condition])) for row in rows]
    det_v10 = values("v10", lambda x: x["score"]["score"])
    det_v11 = values("v11", lambda x: x["score"]["score"])
    judge_complete = len(judge_by_case) == len(CASES)
    judge_v10 = values("v10", lambda x: x["judge_score"] or 0) if judge_complete else []
    judge_v11 = values("v11", lambda x: x["judge_score"] or 0) if judge_complete else []
    det_diff = [b - a for a, b in zip(det_v10, det_v11)]
    det_ci = bootstrap_ci(det_diff, manifest["seed"])
    det_wins = sum(x > 0 for x in det_diff)
    det_losses = sum(x < 0 for x in det_diff)
    det_ties = len(det_diff) - det_wins - det_losses
    if judge_complete:
        judge_diff = [b - a for a, b in zip(judge_v10, judge_v11)]
        combined_v10 = [0.7 * d + 0.3 * j for d, j in zip(det_v10, judge_v10)]
        combined_v11 = [0.7 * d + 0.3 * j for d, j in zip(det_v11, judge_v11)]
        combined_diff = [b - a for a, b in zip(combined_v10, combined_v11)]
        combined_ci = bootstrap_ci(combined_diff, manifest["seed"] + 2)
    else:
        judge_diff = []
        combined_v10 = det_v10
        combined_v11 = det_v11
        combined_diff = det_diff
        combined_ci = det_ci
    false_v10 = sum(bool(row["v10"]["score"]["false_green"]) for row in rows)
    false_v11 = sum(bool(row["v11"]["score"]["false_green"]) for row in rows)
    valid_v10 = sum(bool(row["v10"]["valid_run"]) for row in rows)
    valid_v11 = sum(bool(row["v11"]["valid_run"]) for row in rows)
    input_v10 = values("v10", lambda x: x["usage"]["input_tokens"])
    input_v11 = values("v11", lambda x: x["usage"]["input_tokens"])
    cached_v10 = values("v10", lambda x: x["usage"]["cached_input_tokens"])
    cached_v11 = values("v11", lambda x: x["usage"]["cached_input_tokens"])
    uncached_v10 = [total - cached for total, cached in zip(input_v10, cached_v10)]
    uncached_v11 = [total - cached for total, cached in zip(input_v11, cached_v11)]
    judge_direction = statistics.mean(judge_diff) if judge_complete else None
    regression = statistics.mean(det_diff) < -5 or false_v11 > false_v10
    parity = det_ci[0] > -5 and false_v11 <= false_v10
    improvement = statistics.mean(det_diff) > 0 and false_v11 <= false_v10 and judge_direction is not None and judge_direction >= 0
    drastic = statistics.mean(det_diff) >= 15 and statistics.mean(input_v11) <= 0.75 * statistics.mean(input_v10) and false_v11 <= false_v10
    classification = "regression" if regression else "drastic improvement" if drastic else "improvement" if improvement else "behavioral parity" if parity else "inconclusive"
    summary = {
        "run_id": args.run_id,
        "revisions": REVISIONS,
        "model": manifest["model"],
        "effort": manifest["effort"],
        "judge_model": judge_data.get("model"),
        "classification": classification,
        "harness": manifest.get("harness"),
        "isolation": manifest.get("isolation"),
        "valid_runs": {"v10": valid_v10, "v11": valid_v11},
        "deterministic": {
            "mean": {"v10": statistics.mean(det_v10), "v11": statistics.mean(det_v11)},
            "mean_difference_v11_minus_v10": statistics.mean(det_diff),
            "bootstrap_95_ci": det_ci,
            "wins_ties_losses": {"wins": det_wins, "ties": det_ties, "losses": det_losses},
            "sign_test_p": sign_test_p(det_wins, det_losses),
        },
        "judge": {
            "complete": judge_complete,
            "mean": {"v10": statistics.mean(judge_v10) if judge_complete else None, "v11": statistics.mean(judge_v11) if judge_complete else None},
            "mean_difference_v11_minus_v10": statistics.mean(judge_diff) if judge_complete else None,
        },
        "combined_70_30": {
            "mean": {"v10": statistics.mean(combined_v10), "v11": statistics.mean(combined_v11)},
            "mean_difference_v11_minus_v10": statistics.mean(combined_diff),
            "bootstrap_95_ci": combined_ci,
        },
        "false_greens": {"v10": false_v10, "v11": false_v11},
        "required_corrections": {
            "v10": sum(int(row["v10"]["required_corrections"]) for row in rows),
            "v11": sum(int(row["v11"]["required_corrections"]) for row in rows),
        },
        "input_tokens": {
            "total_v10": sum(input_v10), "total_v11": sum(input_v11),
            "mean_v10": statistics.mean(input_v10), "mean_v11": statistics.mean(input_v11),
            "cached_mean_v10": statistics.mean(cached_v10), "cached_mean_v11": statistics.mean(cached_v11),
            "uncached_mean_v10": statistics.mean(uncached_v10), "uncached_mean_v11": statistics.mean(uncached_v11),
        },
        "wall_seconds": {
            "total_v10": sum(values("v10", lambda x: x["wall_seconds"])),
            "total_v11": sum(values("v11", lambda x: x["wall_seconds"])),
            "mean_v10": statistics.mean(values("v10", lambda x: x["wall_seconds"])),
            "mean_v11": statistics.mean(values("v11", lambda x: x["wall_seconds"])),
        },
    }
    output_dir = REPORTS / args.run_id
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    table_rows: list[str] = []
    for row in rows:
        v10, v11 = row["v10"], row["v11"]
        table_rows.append(
            f"| {row['case'].case_id} | {v10['score']['score']:.1f} | {v11['score']['score']:.1f} | "
            f"{v10['judge_score'] if v10['judge_score'] is not None else '—'} | {v11['judge_score'] if v11['judge_score'] is not None else '—'} | "
            f"{v10['required_corrections']} | {v11['required_corrections']} | {v10['usage']['input_tokens']} | {v11['usage']['input_tokens']} |"
        )
    ratio = statistics.mean(combined_v11) / statistics.mean(combined_v10) if statistics.mean(combined_v10) else float("inf")
    report = f"""# Speck v10-v11 behavioral tournament

Run: `{args.run_id}`
Subjects: `{manifest['model']}` at `{manifest['effort']}` reasoning, identical prompts, isolated workspaces
Revisions: v10 `{REVISIONS['v10']}` · v11 `{REVISIONS['v11']}`
Blinded judge: `{judge_data.get('model')}` ({'complete' if judge_complete else 'not complete'})

## Verdict

Predeclared classification: **{classification}**. The primary hidden-check score changed by **{fmt(statistics.mean(det_diff))} points** in v11 (paired bootstrap 95% CI {fmt(det_ci[0])} to {fmt(det_ci[1])}). V11 won/tied/lost {det_wins}/{det_ties}/{det_losses} cases; two-sided sign-test p={sign_test_p(det_wins, det_losses):.4f}. False greens were {false_v10} for v10 and {false_v11} for v11.

The predeclared 70% deterministic + 30% blinded-judge score was {fmt(statistics.mean(combined_v10))} for v10 and {fmt(statistics.mean(combined_v11))} for v11, a {fmt(statistics.mean(combined_diff))}-point change (95% CI {fmt(combined_ci[0])} to {fmt(combined_ci[1])}). The observed quality multiplier is **{ratio:.2f}x**, so this tournament {'does' if ratio >= 4.0 else 'does not'} support a literal “300% better” claim.

## Paired results

| Case | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
{chr(10).join(table_rows)}

## Aggregate endpoints

| Endpoint | v10 | v11 | Change |
|---|---:|---:|---:|
| Hidden-check quality / 100 | {fmt(statistics.mean(det_v10))} | {fmt(statistics.mean(det_v11))} | {fmt(statistics.mean(det_diff), 1)} points |
| Blinded judge / 100 | {fmt(statistics.mean(judge_v10)) if judge_complete else '—'} | {fmt(statistics.mean(judge_v11)) if judge_complete else '—'} | {fmt(statistics.mean(judge_diff)) if judge_complete else '—'} |
| False greens | {false_v10} | {false_v11} | {false_v11 - false_v10:+d} |
| Required corrections | {summary['required_corrections']['v10']} | {summary['required_corrections']['v11']} | {summary['required_corrections']['v11'] - summary['required_corrections']['v10']:+d} |
| Mean input tokens | {fmt(summary['input_tokens']['mean_v10'], 0)} | {fmt(summary['input_tokens']['mean_v11'], 0)} | {100 * (summary['input_tokens']['mean_v11'] / summary['input_tokens']['mean_v10'] - 1):+.1f}% |
| Mean cached input tokens | {fmt(summary['input_tokens']['cached_mean_v10'], 0)} | {fmt(summary['input_tokens']['cached_mean_v11'], 0)} | {100 * (summary['input_tokens']['cached_mean_v11'] / summary['input_tokens']['cached_mean_v10'] - 1):+.1f}% |
| Mean uncached input tokens | {fmt(summary['input_tokens']['uncached_mean_v10'], 0)} | {fmt(summary['input_tokens']['uncached_mean_v11'], 0)} | {100 * (summary['input_tokens']['uncached_mean_v11'] / summary['input_tokens']['uncached_mean_v10'] - 1):+.1f}% |
| Mean wall time | {fmt(summary['wall_seconds']['mean_v10'])}s | {fmt(summary['wall_seconds']['mean_v11'])}s | {100 * (summary['wall_seconds']['mean_v11'] / summary['wall_seconds']['mean_v10'] - 1):+.1f}% |
| Valid subject runs | {valid_v10}/12 | {valid_v11}/12 | {valid_v11 - valid_v10:+d} |

## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, prompts, and scorer fixed. Deterministic checks were authored before subjects ran and mutation-tested. The quality judge saw anonymous A/B artifacts, not version labels. Twelve pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

Raw subject event streams and workspaces remain ignored under `.runs/`. Checked-in evidence contains every subject result, patch, final response, judge verdict, and this aggregate report. Event hashes in subject JSON bind those files to the raw streams.
"""
    (output_dir / "report.md").write_text(report)
    print(report)
    return 0 if valid_v10 == len(CASES) and valid_v11 == len(CASES) and judge_complete else 1


def command_self_test(_: argparse.Namespace) -> int:
    with tempfile.TemporaryDirectory(prefix="speck-behavioral-selftest-") as directory:
        outcome = self_test(Path(directory))
    outcome["case_count"] = len(CASES)
    outcome["unique_case_ids"] = len({case.case_id for case in CASES}) == len(CASES)
    outcome["five_item_rubrics"] = all(len(case.rubric) == 5 for case in CASES)
    with tempfile.TemporaryDirectory(prefix="speck-behavioral-deletion-mutants-") as directory:
        deletion_scores = {case.case_id: score_case(case.case_id, Path(directory) / case.case_id, "", "", "")["score"] for case in CASES}
    outcome["deletion_mutant_scores"] = deletion_scores
    outcome["all_case_families_turn_red"] = all(float(score) < 50 for score in deletion_scores.values())
    outcome["passed"] = bool(outcome["passed"] and outcome["case_count"] == 12 and outcome["unique_case_ids"] and outcome["five_item_rubrics"] and outcome["all_case_families_turn_red"])
    print(json.dumps(outcome, indent=2))
    return 0 if outcome["passed"] else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    test = sub.add_parser("self-test", help="prove a scorer catches a seeded mutant")
    test.set_defaults(func=command_self_test)
    run = sub.add_parser("run", help="run paired Codex CLI subjects")
    run.add_argument("--run-id", default=DEFAULT_RUN_ID)
    run.add_argument("--cases", default="all", help="comma-separated case ids or all")
    run.add_argument("--model", default=DEFAULT_MODEL)
    run.add_argument("--effort", default=DEFAULT_EFFORT)
    run.add_argument("--seed", type=int, default=DEFAULT_SEED)
    run.add_argument("--workers", type=int, default=2)
    run.add_argument("--force", action="store_true")
    run.set_defaults(func=command_run)
    judge = sub.add_parser("judge", help="run blinded Cursor judge")
    judge.add_argument("--run-id", default=DEFAULT_RUN_ID)
    judge.add_argument("--model", required=True)
    judge.add_argument("--bundle-size", type=int, default=3)
    judge.add_argument("--force", action="store_true")
    judge.set_defaults(func=command_judge)
    rescore = sub.add_parser("rescore", help="apply current scorers to frozen subject artifacts")
    rescore.add_argument("--run-id", default=DEFAULT_RUN_ID)
    rescore.set_defaults(func=command_rescore)
    report = sub.add_parser("report", help="aggregate paired results")
    report.add_argument("--run-id", default=DEFAULT_RUN_ID)
    report.set_defaults(func=command_report)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        return int(args.func(args))
    except (RuntimeError, ValueError, FileNotFoundError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
