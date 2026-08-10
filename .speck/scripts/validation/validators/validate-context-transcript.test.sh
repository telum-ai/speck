#!/usr/bin/env bash
# validate-context-transcript.test.sh — mutation-backed tests for JIT context loader + transcript validator
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOADER="$ROOT/.speck/scripts/context/speck_context.py"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-context-transcript.py"
CONTRACT_SRC="$ROOT/.speck/reference/skill-load-contracts.json"
PROFILE="story-tasks-backend"
GATE_SUB="validate-story-tasks.sh"
FORBIDDEN=".cursor/skills/story-tasks/references/ui-tasks.md"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/.speck/reference"
cp "$CONTRACT_SRC" "$T/.speck/reference/skill-load-contracts.json"

copy_profile_tree() {
  local dst="$1"
  mkdir -p "$dst/.cursor/skills/story-tasks/references" "$dst/.speck/templates/story"
  cp "$ROOT/.speck/templates/story/tasks-template.md" "$dst/.speck/templates/story/tasks-template.md"
  cp "$ROOT/.cursor/skills/story-tasks/references/spine.md" "$dst/.cursor/skills/story-tasks/references/spine.md"
  cp "$ROOT/.cursor/skills/story-tasks/references/api-tasks.md" "$dst/.cursor/skills/story-tasks/references/api-tasks.md"
  cp "$ROOT/.cursor/skills/story-tasks/references/ui-tasks.md" "$dst/.cursor/skills/story-tasks/references/ui-tasks.md"
}

write_transcript() {
  local out="$1"; shift
  python3 - "$out" "$@" <<'PY'
import json, pathlib, sys

out = pathlib.Path(sys.argv[1])
events = []
idx = 0
i = 2
while i < len(sys.argv):
    kind = sys.argv[i]
    i += 1
    if kind == "cmd":
        command = sys.argv[i]; output_file = sys.argv[i+1]; exit_code = int(sys.argv[i+2]); i += 3
        output = pathlib.Path(output_file).read_text(encoding="utf-8", errors="replace")
        events.append({
            "type": "item.completed",
            "item": {
                "type": "command_execution",
                "command": command,
                "aggregated_output": output,
                "exit_code": exit_code,
            },
        })
    elif kind == "cmd_missing_exit":
        command = sys.argv[i]; output_file = sys.argv[i+1]; i += 2
        output = pathlib.Path(output_file).read_text(encoding="utf-8", errors="replace")
        events.append({
            "type": "item.completed",
            "item": {
                "type": "command_execution",
                "command": command,
                "aggregated_output": output,
                "status": "completed",
            },
        })
    elif kind == "change":
        path = sys.argv[i]; i += 1
        events.append({
            "type": "item.completed",
            "item": {"type": "file_change", "path": path},
        })
    elif kind == "raw":
        events.append(json.loads(sys.argv[i])); i += 1
    else:
        raise SystemExit(f"unknown transcript event kind: {kind}")
out.write_text("\n".join(json.dumps(e) for e in events) + "\n", encoding="utf-8")
PY
}

run_loader() {
  local work="$1" profile="$2" out_file="${3:-}"
  RC=0
  if [[ -n "$out_file" ]]; then
    python3 "$LOADER" "$profile" --root "$work" --contract "$work/.speck/reference/skill-load-contracts.json" >"$out_file" 2>"$out_file.stderr" || RC=$?
    OUT="$(<"$out_file")"
  else
    OUT=$(python3 "$LOADER" "$profile" --root "$work" --contract "$work/.speck/reference/skill-load-contracts.json" 2>&1) || RC=$?
  fi
}

run_validator() {
  local work="$1"; shift
  RC=0
  OUT=$(python3 "$VALIDATOR" "$@" --root "$work" --contract "$work/.speck/reference/skill-load-contracts.json" 2>&1) || RC=$?
}

echo "── loader: conforming profile ───────────────────────────────────────────────────────────────"
WORK="$T/conforming"
mkdir -p "$WORK/.speck/reference"
cp "$CONTRACT_SRC" "$WORK/.speck/reference/skill-load-contracts.json"
copy_profile_tree "$WORK"
run_loader "$WORK" "$PROFILE" "$T/loader.out"
[[ "$RC" == 0 ]] && grep -q '^SPECK_CONTEXT_RECEIPT:' "$T/loader.out" \
  && pass "loader exits 0 and emits receipt" || fail "loader conforming case (rc=$RC)"

