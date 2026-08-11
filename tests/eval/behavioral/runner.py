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

from cases import CASES, CASE_BY_ID, Case, patch_changes_methodology, score_case, self_test


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
CONTEXT_PROFILES: dict[str, tuple[str, tuple[str, ...]]] = {
    "epic-breakdown": ("epic-breakdown", ()),
    "story-specify": ("story-specify", ()),
    "story-tasks": ("story-tasks-backend", ()),
    "implement-backend": ("story-implement-backend", ()),
    "implement-ui": ("story-implement-ui", ()),
    "validate-fake-green": ("story-validate-ui", ("claimed_state=ux-rc", "visual_host=web")),
    "validate-unreachable": ("story-validate-ui", ("claimed_state=ux-rc", "visual_host=web")),
    "evidence-contract": ("project-evidence-ui-build", ()),
}
TRUSTED_HARNESS_FILES = (
    ".speck/scripts/validation/validators/validate-context-transcript.py",
    ".speck/scripts/context/speck_context.py",
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


def receipt_schema_at(revision: str) -> int:
    """Read a pinned revision's literal receipt schema without executing it."""
    proc = run_command(
        ["git", "show", f"{revision}:.speck/scripts/context/speck_context.py"],
        cwd=REPO,
        timeout=30,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"cannot read receipt schema from pinned revision {revision}: {proc.stderr}")
    match = re.search(r"(?m)^RECEIPT_SCHEMA_VERSION\s*=\s*(\d+)\s*$", proc.stdout)
    return int(match.group(1)) if match else 1


def revision_file_at(revision: str, path: str, destination: Path) -> None:
    """Snapshot trusted methodology data from a pinned git object."""
    proc = run_command(["git", "show", f"{revision}:{path}"], cwd=REPO, timeout=30)
    if proc.returncode != 0:
        raise RuntimeError(f"cannot read {path} from pinned revision {revision}: {proc.stderr}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(proc.stdout)


def trusted_snapshot_root(run_id: str) -> Path:
    return RUNS / run_id / "trusted"


def snapshot_trusted_harness(destination: Path, revision: str) -> None:
    """Freeze the live evaluator and its imported loader for the whole run."""
    for relative in TRUSTED_HARNESS_FILES:
        proc = run_command(["git", "show", f"{revision}:{relative}"], cwd=REPO, timeout=30)
        if proc.returncode != 0:
            raise RuntimeError(f"cannot snapshot trusted harness file {relative}: {proc.stderr}")
        target = destination / relative
        if target.exists():
            if target.read_text() != proc.stdout:
                raise RuntimeError(f"trusted harness snapshot drifted: {target}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(proc.stdout)


def trusted_context_validator(run_id: str | None = None) -> Path:
    root = trusted_snapshot_root(run_id) if run_id else REPO
    path = root / ".speck/scripts/validation/validators/validate-context-transcript.py"
    if not path.is_file():
        raise RuntimeError(f"trusted context validator missing: {path}")
    return path


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
    shutil.rmtree(destination / "tests/eval/behavioral", ignore_errors=True)


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


def subject_execution_valid(
    *,
    exit_code: int,
    turn_completed: bool,
    tool_events: int,
) -> bool:
    """Whether the subject cell executed to a usable experimental outcome.

    Refusing to mutate after a methodology gate, producing no patch, or
    missing a JIT contract are measured behavioral outcomes. They must not be
    recoded as harness failures or leaked into the artifact-quality judge.
    """
    return exit_code == 0 and turn_completed and tool_events > 0


def subject_experiment_valid(*, execution_valid: bool, methodology_edit: bool) -> bool:
    """Whether the outcome belongs in the controlled methodology comparison."""
    return execution_valid and not methodology_edit


def context_conformance_passed(context_conformance: dict[str, Any] | None) -> bool:
    return bool(
        isinstance(context_conformance, dict)
        and context_conformance.get("exit_code") == 0
        and context_conformance.get("report", {}).get("pass") is True
    )


def context_reports_for_aggregate(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep invalid/contaminated subjects from contributing green process evidence."""
    return [
        row["v11"]["context_conformance"]
        for row in rows
        if isinstance(row["v11"].get("context_conformance"), dict)
        and bool(row["v11"].get("experimental_valid", row["v11"]["valid_run"]))
    ]


def quality_rows_for_aggregate(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep a pair only when both controlled-methodology subjects are valid."""
    return [
        row
        for row in rows
        if all(
            bool(row[condition].get("experimental_valid", row[condition]["valid_run"]))
            for condition in ("v10", "v11")
        )
    ]


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
    paths = [
        HERE / "README.md",
        HERE / "cases.py",
        HERE / "runner.py",
        *(REPO / relative for relative in TRUSTED_HARNESS_FILES),
    ]
    digest = hashlib.sha256()
    for path in paths:
        digest.update(str(path.relative_to(REPO)).encode())
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
    revision: str,
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
    export_methodology(revision, work)
    write_fixture(case, condition, work)
    trusted_contract = raw_dir / f"{case.case_id}-{label}.context-contract.json"
    if condition == "v11" and CONTEXT_PROFILES.get(case.case_id):
        revision_file_at(
            revision,
            ".speck/reference/skill-load-contracts.json",
            trusted_contract,
        )
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
    context_conformance: dict[str, Any] | None = None
    context_profile = CONTEXT_PROFILES.get(case.case_id)
    if condition == "v11" and context_profile:
        context_validator = trusted_context_validator(run_id)
        profile, selections = context_profile
        receipt_schema = receipt_schema_at(revision)
        context_cmd = [
            sys.executable,
            str(context_validator),
            "--transcript", str(raw_path),
            "--profile", profile,
            "--root", str(work),
            "--contract", str(trusted_contract),
            "--json",
            "--receipt-schema", str(receipt_schema),
        ]
        for selection in selections:
            context_cmd.extend(("--select", selection))
        context_proc = run_command(context_cmd, cwd=work, timeout=120)
        try:
            context_report = json.loads(context_proc.stdout)
        except json.JSONDecodeError:
            context_report = {"pass": False, "parse_error": context_proc.stdout[-2000:]}
        context_conformance = {
            "profile": profile,
            "selections": list(selections),
            "exit_code": context_proc.returncode,
            "report": context_report,
            "stderr": context_proc.stderr[-2000:],
        }
    usage = parsed["usage"]
    changed = bool(status.strip())
    execution_valid = subject_execution_valid(
        exit_code=proc.returncode,
        turn_completed=parsed["turn_completed"],
        tool_events=parsed["tool_events"],
    )
    experimental_valid = subject_experiment_valid(
        execution_valid=execution_valid,
        methodology_edit=bool(scoring["methodology_edit"]),
    )
    result: dict[str, Any] = {
        "case_id": case.case_id,
        "label": label,
        "condition": condition,
        "revision": revision,
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
        "context_conformance": context_conformance,
        "context_conformant": (
            context_conformance_passed(context_conformance)
            if condition == "v11" and context_profile is not None
            else None
        ),
        "git_status": status.splitlines(),
        "artifact_changed": changed,
        "events_sha256": hashlib.sha256(raw.encode()).hexdigest(),
        "patch_sha256": hashlib.sha256(patch.encode()).hexdigest(),
        "execution_valid": execution_valid,
        "experimental_valid": experimental_valid,
        "valid_run": experimental_valid,
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
    revisions = dict(REVISIONS)
    if args.v10_revision:
        revisions["v10"] = git("rev-parse", args.v10_revision).strip()
    if args.v11_revision:
        revisions["v11"] = git("rev-parse", args.v11_revision).strip()
    manifest_path = run_root / "manifest.json"
    frozen = harness_fingerprint()
    isolation = isolation_evidence(args.run_id)
    manifest = {
        "run_id": args.run_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "revisions": revisions,
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
    snapshot_trusted_harness(trusted_snapshot_root(args.run_id), manifest["harness"]["git_revision"])
    selected_ids = [x.strip() for x in args.cases.split(",") if x.strip()]
    if selected_ids == ["all"]:
        selected = list(CASES)
    else:
        unknown = sorted(set(selected_ids) - set(CASE_BY_ID))
        if unknown:
            raise RuntimeError(f"unknown cases: {', '.join(unknown)}")
        selected = [CASE_BY_ID[x] for x in selected_ids]
    jobs = [(case, condition, mapping[case.case_id][condition], revisions[condition]) for case in selected for condition in ("v10", "v11")]
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
                revision=revision,
            ): (case, condition, label)
            for case, condition, label, revision in jobs
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


def scrub_for_judge(text: str, revisions: dict[str, str]) -> str:
    text = re.sub(r"(?i)^.*speck[_ ]version.*$", "[condition metadata removed]", text, flags=re.M)
    text = re.sub(r"(?i)\(\s*speck\s+\d+(?:\.\d+)*\s*\)", "(Speck condition)", text)
    text = re.sub(r"(?i)\bspeck\s+v?\d+(?:\.\d+)*\b", "Speck condition", text)
    text = re.sub(r"\b(?:10\.5\.0|11\.0\.0)\b", "[condition-version]", text)
    for revision in revisions.values():
        text = text.replace(revision, "[condition-revision]")
    text = re.sub(r"(?i)\bv(?:ersion\s*)?(?:10|11)(?:\.\d+)*\b", "condition", text)
    return text


def assert_judge_blind(text: str, revisions: dict[str, str]) -> None:
    patterns = (*FORBIDDEN_JUDGE_PATTERNS, *(re.escape(revision) for revision in revisions.values()))
    hits = [pattern for pattern in patterns if re.search(pattern, text)]
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


def judge_prompt(bundle: list[Case], run_id: str, mapping: dict[str, dict[str, str]], revisions: dict[str, str]) -> str:
    blocks: list[str] = []
    for case in bundle:
        outputs: list[str] = []
        condition_by_label = {label: condition for condition, label in mapping[case.case_id].items()}
        for label in ("A", "B"):
            condition = condition_by_label[label]
            result_file, patch_file, final_file = result_paths(run_id, case.case_id, label)
            result = json.loads(result_file.read_text())
            patch = scrub_for_judge(patch_file.read_text(errors="replace"), revisions)
            final = scrub_for_judge(final_file.read_text(errors="replace"), revisions)
            if len(patch) > 30000:
                patch = patch[:30000] + "\n[patch truncated]\n"
            completed = result.get("execution_valid", result["valid_run"])
            outputs.append(f"### Output {label}\nFinal response:\n{final}\n\nArtifact patch:\n```diff\n{patch}\n```\nSubject execution completed: {completed}")
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
    assert_judge_blind(prompt, revisions)
    return prompt


def command_judge(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.run_id)
    mapping = manifest["anonymous_mapping"]
    revisions = manifest["revisions"]
    selected_ids = [value.strip() for value in args.cases.split(",") if value.strip()]
    if selected_ids == ["all"]:
        selected = list(CASES)
    else:
        unknown = sorted(set(selected_ids) - set(CASE_BY_ID))
        if unknown:
            raise RuntimeError(f"unknown cases: {', '.join(unknown)}")
        selected = [CASE_BY_ID[value] for value in selected_ids]
    missing: list[str] = []
    for case in selected:
        for condition in ("v10", "v11"):
            label = mapping[case.case_id][condition]
            if not result_paths(args.run_id, case.case_id, label)[0].exists():
                missing.append(f"{case.case_id}-{label}")
    if missing:
        raise RuntimeError(f"subject results missing: {', '.join(missing)}")
    judge_dir = RUNS / args.run_id / "judge"
    judge_dir.mkdir(parents=True, exist_ok=True)
    bundles = [selected[i:i + args.bundle_size] for i in range(0, len(selected), args.bundle_size)]
    all_cases: list[dict[str, Any]] = []
    blind_checks: list[dict[str, Any]] = []
    for index, bundle in enumerate(bundles, 1):
        prompt = judge_prompt(bundle, args.run_id, mapping, revisions)
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
    blind_patterns = (*FORBIDDEN_JUDGE_PATTERNS, *(re.escape(revision) for revision in revisions.values()))
    (REPORTS / args.run_id / "judge-blinding.json").write_text(json.dumps({"checks": blind_checks, "patterns": blind_patterns}, indent=2) + "\n")
    return 0


def command_rescore(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.run_id)
    manifest["rescore_harness"] = harness_fingerprint()
    (RUNS / args.run_id / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    )
    snapshot_trusted_harness(
        trusted_snapshot_root(args.run_id),
        str(manifest["harness"]["git_revision"]),
    )
    mapping = manifest["anonymous_mapping"]
    selected_ids = [value.strip() for value in args.cases.split(",") if value.strip()]
    if selected_ids == ["all"]:
        selected = list(CASES)
    else:
        unknown = sorted(set(selected_ids) - set(CASE_BY_ID))
        if unknown:
            raise RuntimeError(f"unknown cases: {', '.join(unknown)}")
        selected = [CASE_BY_ID[value] for value in selected_ids]
    count = 0
    for case in selected:
        for condition in ("v10", "v11"):
            label = mapping[case.case_id][condition]
            result_file, patch_file, final_file = result_paths(args.run_id, case.case_id, label)
            work = workspace_path(args.run_id, case.case_id, label)
            raw = (RUNS / args.run_id / "raw" / f"{case.case_id}-{label}.events.jsonl").read_text(errors="replace")
            result = json.loads(result_file.read_text())
            parsed = parse_events(raw)
            scoring = score_case(
                case.case_id,
                work,
                final_file.read_text(errors="replace"),
                parsed["commands"],
                patch_file.read_text(errors="replace"),
            )
            context_conformance: dict[str, Any] | None = None
            context_profile = CONTEXT_PROFILES.get(case.case_id)
            if condition == "v11" and context_profile:
                profile, selections = context_profile
                receipt_schema = receipt_schema_at(str(result["revision"]))
                trusted_contract = (
                    RUNS / args.run_id / "raw" / f"{case.case_id}-{label}.context-contract.json"
                )
                revision_file_at(
                    str(result["revision"]),
                    ".speck/reference/skill-load-contracts.json",
                    trusted_contract,
                )
                context_cmd = [
                    sys.executable,
                    str(trusted_context_validator(args.run_id)),
                    "--transcript", str(RUNS / args.run_id / "raw" / f"{case.case_id}-{label}.events.jsonl"),
                    "--profile", profile,
                    "--root", str(work),
                    "--contract", str(trusted_contract),
                    "--json",
                    "--receipt-schema", str(receipt_schema),
                ]
                for selection in selections:
                    context_cmd.extend(("--select", selection))
                context_proc = run_command(context_cmd, cwd=work, timeout=120)
                try:
                    context_report = json.loads(context_proc.stdout)
                except json.JSONDecodeError:
                    context_report = {"pass": False, "parse_error": context_proc.stdout[-2000:]}
                context_conformance = {
                    "profile": profile,
                    "selections": list(selections),
                    "exit_code": context_proc.returncode,
                    "report": context_report,
                    "stderr": context_proc.stderr[-2000:],
                }
            result["score"] = scoring
            result["required_corrections"] = sum(1 for check in scoring["checks"] if not check["ok"])
            result["context_conformance"] = context_conformance
            result["context_conformant"] = (
                context_conformance_passed(context_conformance)
                if condition == "v11" and context_profile is not None
                else None
            )
            result["artifact_changed"] = bool(result.get("git_status"))
            result["execution_valid"] = subject_execution_valid(
                exit_code=int(result["exit_code"]),
                turn_completed=bool(result["turn_completed"]),
                tool_events=int(result["tool_events"]),
            )
            result["experimental_valid"] = subject_experiment_valid(
                execution_valid=bool(result["execution_valid"]),
                methodology_edit=bool(scoring["methodology_edit"]),
            )
            result["valid_run"] = result["experimental_valid"]
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
    quality_rows = quality_rows_for_aggregate(rows)
    if not quality_rows:
        raise RuntimeError("no pair-valid subjects remain for controlled quality aggregation")
    def values(condition: str, getter) -> list[float]:
        return [float(getter(row[condition])) for row in quality_rows]
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
    false_v10 = sum(bool(row["v10"]["score"]["false_green"]) for row in quality_rows)
    false_v11 = sum(bool(row["v11"]["score"]["false_green"]) for row in quality_rows)
    valid_v10 = sum(bool(row["v10"].get("experimental_valid", row["v10"]["valid_run"])) for row in rows)
    valid_v11 = sum(bool(row["v11"].get("experimental_valid", row["v11"]["valid_run"])) for row in rows)
    changed_v10 = sum(bool(row["v10"].get("artifact_changed", row["v10"].get("git_status"))) for row in rows)
    changed_v11 = sum(bool(row["v11"].get("artifact_changed", row["v11"].get("git_status"))) for row in rows)
    rescored = any("rescored_at" in row[condition] for row in rows for condition in ("v10", "v11"))
    all_context_reports = [
        row["v11"]["context_conformance"]
        for row in rows
        if isinstance(row["v11"].get("context_conformance"), dict)
    ]
    context_reports = context_reports_for_aggregate(rows)
    excluded_context_reports = len(all_context_reports) - len(context_reports)
    context_axes: dict[str, dict[str, int]] = {}
    for conformance in context_reports:
        axes = conformance.get("report", {}).get("axes", {})
        for axis in ("REACH", "SELECTIVITY", "TIMING", "GATE_USE"):
            if axis in axes:
                counts = context_axes.setdefault(axis, {"pass": 0, "checked": 0})
                counts["checked"] += 1
                counts["pass"] += int(bool(axes[axis].get("ok")))
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
    all_runs_valid = valid_v10 == len(CASES) and valid_v11 == len(CASES)
    classification = (
        "invalid run"
        if not all_runs_valid
        else "regression" if regression
        else "drastic improvement" if drastic
        else "improvement" if improvement
        else "behavioral parity" if parity
        else "inconclusive"
    )
    summary = {
        "run_id": args.run_id,
        "revisions": manifest["revisions"],
        "model": manifest["model"],
        "effort": manifest["effort"],
        "judge_model": judge_data.get("model"),
        "classification": classification,
        "harness": manifest.get("harness"),
        "rescore_harness": manifest.get("rescore_harness"),
        "isolation": manifest.get("isolation"),
        "valid_runs": {"v10": valid_v10, "v11": valid_v11},
        "quality_pairs": {"included": len(quality_rows), "excluded": len(rows) - len(quality_rows)},
        "artifact_changed": {"v10": changed_v10, "v11": changed_v11},
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
        "context_conformance": {
            "applicable_runs": len(context_reports),
            "excluded_invalid_runs": excluded_context_reports,
            "overall_pass": sum(bool(item.get("report", {}).get("pass")) for item in context_reports),
            "axes": context_axes,
        },
        "required_corrections": {
            "v10": sum(int(row["v10"]["required_corrections"]) for row in quality_rows),
            "v11": sum(int(row["v11"]["required_corrections"]) for row in quality_rows),
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
        included = "yes" if row in quality_rows else "no"
        table_rows.append(
            f"| {row['case'].case_id} | {included} | {v10['score']['score']:.1f} | {v11['score']['score']:.1f} | "
            f"{v10['judge_score'] if v10['judge_score'] is not None else '—'} | {v11['judge_score'] if v11['judge_score'] is not None else '—'} | "
            f"{v10['required_corrections']} | {v11['required_corrections']} | {v10['usage']['input_tokens']} | {v11['usage']['input_tokens']} |"
        )
    ratio = statistics.mean(combined_v11) / statistics.mean(combined_v10) if statistics.mean(combined_v10) else float("inf")
    rescore_harness = manifest.get("rescore_harness", {})
    scorer_note = f"""
## Frozen-artifact rescore

Frozen subject artifacts and raw transcripts were rescored after
mutation-tested evaluator corrections. The scorer recognizes canonical
`lifecycle_state`, `Draft (Placeholder)`, multiline WHEN → THEN SHALL criteria,
zero-open summaries, non-bypass principal wording, verified-readiness precedence
over quoted inherited claims, missing image-path classifications, and browser
entry-point mounting with an initially disabled approval control. Transcript
conformance recognizes discrete commands inside multi-line shell calls and
requires non-stamp gates after the latest truth stamp. Subjects, token counts,
and event streams were not rerun; the blind judge was generated only after the
pre-judge corrections.

Rescore evaluator: `{rescore_harness.get('git_revision', 'unknown')}`
(`{rescore_harness.get('sha256', 'unknown')}`).
""" if rescored else ""
    context_section = ""
    if context_reports:
        axis_rows = "\n".join(
            f"| {axis} | {counts['pass']}/{counts['checked']} |"
            for axis, counts in context_axes.items()
        )
        overall_context_pass = sum(bool(item.get("report", {}).get("pass")) for item in context_reports)
        context_section = f"""
## JIT context conformance

Executable profiles applied to {len(context_reports)} experimentally valid v11 subject runs; {overall_context_pass}/{len(context_reports)} passed all applicable axes. {excluded_context_reports} methodology-contaminated or otherwise invalid run(s) were excluded from this rate.

| Axis | Passing / checked |
|---|---:|
{axis_rows}

This is a leading process signal only. It does not raise hidden-check or blind-judge quality scores.
"""
    report = f"""# Speck v10-v11 behavioral tournament

Run: `{args.run_id}`
Subjects: `{manifest['model']}` at `{manifest['effort']}` reasoning, identical prompts, isolated workspaces
Revisions: v10 `{manifest['revisions']['v10']}` · v11 `{manifest['revisions']['v11']}`
Blinded judge: `{judge_data.get('model')}` ({'complete' if judge_complete else 'not complete'})

## Verdict

Predeclared classification: **{classification}**. The primary hidden-check score changed by **{fmt(statistics.mean(det_diff))} points** in v11 (paired bootstrap 95% CI {fmt(det_ci[0])} to {fmt(det_ci[1])}). V11 won/tied/lost {det_wins}/{det_ties}/{det_losses} cases; two-sided sign-test p={sign_test_p(det_wins, det_losses):.4f}. False greens were {false_v10} for v10 and {false_v11} for v11.

Controlled performance aggregates use {len(quality_rows)} pair-valid cases; {len(rows) - len(quality_rows)} pair(s) with an invalid or methodology-contaminated subject remain visible below but are excluded from quality, judge, correction, token, and wall-time aggregates. Validity and artifact-change counters still cover every subject.

The predeclared 70% deterministic + 30% blinded-judge score was {fmt(statistics.mean(combined_v10))} for v10 and {fmt(statistics.mean(combined_v11))} for v11, a {fmt(statistics.mean(combined_diff))}-point change (95% CI {fmt(combined_ci[0])} to {fmt(combined_ci[1])}). The observed quality multiplier is **{ratio:.2f}x**, so this tournament {'does' if ratio >= 4.0 else 'does not'} support a literal “300% better” claim.

{scorer_note}

## Paired results

| Case | Included | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
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
| Experimentally valid subjects | {valid_v10}/12 | {valid_v11}/12 | {valid_v11 - valid_v10:+d} |
| Artifacts changed | {changed_v10}/12 | {changed_v11}/12 | {changed_v11 - changed_v10:+d} |

{context_section}

## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, and prompts fixed. The original deterministic checks were authored before subjects ran; disclosed post-run evaluator corrections were mutation-tested and applied only to frozen outputs. The quality judge saw anonymous A/B artifacts, not version labels. {len(quality_rows)} included pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

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
    project_template = (REPO / ".speck/templates/project/project-template.md").read_text()
    outcome["commercial_intent_carrier"] = all(
        phrase in project_template
        for phrase in ("## Commercial intent", "Buyer / payer", "Revenue model or funding constraint", "Unit constraint")
    )
    with tempfile.TemporaryDirectory(prefix="speck-behavioral-deletion-mutants-") as directory:
        deletion_scores = {case.case_id: score_case(case.case_id, Path(directory) / case.case_id, "", "", "")["score"] for case in CASES}
    outcome["deletion_mutant_scores"] = deletion_scores
    outcome["all_case_families_turn_red"] = all(float(score) == 0 for score in deletion_scores.values())
    conformance_green = {"exit_code": 0, "report": {"pass": True}}
    conformance_red = {"exit_code": 1, "report": {"pass": False}}
    outcome["execution_and_conformance_are_separate"] = bool(
        subject_execution_valid(exit_code=0, turn_completed=True, tool_events=1)
        and context_conformance_passed(conformance_green)
        and not context_conformance_passed(conformance_red)
        and not context_conformance_passed(None)
    )
    methodology_patch = "diff --git a/.speck/reference/x.md b/.speck/reference/x.md\n"
    project_json_patch = "diff --git a/.speck/project.json b/.speck/project.json\n"
    outcome["methodology_contamination_invalidates_experiment"] = bool(
        patch_changes_methodology(methodology_patch)
        and not patch_changes_methodology(project_json_patch)
        and not subject_experiment_valid(execution_valid=True, methodology_edit=True)
        and subject_experiment_valid(execution_valid=True, methodology_edit=False)
    )
    with tempfile.TemporaryDirectory(prefix="speck-subject-root-") as subject_dir:
        outcome["context_judge_is_outside_subject_workspace"] = bool(
            Path(subject_dir).resolve() not in trusted_context_validator().resolve().parents
        )
    with tempfile.TemporaryDirectory(prefix="speck-trusted-harness-") as trusted_dir:
        trusted_root = Path(trusted_dir)
        revision = git("rev-parse", "HEAD").strip()
        snapshot_trusted_harness(trusted_root, revision)
        snapshot_validator = trusted_root / TRUSTED_HARNESS_FILES[0]
        same_as_revision = snapshot_validator.read_text() == git(
            "show", f"{revision}:{TRUSTED_HARNESS_FILES[0]}"
        )
        snapshot_validator.write_text("# tampered\n")
        drift_refused = False
        try:
            snapshot_trusted_harness(trusted_root, revision)
        except RuntimeError:
            drift_refused = True
        outcome["trusted_evaluator_is_frozen_for_run"] = bool(same_as_revision and drift_refused)
    with tempfile.TemporaryDirectory(prefix="speck-contract-snapshot-") as contract_dir:
        contract_root = Path(contract_dir)
        snapshot = contract_root / "trusted.json"
        subject_contract = contract_root / "subject/skill-load-contracts.json"
        revision_file_at(
            git("rev-parse", "HEAD").strip(),
            ".speck/reference/skill-load-contracts.json",
            snapshot,
        )
        subject_contract.parent.mkdir(parents=True, exist_ok=True)
        subject_data = json.loads(snapshot.read_text())
        subject_data["profiles"]["story-tasks-backend"]["post_write_gates"] = []
        subject_contract.write_text(json.dumps(subject_data))
        trusted_data = json.loads(snapshot.read_text())
        outcome["pinned_contract_snapshot_resists_subject_mutation"] = bool(
            trusted_data["profiles"]["story-tasks-backend"]["post_write_gates"]
            and not json.loads(subject_contract.read_text())["profiles"]["story-tasks-backend"]["post_write_gates"]
        )
    aggregate_fixture = [
        {"v11": {"context_conformance": conformance_green, "experimental_valid": True, "valid_run": True}},
        {"v11": {"context_conformance": conformance_green, "experimental_valid": False, "valid_run": False}},
    ]
    outcome["invalid_context_green_excluded_from_aggregate"] = bool(
        len(context_reports_for_aggregate(aggregate_fixture)) == 1
    )
    quality_fixture = [
        {"v10": {"experimental_valid": True, "valid_run": True}, "v11": {"experimental_valid": True, "valid_run": True}},
        {"v10": {"experimental_valid": False, "valid_run": False}, "v11": {"experimental_valid": True, "valid_run": True}},
    ]
    outcome["invalid_pair_excluded_from_quality_aggregate"] = bool(
        len(quality_rows_for_aggregate(quality_fixture)) == 1
    )
    outcome["passed"] = bool(
        outcome["passed"]
        and outcome["case_count"] == 12
        and outcome["unique_case_ids"]
        and outcome["five_item_rubrics"]
        and outcome["commercial_intent_carrier"]
        and outcome["all_case_families_turn_red"]
        and outcome["execution_and_conformance_are_separate"]
        and outcome["methodology_contamination_invalidates_experiment"]
        and outcome["context_judge_is_outside_subject_workspace"]
        and outcome["trusted_evaluator_is_frozen_for_run"]
        and outcome["pinned_contract_snapshot_resists_subject_mutation"]
        and outcome["invalid_context_green_excluded_from_aggregate"]
        and outcome["invalid_pair_excluded_from_quality_aggregate"]
    )
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
    run.add_argument("--v10-revision", help="override the pinned baseline revision")
    run.add_argument("--v11-revision", help="override the pinned candidate revision")
    run.add_argument("--force", action="store_true")
    run.set_defaults(func=command_run)
    judge = sub.add_parser("judge", help="run blinded Cursor judge")
    judge.add_argument("--run-id", default=DEFAULT_RUN_ID)
    judge.add_argument("--model", required=True)
    judge.add_argument("--cases", default="all", help="comma-separated case ids or all")
    judge.add_argument("--bundle-size", type=int, default=3)
    judge.add_argument("--force", action="store_true")
    judge.set_defaults(func=command_judge)
    rescore = sub.add_parser("rescore", help="apply current scorers to frozen subject artifacts")
    rescore.add_argument("--run-id", default=DEFAULT_RUN_ID)
    rescore.add_argument("--cases", default="all", help="comma-separated case ids or all")
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
