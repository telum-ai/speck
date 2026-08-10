#!/usr/bin/env python3
"""Manifest-backed JIT skill context loader with deterministic receipt."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

RECEIPT_PREFIX = "SPECK_CONTEXT_RECEIPT:"
BEGIN_MARKER = "---SPECK_CONTEXT_BEGIN "
END_MARKER = "---SPECK_CONTEXT_END "
DEFAULT_CONTRACT = ".speck/reference/skill-load-contracts.json"


class ContextError(Exception):
    """User-facing loader failure."""


def repo_root(start: Path | None = None) -> Path:
    cur = (start or Path.cwd()).resolve()
    for parent in (cur, *cur.parents):
        if (parent / ".speck").is_dir():
            return parent
    return cur


def normalize_rel(path: str) -> str:
    cleaned = path.replace("\\", "/")
    while cleaned.startswith("./"):
        cleaned = cleaned[2:]
    return cleaned


def resolve_inside(root: Path, rel: str) -> Path:
    rel = normalize_rel(rel)
    if not rel:
        raise ContextError(f"empty path in contract: {rel!r}")
    candidate = (root / rel).resolve()
    root_resolved = root.resolve()
    try:
        candidate.relative_to(root_resolved)
    except ValueError as exc:
        raise ContextError(f"path escapes root: {rel}") from exc
    return candidate


def load_contract(contract_path: Path) -> dict[str, Any]:
    try:
        data = json.loads(contract_path.read_text(encoding="utf-8"))
    except OSError as exc:
        raise ContextError(f"cannot read contract: {contract_path}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise ContextError(f"malformed contract JSON: {exc}") from exc

    if data.get("schema_version") != 1:
        raise ContextError("contract schema_version must be 1")
    profiles = data.get("profiles")
    if not isinstance(profiles, dict) or not profiles:
        raise ContextError("contract must contain a non-empty profiles object")
    return data


def parse_selections(raw: list[str]) -> dict[str, str]:
    selections: dict[str, str] = {}
    for token in raw:
        if "=" not in token:
            raise ContextError(f"selection must be KEY=VALUE: {token!r}")
        key, value = token.split("=", 1)
        if not key or not value or key in selections:
            raise ContextError(f"invalid or duplicate selection: {token!r}")
        selections[key] = value
    return selections


def get_profile(
    contract: dict[str, Any], profile: str, selections: dict[str, str] | None = None
) -> dict[str, Any]:
    profiles = contract.get("profiles", {})
    if profile not in profiles:
        known = ", ".join(sorted(profiles))
        raise ContextError(f"unknown profile {profile!r}; known: {known}")
    entry = profiles[profile]
    if not isinstance(entry, dict):
        raise ContextError(f"profile {profile!r} must be an object")

    required = entry.get("required_files")
    forbidden = entry.get("forbidden_files", [])
    gates = entry.get("post_write_gates", [])
    all_gates = entry.get("post_write_gates_all", [])

    if not isinstance(required, list) or not required:
        raise ContextError(f"profile {profile!r} requires non-empty required_files list")
    if not all(isinstance(p, str) and p for p in required):
        raise ContextError(f"profile {profile!r} required_files must be strings")
    if not isinstance(forbidden, list) or not all(isinstance(p, str) for p in forbidden):
        raise ContextError(f"profile {profile!r} forbidden_files must be a string list")
    if not isinstance(gates, list) or not all(isinstance(p, str) for p in gates):
        raise ContextError(f"profile {profile!r} post_write_gates must be a string list")
    if not isinstance(all_gates, list) or not all(isinstance(p, str) for p in all_gates):
        raise ContextError(f"profile {profile!r} post_write_gates_all must be a string list")

    selected = selections or {}
    selector_specs = entry.get("selectors", {})
    if not isinstance(selector_specs, dict):
        raise ContextError(f"profile {profile!r} selectors must be an object")
    unknown = sorted(set(selected) - set(selector_specs))
    if unknown:
        raise ContextError(f"profile {profile!r} has unknown selectors: {unknown}")

    resolved_required = list(required)
    resolved_forbidden = list(forbidden)
    resolved_all_gates = list(all_gates)
    exclusive_forbidden: list[str] = []
    for key, selector in selector_specs.items():
        if not isinstance(selector, dict) or not isinstance(selector.get("values"), dict):
            raise ContextError(f"profile {profile!r} selector {key!r} requires a values object")
        values = selector["values"]
        if key not in selected:
            if selector.get("required", False):
                raise ContextError(f"profile {profile!r} requires --select {key}=VALUE")
            continue
        value = selected[key]
        if value not in values or not isinstance(values[value], dict):
            raise ContextError(
                f"profile {profile!r} selector {key!r} unknown value {value!r}; "
                f"known: {', '.join(sorted(values))}"
            )
        chosen = values[value]
        chosen_required = chosen.get("required_files", [])
        chosen_forbidden = chosen.get("forbidden_files", [])
        chosen_all_gates = chosen.get("post_write_gates_all", [])
        if not isinstance(chosen_required, list) or not all(isinstance(p, str) and p for p in chosen_required):
            raise ContextError(f"profile {profile!r} selector {key}={value} has invalid required_files")
        if not isinstance(chosen_forbidden, list) or not all(isinstance(p, str) and p for p in chosen_forbidden):
            raise ContextError(f"profile {profile!r} selector {key}={value} has invalid forbidden_files")
        if not isinstance(chosen_all_gates, list) or not all(isinstance(p, str) and p for p in chosen_all_gates):
            raise ContextError(f"profile {profile!r} selector {key}={value} has invalid post_write_gates_all")
        resolved_required.extend(chosen_required)
        resolved_forbidden.extend(chosen_forbidden)
        resolved_all_gates.extend(chosen_all_gates)
        if selector.get("exclusive", False):
            for other_value, other in values.items():
                if other_value != value and isinstance(other, dict):
                    siblings = other.get("required_files", [])
                    if isinstance(siblings, list):
                        exclusive_forbidden.extend(p for p in siblings if isinstance(p, str))

    normalized_required = [normalize_rel(p) for p in resolved_required]
    if len(set(normalized_required)) != len(normalized_required):
        raise ContextError(f"profile {profile!r} has duplicate required_files paths")

    explicit_forbidden = {normalize_rel(p) for p in resolved_forbidden}
    overlap = set(normalized_required) & explicit_forbidden
    if overlap:
        raise ContextError(
            f"profile {profile!r} lists paths as both required and forbidden: {sorted(overlap)}"
        )
    normalized_forbidden = (
        explicit_forbidden | {normalize_rel(p) for p in exclusive_forbidden}
    ) - set(normalized_required)

    return {
        "required_files": normalized_required,
        "forbidden_files": sorted(normalized_forbidden),
        "post_write_gates": gates,
        "post_write_gates_all": list(dict.fromkeys(resolved_all_gates)),
        "selections": dict(sorted(selected.items())),
    }


def parse_receipt_line(line: str) -> dict[str, Any] | None:
    stripped = line.strip()
    if not stripped.startswith(RECEIPT_PREFIX):
        return None
    payload = stripped[len(RECEIPT_PREFIX) :]
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def emit_context(
    root: Path, profile: str, contract_path: Path, selections: dict[str, str] | None = None
) -> int:
    contract = load_contract(contract_path)
    spec = get_profile(contract, profile, selections)

    file_records: list[dict[str, Any]] = []
    total_bytes = 0

    payloads: list[tuple[str, bytes]] = []
    for rel in spec["required_files"]:
        path = resolve_inside(root, rel)
        if not path.is_file():
            print(f"speck_context: missing required file: {rel}", file=sys.stderr)
            return 1
        data = path.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        size = len(data)
        total_bytes += size
        file_records.append({"path": rel, "sha256": digest, "bytes": size})
        payloads.append((rel, data))

    receipt = {
        "schema_version": 1,
        "profile": profile,
        "selections": spec["selections"],
        "files": file_records,
        "total_bytes": total_bytes,
    }
    out = sys.stdout.buffer
    for rel, data in payloads:
        out.write(f"{BEGIN_MARKER}{rel}---\n".encode())
        out.write(data)
        if data and not data.endswith(b"\n"):
            out.write(b"\n")
        out.write(f"{END_MARKER}{rel}---\n".encode())
    rendered = json.dumps(receipt, separators=(",", ":"), sort_keys=True)
    out.write(f"{RECEIPT_PREFIX}{rendered}\n".encode())
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Load declared JIT skill context and emit a receipt.")
    parser.add_argument("profile", help="Contract profile id")
    parser.add_argument("--select", action="append", default=[], metavar="KEY=VALUE", help="Resolve a declared JIT branch selector")
    parser.add_argument("--root", type=Path, default=None, help="Repository root (default: auto-detect)")
    parser.add_argument("--contract", type=Path, default=None, help="Contract JSON path")
    args = parser.parse_args(argv)

    root = (args.root or repo_root()).resolve()
    contract = (args.contract or (root / DEFAULT_CONTRACT)).resolve()
    if not contract.is_file():
        print(f"speck_context: contract not found: {contract}", file=sys.stderr)
        return 1

    if not root.is_dir():
        print(f"speck_context: root is not a directory: {root}", file=sys.stderr)
        return 1

    try:
        selections = parse_selections(args.select)
        loaded = load_contract(contract)
        get_profile(loaded, args.profile, selections)
    except ContextError as exc:
        print(f"speck_context: {exc}", file=sys.stderr)
        return 1

    return emit_context(root, args.profile, contract, selections)


if __name__ == "__main__":
    raise SystemExit(main())
