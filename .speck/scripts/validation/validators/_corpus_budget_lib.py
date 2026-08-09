#!/usr/bin/env python3
"""Skill-catalog half of validate-corpus-budget.sh"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ALLOW_DISABLE = {"speck", "story", "epic"}


def parse_fm(text: str) -> tuple[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n?", text, re.S)
    if not m:
        return "", text
    return m.group(1), text[m.end() :]


def description(fm: str) -> str:
    dm = re.search(r"^description:\s*(.*?)(?=\n[a-zA-Z0-9_-]+:|\Z)", fm, re.S | re.M)
    if not dm:
        return ""
    d = dm.group(1).strip()
    if d.startswith(">") or d.startswith(">-"):
        parts = d.split("\n", 1)
        d = parts[1] if len(parts) > 1 else ""
    d = re.sub(r"\s+", " ", d).strip()
    if d.startswith("|"):
        d = d[1:].strip()
    return d


def main() -> int:
    root = Path(sys.argv[1])
    max_desc = int(sys.argv[2])
    max_sum = int(sys.argv[3])
    max_body = int(sys.argv[4])
    gf_path = Path(sys.argv[5])

    grandfather: set[str] = set()
    if gf_path.is_file():
        for line in gf_path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            grandfather.add(line)

    skills = root / ".cursor" / "skills"
    fail = 0
    desc_sum = 0
    auto = 0

    def err(msg: str) -> None:
        nonlocal fail
        print(f"FAIL: {msg}")
        fail = 1

    for skill_md in sorted(skills.glob("*/SKILL.md")):
        name = skill_md.parent.name
        text = skill_md.read_text()
        fm, body = parse_fm(text)
        desc = description(fm)
        disabled = bool(re.search(r"^disable-model-invocation:\s*true\s*$", fm, re.M))

        if disabled:
            if name not in ALLOW_DISABLE:
                err(f"disable-model-invocation: true not allowed on skill '{name}'")
        else:
            auto += 1
            dlen = len(desc)
            desc_sum += dlen
            if dlen > max_desc:
                err(f"skill {name} description length {dlen} > {max_desc}: {desc[:80]}...")

        body_lines = len(body.splitlines())
        if body_lines > max_body:
            if name in grandfather:
                print(f"WARN grandfather body {name} lines={body_lines}")
            else:
                err(f"skill {name} body lines {body_lines} > {max_body} (not grandfathered)")

        if re.search(r"^## .*[🎯🔄✅❌🚨📋🧠🔧💡🧪📊🧭🧱🏁]", body, re.M):
            err(f"skill {name} has emoji section headers")

    print(f"auto_skills={auto} desc_sum={desc_sum} (max {max_sum})")
    if desc_sum > max_sum:
        err(f"description sum {desc_sum} > {max_sum}")

    if gf_path.is_file():
        for name in sorted(grandfather):
            sm = skills / name / "SKILL.md"
            if not sm.is_file():
                err(f"grandfather entry '{name}' skill missing — remove from grandfather file")
                continue
            fm, body = parse_fm(sm.read_text())
            if len(body.splitlines()) <= max_body:
                err(f"grandfather entry '{name}' is now <= {max_body} — remove from grandfather file")

    return fail


if __name__ == "__main__":
    raise SystemExit(main())
