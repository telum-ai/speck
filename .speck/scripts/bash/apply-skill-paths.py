#!/usr/bin/env python3
"""Add Cursor paths: frontmatter to Speck skills (idempotent)."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3] if False else Path(".cursor/skills")

STORY = [
    "specs/projects/**/S*/**",
    "specs/projects/**/stories/**",
    "specs/projects/**/**/spec.md",
    "specs/projects/**/**/plan.md",
    "specs/projects/**/**/tasks.md",
]
EPIC = [
    "specs/projects/**/E*/**",
    "specs/projects/**/epics/**",
    "specs/projects/**/**/epic.md",
]
PROJECT = [
    "specs/projects/**",
]
UI = [
    "**/*.{tsx,jsx,vue,svelte,css,scss}",
    "specs/projects/**/**/ui-spec.md",
    "specs/projects/**/**/wireframes.md",
    "specs/projects/**/design-system.md",
]


def yaml_paths(patterns: list[str]) -> str:
    lines = ["paths:"]
    for p in patterns:
        lines.append(f'  - "{p}"')
    return "\n".join(lines)


def classify(name: str) -> list[str] | None:
    if name in ("visual-testing", "visual-quality", "story-ui-spec"):
        return UI
    if name.startswith("story-") or name == "story":
        return STORY
    if name.startswith("epic-") or name == "epic":
        return EPIC
    if name.startswith("project-"):
        return PROJECT
    return None


def upsert(skill_md: Path, patterns: list[str]) -> bool:
    text = skill_md.read_text()
    m = re.match(r"^---\n(.*?)\n---\n?", text, re.S)
    if not m:
        return False
    fm = m.group(1)
    rest = text[m.end() :]
    if re.search(r"^paths:", fm, re.M):
        # replace existing paths block
        fm2 = re.sub(
            r"^paths:.*?(?=\n[a-zA-Z0-9_-]+:|\Z)",
            yaml_paths(patterns) + "\n",
            fm,
            count=1,
            flags=re.S | re.M,
        )
        if fm2 == fm:
            return False
        fm = fm2.rstrip() + "\n"
    else:
        # insert after description block
        fm = fm.rstrip() + "\n" + yaml_paths(patterns) + "\n"
    skill_md.write_text(f"---\n{fm}---\n{rest}")
    return True


def main() -> None:
    skills = Path(".cursor/skills")
    n = 0
    for d in sorted(skills.iterdir()):
        if not d.is_dir():
            continue
        patterns = classify(d.name)
        if not patterns:
            continue
        sm = d / "SKILL.md"
        if not sm.is_file():
            continue
        if upsert(sm, patterns):
            print("paths:", d.name)
            n += 1
    print(f"updated {n} skills")


if __name__ == "__main__":
    main()
