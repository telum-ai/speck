#!/usr/bin/env python3
"""Evaluate one seeded artifact and prove its owning Speck instruction is reachable."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


CORPUS_ANCHORS: dict[str, tuple[str, tuple[str, ...]]] = {
    "banned-language": ("story-implement", (r"banned-language",)),
    "fabricated-evidence": ("story-validate", (r"evidence", r"cit(?:e|ation)|path")),
    "fake-green": ("story-validate", (r"IS-IT-GOOD|adjudicat",)),
    "phantom-promise": ("story-validate", (r"PRM|promise discharge",)),
    "self-audit": ("speck-audit", (r"Auditor.*implementer|separate.*(?:auditor|subagent|session|model)",)),
    "unreachable-excuse": ("story-validate", (r"logged reproduced|attempt log|reproduced.*(?:failure|attempt)",)),
}


def router_reaches(router: str, rel: str) -> bool:
    if f"references/{rel}" in router:
        return True
    if rel.startswith("states/") and "references/states/<kebab>.md" in router:
        return True
    if rel.startswith("lenses/L") and "references/lenses/L#.md" in router:
        return True
    return False


def contracted_files(root: Path, entrypoint: str) -> list[Path]:
    """Return the union of files executable profiles can load for an entrypoint."""
    contract_path = root / ".speck" / "reference" / "skill-load-contracts.json"
    try:
        data = json.loads(contract_path.read_text())
        profiles = data["profiles"]
    except (OSError, KeyError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"executable load contracts unavailable: {exc}") from exc

    paths: set[str] = set()
    for profile in profiles.values():
        if profile.get("entrypoint") != entrypoint:
            continue
        paths.update(profile.get("required_files", []))
        for selector in profile.get("selectors", {}).values():
            for value in selector.get("values", {}).values():
                paths.update(value.get("required_files", []))

    resolved: list[Path] = []
    for rel in sorted(paths):
        path = (root / rel).resolve()
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise RuntimeError(f"contracted path escapes repository: {rel}") from exc
        if not path.is_file():
            raise RuntimeError(f"contracted corpus file missing: {rel}")
        resolved.append(path)
    return resolved


def skill_corpus(root: Path, skill: str) -> str:
    skill_dir = root / ".cursor" / "skills" / skill
    router_path = skill_dir / "SKILL.md"
    if not router_path.is_file():
        raise RuntimeError(f"owning skill missing: {skill}")
    router = router_path.read_text()
    parts = [router]
    loaded = {router_path.resolve()}
    refs = skill_dir / "references"
    for path in sorted(refs.rglob("*.md")) if refs.is_dir() else []:
        if router_reaches(router, path.relative_to(refs).as_posix()):
            parts.append(path.read_text())
            loaded.add(path.resolve())
    entrypoint = router_path.relative_to(root).as_posix()
    for path in contracted_files(root, entrypoint):
        if path not in loaded:
            parts.append(path.read_text())
            loaded.add(path)
    return "\n".join(parts)


def assert_corpus_anchor(root: Path, defect_class: str) -> None:
    try:
        skill, patterns = CORPUS_ANCHORS[defect_class]
    except KeyError as exc:
        raise RuntimeError(f"unknown defect class: {defect_class}") from exc
    corpus = skill_corpus(root, skill)
    for pattern in patterns:
        if not re.search(pattern, corpus, re.IGNORECASE):
            raise RuntimeError(
                f"candidate corpus lost /{pattern}/ for {defect_class} in skill {skill}"
            )


def first(fixture: Path, name: str) -> str:
    path = fixture / name
    if not path.is_file():
        raise RuntimeError(f"fixture input missing: {path}")
    return path.read_text()


def defect_present(fixture: Path, defect_class: str) -> bool:
    if defect_class == "banned-language":
        text = first(fixture, "copy.md")
        return bool(re.search(r"ready for launch|premium polish complete|tests pass therefore done", text, re.I))

    if defect_class == "fabricated-evidence":
        text = first(fixture, "validation-report.md")
        match = re.search(r"screenshots/[^\s)]+", text)
        if not match:
            raise RuntimeError("fabricated-evidence fixture has no screenshot citation")
        return not (fixture / match.group(0)).is_file()

    if defect_class == "fake-green":
        text = first(fixture, "validation-report.md")
        claims_ux = "UX-RC" in text
        adjudicated = bool(re.search(r"adjudicat|IS-IT-GOOD|per-screen critique", text, re.I))
        return claims_ux and not adjudicated

    if defect_class == "phantom-promise":
        return bool(re.search(r"\|\s*open\s*\|", first(fixture, "traceability-matrix.md"), re.I))

    if defect_class == "self-audit":
        text = first(fixture, "audit-report.md")
        return bool(re.search(r"same-session-implementer|skills_invoked:\s*\[\s*\]", text, re.I))

    if defect_class == "unreachable-excuse":
        text = first(fixture, "validation-report.md")
        blocker = bool(re.search(r"named infra blocker|cannot reach|tooling limitation", text, re.I))
        attempted = bool(re.search(r"attempt log|reproduced", text, re.I))
        return blocker and not attempted

    raise RuntimeError(f"no evaluator for defect class: {defect_class}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("fixture", type=Path)
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()

    try:
        manifest = json.loads((args.fixture / "manifest.json").read_text())
        defect_class = manifest["class"]
        assert_corpus_anchor(args.root.resolve(), defect_class)
        caught = defect_present(args.fixture.resolve(), defect_class)
    except (OSError, KeyError, json.JSONDecodeError, RuntimeError) as exc:
        print(f"HARNESS_ERROR: {exc}", file=sys.stderr)
        return 2

    print("CATCH" if caught else "MISS")
    return 0 if caught else 1


if __name__ == "__main__":
    raise SystemExit(main())