echo "── loader: deterministic receipt/hash ─────────────────────────────────────────────────────"
RECEIPT1=$(grep '^SPECK_CONTEXT_RECEIPT:' "$T/loader.out" | tail -1)
run_loader "$WORK" "$PROFILE" "$T/loader2.out"
RECEIPT2=$(grep '^SPECK_CONTEXT_RECEIPT:' "$T/loader2.out" | tail -1)
[[ "$RECEIPT1" == "$RECEIPT2" ]] && pass "receipt line is deterministic across runs" || fail "deterministic receipt mismatch"
[[ "$RECEIPT1" == *'"schema_version":2'* ]] \
  && [[ "$RECEIPT1" == *'"post_write_gates":[".speck/scripts/validation/validators/validate-story-tasks.sh"]'* ]] \
  && [[ "$RECEIPT1" == *'"post_write_gates_all":[]'* ]] \
  && [[ "$RECEIPT1" == *'"gate_policy":"direct-event-exit-bound"'* ]] \
  && pass "receipt exposes the exact executable gate contract" || fail "receipt gate contract missing or incorrect"

python3 "$LOADER" project-evidence-ui-build --root "$ROOT" > "$T/evidence-loader.out"
EVIDENCE_RECEIPT=$(grep '^SPECK_CONTEXT_RECEIPT:' "$T/evidence-loader.out" | tail -1)
[[ "$EVIDENCE_RECEIPT" == *'"post_write_gates":[".speck/scripts/validation/validate-template.sh"]'* ]] \
  && [[ "$EVIDENCE_RECEIPT" == *'"post_write_gates_all":[".speck/scripts/stamp-truth.sh"]'* ]] \
  && pass "evidence contract requires both template validation and truth stamp" || fail "evidence contract gate semantics are not exact"

echo "── loader: missing required file ──────────────────────────────────────────────────────────"
MISS="$T/missing"
mkdir -p "$MISS/.speck/reference"
cp "$CONTRACT_SRC" "$MISS/.speck/reference/skill-load-contracts.json"
mkdir -p "$MISS/.cursor/skills/story-tasks/references"
mkdir -p "$MISS/.speck/templates/story"
cp "$ROOT/.speck/templates/story/tasks-template.md" "$MISS/.speck/templates/story/tasks-template.md"
cp "$ROOT/.cursor/skills/story-tasks/references/spine.md" "$MISS/.cursor/skills/story-tasks/references/spine.md"
# api-tasks.md intentionally omitted
run_loader "$MISS" "$PROFILE"
[[ "$RC" != 0 ]] && pass "missing required file fails closed" || fail "missing required file should fail (rc=$RC)"

echo "── loader: unknown profile ────────────────────────────────────────────────────────────────"
run_loader "$WORK" "not-a-real-profile"
[[ "$RC" != 0 ]] && pass "unknown profile fails closed" || fail "unknown profile should fail (rc=$RC)"

echo "── loader: path escape in contract ────────────────────────────────────────────────────────"
ESCAPE="$T/escape"
mkdir -p "$ESCAPE/.speck/reference"
copy_profile_tree "$ESCAPE"
python3 - <<'PY' > "$ESCAPE/.speck/reference/skill-load-contracts.json"
import json
print(json.dumps({
    "schema_version": 1,
    "profiles": {
        "evil": {
            "required_files": ["../../../etc/passwd"],
            "forbidden_files": [],
            "post_write_gates": []
        }
    }
}))
PY
run_loader "$ESCAPE" evil
[[ "$RC" != 0 ]] && [[ "$OUT" == *"path escapes root"* ]] && pass "path escape fails closed" || fail "path escape should fail as an escape (rc=$RC)"

echo "── validator: conforming transcript ───────────────────────────────────────────────────────"
TRANSCRIPT_OK="$T/ok.jsonl"
LOADER_CMD="python3 .speck/scripts/context/speck_context.py $PROFILE --root $WORK"
LOADER_OUT_FILE="$T/loader.out"
write_transcript "$TRANSCRIPT_OK" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB specs/projects/demo/stories/S001/tasks.md" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_OK" --profile "$PROFILE" --json
[[ "$RC" == 0 ]] && echo "$OUT" | grep -q '"pass": true' \
  && pass "conforming transcript passes all axes" || fail "conforming transcript (rc=$RC)"

echo "── validator: workspace loader cannot redefine its judge ─────────────────────────────────"
MALICIOUS_MARKER="$T/workspace-loader-executed"
mkdir -p "$WORK/.speck/scripts/context"
printf 'from pathlib import Path\nPath("%s").write_text("executed")\nRECEIPT_SCHEMA_VERSION = 1\n' \
  "$MALICIOUS_MARKER" > "$WORK/.speck/scripts/context/speck_context.py"
