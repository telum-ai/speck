#!/usr/bin/env python3
"""Validate that every load-bearing methodology obligation has a live carrier."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
BASELINE = ROOT / "tests/eval/semantic-conservation/baseline.json"
CLASSES = {"spine", "jit", "gate", "compatibility", "retired"}


def parse_frontmatter(text: str) -> str:
    match = re.match(r"^---\n(.*?)\n---", text, re.S)
    return match.group(1) if match else ""


def validate_compatibility(path: Path, text: str) -> list[str]:
    errors: list[str] = []
    frontmatter = parse_frontmatter(text)
    if not re.search(r"^disable-model-invocation:\s*true\s*$", frontmatter, re.M):
        errors.append(f"{path}: compatibility skill must disable model invocation")
    body = text.split("---", 2)[-1].strip().splitlines()
    meaningful = [line for line in body if line.strip()]
    if len(meaningful) > 12:
        errors.append(f"{path}: compatibility body exceeds 12 non-empty lines")
    references = path.parent / "references"
    if references.is_dir() and any(item.is_file() for item in references.rglob("*")):
        errors.append(f"{path}: compatibility skill owns reference files")
    return errors


def sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def extract_region(text: str, start: str, end: str) -> str:
    start_match = re.search(start, text, re.M)
    if not start_match:
        return ""
    end_match = re.search(end, text[start_match.end():], re.M)
    if not end_match:
        return ""
    end_offset = start_match.end() + end_match.start()
    return text[start_match.start():end_offset]


def validate(root: Path, baseline_path: Path) -> list[str]:
    errors: list[str] = []
    try:
        baseline: Any = json.loads(baseline_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [f"semantic baseline unreadable: {exc}"]
    if not isinstance(baseline, dict) or baseline.get("schema_version") != 1:
        return ["semantic baseline requires schema_version 1"]
    if not re.fullmatch(r"[0-9a-f]{40}", str(baseline.get("origin_revision", ""))):
        errors.append("semantic baseline requires a 40-character origin_revision")

    protected_regions = baseline.get("protected_regions")
    if not isinstance(protected_regions, list) or not protected_regions:
        errors.append("semantic baseline requires protected_regions")
    else:
        for index, region in enumerate(protected_regions):
            if not isinstance(region, dict):
                errors.append(f"protected region {index} must be an object")
                continue
            rel, start, end, expected = (region.get(key) for key in ("path", "start", "end", "sha256"))
            if not all(isinstance(value, str) and value for value in (rel, start, end, expected)):
                errors.append(f"protected region {index} requires path, start, end, and sha256")
                continue
            if not re.fullmatch(r"[0-9a-f]{64}", expected):
                errors.append(f"protected region {index} requires a 64-character sha256")
                continue
            path = root / rel
            if not path.is_file():
                errors.append(f"protected region carrier missing: {rel}")
                continue
            text = path.read_text(errors="replace")
            value = extract_region(text, start, end)
            if not value:
                errors.append(f"protected region boundaries missing: {rel} {start!r}..{end!r}")
            elif sha256(value) != expected:
                errors.append(f"protected region changed without a baseline update: {rel} {start!r}..{end!r}")

    protected_files = baseline.get("protected_files")
    protected_paths: set[str] = set()
    if not isinstance(protected_files, list) or not protected_files:
        errors.append("semantic baseline requires protected_files")
    else:
        for index, item in enumerate(protected_files):
            if not isinstance(item, dict) or not isinstance(item.get("path"), str) or not isinstance(item.get("sha256"), str):
                errors.append(f"protected file {index} requires path and sha256")
                continue
            if not re.fullmatch(r"[0-9a-f]{64}", item["sha256"]):
                errors.append(f"protected file {index} requires a 64-character sha256")
                continue
            if item["path"] in protected_paths:
                errors.append(f"protected file declared twice: {item['path']}")
                continue
            protected_paths.add(item["path"])
            path = root / item["path"]
            if not path.is_file():
                errors.append(f"protected file missing: {item['path']}")
            elif hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
                errors.append(f"protected file changed without a baseline update: {item['path']}")
    obligations = baseline.get("obligations")
    if not isinstance(obligations, list) or not obligations:
        return errors + ["semantic baseline requires a non-empty obligations list"]

    seen_ids: set[str] = set()
    class_counts = {name: 0 for name in CLASSES}
    for index, obligation in enumerate(obligations):
        if not isinstance(obligation, dict):
            errors.append(f"obligation {index} must be an object")
            continue
        obligation_id = obligation.get("id")
        classification = obligation.get("classification")
        rationale = obligation.get("rationale")
        carriers = obligation.get("carriers")
        forbidden = obligation.get("forbidden")
        prefix = f"obligation {obligation_id!r}"
        if not isinstance(obligation_id, str) or not obligation_id or obligation_id in seen_ids:
            errors.append(f"invalid or duplicate obligation id: {obligation_id!r}")
        else:
            seen_ids.add(obligation_id)
        if classification not in CLASSES:
            errors.append(f"{prefix} has invalid classification {classification!r}")
            continue
        class_counts[classification] += 1
        if not isinstance(rationale, str) or len(rationale.strip()) < 20:
            errors.append(f"{prefix} requires a substantive rationale")
        if not isinstance(carriers, list):
            errors.append(f"{prefix} carriers must be a list")
            continue
        if classification == "retired":
            if carriers:
                errors.append(f"{prefix} is retired but still declares carriers")
            if not isinstance(forbidden, list) or not forbidden:
                errors.append(f"{prefix} is retired but declares no forbidden residue")
                continue
            for forbidden_index, residue in enumerate(forbidden):
                if not isinstance(residue, dict):
                    errors.append(f"{prefix} forbidden residue {forbidden_index} must be an object")
                    continue
                rel = residue.get("path")
                anchors = residue.get("anchors", [])
                must_be_absent = residue.get("must_be_absent", False)
                if not isinstance(rel, str) or not rel or Path(rel).is_absolute() or ".." in Path(rel).parts:
                    errors.append(f"{prefix} forbidden residue {forbidden_index} has invalid path {rel!r}")
                    continue
                if not isinstance(must_be_absent, bool) or not isinstance(anchors, list):
                    errors.append(f"{prefix} forbidden residue {rel} has invalid rules")
                    continue
                path = root / rel
                if must_be_absent and path.exists():
                    errors.append(f"{prefix} retired path returned: {rel}")
                if anchors and path.is_file():
                    text = path.read_text(errors="replace")
                    for anchor in anchors:
                        if not isinstance(anchor, str) or not anchor:
                            errors.append(f"{prefix} forbidden residue {rel} has an invalid anchor")
                            continue
                        try:
                            matched = re.search(anchor, text, re.S | re.I)
                        except re.error as exc:
                            errors.append(f"{prefix} forbidden residue {rel} has invalid anchor {anchor!r}: {exc}")
                            continue
                        if matched:
                            errors.append(f"{prefix} retired doctrine returned in {rel}: {anchor!r}")
            continue
        if not carriers:
            errors.append(f"{prefix} has no live carrier")
            continue
        if classification == "spine" and not any(carrier.get("path") == "AGENTS.md" for carrier in carriers if isinstance(carrier, dict)):
            errors.append(f"{prefix} is spine but has no AGENTS.md carrier")
        if classification == "gate" and not any(
            isinstance(carrier, dict)
            and any(token in str(carrier.get("path", "")) for token in (".speck/scripts/", "tests/", ".test.", ".github/"))
            for carrier in carriers
        ):
            errors.append(f"{prefix} is a gate but has no executable or evaluator carrier")

        for carrier_index, carrier in enumerate(carriers):
            if not isinstance(carrier, dict):
                errors.append(f"{prefix} carrier {carrier_index} must be an object")
                continue
            rel = carrier.get("path")
            anchors = carrier.get("anchors")
            if not isinstance(rel, str) or not rel or Path(rel).is_absolute() or ".." in Path(rel).parts:
                errors.append(f"{prefix} carrier {carrier_index} has invalid path {rel!r}")
                continue
            path = root / rel
            if rel not in protected_paths:
                errors.append(f"{prefix} carrier is anchor-only instead of tamper-evident: {rel}")
            if not path.is_file():
                errors.append(f"{prefix} carrier missing: {rel}")
                continue
            if not isinstance(anchors, list) or not anchors or not all(isinstance(anchor, str) and anchor for anchor in anchors):
                errors.append(f"{prefix} carrier {rel} requires non-empty regex anchors")
                continue
            text = path.read_text(errors="replace")
            for anchor in anchors:
                try:
                    matched = re.search(anchor, text, re.S | re.I)
                except re.error as exc:
                    errors.append(f"{prefix} carrier {rel} has invalid anchor {anchor!r}: {exc}")
                    continue
                if not matched:
                    errors.append(f"{prefix} carrier {rel} lost anchor {anchor!r}")
            if classification == "compatibility":
                if not rel.endswith("/SKILL.md"):
                    errors.append(f"{prefix} compatibility carrier is not a SKILL.md: {rel}")
                else:
                    errors.extend(validate_compatibility(path, text))

    missing_classes = sorted(name for name, count in class_counts.items() if count == 0)
    if missing_classes:
        errors.append(f"semantic baseline leaves classifications unused: {missing_classes}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--baseline", type=Path, default=BASELINE)
    args = parser.parse_args()
    errors = validate(args.root.resolve(), args.baseline.resolve())
    if errors:
        for error in errors:
            print(f"SEMANTIC_CONSERVATION.P1: {error}", file=sys.stderr)
        return 1
    baseline = json.loads(args.baseline.read_text())
    counts: dict[str, int] = {}
    for row in baseline["obligations"]:
        counts[row["classification"]] = counts.get(row["classification"], 0) + 1
    detail = " ".join(f"{key}={counts[key]}" for key in sorted(counts))
    print(f"semantic-conservation: PASS obligations={len(baseline['obligations'])} {detail}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
