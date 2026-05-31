#!/usr/bin/env python3
"""
asset-drift-check.py — Detect duplicated SVG path geometry across source files.

Flags when the same brand/visual identity appears as authored geometry in 2+ files,
which indicates asset dual-encoding (e.g., logo in component AND icon generator).

Usage:
  python3 asset-drift-check.py [WORKSPACE_ROOT] [--min-length N]

Exit codes:
  0 — no duplicate geometry detected
  1 — duplicate geometry found (ASSET_DRIFT)
  2 — invocation error
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections import defaultdict

SKIP_DIRS = {
    ".git",
    "node_modules",
    "dist",
    "build",
    ".next",
    "out",
    ".cache",
    "vendor",
    "coverage",
    ".speck",
    "specs",
}

SCAN_EXTENSIONS = {
    ".tsx",
    ".jsx",
    ".ts",
    ".js",
    ".mjs",
    ".cjs",
    ".vue",
    ".svelte",
    ".svg",
    ".html",
    ".css",
}

# Match d="..." or d='...' on SVG path elements (attribute or JSX prop)
PATH_D_PATTERN = re.compile(
    r"""(?:\bd\s*=\s*|"d"\s*:\s*|"d"\s*=\s*\{?)"""
    r"""["']([^"']{20,})["']""",
    re.IGNORECASE,
)


def normalize_path_data(path_data: str) -> str:
    return re.sub(r"\s+", " ", path_data.strip())


def should_skip_dir(name: str) -> bool:
    return name in SKIP_DIRS or name.startswith(".")


def iter_source_files(root: str):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if not should_skip_dir(d)]
        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            if ext not in SCAN_EXTENSIONS:
                continue
            yield os.path.join(dirpath, filename)


def scan_workspace(root: str, min_length: int) -> dict[str, list[tuple[str, int]]]:
    """Map normalized path data -> list of (file, line_number)."""
    hits: dict[str, list[tuple[str, int]]] = defaultdict(list)

    for filepath in iter_source_files(root):
        try:
            with open(filepath, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
        except OSError:
            continue

        for match in PATH_D_PATTERN.finditer(content):
            raw = match.group(1)
            if len(raw) < min_length:
                continue
            normalized = normalize_path_data(raw)
            if len(normalized) < min_length:
                continue
            line_num = content[: match.start()].count("\n") + 1
            rel = os.path.relpath(filepath, root)
            hits[normalized].append((rel, line_num))

    return hits


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect duplicated SVG path geometry")
    parser.add_argument(
        "workspace_root",
        nargs="?",
        default=".",
        help="Repository root to scan (default: cwd)",
    )
    parser.add_argument(
        "--min-length",
        type=int,
        default=30,
        help="Minimum path d= string length to consider (default: 30)",
    )
    args = parser.parse_args()

    root = os.path.abspath(args.workspace_root)
    if not os.path.isdir(root):
        print(f"ERROR: Not a directory: {root}", file=sys.stderr)
        return 2

    hits = scan_workspace(root, args.min_length)
    duplicates = {k: v for k, v in hits.items() if len({f for f, _ in v}) > 1}

    if not duplicates:
        print("ASSET_DRIFT_SUMMARY duplicates=0")
        print("✅ No duplicated SVG path geometry detected.")
        return 0

    print(f"ASSET_DRIFT_SUMMARY duplicates={len(duplicates)} severity=P1")
    print("⚠️  Brand asset geometry may be dual-encoded (same path d= in 2+ files):\n")

    for idx, (path_data, locations) in enumerate(sorted(duplicates.items(), key=lambda x: -len(x[1])), 1):
        unique_files = sorted({f for f, _ in locations})
        preview = path_data[:60] + ("…" if len(path_data) > 60 else "")
        print(f"  [{idx}] Path geometry ({len(path_data)} chars): {preview!r}")
        print(f"      Defined in {len(unique_files)} files:")
        for filepath, line_num in sorted(set(locations)):
            print(f"        - {filepath}:{line_num}")
        print()

    print(
        "Remediation: collapse to ONE authoring source; generate app icon / favicon / OG / splash from it."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
