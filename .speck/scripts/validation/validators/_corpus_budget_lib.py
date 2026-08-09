#!/usr/bin/env python3
"""Skill-catalog + agent-prose half of validate-corpus-budget.sh"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ALLOW_DISABLE = {"speck", "story", "epic"}

# Essay / history patterns banned in agent-consumed instruction files
ESSAY_RES = [
    re.compile(p, re.I)
    for p in (
        r"Field evidence",
        r"Until v10\.",
        r"Until v9\.",
        r"001-odd",
        r"Why this is no longer optional",
        r"anti-bloat trade",
        r"why Speck exists",
        r"\bfeel free to\b",
    )
]
EMOJI_HEADER = re.compile(r"^## .*[🎯🔄✅❌🚨📋🧠🔧💡🧪📊🧭🧱🏁]", re.M)

MAX_REF_LINES = 280


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


STRICT_ESSAY = ESSAY_RES
REF_ROOT_ESSAY = [
    re.compile(p, re.I)
    for p in (
        r"Field evidence",
        r"Until v10\.",
        r"001-odd",
        r"Why this is no longer optional",
        r"why Speck exists",
    )
]


def lint_agent_prose(path: Path, text: str, err, *, strict: bool = True) -> None:
    rel = path.as_posix()
    if EMOJI_HEADER.search(text):
        err(f"emoji section headers in {rel}")
    for rx in STRICT_ESSAY if strict else REF_ROOT_ESSAY:
        if rx.search(text):
            err(f"agent-prose essay pattern /{rx.pattern}/ in {rel}")
            break


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

        lint_agent_prose(skill_md, body, err)

        refs = skill_md.parent / "references"
        if refs.is_dir():
            for ref in sorted(refs.rglob("*.md")):
                rtext = ref.read_text()
                rlines = len(rtext.splitlines())
                key = f"{name}/references/{ref.relative_to(refs).as_posix()}"
                if rlines > MAX_REF_LINES:
                    if key in grandfather:
                        print(f"WARN grandfather ref {key} lines={rlines}")
                    else:
                        err(f"skill ref {key} lines {rlines} > {MAX_REF_LINES}")
                lint_agent_prose(ref, rtext, err)

    ref_root = root / ".speck" / "reference"
    if ref_root.is_dir():
        for ref in sorted(ref_root.glob("*.md")):
            lint_agent_prose(ref, ref.read_text(), err, strict=False)

    print(f"auto_skills={auto} desc_sum={desc_sum} (max {max_sum})")
    if desc_sum > max_sum:
        err(f"description sum {desc_sum} > {max_sum}")

    if gf_path.is_file():
        for name in sorted(grandfather):
            if "/" in name:
                # skill/references/path.md grandfather
                sm = skills / name
                if not sm.is_file():
                    err(f"grandfather entry '{name}' missing — remove from grandfather file")
                    continue
                if len(sm.read_text().splitlines()) <= MAX_REF_LINES:
                    err(f"grandfather entry '{name}' is now <= {MAX_REF_LINES} — remove from grandfather file")
                continue
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