run_validator "$WORK" --transcript "$TRANSCRIPT_OK" --profile "$PROFILE" --json
[[ "$RC" == 0 ]] && [[ ! -e "$MALICIOUS_MARKER" ]] && echo "$OUT" | grep -q '"pass": true' \
  && pass "validator ignores workspace Python and keeps current receipt semantics" || fail "workspace loader must not execute or downgrade receipt checks (rc=$RC)"

echo "── validator: loader discovery in a multi-line shell call ────────────────────────────────"
TRANSCRIPT_MULTILINE="$T/multiline.jsonl"
MULTILINE_LOADER_CMD=$(printf 'rg --files | sed -n '\''1,2p'\''\npython3 .speck/scripts/context/speck_context.py %s --root %s' "$PROFILE" "$WORK")
write_transcript "$TRANSCRIPT_MULTILINE" \
  cmd "$MULTILINE_LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB specs/projects/demo/stories/S001/tasks.md" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_MULTILINE" --profile "$PROFILE" --json
[[ "$RC" == 0 ]] && echo "$OUT" | grep -q '"pass": true' \
  && pass "loader discovery survives multi-line shell wrapping" || fail "multi-line loader should pass (rc=$RC)"

echo "── validator: grouped gate commands are not direct evidence ───────────────────────────────"
TRANSCRIPT_GROUPED_GATE="$T/grouped-gate.jsonl"
GROUPED_GATE_CMD=$(printf 'set -e\ngit diff --check\nbash .speck/scripts/validation/validators/%s specs/projects/demo/stories/S001/tasks.md\ngit status --short' "$GATE_SUB")
write_transcript "$TRANSCRIPT_GROUPED_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$GROUPED_GATE_CMD" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_GROUPED_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "a gate grouped with other commands cannot borrow the event exit" || fail "grouped gate should fail GATE_USE (rc=$RC)"

echo "── validator: missing receipt ─────────────────────────────────────────────────────────────"
TRANSCRIPT_NOREC="$T/norec.jsonl"
echo "no receipt here" > "$T/norec.out"
write_transcript "$TRANSCRIPT_NOREC" \
  cmd "python3 .speck/scripts/context/speck_context.py $PROFILE --root $WORK" "$T/norec.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_NOREC" --profile "$PROFILE"
[[ "$RC" == 1 ]] && pass "missing receipt fails validator" || fail "missing receipt should fail (rc=$RC)"

echo "── validator: forged receipt paths ────────────────────────────────────────────────────────"
FORGED_RECEIPT='SPECK_CONTEXT_RECEIPT:{"schema_version":1,"profile":"story-tasks-backend","selections":{},"files":[{"path":"wrong.md","sha256":"deadbeef","bytes":1}],"total_bytes":1}'
echo "$FORGED_RECEIPT" > "$T/forged.out"
TRANSCRIPT_FORGED="$T/forged.jsonl"
write_transcript "$TRANSCRIPT_FORGED" \
  cmd "$LOADER_CMD" "$T/forged.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_FORGED" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "REACH" \
  && pass "forged receipt fails REACH" || fail "forged receipt should fail REACH (rc=$RC)"

echo "── validator: forged receipt hash with exact paths ─────────────────────────────────────────"
python3 - "$LOADER_OUT_FILE" "$T/forged-hash.out" <<'PY'
import json, pathlib, sys
line = next(x for x in pathlib.Path(sys.argv[1]).read_text().splitlines() if x.startswith("SPECK_CONTEXT_RECEIPT:"))
payload = json.loads(line.split(":", 1)[1])
payload["files"][0]["sha256"] = "0" * 64
pathlib.Path(sys.argv[2]).write_text("SPECK_CONTEXT_RECEIPT:" + json.dumps(payload, separators=(",", ":")) + "\n")
PY
TRANSCRIPT_FORGED_HASH="$T/forged-hash.jsonl"
write_transcript "$TRANSCRIPT_FORGED_HASH" \
  cmd "$LOADER_CMD" "$T/forged-hash.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_FORGED_HASH" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "sha256 mismatch" \
  && pass "exact-path forged hash fails REACH" || fail "forged hash should fail REACH (rc=$RC)"

echo "── validator: forged receipt gate contract ────────────────────────────────────────────────"
python3 - "$LOADER_OUT_FILE" "$T/forged-gates.out" <<'PY'
import json, pathlib, sys
source = pathlib.Path(sys.argv[1])
line = next(x for x in source.read_text().splitlines() if x.startswith("SPECK_CONTEXT_RECEIPT:"))
payload = json.loads(line.split(":", 1)[1])
payload["post_write_gates"] = []
text = source.read_text().replace(line, "SPECK_CONTEXT_RECEIPT:" + json.dumps(payload, separators=(",", ":"), sort_keys=True))
pathlib.Path(sys.argv[2]).write_text(text)
PY
TRANSCRIPT_FORGED_GATES="$T/forged-gates.jsonl"
write_transcript "$TRANSCRIPT_FORGED_GATES" \
  cmd "$LOADER_CMD" "$T/forged-gates.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_FORGED_GATES" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "receipt post_write_gates" \
  && pass "forged gate list fails REACH" || fail "forged gate list should fail REACH (rc=$RC)"

python3 - "$LOADER_OUT_FILE" "$T/forged-policy.out" <<'PY'
import json, pathlib, sys
source = pathlib.Path(sys.argv[1])
line = next(x for x in source.read_text().splitlines() if x.startswith("SPECK_CONTEXT_RECEIPT:"))
payload = json.loads(line.split(":", 1)[1])
payload["gate_policy"] = "trust-me"
text = source.read_text().replace(line, "SPECK_CONTEXT_RECEIPT:" + json.dumps(payload, separators=(",", ":"), sort_keys=True))
pathlib.Path(sys.argv[2]).write_text(text)
PY
TRANSCRIPT_FORGED_POLICY="$T/forged-policy.jsonl"
write_transcript "$TRANSCRIPT_FORGED_POLICY" \
  cmd "$LOADER_CMD" "$T/forged-policy.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_FORGED_POLICY" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "receipt gate_policy" \
  && pass "forged gate policy fails REACH" || fail "forged gate policy should fail REACH (rc=$RC)"

echo "── validator: correct receipt without emitted bodies ──────────────────────────────────────"
grep '^SPECK_CONTEXT_RECEIPT:' "$LOADER_OUT_FILE" > "$T/receipt-only.out"
TRANSCRIPT_RECEIPT_ONLY="$T/receipt-only.jsonl"
write_transcript "$TRANSCRIPT_RECEIPT_ONLY" \
  cmd "$LOADER_CMD" "$T/receipt-only.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_RECEIPT_ONLY" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "context body order mismatch" \
  && pass "correct receipt without bodies fails REACH" || fail "receipt-only output should fail REACH (rc=$RC)"

echo "── validator: profile must bind as loader argv ─────────────────────────────────────────────"
TRANSCRIPT_PROFILE_COMMENT="$T/profile-comment.jsonl"
write_transcript "$TRANSCRIPT_PROFILE_COMMENT" \
  cmd "python3 .speck/scripts/context/speck_context.py story-tasks-ui # $PROFILE" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_PROFILE_COMMENT" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "no completed loader command" \
  && pass "profile name in a shell comment cannot bind a loader" || fail "profile comment should fail REACH (rc=$RC)"

TRANSCRIPT_LOADER_HEREDOC="$T/loader-heredoc.jsonl"
LOADER_HEREDOC_CMD=$(printf "cat <<'EOF'\npython3 .speck/scripts/context/speck_context.py %s --root %s\nEOF" "$PROFILE" "$WORK")
write_transcript "$TRANSCRIPT_LOADER_HEREDOC" \
  cmd "$LOADER_HEREDOC_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_LOADER_HEREDOC" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "no completed loader command" \
  && pass "loader argv inside a heredoc cannot satisfy REACH" || fail "heredoc loader text should fail REACH (rc=$RC)"

echo "── validator: completed commands require an explicit exit code ────────────────────────────"
TRANSCRIPT_NO_EXIT="$T/no-exit.jsonl"
write_transcript "$TRANSCRIPT_NO_EXIT" \
  cmd_missing_exit "$LOADER_CMD" "$LOADER_OUT_FILE" \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_NO_EXIT" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "none completed with exit 0" \
  && pass "missing exit_code cannot masquerade as loader success" || fail "missing exit should fail closed (rc=$RC)"

echo "── validator: forbidden branch read ───────────────────────────────────────────────────────"
TRANSCRIPT_FORB="$T/forbidden.jsonl"
echo "branch pollution" > "$T/forb-read.out"
write_transcript "$TRANSCRIPT_FORB" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  cmd "cat $FORBIDDEN" "$T/forb-read.out" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_FORB" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "SELECTIVITY" \
  && pass "forbidden branch read fails SELECTIVITY" || fail "forbidden branch read should fail (rc=$RC)"

TRANSCRIPT_FAILED_FORB="$T/failed-forbidden.jsonl"
write_transcript "$TRANSCRIPT_FAILED_FORB" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  cmd "cat $FORBIDDEN; false" "$T/forb-read.out" 1 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_FAILED_FORB" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "SELECTIVITY" \
  && pass "a failed command cannot hide its forbidden read" || fail "failed forbidden read should fail SELECTIVITY (rc=$RC)"

TRANSCRIPT_EXIT_UNKNOWN_FORB="$T/exit-unknown-forbidden.jsonl"
write_transcript "$TRANSCRIPT_EXIT_UNKNOWN_FORB" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  cmd_missing_exit "cat $FORBIDDEN" "$T/forb-read.out" \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_EXIT_UNKNOWN_FORB" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "SELECTIVITY" \
  && pass "a host-thin command cannot hide its forbidden read" || fail "exit-unknown forbidden read should fail SELECTIVITY (rc=$RC)"

echo "── validator: late receipt (mutation before loader) ───────────────────────────────────────"
TRANSCRIPT_LATE="$T/late.jsonl"
write_transcript "$TRANSCRIPT_LATE" \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_LATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "TIMING" \
  && pass "late receipt fails TIMING" || fail "late receipt should fail TIMING (rc=$RC)"

echo "── validator: gate before last mutation ───────────────────────────────────────────────────"
TRANSCRIPT_EARLY_GATE="$T/early-gate.jsonl"
write_transcript "$TRANSCRIPT_EARLY_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0 \
  change "specs/projects/demo/stories/S001/tasks.md"
run_validator "$WORK" --transcript "$TRANSCRIPT_EARLY_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "gate before last mutation fails GATE_USE" || fail "early gate should fail GATE_USE (rc=$RC)"

echo "── validator: failed gate command ─────────────────────────────────────────────────────────"
TRANSCRIPT_BAD_GATE="$T/bad-gate.jsonl"
echo "fail" > "$T/bad-gate.out"
write_transcript "$TRANSCRIPT_BAD_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" "$T/bad-gate.out" 1
run_validator "$WORK" --transcript "$TRANSCRIPT_BAD_GATE" --profile "$PROFILE" --json
[[ "$RC" == 0 ]] && echo "$OUT" | grep -q '"status": "conformant_red"' \
  && echo "$OUT" | grep -q 'exit=1:' \
  && pass "a direct failed gate is conformant while its red outcome stays visible" || fail "direct red gate should preserve a conformant red outcome (rc=$RC)"

TRANSCRIPT_GATE_NO_EXIT="$T/gate-no-exit.jsonl"
write_transcript "$TRANSCRIPT_GATE_NO_EXIT" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd_missing_exit "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null
run_validator "$WORK" --transcript "$TRANSCRIPT_GATE_NO_EXIT" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "a gate without an explicit exit remains non-conforming" || fail "exit-less gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_CAPTURED_GATE="$T/captured-gate.jsonl"
CAPTURED_GATE_CMD=$(printf "set +e\nbash .speck/scripts/validation/validators/%s x; gate_rc=\$?\nprintf 'gate_rc=%%s\\n' \"\$gate_rc\"\ngit diff --check" "$GATE_SUB")
write_transcript "$TRANSCRIPT_CAPTURED_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$CAPTURED_GATE_CMD" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_CAPTURED_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "capturing a gate exit under set +e cannot turn the outer zero into proof" || fail "captured gate exit should fail GATE_USE (rc=$RC)"

TRANSCRIPT_PREFIX_ASSIGN_GATE="$T/prefix-assign-gate.jsonl"
write_transcript "$TRANSCRIPT_PREFIX_ASSIGN_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "GATE_RC=\$(bash .speck/scripts/validation/validators/$GATE_SUB x) true" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_PREFIX_ASSIGN_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "a gate hidden in a prefix assignment cannot borrow a trailing zero" || fail "prefix-assignment gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_ENV_ASSIGN_GATE="$T/env-assign-gate.jsonl"
write_transcript "$TRANSCRIPT_ENV_ASSIGN_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "env GATE_RC=\$(bash .speck/scripts/validation/validators/$GATE_SUB x) true" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_ENV_ASSIGN_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "an env-wrapped substitution cannot expose a nested gate" || fail "env-assignment gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_BACKGROUND_GATE="$T/background-gate.jsonl"
write_transcript "$TRANSCRIPT_BACKGROUND_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x &" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_BACKGROUND_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "a backgrounded gate cannot inherit the shell event's zero" || fail "background gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_BACKGROUND_CHAIN="$T/background-chain.jsonl"
write_transcript "$TRANSCRIPT_BACKGROUND_CHAIN" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x && true &" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_BACKGROUND_CHAIN" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "a backgrounded AND-chain cannot launder its gate" || fail "backgrounded gate chain should fail GATE_USE (rc=$RC)"

TRANSCRIPT_OR_GATE="$T/or-gate.jsonl"
write_transcript "$TRANSCRIPT_OR_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x || true" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_OR_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "an OR-list cannot mask a red gate" || fail "OR-masked gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_PIPE_GATE="$T/pipe-gate.jsonl"
write_transcript "$TRANSCRIPT_PIPE_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x | sed -n '1p'" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_PIPE_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "a formatter cannot launder an earlier failing pipeline gate" || fail "unprotected piped gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_PIPEFAIL_GATE="$T/pipefail-gate.jsonl"
PIPEFAIL_GATE_CMD=$(printf "set -o pipefail\nbash .speck/scripts/validation/validators/%s x | sed -n '1p'" "$GATE_SUB")
write_transcript "$TRANSCRIPT_PIPEFAIL_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$PIPEFAIL_GATE_CMD" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_PIPEFAIL_GATE" --profile "$PROFILE" --json
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "even pipefail-protected gates must run individually" || fail "piped gate should fail even with pipefail (rc=$RC)"

TRANSCRIPT_LATE_PIPEFAIL_GATE="$T/late-pipefail-gate.jsonl"
LATE_PIPEFAIL_GATE_CMD=$(printf "bash .speck/scripts/validation/validators/%s x | sed -n '1p'\nset -o pipefail" "$GATE_SUB")
write_transcript "$TRANSCRIPT_LATE_PIPEFAIL_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$LATE_PIPEFAIL_GATE_CMD" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_LATE_PIPEFAIL_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "enabling pipefail after a pipe cannot launder its gate" || fail "late pipefail should not protect an earlier gate (rc=$RC)"

TRANSCRIPT_DISABLED_PIPEFAIL_GATE="$T/disabled-pipefail-gate.jsonl"
DISABLED_PIPEFAIL_GATE_CMD=$(printf "set -o pipefail\nset +o pipefail\nbash .speck/scripts/validation/validators/%s x | sed -n '1p'" "$GATE_SUB")
write_transcript "$TRANSCRIPT_DISABLED_PIPEFAIL_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$DISABLED_PIPEFAIL_GATE_CMD" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_DISABLED_PIPEFAIL_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "disabled pipefail cannot launder a later piped gate" || fail "disabled pipefail should fail GATE_USE (rc=$RC)"

echo "── validator: gate names in echo output are not invocations ────────────────────────────────"
TRANSCRIPT_ECHO_GATE="$T/echo-gate.jsonl"
write_transcript "$TRANSCRIPT_ECHO_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "echo ran $GATE_SUB in docs" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_ECHO_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "echoing a gate name cannot satisfy GATE_USE" || fail "echo gate should fail GATE_USE (rc=$RC)"

TRANSCRIPT_HEREDOC_GATE="$T/heredoc-gate.jsonl"
HEREDOC_GATE_CMD=$(printf "cat <<'EOF'\nbash .speck/scripts/validation/validators/%s x\nEOF" "$GATE_SUB")
write_transcript "$TRANSCRIPT_HEREDOC_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "$HEREDOC_GATE_CMD" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_HEREDOC_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "gate argv inside a heredoc cannot satisfy GATE_USE" || fail "heredoc gate text should fail GATE_USE (rc=$RC)"

TRANSCRIPT_TROJAN_GATE="$T/trojan-gate.jsonl"
write_transcript "$TRANSCRIPT_TROJAN_GATE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash ./validate-story-tasks.sh x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_TROJAN_GATE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "same-basename local script cannot impersonate the declared gate" || fail "trojan gate should fail GATE_USE (rc=$RC)"

IMPL_PROFILE="story-implement-backend"
IMPL_LOADER_CMD="python3 .speck/scripts/context/speck_context.py $IMPL_PROFILE --root $ROOT"
python3 "$LOADER" "$IMPL_PROFILE" --root "$ROOT" > "$T/impl-loader.out"
TRANSCRIPT_UNITTEST_ECHO="$T/unittest-echo.jsonl"
write_transcript "$TRANSCRIPT_UNITTEST_ECHO" \
  cmd "$IMPL_LOADER_CMD" "$T/impl-loader.out" 0 \
  change "src/demo.py" \
  cmd "echo ran unittest in docs" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_UNITTEST_ECHO" --profile "$IMPL_PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "GATE_USE" \
  && pass "echoing unittest cannot satisfy an implementation gate" || fail "unittest echo should fail GATE_USE (rc=$RC)"

TRANSCRIPT_UNITTEST_REAL="$T/unittest-real.jsonl"
write_transcript "$TRANSCRIPT_UNITTEST_REAL" \
  cmd "$IMPL_LOADER_CMD" "$T/impl-loader.out" 0 \
  change "src/demo.py" \
  cmd "python3 -m unittest tests.test_demo" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_UNITTEST_REAL" --profile "$IMPL_PROFILE" --json
[[ "$RC" == 0 ]] && echo "$OUT" | grep -q '"pass": true' \
  && pass "a real python -m unittest invocation satisfies GATE_USE" || fail "real unittest should pass GATE_USE (rc=$RC)"

echo "── validator: shell writes are mutation events ─────────────────────────────────────────────"
TRANSCRIPT_SHELL_WRITE="$T/shell-write.jsonl"
write_transcript "$TRANSCRIPT_SHELL_WRITE" \
  cmd "bash -lc 'echo hi > specs/projects/demo/stories/S001/tasks.md'" /dev/null 0 \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_SHELL_WRITE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "TIMING" \
  && pass "shell write before loader fails TIMING without file_change events" || fail "shell write should be inferred (rc=$RC)"

TRANSCRIPT_NOSPACE_WRITE="$T/no-space-write.jsonl"
write_transcript "$TRANSCRIPT_NOSPACE_WRITE" \
  cmd "bash -lc 'echo hi>specs/projects/demo/stories/S001/tasks.md'" /dev/null 0 \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/spec.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_NOSPACE_WRITE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "TIMING" \
  && pass "no-space shell redirect before loader fails TIMING" || fail "no-space redirect should be inferred (rc=$RC)"

TRANSCRIPT_INTERPRETER_WRITE="$T/interpreter-write.jsonl"
write_transcript "$TRANSCRIPT_INTERPRETER_WRITE" \
  cmd "python3 -c 'from pathlib import Path; Path(\"specs/projects/demo/stories/S001/tasks.md\").write_text(\"hi\")'" /dev/null 0 \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/spec.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0
run_validator "$WORK" --transcript "$TRANSCRIPT_INTERPRETER_WRITE" --profile "$PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "TIMING" \
  && pass "interpreter write before loader fails TIMING even with a later file_change" || fail "interpreter write should be inferred (rc=$RC)"

echo "── validator: prose mention of forbidden file must not count ──────────────────────────────"
TRANSCRIPT_PROSE="$T/prose.jsonl"
write_transcript "$TRANSCRIPT_PROSE" \
  cmd "$LOADER_CMD" "$LOADER_OUT_FILE" 0 \
  change "specs/projects/demo/stories/S001/tasks.md" \
  cmd "bash .speck/scripts/validation/validators/$GATE_SUB x" /dev/null 0 \
  raw "{\"type\":\"turn.completed\",\"message\":\"I considered $FORBIDDEN but did not read it\"}"
run_validator "$WORK" --transcript "$TRANSCRIPT_PROSE" --profile "$PROFILE" --json
[[ "$RC" == 0 ]] && pass "prose-only forbidden mention does not fail SELECTIVITY" || fail "prose mention should not count as read (rc=$RC)"

echo "── loader: required dynamic selector ───────────────────────────────────────────────────────"
RC=0
OUT=$(python3 "$LOADER" story-validate-backend --root "$ROOT" --contract "$CONTRACT_SRC" 2>&1) || RC=$?
[[ "$RC" != 0 ]] && [[ "$OUT" == *"requires --select claimed_state=VALUE"* ]] \
  && pass "missing required selector fails closed" || fail "missing selector should fail (rc=$RC)"

RC=0
OUT=$(python3 "$LOADER" story-validate-backend --select claimed_state=api-rc --root "$ROOT" --contract "$CONTRACT_SRC" 2>&1) || RC=$?
[[ "$RC" == 0 ]] && [[ "$OUT" == *'"claimed_state":"api-rc"'* ]] && [[ "$OUT" != *"SPECK_CONTEXT_BEGIN .cursor/skills/story-validate/references/axes/felt.md"* ]] \
  && pass "backend API-RC selector loads its ladder without UI axes" || fail "backend selector resolution (rc=$RC)"

echo "── validator: project evidence requires template plus truth stamp ─────────────────────────"
EVIDENCE_PROFILE="project-evidence-ui-build"
EVIDENCE_LOADER_CMD="python3 .speck/scripts/context/speck_context.py $EVIDENCE_PROFILE --root $ROOT"
TRANSCRIPT_EVIDENCE_THIN="$T/evidence-thin.jsonl"
write_transcript "$TRANSCRIPT_EVIDENCE_THIN" \
  cmd "$EVIDENCE_LOADER_CMD" "$T/evidence-loader.out" 0 \
  change "specs/projects/demo/evidence-contract.md" \
  cmd "bash .speck/scripts/validation/validate-template.sh specs/projects/demo/evidence-contract.md" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_EVIDENCE_THIN" --profile "$EVIDENCE_PROFILE"
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "stamp-truth.sh" \
  && pass "template validation alone cannot satisfy evidence-contract closure" || fail "evidence contract without stamp should fail GATE_USE (rc=$RC)"

TRANSCRIPT_EVIDENCE_FULL="$T/evidence-full.jsonl"
write_transcript "$TRANSCRIPT_EVIDENCE_FULL" \
  cmd "$EVIDENCE_LOADER_CMD" "$T/evidence-loader.out" 0 \
  change "specs/projects/demo/evidence-contract.md" \
  cmd "bash .speck/scripts/validation/validate-template.sh specs/projects/demo/evidence-contract.md" /dev/null 0 \
  cmd ".speck/scripts/stamp-truth.sh specs/projects/demo/evidence-contract.md" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_EVIDENCE_FULL" --profile "$EVIDENCE_PROFILE" --json
[[ "$RC" == 0 ]] && echo "$OUT" | grep -q '"pass": true' \
  && pass "template validation plus truth stamp satisfies evidence-contract closure" || fail "full evidence-contract gates should pass (rc=$RC)"

echo "── validator: UX-RC requires template plus FELT and TASTE gates ───────────────────────────"
UI_PROFILE="story-validate-ui"
UI_LOADER_CMD="python3 .speck/scripts/context/speck_context.py $UI_PROFILE --select claimed_state=ux-rc --select visual_host=web --root $ROOT"
python3 "$LOADER" "$UI_PROFILE" --select claimed_state=ux-rc --select visual_host=web --root "$ROOT" > "$T/ui-loader.out"
TRANSCRIPT_UI_THIN="$T/ui-thin.jsonl"
write_transcript "$TRANSCRIPT_UI_THIN" \
  cmd "$UI_LOADER_CMD" "$T/ui-loader.out" 0 \
  change "specs/projects/demo/stories/S001/validation-report.md" \
  cmd "bash .speck/scripts/validation/validate-template.sh validation-report.md" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_UI_THIN" --profile "$UI_PROFILE" --select claimed_state=ux-rc --select visual_host=web
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "validate-felt-axis.sh" && echo "$OUT" | grep -q "validate-taste-axis.sh" \
  && pass "UX-RC cannot pass GATE_USE without FELT and TASTE validators" || fail "thin UX-RC gates should fail (rc=$RC)"

TRANSCRIPT_UI_NO_STAMP="$T/ui-no-stamp.jsonl"
write_transcript "$TRANSCRIPT_UI_NO_STAMP" \
  cmd "$UI_LOADER_CMD" "$T/ui-loader.out" 0 \
  change "specs/projects/demo/stories/S001/validation-report.md" \
  cmd "bash .speck/scripts/validation/validate-template.sh validation-report.md" /dev/null 0 \
  cmd "bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict validation-report.md" /dev/null 0 \
  cmd "bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict validation-report.md" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_UI_NO_STAMP" --profile "$UI_PROFILE" --select claimed_state=ux-rc --select visual_host=web
[[ "$RC" == 1 ]] && echo "$OUT" | grep -q "stamp-truth.sh" \
  && pass "UX-RC cannot pass GATE_USE without a fresh truth stamp" || fail "missing truth stamp should fail (rc=$RC)"

TRANSCRIPT_UI_FULL="$T/ui-full.jsonl"
write_transcript "$TRANSCRIPT_UI_FULL" \
  cmd "$UI_LOADER_CMD" "$T/ui-loader.out" 0 \
  change "specs/projects/demo/stories/S001/validation-report.md" \
  cmd "bash .speck/scripts/stamp-truth.sh validation-report.md" /dev/null 0 \
  cmd "bash .speck/scripts/validation/validate-template.sh validation-report.md" /dev/null 0 \
  cmd "bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict validation-report.md" /dev/null 0 \
  cmd "bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict validation-report.md" /dev/null 0
run_validator "$ROOT" --transcript "$TRANSCRIPT_UI_FULL" --profile "$UI_PROFILE" --select claimed_state=ux-rc --select visual_host=web --json
[[ "$RC" == 0 ]] && echo "$OUT" | grep -q '"pass": true' \
  && pass "UX-RC passes after template, FELT, and TASTE gates" || fail "full UX-RC gates should pass (rc=$RC)"

if [[ "$FAILED" == 0 ]]; then
  echo ""
  echo "All validate-context-transcript tests passed."
  exit 0
fi
echo ""
echo "validate-context-transcript tests FAILED."
exit 1
