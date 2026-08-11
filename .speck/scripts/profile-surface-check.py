#!/usr/bin/env python3
"""Check every public surface declared in a project's PROFILE registry."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


STATE_RANK = {
    "no-ship": 0,
    "impl-green": 1,
    "integration-green": 2,
    "ux-rc": 3,
    "api-rc": 3,
    "commercial-rc": 4,
    "ship-rc": 5,
    "ship": 6,
}


@dataclass(frozen=True)
class Surface:
    name: str
    adapter: str
    target: str
    source: str
    required_by: str


def clean_cell(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "`":
        value = value[1:-1]
    return value.strip()


def normalize_state(value: str) -> str:
    return clean_cell(value).lower().replace("_", "-").replace(" ", "-")


def required_rank(value: str) -> int | None:
    states = re.findall(
        r"NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN|UX-RC|API-RC|COMMERCIAL-RC|SHIP-RC|SHIP",
        value.upper(),
    )
    ranks = [STATE_RANK[normalize_state(state)] for state in states]
    return min(ranks) if ranks else None


def resolve_project_id(root: Path, explicit: str) -> str:
    if explicit:
        return explicit
    config = root / ".speck/project.json"
    if config.is_file():
        try:
            data = json.loads(config.read_text())
            active = data.get("_active_project") or data.get("active_project")
            if isinstance(active, str) and active:
                return active
        except (OSError, json.JSONDecodeError):
            pass
    projects = root / "specs/projects"
    if projects.is_dir():
        candidates = [path.name for path in projects.iterdir() if path.is_dir()]
        if len(candidates) == 1:
            return candidates[0]
    return ""


def parse_registry(project_md: Path) -> tuple[list[Surface], bool, list[str]]:
    if not project_md.is_file():
        return [], False, []
    lines = project_md.read_text(errors="replace").splitlines()
    section: list[tuple[int, str]] = []
    active = False
    found_section = False
    for line_number, line in enumerate(lines, start=1):
        if re.match(r"^##\s+PROFILE surfaces\s*$", line, re.I):
            active = True
            found_section = True
            continue
        if active and line.startswith("## "):
            break
        if active:
            section.append((line_number, line))

    rows: list[tuple[int, list[str]]] = []
    errors: list[str] = []
    header_width = 0
    for line_number, line in section:
        if not re.match(r"^\s*\|.*\|\s*$", line):
            continue
        cells = [clean_cell(cell) for cell in line.strip().strip("|").split("|")]
        if cells and cells[0].lower() == "surface":
            header_width = len(cells)
            if header_width not in {4, 5}:
                errors.append(f"line {line_number}: PROFILE header requires 4 or 5 columns, found {header_width}")
            continue
        if all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells):
            continue
        if not header_width:
            errors.append(f"line {line_number}: PROFILE data row appears before a Surface header")
            continue
        if len(cells) != header_width:
            errors.append(
                f"line {line_number}: PROFILE row requires {header_width} columns from its header, found {len(cells)}"
            )
            continue
        rows.append((line_number, cells))

    surfaces: list[Surface] = []
    for line_number, cells in rows:
        if len(cells) >= 5:
            name, adapter, target, source, required = cells[:5]
        elif len(cells) == 4:
            name, target, source, required = cells
            label = name.lower()
            adapter = (
                "readme" if "readme" in label else
                "package" if "package" in label else
                "github" if "github" in label else
                "file"
            )
        if not all((name, adapter, target, source, required)):
            errors.append(f"line {line_number}: PROFILE row contains an empty required field")
            continue
        if adapter.lower() not in {"readme", "package", "github", "file"}:
            errors.append(f"line {line_number}: unsupported PROFILE adapter: {adapter}")
            continue
        if required_rank(required) is None:
            errors.append(f"line {line_number}: unknown Required by readiness state: {required}")
            continue
        surfaces.append(Surface(name, adapter.lower(), target, source, required))
    return surfaces, found_section, errors


def first_blockquote(path: Path) -> str:
    if not path.is_file():
        return ""
    for line in path.read_text(errors="replace").splitlines():
        if line.startswith("> "):
            return line[2:].strip()
    return ""


def paid_promise(path: Path) -> str:
    if not path.is_file():
        return ""
    active = False
    for line in path.read_text(errors="replace").splitlines():
        if re.match(r"^## (?:1\.|Section 1\b)", line) or re.match(r"^# Section 1\b", line):
            active = True
            continue
        if active and re.match(r"^## [0-9]+\.", line):
            break
        stripped = line.strip()
        if active and stripped and not stripped.startswith("#"):
            return stripped.lstrip("> ").strip()
    return ""


def safe_repo_path(root: Path, raw: str) -> Path | None:
    target = clean_cell(raw).split("#", 1)[0]
    if not target or target.startswith("remote:"):
        return None
    candidate = (root / target).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def source_text(root: Path, project_dir: Path, source: str) -> tuple[str, str]:
    clean = clean_cell(source)
    path_part, _, selector = clean.partition("#")
    if path_part == "product-contract.md":
        path = project_dir / path_part
    else:
        path = safe_repo_path(root, path_part)
    if path is None or not path.is_file():
        return "", f"source missing: {clean}"
    selector = selector.lower()
    if path.name == "product-contract.md" and selector in {"", "1", "section-1"}:
        text = paid_promise(path)
    elif path.name.lower() == "readme.md" and selector in {"one-liner", "oneliner", "pitch"}:
        text = first_blockquote(path)
    else:
        text = path.read_text(errors="replace")
    return text.strip(), "" if text.strip() else f"source empty: {clean}"


def github_description(root: Path) -> tuple[str, str]:
    if "SPECK_PROFILE_GITHUB_DESCRIPTION" in os.environ:
        if os.environ.get("SPECK_PROFILE_TEST_MODE") != "1":
            return "", "GitHub fixture override refused outside SPECK_PROFILE_TEST_MODE=1"
        value = os.environ["SPECK_PROFILE_GITHUB_DESCRIPTION"].strip()
        return value, "" if value else "GitHub description is empty"
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "description", "--jq", ".description // \"\""],
            cwd=root,
            text=True,
            capture_output=True,
            timeout=20,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return "", f"GitHub description unreachable: {exc}"
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip().splitlines()
        return "", "GitHub description unreachable" + (f": {detail[-1]}" if detail else "")
    value = result.stdout.strip()
    return value, "" if value else "GitHub description is empty"


def surface_text(root: Path, surface: Surface) -> tuple[str, str]:
    adapter = surface.adapter
    if adapter == "github":
        return github_description(root)
    path = safe_repo_path(root, surface.target)
    if path is None:
        return "", f"invalid or non-local target: {surface.target}"
    if adapter == "readme":
        value = first_blockquote(path)
        return value, "" if value else f"README one-liner missing: {surface.target}"
    if adapter == "package":
        if not path.is_file():
            return "", f"package target missing: {surface.target}"
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as exc:
            return "", f"package target unreadable: {exc}"
        selector = clean_cell(surface.target).partition("#")[2] or "description"
        value: object = data
        for key in selector.split("."):
            value = value.get(key, "") if isinstance(value, dict) else ""
        text = value.strip() if isinstance(value, str) else ""
        return text, "" if text else f"package field empty: {surface.target}"
    if adapter == "file":
        if not path.is_file():
            return "", f"file target missing: {surface.target}"
        text = path.read_text(errors="replace").strip()
        return text, "" if text else f"file target empty: {surface.target}"
    return "", f"unsupported adapter: {adapter}"


def tokens(value: str) -> set[str]:
    return set(re.findall(r"[a-zA-Z0-9]{3,}", value.lower()))


def overlap_pct(actual: str, expected: str) -> int:
    actual_tokens, expected_tokens = tokens(actual), tokens(expected)
    if not actual_tokens or not expected_tokens:
        return 0
    return round(100 * len(actual_tokens & expected_tokens) / min(len(actual_tokens), len(expected_tokens)))


def placeholder(value: str) -> bool:
    return bool(re.search(r"REPLACE_BEFORE_SHIP|\[[^\]]*(?:placeholder|project name|one-line)[^\]]*\]", value, re.I))


def result_line(kind: str, surface: Surface, detail: str) -> str:
    return f'{kind}: [{surface.name}] adapter={surface.adapter} target="{surface.target}" {detail}'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workspace_root", nargs="?", default=".")
    parser.add_argument("project_id", nargs="?", default="")
    parser.add_argument("--claim", default="")
    parser.add_argument("--surface", default="")
    args = parser.parse_args()

    root = Path(args.workspace_root).resolve()
    project_id = resolve_project_id(root, args.project_id)
    if not project_id:
        print("ERROR: No project ID found", file=sys.stderr)
        return 2
    project_dir = root / "specs/projects" / project_id
    surfaces, has_registry_section, registry_errors = parse_registry(project_dir / "project.md")
    legacy_registry = not surfaces
    if legacy_registry:
        surfaces = [Surface("Root README", "readme", "README.md", "product-contract.md#1", "UX-RC / API-RC")]

    if args.surface:
        needle = args.surface.lower()
        surfaces = [
            surface for surface in surfaces
            if needle in surface.name.lower() or needle == surface.adapter.lower()
        ]
        if not surfaces:
            print(f'PROFILE_DRIFT.P2: [registry] no declared surface matches "{args.surface}"')
            print(f"PROFILE_DRIFT_SUMMARY P1=0 P2=1 P3=0 surfaces=0 project={project_id} claim={args.claim or 'none'}")
            return 0

    claim = normalize_state(args.claim) if args.claim else ""
    if claim and claim not in STATE_RANK:
        print(f"ERROR: Unknown readiness claim: {args.claim}", file=sys.stderr)
        return 2
    claim_rank = STATE_RANK.get(claim, -1)
    counts = {"P1": 0, "P2": 0, "P3": 0}

    for error in registry_errors:
        print(f"PROFILE_DRIFT.P1: [registry] {error}")
        counts["P1"] += 1

    if legacy_registry:
        severity = "P1" if claim else "P3"
        reason = "PROFILE registry missing or empty; using legacy README-only fallback"
        if has_registry_section:
            reason = "PROFILE registry has no usable rows; using legacy README-only fallback"
        print(f"PROFILE_DRIFT.{severity}: [registry] {reason}")
        counts[severity] += 1

    seen: set[tuple[str, str]] = set()
    for surface in surfaces:
        identity = (surface.adapter, surface.target)
        if identity in seen:
            print(result_line("PROFILE_DRIFT.P1", surface, "duplicates another registry target"))
            counts["P1"] += 1
            continue
        seen.add(identity)
        required = required_rank(surface.required_by)
        if required is None:
            print(result_line("PROFILE_DRIFT.P1", surface, f'unknown required_by="{surface.required_by}"'))
            counts["P1"] += 1
            continue
        due = bool(claim) and claim_rank >= required
        if placeholder(surface.target) or placeholder(surface.source):
            severity = "P1" if due else "P2"
            print(result_line(f"PROFILE_DRIFT.{severity}", surface, f"registry placeholder remains required_by=\"{surface.required_by}\""))
            counts[severity] += 1
            continue

        expected, source_error = source_text(root, project_dir, surface.source)
        actual, target_error = surface_text(root, surface)
        if source_error or target_error or placeholder(actual):
            severity = "P1" if due else "P2"
            detail = source_error or target_error or "target contains a placeholder"
            print(result_line(f"PROFILE_DRIFT.{severity}", surface, f"{detail}; required_by=\"{surface.required_by}\""))
            counts[severity] += 1
            continue

        overlap = overlap_pct(actual, expected)
        if overlap < 20:
            severity = "P1" if due else "P2"
            print(result_line(f"PROFILE_DRIFT.{severity}", surface, f"severely diverged overlap={overlap}% required_by=\"{surface.required_by}\""))
            counts[severity] += 1
        elif overlap < 60:
            severity = "P1" if due else "P2"
            print(result_line(f"PROFILE_DRIFT.{severity}", surface, f"partially diverged overlap={overlap}% required_by=\"{surface.required_by}\""))
            counts[severity] += 1
        else:
            print(result_line("PROFILE_SURFACE PASS", surface, f"overlap={overlap}% required_by=\"{surface.required_by}\""))

        if surface.adapter == "readme":
            path = safe_repo_path(root, surface.target)
            readme = path.read_text(errors="replace") if path and path.is_file() else ""
            if "<!-- SPECK:START -->" not in readme or "<!-- SPECK:END -->" not in readme:
                print(result_line("PROFILE_DRIFT.P1", surface, "lacks SPECK:START..END markers"))
                counts["P1"] += 1
            if placeholder(readme):
                severity = "P1" if due else "P3"
                print(result_line(f"PROFILE_DRIFT.{severity}", surface, "contains unreplaced scaffold placeholders"))
                counts[severity] += 1
            first = readme.splitlines()[0] if readme.splitlines() else ""
            if first.startswith("# Speck"):
                print(result_line("PROFILE_DRIFT.P1", surface, "still has the legacy Speck marketing title"))
                counts["P1"] += 1

    print(
        "PROFILE_DRIFT_SUMMARY "
        f"P1={counts['P1']} P2={counts['P2']} P3={counts['P3']} "
        f"surfaces={len(surfaces)} project={project_id} claim={claim or 'none'}"
    )
    return 1 if counts["P1"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
