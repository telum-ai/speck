#!/usr/bin/env python3
"""Post-hoc transcript validator for JIT skill context loading."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import shlex
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

DISCLAIMER = (
    "Transcript conformance proves declared context reach, selectivity, timing, and gate use only. "
    "It does not prove semantic understanding, correct application, or output quality."
)

PATH_IN_COMMAND_RE = re.compile(
    r"([A-Za-z0-9_./-]+\.(?:md|json|py|sh|txt|yaml|yml|toml|js|jsx|ts|tsx|go|rs|swift|java|kt|dart|css|scss|html))"
)


@dataclass
class AxisResult:
    axis: str
    status: str
    ok: bool
    details: list[str] = field(default_factory=list)


@dataclass
class CommandEvent:
    index: int
    command: str
    output: str
    exit_code: int | None
    success: bool


@dataclass
class FileChangeEvent:
    index: int
    paths: list[str]


@dataclass
class ParsedTranscript:
    commands: list[CommandEvent] = field(default_factory=list)
    file_changes: list[FileChangeEvent] = field(default_factory=list)
    prose_blocks: list[str] = field(default_factory=list)
    parse_errors: list[str] = field(default_factory=list)


def load_speck_context_module() -> Any:
    here = Path(__file__).resolve()
    local_path = here.parents[2] / "context" / "speck_context.py"
    spec = importlib.util.spec_from_file_location("speck_context", local_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import loader module from {local_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _command_exit_code(item: dict[str, Any], event: dict[str, Any]) -> int | None:
    for key in ("exit_code", "return_code", "status_code"):
        value = item.get(key, event.get(key))
        if value is not None:
            try:
                return int(value)
            except (TypeError, ValueError):
                return None
    return None


def _extract_paths_from_change(item: dict[str, Any]) -> list[str]:
    paths: list[str] = []
    for key in ("path", "file_path", "file", "target"):
        val = item.get(key)
        if isinstance(val, str) and val:
            paths.append(val)
    changes = item.get("changes")
    if isinstance(changes, list):
        for change in changes:
            if not isinstance(change, dict):
                continue
            for key in ("path", "file_path", "file"):
                val = change.get(key)
                if isinstance(val, str) and val:
                    paths.append(val)
    return paths


def parse_codex_transcript(text: str) -> ParsedTranscript:
    parsed = ParsedTranscript()
    for line_no, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        try:
            event = json.loads(stripped)
        except json.JSONDecodeError:
            parsed.prose_blocks.append(stripped)
            continue
        if not isinstance(event, dict):
            parsed.prose_blocks.append(stripped)
            continue

        item = _as_dict(event.get("item"))
        item_type = str(item.get("type") or event.get("type") or "")
        idx = len(parsed.commands) + len(parsed.file_changes)

        if item_type == "command_execution" or (
            "command" in item and item_type.endswith("command_execution")
        ):
            cmd = str(item.get("command") or "")
            output = str(item.get("aggregated_output") or item.get("output") or item.get("stdout") or "")
            exit_code = _command_exit_code(item, event)
            parsed.commands.append(
                CommandEvent(
                    index=idx,
                    command=cmd,
                    output=output,
                    exit_code=exit_code,
                    success=exit_code == 0,
                )
            )
            continue

        if item_type == "file_change" or item_type.endswith("file_change"):
            paths = _extract_paths_from_change(item)
            parsed.file_changes.append(FileChangeEvent(index=idx, paths=paths))
            continue

        # Some hosts wrap tool output at the top level.
        if event.get("type") in {"turn.completed", "turn.failed", "error"}:
            continue

        message = event.get("message")
        if isinstance(message, str) and message and event.get("type") in {None, "message", "assistant"}:
            parsed.prose_blocks.append(message)

    return parsed


def _normalize_repo_path(path: str, root: Path) -> str | None:
    raw = path.replace("\\", "/").strip().strip("'\"")
    if not raw:
        return None
    try:
        resolved = Path(raw)
        if resolved.is_absolute():
            rel = resolved.resolve().relative_to(root.resolve())
        else:
            rel = (root / raw).resolve().relative_to(root.resolve())
        return str(rel).replace("\\", "/")
    except (ValueError, OSError):
        root_s = str(root.resolve()).replace("\\", "/")
        if raw.startswith(root_s + "/"):
            return raw[len(root_s) + 1 :]
        token = raw.lstrip("./")
        for prefix in (".cursor/", ".speck/", "specs/"):
            if token.startswith(prefix):
                return token
            marker = f"/{prefix}"
            if marker in raw:
                return prefix + raw.split(marker, 1)[1]
        return None


def _paths_from_command(command: str, root: Path) -> set[str]:
    found: set[str] = set()
    for match in PATH_IN_COMMAND_RE.finditer(command):
        rel = _normalize_repo_path(match.group(1), root)
        if rel:
            found.add(rel)
    return found


def _receipts_from_output(output: str, loader: Any) -> list[dict[str, Any]]:
    receipts: list[dict[str, Any]] = []
    for line in output.splitlines():
        receipt = loader.parse_receipt_line(line)
        if receipt:
            receipts.append(receipt)
    return receipts


def _shell_script(command: str) -> str:
    """Unwrap the outer shell command emitted by Codex stream-json."""
    try:
        words = shlex.split(command, comments=True)
    except ValueError:
        return command
    if len(words) >= 3 and Path(words[0]).name in {"sh", "bash", "zsh"} and words[1] in {"-c", "-lc"}:
        return words[2]
    return command


def _heredoc_delimiters(line: str) -> list[tuple[str, bool]]:
    """Return unquoted shell heredoc delimiters declared on one command line."""
    found: list[tuple[str, bool]] = []
    index = 0
    quote: str | None = None
    escaped = False
    while index < len(line):
        char = line[index]
        if escaped:
            escaped = False
            index += 1
            continue
        if char == "\\" and quote != "'":
            escaped = True
            index += 1
            continue
        if quote:
            if char == quote:
                quote = None
            index += 1
            continue
        if char in {"'", '"'}:
            quote = char
            index += 1
            continue
        if char == "#" and (index == 0 or line[index - 1].isspace()):
            break
        if line.startswith("<<<", index) or not line.startswith("<<", index):
            index += 1
            continue
        cursor = index + 2
        strip_tabs = False
        if cursor < len(line) and line[cursor] == "-":
            strip_tabs = True
            cursor += 1
        while cursor < len(line) and line[cursor] in " \t":
            cursor += 1
        if cursor >= len(line):
            break
        token_quote = line[cursor] if line[cursor] in {"'", '"'} else None
        if token_quote:
            cursor += 1
            end = line.find(token_quote, cursor)
            if end < 0:
                break
            delimiter = line[cursor:end]
            cursor = end + 1
        else:
            end = cursor
            while end < len(line) and not line[end].isspace() and line[end] not in ";&|<>":
                end += 1
            delimiter = line[cursor:end]
            cursor = end
        if delimiter:
            found.append((delimiter, strip_tabs))
        index = max(cursor, index + 2)
    return found


def _without_heredoc_bodies(script: str) -> str:
    """Blank heredoc payloads so prose cannot impersonate executed argv."""
    pending: list[tuple[str, bool]] = []
    rendered: list[str] = []
    for line in script.splitlines(keepends=True):
        newline = "\n" if line.endswith(("\n", "\r")) else ""
        logical = line.rstrip("\r\n")
        if pending:
            delimiter, strip_tabs = pending[0]
            candidate = logical.lstrip("\t") if strip_tabs else logical
            if candidate == delimiter:
                pending.pop(0)
            rendered.append(newline)
            continue
        rendered.append(line)
        pending.extend(_heredoc_delimiters(logical))
    return "".join(rendered)


def _command_parts(command: str) -> list[tuple[list[str], str]]:
    try:
        # A Codex command frequently contains a real multi-line shell script.
        # Newlines are command separators in the shell, not ordinary spaces.
        # Keeping them as punctuation prevents `read-only-command\nloader` from
        # being misparsed as one argv vector while still respecting quoted
        # newlines through shlex.
        lexer = shlex.shlex(_without_heredoc_bodies(_shell_script(command)), posix=True, punctuation_chars=";&|\n")
        lexer.whitespace = " \t\r"
        lexer.whitespace_split = True
        lexer.commenters = "#"
        words = list(lexer)
    except ValueError:
        return []
    parts: list[tuple[list[str], str]] = []
    current: list[str] = []
    for word in words:
        if word and set(word) <= {";", "&", "|", "\n"}:
            if current:
                parts.append((current, word))
                current = []
            continue
        current.append(word)
    if current:
        parts.append((current, ""))
    return parts


def _command_segments(command: str) -> list[list[str]]:
    return [segment for segment, _ in _command_parts(command)]


def _effective_words(segment: list[str]) -> list[str]:
    words = list(segment)
    while words and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]):
        words.pop(0)
    if words and Path(words[0]).name in {"env", "command", "time"}:
        words.pop(0)
        while words and (words[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0])):
            words.pop(0)
    return words


def _loader_invocation_matches(command: str, profile: str, selections: dict[str, str]) -> bool:
    for segment in _command_segments(command):
        words = _effective_words(segment)
        if not words:
            continue
        program = Path(words[0]).name
        if program == "speck_context.py":
            script_idx = 0
        elif re.fullmatch(r"python(?:3(?:\.\d+)?)?", program) and len(words) > 1 and Path(words[1]).name == "speck_context.py":
            script_idx = 1
        else:
            continue
        if len(words) <= script_idx + 1 or words[script_idx + 1] != profile:
            continue
        selected: list[str] = []
        rest = words[script_idx + 2 :]
        index = 0
        valid = True
        while index < len(rest):
            token = rest[index]
            if token == "--select":
                if index + 1 >= len(rest):
                    valid = False
                    break
                selected.append(rest[index + 1])
                index += 2
                continue
            if token.startswith("--select="):
                selected.append(token.split("=", 1)[1])
            index += 1
        parsed: dict[str, str] = {}
        for token in selected:
            if "=" not in token:
                valid = False
                break
            key, value = token.split("=", 1)
            if not key or not value or key in parsed:
                valid = False
                break
            parsed[key] = value
        if valid and parsed == selections:
            return True
    return False


def _loader_commands(
    commands: list[CommandEvent], profile: str, selections: dict[str, str]
) -> list[CommandEvent]:
    return [cmd for cmd in commands if _loader_invocation_matches(cmd.command, profile, selections)]


def _receipt_paths(receipt: dict[str, Any]) -> list[str]:
    files = receipt.get("files")
    if not isinstance(files, list):
        return []
    paths: list[str] = []
    for entry in files:
        if isinstance(entry, dict) and isinstance(entry.get("path"), str):
            paths.append(entry["path"])
    return paths


def _context_blocks(output: str, loader: Any) -> tuple[list[tuple[str, bytes]], list[str]]:
    blocks: list[tuple[str, bytes]] = []
    problems: list[str] = []
    begin = re.compile(rf"^{re.escape(loader.BEGIN_MARKER)}(.+?)---\n", re.MULTILINE)
    cursor = 0
    while True:
        match = begin.search(output, cursor)
        if not match:
            break
        rel = match.group(1)
        end_marker = f"{loader.END_MARKER}{rel}---\n"
        end = output.find(end_marker, match.end())
        if end < 0:
            problems.append(f"context body for {rel} has no matching END marker")
            break
        blocks.append((rel, output[match.end() : end].encode("utf-8")))
        cursor = end + len(end_marker)
    return blocks, problems


def _receipt_integrity(
    receipt: dict[str, Any],
    *,
    output: str,
    root: Path,
    required: list[str],
    selections: dict[str, str],
    gates: list[str],
    all_gates: list[str],
    expected_schema: int,
    loader: Any,
) -> list[str]:
    problems: list[str] = []
    if receipt.get("schema_version") != expected_schema:
        problems.append(
            f"receipt schema_version {receipt.get('schema_version')!r} != expected {expected_schema}"
        )
    if receipt.get("selections", {}) != selections:
        problems.append(
            f"receipt selections {receipt.get('selections', {})!r} != expected {selections!r}"
        )
    if expected_schema >= 2:
        if receipt.get("post_write_gates") != gates:
            problems.append(
                f"receipt post_write_gates {receipt.get('post_write_gates')!r} != expected {gates!r}"
            )
        if receipt.get("post_write_gates_all") != all_gates:
            problems.append(
                "receipt post_write_gates_all "
                f"{receipt.get('post_write_gates_all')!r} != expected {all_gates!r}"
            )
        expected_policy = getattr(loader, "GATE_POLICY", "direct-event-exit-bound")
        if receipt.get("gate_policy") != expected_policy:
            problems.append(
                f"receipt gate_policy {receipt.get('gate_policy')!r} != expected {expected_policy!r}"
            )
    files = receipt.get("files")
    if not isinstance(files, list) or len(files) != len(required):
        problems.append("receipt file records do not match required file count")
        return problems
    blocks, block_problems = _context_blocks(output, loader)
    problems.extend(block_problems)
    block_paths = [path for path, _ in blocks]
    if block_paths != required:
        problems.append(f"context body order mismatch: expected {required}, got {block_paths}")
    bodies = {path: body for path, body in blocks}
    total = 0
    for rel, record in zip(required, files):
        if not isinstance(record, dict) or record.get("path") != rel:
            problems.append(f"receipt record path mismatch for {rel}")
            continue
        try:
            data = loader.resolve_inside(root, rel).read_bytes()
        except (OSError, loader.ContextError) as exc:
            problems.append(f"cannot verify receipt file {rel}: {exc}")
            continue
        expected_hash = hashlib.sha256(data).hexdigest()
        if record.get("sha256") != expected_hash:
            problems.append(f"receipt sha256 mismatch for {rel}")
        if record.get("bytes") != len(data):
            problems.append(f"receipt byte count mismatch for {rel}")
        expected_body = data if not data or data.endswith(b"\n") else data + b"\n"
        if bodies.get(rel) != expected_body:
            problems.append(f"emitted context body mismatch for {rel}")
        total += len(data)
    if receipt.get("total_bytes") != total:
        problems.append(
            f"receipt total_bytes {receipt.get('total_bytes')!r} != verified {total}"
        )
    return problems


def _script_path_matches(token: str, gate: str, root: Path) -> bool:
    candidate = Path(token)
    if not candidate.is_absolute():
        candidate = root / candidate
    expected = root / gate
    try:
        return candidate.resolve() == expected.resolve()
    except OSError:
        return False


def _direct_gate_words(segment: list[str]) -> list[str]:
    """Unwrap only literal, exit-preserving prefixes for direct gate proof."""
    words = list(segment)

    def pop_safe_assignments() -> bool:
        while words and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]):
            assignment = words.pop(0)
            if any(marker in assignment for marker in ("$(", "`", "<(", ">(")):
                return False
        return True

    if not pop_safe_assignments():
        return []
    if words and Path(words[0]).name in {"env", "command", "time"}:
        words.pop(0)
        while words and words[0].startswith("-"):
            words.pop(0)
        if not pop_safe_assignments():
            return []
    return words


def _segment_invokes_gate(segment: list[str], gate: str, root: Path) -> bool:
    # shlex does not understand command substitution. A dedicated direct-word
    # parser prevents `RC=$(bash gate) true` and
    # `env RC=$(bash gate) true` from exposing the nested gate as argv[0].
    words = _direct_gate_words(segment)
    if not words:
        return False
    program = Path(words[0]).name
    if gate.endswith(".sh"):
        return _script_path_matches(words[0], gate, root) or (
            program in {"sh", "bash", "zsh"}
            and len(words) > 1
            and _script_path_matches(words[1], gate, root)
        )
    if gate == "pytest":
        return program == "pytest" or (
            re.fullmatch(r"python(?:3(?:\.\d+)?)?", program) is not None
            and len(words) > 2 and words[1:3] == ["-m", "pytest"]
        )
    if gate == "unittest":
        return program == "unittest" or (
            re.fullmatch(r"python(?:3(?:\.\d+)?)?", program) is not None
            and len(words) > 2 and words[1:3] == ["-m", "unittest"]
        )
    expected = shlex.split(gate)
    if not expected:
        return False
    actual_program = "gradle" if program == "gradlew" else program
    expected_program = Path(expected[0]).name
    return [actual_program, *words[1 : len(expected)]] == [expected_program, *expected[1:]]


def _command_proves_gate(command: str, gate: str, root: Path) -> bool:
    parts = _command_parts(command)
    # The contract deliberately requires one direct gate command per tool
    # event. That makes the recorded event exit code the gate exit code without
    # emulating shell state across `set -e`, lists, pipelines,
    # substitution-wrapped gates, background jobs, functions, or wrappers that
    # can launder a failure.
    return (
        len(parts) == 1
        and parts[0][1] == ""
        and _segment_invokes_gate(parts[0][0], gate, root)
    )


def _inferred_mutation_paths(command: CommandEvent, root: Path) -> list[str]:
    if not command.success:
        return []
    script = _shell_script(command.command)
    redirect = re.search(
        r"(?<![<>])(?:>>|>)\s*['\"]?([A-Za-z0-9_./-]+\.(?:md|json|py|sh|txt|yaml|yml|toml|js|jsx|ts|tsx|go|rs|swift|java|kt|dart|css|scss|html))",
        script,
    )
    write_capable = False
    for segment in _command_segments(command.command):
        words = _effective_words(segment)
        if not words:
            continue
        program = Path(words[0]).name
        lowered = " ".join(words).lower()
        if program in {"touch", "cp", "mv", "install", "tee", "truncate"}:
            write_capable = True
        elif re.fullmatch(r"python(?:3(?:\.\d+)?)?", program) and re.search(
            r"(?:\.write\s*\(|write_(?:text|bytes)\s*\(|open\s*\([^)]*,\s*['\"][wax+])", lowered
        ):
            write_capable = True
        elif program in {"node", "deno", "bun"} and re.search(r"(?:writefile|appendfile|creat[e]?writestream)", lowered):
            write_capable = True
        elif program == "ruby" and re.search(r"file\.(?:write|open)", lowered):
            write_capable = True
        elif program == "perl" and any(re.fullmatch(r"-[a-z]*i[a-z]*", word) for word in words[1:]):
            write_capable = True
        elif program == "sed" and any(word == "-i" or word.startswith("-i.") for word in words[1:]):
            write_capable = True
        elif program == "dd" and any(word.startswith("of=") for word in words[1:]):
            write_capable = True
        elif program == "git" and len(words) > 1 and words[1] in {
            "apply", "am", "checkout", "switch", "restore", "reset", "merge", "rebase", "cherry-pick"
        }:
            write_capable = True
        elif program in {"npm", "pnpm", "yarn", "bun"} and len(words) > 1 and words[1] in {
            "install", "add", "remove", "update"
        }:
            write_capable = True
    if not redirect and not write_capable:
        return []
    paths = sorted(_paths_from_command(script, root))
    if redirect:
        rel = _normalize_repo_path(redirect.group(1), root)
        if rel and rel not in paths:
            paths.append(rel)
    return paths or ["<write-capable-command>"]


def evaluate_axes(
    *,
    profile: str,
    spec: dict[str, Any],
    transcript: ParsedTranscript,
    root: Path,
    loader: Any,
    expected_receipt_schema: int,
) -> list[AxisResult]:
    required = spec["required_files"]
    forbidden = set(spec["forbidden_files"])
    gates = spec["post_write_gates"]
    all_gates = spec.get("post_write_gates_all", [])
    selections = spec.get("selections", {})

    loader_cmds = _loader_commands(transcript.commands, profile, selections)
    receipt_events: list[tuple[CommandEvent, dict[str, Any]]] = []
    for cmd in loader_cmds:
        if cmd.success:
            receipt_events.extend((cmd, receipt) for receipt in _receipts_from_output(cmd.output, loader))

    reach = AxisResult(axis="REACH", status="fail", ok=False)
    selectivity = AxisResult(axis="SELECTIVITY", status="fail", ok=False)
    timing = AxisResult(axis="TIMING", status="fail", ok=False)
    gate_use = AxisResult(axis="GATE_USE", status="fail", ok=False)

    if not loader_cmds:
        msg = "no completed loader command containing speck_context.py and profile found"
        for axis in (reach, selectivity, timing):
            axis.details.append(msg)
        if gates or all_gates:
            gate_use.details.append(msg)
        else:
            gate_use.status = "not_applicable"
            gate_use.ok = True
        return [reach, selectivity, timing, gate_use]

    successful_loaders = [c for c in loader_cmds if c.success]
    if not successful_loaders:
        reach.details.append("loader command(s) present but none completed with exit 0")
        selectivity.details.append("loader command(s) present but none completed with exit 0")
        timing.details.append("loader command(s) present but none completed with exit 0")
        if gates or all_gates:
            gate_use.details.append("loader command(s) present but none completed with exit 0")
        else:
            gate_use.status = "not_applicable"
            gate_use.ok = True
        return [reach, selectivity, timing, gate_use]

    if not receipt_events:
        reach.details.append("successful loader command output missing SPECK_CONTEXT_RECEIPT line")
        selectivity.details.append("successful loader command output missing SPECK_CONTEXT_RECEIPT line")
        timing.details.append("successful loader command output missing SPECK_CONTEXT_RECEIPT line")
        if gates or all_gates:
            gate_use.details.append("successful loader command output missing SPECK_CONTEXT_RECEIPT line")
        else:
            gate_use.status = "not_applicable"
            gate_use.ok = True
        return [reach, selectivity, timing, gate_use]

    receipt_cmd, receipt = receipt_events[0]
    receipt_profile = receipt.get("profile")
    receipt_paths = _receipt_paths(receipt)

    integrity = _receipt_integrity(
        receipt,
        output=receipt_cmd.output,
        root=root,
        required=required,
        selections=selections,
        gates=gates,
        all_gates=all_gates,
        expected_schema=expected_receipt_schema,
        loader=loader,
    )
    if receipt_profile != profile:
        reach.details.append(f"receipt profile {receipt_profile!r} != expected {profile!r}")
    elif receipt_paths != required:
        reach.details.append(f"receipt file order mismatch: expected {required}, got {receipt_paths}")
    elif integrity:
        reach.details.extend(integrity)
    else:
        reach.status = "pass"
        reach.ok = True
        reach.details.append("loader argv, emitted bodies, receipt profile, selectors, ordered paths, hashes, and byte counts match contract")

    read_paths: set[str] = set(receipt_paths)
    for cmd in transcript.commands:
        read_paths.update(_paths_from_command(cmd.command, root))
        for rec in _receipts_from_output(cmd.output, loader):
            read_paths.update(_receipt_paths(rec))

    forbidden_hits = sorted(p for p in forbidden if p in read_paths)
    if forbidden_hits:
        selectivity.details.append(f"forbidden files observed in receipts/command reads: {forbidden_hits}")
    else:
        selectivity.status = "pass"
        selectivity.ok = True
        selectivity.details.append("no forbidden branch files in receipts or observed command reads")

    inferred_changes: list[FileChangeEvent] = []
    for command in transcript.commands:
        paths = _inferred_mutation_paths(command, root)
        if paths:
            inferred_changes.append(FileChangeEvent(index=command.index, paths=paths))
    mutations = sorted([*transcript.file_changes, *inferred_changes], key=lambda event: event.index)
    first_change_idx = mutations[0].index if mutations else None
    receipt_idx = receipt_cmd.index
    if first_change_idx is None:
        timing.details.append("no explicit or inferred mutation event; timing cannot be established")
    elif receipt_idx > first_change_idx:
        timing.details.append(
            f"first verified loader receipt at event {receipt_idx} is after first mutation at {first_change_idx}"
        )
    else:
        timing.status = "pass"
        timing.ok = True
        timing.details.append(
            f"verified receipt at event {receipt_idx} precedes first mutation at {first_change_idx}"
        )

    if not gates and not all_gates:
        gate_use.status = "not_applicable"
        gate_use.ok = True
        gate_use.details.append("profile declares no post_write_gates")
    elif not mutations:
        gate_use.details.append("no explicit or inferred mutation event; post-write gate ordering cannot be established")
    else:
        last_change_idx = mutations[-1].index
        after = [
            command
            for command in transcript.commands
            if command.index > last_change_idx and command.exit_code is not None
        ]
        any_matches = [c for c in after if any(_command_proves_gate(c.command, gate, root) for gate in gates)]
        missing_all = [
            gate for gate in all_gates
            if not any(_command_proves_gate(c.command, gate, root) for c in after)
        ]
        if gates and not any_matches:
            gate_use.details.append(f"no exit-bound post-mutation invocation of any gate in {gates!r}")
        if missing_all:
            gate_use.details.append(f"missing required post-mutation gate invocation(s): {missing_all}")
        if (not gates or any_matches) and not missing_all:
            witnessed = [any_matches[-1]] if any_matches else []
            witnessed.extend(
                next(c for c in reversed(after) if _command_proves_gate(c.command, gate, root))
                for gate in all_gates
            )
            gate_use.ok = True
            gate_use.status = "pass" if all(c.success for c in witnessed) else "conformant_red"
            outcomes = [f"exit={c.exit_code}: {c.command}" for c in witnessed]
            gate_use.details.append(
                "exit-bound gate outcome(s) after last mutation; red remains red: "
                f"{outcomes!r}"
            )
        else:
            gate_use.details.append(f"last mutation event was {last_change_idx}")

    return [reach, selectivity, timing, gate_use]


def run_validator(args: argparse.Namespace) -> int:
    requested_root = args.root.resolve() if args.root else None
    # The validator owns its parser and contract semantics. Importing Python
    # from the workspace being judged would let the subject redefine its judge.
    loader = load_speck_context_module()
    root = (requested_root or loader.repo_root()).resolve()
    contract_path = (args.contract or (root / loader.DEFAULT_CONTRACT)).resolve()

    if not args.transcript.is_file():
        print(f"validate-context-transcript: transcript not found: {args.transcript}", file=sys.stderr)
        return 2

    try:
        contract = loader.load_contract(contract_path)
        selections = loader.parse_selections(args.select)
        spec = loader.get_profile(contract, args.profile, selections)
    except loader.ContextError as exc:
        print(f"validate-context-transcript: {exc}", file=sys.stderr)
        return 2

    transcript_text = args.transcript.read_text(encoding="utf-8", errors="replace")
    if args.format != "codex":
        print(f"validate-context-transcript: unsupported format {args.format!r}", file=sys.stderr)
        return 2

    parsed = parse_codex_transcript(transcript_text)
    axes = evaluate_axes(
        profile=args.profile,
        spec=spec,
        transcript=parsed,
        root=root,
        loader=loader,
        expected_receipt_schema=args.receipt_schema,
    )
    required_fail = [a for a in axes if not a.ok and a.status != "not_applicable"]

    report = {
        "schema_version": 1,
        "profile": args.profile,
        "selections": spec.get("selections", {}),
        "disclaimer": DISCLAIMER,
        "axes": {
            a.axis: {"status": a.status, "ok": a.ok, "details": a.details} for a in axes
        },
        "pass": not required_fail,
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"profile: {args.profile}")
        print(DISCLAIMER)
        for axis in axes:
            mark = "PASS" if axis.ok else ("N/A" if axis.status == "not_applicable" else "FAIL")
            print(f"\n[{mark}] {axis.axis}")
            for detail in axis.details:
                print(f"  - {detail}")
        print(f"\noverall: {'PASS' if report['pass'] else 'FAIL'}")

    return 0 if report["pass"] else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate JIT context loader conformance in a transcript.")
    parser.add_argument("--transcript", type=Path, required=True, help="Codex stream-json transcript path")
    parser.add_argument("--profile", required=True, help="Contract profile id")
    parser.add_argument("--select", action="append", default=[], metavar="KEY=VALUE", help="Resolve a declared JIT branch selector")
    parser.add_argument("--root", type=Path, default=None, help="Repository root")
    parser.add_argument("--contract", type=Path, default=None, help="Contract JSON path")
    parser.add_argument(
        "--receipt-schema",
        type=int,
        choices=(1, 2),
        default=2,
        help="Expected receipt schema; use 1 only when rescoring a pinned legacy revision",
    )
    parser.add_argument("--format", choices=["codex"], default="codex", help="Transcript format")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON")
    args = parser.parse_args(argv)
    return run_validator(args)


if __name__ == "__main__":
    raise SystemExit(main())
