#!/usr/bin/env python3
"""Filter banned-language grep hits inside forbidding/teaching context."""

import re
import sys

FORBIDDING_HEADER = re.compile(
    r"not\s+this|banned|avoid|negative|what we explicitly do not|❌",
    re.I,
)
FORBIDDING_BLOCKQUOTE = re.compile(
    r"\b(not this|banned|avoid|do not|we are not)\b",
    re.I,
)


def split_cells(row: str) -> list[str]:
    row = row.strip()
    if row.startswith("|"):
        row = row[1:]
    if row.endswith("|"):
        row = row[:-1]
    return [c.strip() for c in row.split("|")]


def table_forbidding_columns(lines: list[str], idx: int) -> set[int]:
    start = idx
    while start > 0 and "|" in lines[start - 1]:
        start -= 1
    header_idx = None
    for i in range(start, idx + 1):
        line = lines[i].strip()
        if "|" not in line:
            continue
        if re.match(r"^\|[\s\-:|]+\|$", line):
            continue
        header_idx = i
        break
    if header_idx is None:
        return set()
    headers = split_cells(lines[header_idx])
    return {i for i, h in enumerate(headers) if FORBIDDING_HEADER.search(h)}


def should_skip(file_path: str, line_no: int, term_lc: str) -> bool:
    try:
        with open(file_path, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return False
    idx = line_no - 1
    if idx < 0 or idx >= len(lines):
        return False
    line = lines[idx]

    stripped = line.lstrip()
    if stripped.startswith(">"):
        if FORBIDDING_BLOCKQUOTE.search(stripped):
            return True

    if "|" in line and term_lc in line.lower():
        forbidding_cols = table_forbidding_columns(lines, idx)
        if forbidding_cols:
            cells = split_cells(line)
            hit_cols = [i for i, c in enumerate(cells) if term_lc in c.lower()]
            if hit_cols and all(i in forbidding_cols for i in hit_cols):
                return True
    return False


def main() -> int:
    if len(sys.argv) < 2:
        return 0
    term_lc = sys.argv[1].lower()
    raw = sys.stdin.read().strip()
    if not raw:
        return 0

    for entry in raw.splitlines():
        if not entry.strip():
            continue
        m = re.match(r"^(.+?):(\d+):(.*)$", entry)
        if not m:
            print(entry)
            continue
        path, line_no, _content = m.group(1), int(m.group(2)), m.group(3)
        if not should_skip(path, line_no, term_lc):
            print(entry)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
