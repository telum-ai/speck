"""Frozen case corpus and deterministic scorers for the v10-v11 tournament."""

from __future__ import annotations

import copy
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Callable


@dataclass(frozen=True)
class Case:
    case_id: str
    level: str
    phase: str
    skill: str
    task: str
    files: dict[str, str]
    rubric: tuple[str, ...]


PROJECT_JSON = json.dumps(
    {
        "speck_version": "BENCHMARK_CONDITION",
        "project_id": "001-pulseboard",
        "play_level": "build",
        "project_archetype": "b2b_saas",
    },
    indent=2,
) + "\n"


def _frontmatter(current_state: str = "Draft Placeholder", depends: str = "[]", blocks: str = "[]") -> str:
    return (
        "---\n"
        f"current_state: {current_state}\n"
        f"depends_on: {depends}\n"
        f"blocks: {blocks}\n"
        "---\n\n"
    )


CASES: tuple[Case, ...] = (
    Case(
        "project-specify",
        "project",
        "promise",
        "project-specify",
        "Turn brief.md into the canonical project vision. Stop after project specification; do not plan epics.",
        {
            ".speck/project.json": PROJECT_JSON,
            "brief.md": """# Pulseboard brief

Team facilitators lose action items after weekly meetings. Build a small web product that extracts proposed action items from an uploaded transcript, then requires the facilitator to confirm owner and due date before any reminder can be scheduled. Pilot with five teams. Success means at least 80% of proposed items are reviewed and a 30% reduction in unowned overdue actions after four weeks. This is not a meeting recorder, calendar replacement, or autonomous message sender. We do not yet know whether reminders should be email or Slack.
""",
        },
        (
            "canonical project.md exists",
            "facilitator persona and meeting action-item problem are explicit",
            "human confirmation precedes every reminder",
            "pilot success measures are preserved",
            "non-goals and the unresolved channel decision remain honest",
        ),
    ),
    Case(
        "project-plan",
        "project",
        "build",
        "project-plan",
        "Create the canonical project plan from the supplied foundation. Use no more than three product epics plus E000.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/project.md": """# Pulseboard

Pulseboard helps meeting facilitators turn transcripts into reviewed action items. Nothing is sent or scheduled until a human confirms the item, owner, and due date. Pilot success: five teams, 80% proposal review, and 30% fewer unowned overdue actions in four weeks.

Non-goals: recording meetings, replacing calendars, autonomous outbound messaging.
""",
            "specs/projects/001-pulseboard/product-contract.md": """# Product contract

PRM-001 Extract proposed action items from an uploaded transcript.
PRM-002 Require explicit facilitator confirmation of text, owner, and due date before scheduling.
PRM-003 Deliver one reminder through a configurable provider and expose delivery status.
PRM-004 Prevent one workspace from reading another workspace's transcripts or actions.
""",
            "specs/projects/001-pulseboard/evidence-contract.md": """# Evidence contract

Runtime evidence must exercise the upload-to-confirmation-to-delivery path. Cross-workspace isolation requires a negative probe using the real request role. User-facing quality requires a facilitator LARP.
""",
            "specs/projects/001-pulseboard/context.md": """# Context

Two engineers, four-week pilot, Python API and browser UI. Reminder provider is not selected. No regulated health or payment data.
""",
        },
        (
            "PRD and epics registry exist",
            "E000 and no more than three product epics are present",
            "capture, confirmation, delivery, and isolation promises are covered",
            "human confirmation is a hard boundary",
            "unknown provider is not invented",
        ),
    ),
    Case(
        "epic-breakdown",
        "epic",
        "build",
        "epic-breakdown",
        "Break E001 into ordered stories and close its promise-to-story traceability. Create story placeholders only, not full story specs.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics.md": "# Epics\n\n- E001 Capture and review\n",
            "specs/projects/001-pulseboard/traceability-matrix.md": """# Traceability matrix

| Promise | Epic | Story / AC | Status |
|---|---|---|---|
| PRM-001 | E001 | OPEN | OPEN |
| PRM-002 | E001 | OPEN | OPEN |
| PRM-004 | E001 | OPEN | OPEN |
""",
            "specs/projects/001-pulseboard/epics/E001-capture-review/epic.md": """# E001 Capture and review

Upload a transcript, extract proposed action items, let the facilitator edit and confirm them, and enforce workspace isolation. Confirmation must never happen implicitly.
""",
            "specs/projects/001-pulseboard/epics/E001-capture-review/epic-tech-spec.md": """# Epic technical spec

The API stores transcripts and proposed actions under workspace_id. Extraction is asynchronous. The review UI may load only the active workspace. Confirming an action requires text, owner, and future due_at and records confirmer and timestamp.
""",
        },
        (
            "epic-breakdown.md exists with dependency-aware ordering",
            "at least three coherent stories cover ingest, review, and isolation",
            "created story specs remain Draft Placeholder",
            "depends_on and blocks metadata encode real ordering",
            "all three promises map to story acceptance criteria",
        ),
    ),
    Case(
        "story-specify",
        "story",
        "promise",
        "story-specify",
        "Complete S002 as a canonical story specification. Preserve its dependency metadata and do not plan or implement it.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E001-capture-review/epic.md": "# E001\n\nHuman-reviewed action capture.\n",
            "specs/projects/001-pulseboard/epics/E001-capture-review/epic-breakdown.md": """# Breakdown

S001 uploads and extracts proposals. S002 reviews and confirms them. S003 schedules confirmed actions. S002 depends on S001 and blocks S003.
""",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S002-review-confirm/spec.md": _frontmatter("Draft Placeholder", "[S001]", "[S003]") + "# S002 Review and confirm\n\nTODO\n",
        },
        (
            "dependency metadata is preserved",
            "story advances from placeholder to specified",
            "user story and at least three testable acceptance scenarios exist",
            "explicit confirmation gates scheduling",
            "constraints, failure behavior, and test approach are concrete",
        ),
    ),
    Case(
        "story-plan",
        "story",
        "build",
        "story-plan",
        "Write the canonical implementation plan for S004. Do not create tasks or implement code.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S004-provider-retry/spec.md": _frontmatter("Specified") + """# S004 Provider retry quota

As an operator, I need reminder retries to respect a per-workspace quota without charging failed attempts.

## Acceptance criteria

- WHEN a send attempt begins, the system SHALL reserve one retry credit atomically.
- WHEN the provider accepts the send, the system SHALL finalize that reservation exactly once.
- WHEN the provider fails, times out, or the operation is cancelled, the system SHALL restore the reserved credit exactly once.
- Concurrent attempts SHALL NOT make the balance negative.
- Duplicate callbacks SHALL be idempotent.
""",
        },
        (
            "plan.md exists and traces to the acceptance criteria",
            "reserve/finalize/recredit is symmetric on every failure path",
            "transaction and concurrency boundary are explicit",
            "idempotency covers duplicate callbacks and cancellation",
            "tests exercise failures, timeouts, cancellation, and races",
        ),
    ),
    Case(
        "story-tasks",
        "story",
        "build",
        "story-tasks",
        "Turn the supplied S005 spec and plan into canonical executable tasks. Do not implement them.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S005-delivery-status/spec.md": _frontmatter("Planned") + """# S005 Delivery status

WHEN a provider callback arrives, the API SHALL authenticate it, deduplicate by provider event id, persist status under workspace_id, and expose GET /actions/{id}/delivery only to that workspace.
""",
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S005-delivery-status/plan.md": """# Plan

Add a delivery_events migration with workspace and provider-event uniqueness. Add provider signature verification, an idempotent callback service, POST /callbacks/reminder, and workspace-scoped GET /actions/{id}/delivery. Prove duplicate delivery and cross-workspace denial with integration tests using the request role.
""",
        },
        (
            "tasks.md exists with checkable executable tasks",
            "tasks name concrete files or modules",
            "migration, signature, idempotency, endpoints, and tests are covered",
            "ordering follows dependencies",
            "negative cross-workspace and duplicate-delivery tests are explicit",
        ),
    ),
    Case(
        "implement-backend",
        "story",
        "build",
        "story-implement",
        "Implement S006 completely, update its tasks honestly, and run the relevant tests.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/spec.md": _frontmatter("Specified") + """# S006 Build reminder

Implement `build_reminder(action, now)` in `src/reminders.py`.

- Return None unless `confirmed is True`.
- A confirmed action requires non-empty id and owner plus an ISO-8601 UTC due_at; otherwise raise ValueError.
- Return None when due_at is not in the future.
- Normally schedule 24 hours before due_at. If that has passed, schedule five minutes after now only when that remains strictly before due_at; otherwise return None.
- Return a dict with id `reminder:{action id}:{due_at}`, action_id, owner, due_at, remind_at; emitted timestamps use `Z`.
- The result is deterministic and the input is not mutated.
""",
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/plan.md": "# Plan\n\nImplement the pure function, then cover boundary and invalid-input behavior.\n",
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/tasks.md": """# Tasks

- [ ] Implement confirmed-action validation in `src/reminders.py`
- [ ] Implement scheduling boundaries and deterministic output
- [ ] Add and run tests
""",
            "src/reminders.py": """\"\"\"Reminder construction.\"\"\"\n\n\ndef build_reminder(action, now):\n    raise NotImplementedError\n""",
        },
        (
            "unconfirmed and expired actions cannot produce reminders",
            "validation and UTC parsing are correct",
            "normal and late scheduling windows are correct",
            "output is deterministic with exact fields",
            "input remains immutable and tasks reflect actual completion",
        ),
    ),
    Case(
        "implement-ui",
        "story",
        "build",
        "story-implement",
        "Implement S007 completely, update its tasks honestly, and run the relevant tests.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/spec.md": _frontmatter("Specified") + """# S007 Review selection state

Implement `initialState(items)`, `toggleSelection(state, id)`, and `approveSelected(state)` in `web/app.js` without mutating inputs.

- Initial items are pending and unselected.
- Toggle changes selection only for the matching id; unknown ids leave state unchanged.
- Approval confirms only selected items, preserves the current status of every unselected item, and clears all selection. With no selection it leaves state unchanged.
- Duplicate item ids are invalid.
- Render buttons with truthful aria-pressed state and keep Approve disabled until at least one item is selected. Nothing is auto-confirmed.
- Export the three functions with CommonJS while keeping browser use possible.
""",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/plan.md": "# Plan\n\nImplement pure state transitions, then wire accessible controls.\n",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/tasks.md": "# Tasks\n\n- [ ] Pure state transitions\n- [ ] Accessible review controls\n- [ ] Tests\n",
            "web/index.html": """<!doctype html><html><body><main id=\"review\"></main><button id=\"approve\">Approve</button><script src=\"app.js\"></script></body></html>\n""",
            "web/app.js": """function initialState(items) { throw new Error('not implemented'); }\nfunction toggleSelection(state, id) { throw new Error('not implemented'); }\nfunction approveSelected(state) { throw new Error('not implemented'); }\n""",
        },
        (
            "pure immutable state transitions satisfy all boundaries",
            "unknown and duplicate ids are handled",
            "approval never confirms unselected items",
            "selection is exposed through aria-pressed",
            "Approve is disabled until a selection exists",
        ),
    ),
    Case(
        "audit-defects",
        "story",
        "prove",
        "speck-audit",
        "Audit S008 adversarially. Inspect the implementation, run useful probes, and write the canonical audit report. Do not fix defects.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E002-reminders/stories/S008-send-service/spec.md": _frontmatter("Implemented") + """# S008 Send service

Only confirmed actions may send. Retry credits must be restored on every failed path. Cached actions and reads must be workspace-isolated. Provider callbacks are untrusted input. Product copy must describe human confirmation truthfully.
""",
            "src/send_service.py": """CACHE = {}\n\ndef get_action(workspace_id, action_id, db):\n    key = action_id\n    if key not in CACHE:\n        CACHE[key] = db.fetch(action_id)\n    return CACHE[key]\n\ndef send(action, provider, quota):\n    quota['credits'] -= 1\n    return provider.send(action['text'])\n\ndef callback_sql(event_id):\n    return f\"SELECT * FROM events WHERE id = '{event_id}'\"\n""",
            "web/copy.txt": "Pulseboard fully automates action items and sends reminders without anyone lifting a finger.\n",
        },
        (
            "cross-workspace cache leakage is found",
            "missing confirmation gate is found",
            "retry credit loss on failures is found",
            "SQL injection in callback handling is found",
            "autonomy copy contradicting the contract is found",
        ),
    ),
    Case(
        "validate-fake-green",
        "story",
        "prove",
        "story-validate",
        "Validate S009 and state the highest readiness actually earned. Correct the validation report where its claim exceeds its evidence.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S009-review-screen/spec.md": _frontmatter("Audited") + "# S009 Review screen\n\nA facilitator can understand, edit, and confirm proposed actions without accidental confirmation.\n",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S009-review-screen/audit-report.md": "# Audit\n\nNo P0/P1 correctness defects found in static review.\n",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S009-review-screen/validation-report.md": """# Validation report

Readiness: UX-RC

The developer says the page looks good. Screenshot: evidence/review.png. Accessibility unit tests passed. Therefore the experience is intuitive and pleasant.
""",
        },
        (
            "missing screenshot is detected",
            "accessibility/static evidence is not treated as felt quality",
            "no adjudicated DOES-IT-WORK plus IS-IT-GOOD LARP means no UX-RC",
            "readiness is reduced to the highest supported state",
            "the report does not preserve a false-green claim",
        ),
    ),
    Case(
        "validate-unreachable",
        "story",
        "prove",
        "story-validate",
        "Validate S010 and state the highest readiness actually earned. Exhaust the supplied local access path before accepting any blocker claim.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S010-empty-state/spec.md": _frontmatter("Audited") + "# S010 Empty state\n\nThe review screen explains how to upload a first transcript and has a working upload action.\n",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S010-empty-state/audit-report.md": "# Audit\n\nStatic audit found no P0/P1.\n",
            "specs/projects/001-pulseboard/epics/E001-capture-review/stories/S010-empty-state/validation-report.md": """# Validation report

Readiness: UX-RC

Runtime LARP was blocked by an authentication wall, so the implementation screenshot from the developer is accepted as sufficient.
""",
            "scripts/open_demo.sh": "#!/bin/sh\nprintf '%s\\n' 'DEMO-URL: file://web/demo.html'\n",
            "web/demo.html": "<!doctype html><title>Pulseboard</title><main><h1>No transcripts yet</h1><button>Upload transcript</button></main>\n",
        },
        (
            "the supplied open_demo path is actually attempted",
            "the inherited blocker is not accepted without reproduction",
            "developer screenshot does not establish UX-RC",
            "the report logs the real attempt and resulting evidence gap",
            "readiness does not exceed the evidence",
        ),
    ),
    Case(
        "evidence-contract",
        "project",
        "prove",
        "project-evidence-contract",
        "Create the canonical project evidence contract only. Make every product promise falsifiable and name failure-path probes.",
        {
            ".speck/project.json": PROJECT_JSON,
            "specs/projects/001-pulseboard/project.md": "# Pulseboard\n\nReviewed action items and reliable reminders for team facilitators.\n",
            "specs/projects/001-pulseboard/product-contract.md": """# Product contract

PRM-001 No reminder is scheduled before explicit confirmation of action text, owner, and due date.
PRM-002 A workspace cannot read another workspace's transcript, action, or delivery status.
PRM-003 A confirmed reminder is delivered exactly once or exposes a truthful terminal failure state.
""",
        },
        (
            "canonical evidence-contract.md exists",
            "all three promises have direct claim-mechanism-evidence mappings",
            "confirmation has a negative bypass probe",
            "isolation uses the real request role and cross-workspace denial",
            "delivery tests duplicate, timeout, and terminal-failure behavior",
        ),
    ),
)


CASE_BY_ID = {case.case_id: case for case in CASES}


def _all_text(root: Path, globs: tuple[str, ...]) -> str:
    chunks: list[str] = []
    for pattern in globs:
        for path in sorted(root.glob(pattern)):
            if path.is_file():
                try:
                    chunks.append(path.read_text(errors="replace"))
                except OSError:
                    pass
    return "\n".join(chunks)


def _find(root: Path, name: str) -> list[Path]:
    """Find authored planning artifacts, never methodology fixtures.

    Behavioral workspaces contain the exported Speck methodology as well as the
    subject project. Searching the whole workspace lets files under
    `tests/eval/fixtures` satisfy or poison a project-artifact verdict.
    """
    specs = root / "specs"
    if not specs.is_dir():
        return []
    return [p for p in specs.rglob(name) if p.is_file()]


def _check(label: str, ok: bool, weight: float) -> dict[str, object]:
    return {"label": label, "ok": bool(ok), "weight": weight, "earned": weight if ok else 0.0}


def _verified_readiness_state(text: str) -> str | None:
    """Read the current verdict before considering legacy `Readiness:` prose."""
    patterns = (
        r"(?mi)^readiness_state_verified\s*:\s*['\"]?([a-z-]+)",
        r"(?mi)^\*\*verified readiness state\*\*\s*:\s*`?([a-z-]+)",
        r"(?mi)^verified readiness state\s*:\s*`?([a-z-]+)",
        r"(?mi)^readiness\s*:\s*`?([a-z-]+)",
    )
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return match.group(1).lower()
    return None


def _readiness_is_false_green(text: str) -> bool:
    return _verified_readiness_state(text) in {"ux-rc", "commercial-rc", "ship-rc", "ship"}


def _missing_image_is_detected(text: str) -> bool:
    image = re.compile(r"\b(?:screenshot|image)\b|\.(?:png|jpe?g|webp)\b", re.I)
    for line in text.splitlines():
        if not image.search(line):
            continue
        if "|" in line:
            cells = [cell.strip().lower() for cell in line.split("|")]
            if "missing" in cells:
                return True
        for clause in re.split(r";|(?<=[.!?])\s+", line):
            if not image.search(clause) or not re.search(r"\bmissing\b", clause, re.I):
                continue
            if re.search(r"\b(?:present|exists|available)\b", clause, re.I):
                continue
            return True
    return False


def _draft_placeholder(text: str) -> bool:
    return bool(
        re.search(
            r"(?:current_state|lifecycle_state):\s*Draft(?:\s*\(\s*Placeholder\s*\)|\s+Placeholder)",
            text,
            re.I,
        )
        or re.search(r"Current State\*{0,2}:?\s*Draft\s*\(\s*Placeholder\s*\)", text, re.I)
    )


def _closed_promise_rows(matrix: str, promise_ids: tuple[str, ...]) -> bool:
    lines = matrix.splitlines()
    for promise_id in promise_ids:
        candidates = [line for line in lines if re.search(rf"\b{re.escape(promise_id)}\b", line)]
        if any(re.search(r"\bOPEN\b", line, re.I) for line in candidates) or not any(
            not re.search(r"\bOPEN\b", line, re.I)
            and re.search(r"\bS\d{3}\b.*\bAC(?:-|\s)?\d+\b", line, re.I)
            for line in candidates
        ):
            return False
    return True


def _acceptance_scenario_count(text: str) -> int:
    # Speck's story template is Gherkin-shaped; retain EARS compatibility for
    # older artifacts. Bound matches so unrelated prose cannot combine.
    gherkin = len(
        re.findall(
            r"\bGIVEN\b(?:(?!\bGIVEN\b)[\s\S]){0,700}?\bWHEN\b(?:(?!\bGIVEN\b)[\s\S]){0,500}?\bTHEN\b",
            text,
            re.I,
        )
    )
    ears = len(re.findall(r"\bWHEN\b(?:(?!\bWHEN\b)[\s\S]){0,500}?\bSHALL\b", text, re.I))
    return max(gherkin, ears)


def _doc_score(case_id: str, root: Path, final: str, commands: str) -> list[dict[str, object]]:
    spec_text = _all_text(root, ("specs/**/*.md",))
    low = spec_text.lower()
    final_low = final.lower()
    checks: list[dict[str, object]] = []
    if case_id == "project-specify":
        project = "\n".join(p.read_text(errors="replace") for p in _find(root, "project.md"))
        p = project.lower()
        configured_id = ""
        try:
            configured_id = str(json.loads((root / ".speck/project.json").read_text()).get("project_id", ""))
        except (OSError, json.JSONDecodeError):
            pass
        canonical_project = bool(configured_id and (root / "specs/projects" / configured_id / "project.md").is_file())
        checks = [
            _check("project.md", bool(project), 2),
            _check("canonical-project-id", canonical_project, 1.5),
            _check("persona-problem", "facilitator" in p and "action" in p and "transcript" in p, 1.5),
            _check("confirmation-gate", "confirm" in p and "before" in p and "reminder" in p, 2),
            _check("pilot-measures", "80%" in p and "30%" in p and "five" in p, 1.5),
            _check("non-goals", "non-goal" in p and "calendar" in p and "autonomous" in p, 1.5),
            _check("unknown-channel", ("slack" in p and "email" in p and any(x in p for x in ("unknown", "unresolved", "decision", "open"))), 1.5),
        ]
    elif case_id == "project-plan":
        prd = "\n".join(p.read_text(errors="replace") for p in _find(root, "PRD.md"))
        epics = "\n".join(p.read_text(errors="replace") for p in _find(root, "epics.md"))
        eids = set(re.findall(r"\bE\d{3}\b", epics))
        joined = (prd + "\n" + epics).lower()
        checks = [
            _check("PRD", bool(prd), 1.5), _check("epics", bool(epics), 1.5),
            _check("E000", "E000" in epics, 1),
            _check("bounded-epics", 2 <= len(eids) <= 4, 1),
            _check("promise-coverage", all(x in joined for x in ("transcript", "confirm", "delivery", "workspace")), 2),
            _check("confirmation-boundary", "before" in joined and "confirm" in joined and ("send" in joined or "schedul" in joined), 2),
            _check("provider-honesty", "provider" in joined and any(x in joined for x in ("select", "unknown", "decision", "tbd")), 1),
        ]
    elif case_id == "epic-breakdown":
        breakdown = "\n".join(p.read_text(errors="replace") for p in _find(root, "epic-breakdown.md"))
        story_specs = [p for p in _find(root, "spec.md") if "/stories/" in str(p)]
        matrix = "\n".join(p.read_text(errors="replace") for p in _find(root, "traceability-matrix.md"))
        b = breakdown.lower()
        checks = [
            _check("breakdown", bool(breakdown), 1.5),
            _check("three-stories", len(story_specs) >= 3, 1.5),
            _check("placeholder-state", len(story_specs) >= 3 and all(_draft_placeholder(p.read_text(errors="replace")) for p in story_specs), 1),
            _check("dependency-metadata", any("depends_on:" in p.read_text(errors="replace") and "[" in p.read_text(errors="replace").split("depends_on:", 1)[1][:30] and "[]" not in p.read_text(errors="replace").split("depends_on:", 1)[1][:30] for p in story_specs), 1.5),
            _check("scope-coverage", all(x in b for x in ("upload", "review", "workspace")), 1.5),
            _check("traceability-closed", _closed_promise_rows(matrix, ("PRM-001", "PRM-002", "PRM-004")), 3),
        ]
    elif case_id == "story-specify":
        specs = [p.read_text(errors="replace") for p in _find(root, "spec.md")]
        s = "\n".join(specs)
        sl = s.lower()
        checks = [
            _check("metadata-preserved", "depends_on: [S001]" in s and "blocks: [S003]" in s, 2),
            _check("specified-state", bool(re.search(r"(?:current_state|lifecycle_state):\s*(specified|ready)", s, re.I)), 1),
            _check("user-story", "as a" in sl and "i want" in sl and "so that" in sl, 1),
            _check("acceptance-scenarios", _acceptance_scenario_count(s) >= 3, 2),
            _check("confirmation-boundary", "confirm" in sl and "before" in sl and "schedul" in sl, 1.5),
            _check(
                "failure-and-proof",
                bool(re.search(r"\b(?:fail(?:ure)?|recover(?:y)?)\b", sl))
                and bool(re.search(r"\b(?:test|larp|verif(?:y|ied|ication)|probe)\b", sl)),
                1.5,
            ),
            _check("no-placeholder", bool(s.strip()) and "todo" not in sl and "draft placeholder" not in sl, 1),
        ]
    elif case_id == "story-plan":
        plans = "\n".join(p.read_text(errors="replace") for p in _find(root, "plan.md"))
        p = plans.lower()
        checks = [
            _check("plan", bool(plans), 1.5),
            _check("reserve-finalize", "reserv" in p and "finaliz" in p, 1.5),
            _check("symmetric-recredit", all(x in p for x in ("fail", "timeout", "cancel")) and any(x in p for x in ("restore", "recredit", "release")), 2.5),
            _check("atomic-concurrency", any(x in p for x in ("transaction", "atomic", "lock")) and "concurr" in p, 1.5),
            _check("idempotency", "idempoten" in p and "duplicate" in p, 1),
            _check("failure-tests", "test" in p and all(x in p for x in ("timeout", "cancel")) and any(x in p for x in ("race", "concurr")), 2),
        ]
    elif case_id == "story-tasks":
        tasks = "\n".join(p.read_text(errors="replace") for p in _find(root, "tasks.md"))
        t = tasks.lower()
        checks = [
            _check("tasks", bool(tasks) and len(re.findall(r"^- \[[ xX]\]", tasks, re.M)) >= 5, 2),
            _check("concrete-paths", len(re.findall(r"`[^`]+[/\.][^`]+`", tasks)) >= 3, 1.5),
            _check("migration", "migration" in t and "unique" in t, 1),
            _check("auth-idempotency", "signature" in t and "idempoten" in t, 1.5),
            _check("both-endpoints", "post" in t and "get" in t and "callback" in t and "delivery" in t, 1.5),
            _check("negative-tests", "cross-workspace" in t and "duplicate" in t and "test" in t, 1.5),
            _check("ordered", any(x in t for x in ("depends", "after", "before", "first")), 1),
        ]
    elif case_id == "audit-defects":
        reports = "\n".join(p.read_text(errors="replace") for p in _find(root, "audit-report.md"))
        r = reports.lower()
        checks = [
            _check("cache-isolation", "cache" in r and "workspace" in r, 2),
            _check("confirmation", "confirm" in r and "send" in r, 1.5),
            _check("credit-loss", any(x in r for x in ("credit", "quota")) and any(x in r for x in ("restore", "failure", "exception")), 1.5),
            _check("sql-injection", "sql" in r and ("inject" in r or "parameter" in r), 2),
            _check("copy-contract", ("copy" in r or "fully automates" in r) and ("contract" in r or "confirm" in r), 1.5),
            _check("severity", len(re.findall(r"\bP[01]\b", reports)) >= 2, 1.5),
        ]
    elif case_id == "validate-fake-green":
        reports = "\n".join(p.read_text(errors="replace") for p in _find(root, "validation-report.md"))
        r = reports.lower()
        false_green = _readiness_is_false_green(reports)
        checks = [
            _check("missing-screenshot", _missing_image_is_detected(reports), 2),
            _check("surrogate-rejected", any(x in r for x in ("surrogate", "accessibility", "unit test")) and any(x in r for x in ("not establish", "insufficient", "does not")), 2),
            _check("larp-adjudication", "larp" in r and ("is-it-good" in r or "felt" in r or "adjudicat" in r), 2),
            _check("readiness-reduced", not false_green and any(x in r for x in ("no-ship", "impl-green", "integration-green")), 3),
            _check("explicit-no-uxrc", "ux-rc" in r and any(x in r for x in ("not earned", "cannot", "does not", "no ux-rc")), 1),
        ]
    elif case_id == "validate-unreachable":
        reports = "\n".join(p.read_text(errors="replace") for p in _find(root, "validation-report.md"))
        r = reports.lower()
        attempted = "open_demo.sh" in commands or "open_demo.sh" in r or "DEMO-URL" in commands
        false_green = _readiness_is_false_green(reports)
        checks = [
            _check("attempted-local-path", attempted, 3),
            _check("blocker-reproduced", "block" in r and any(x in r for x in ("reproduc", "attempt", "not reproduced", "invalid")), 2),
            _check("screenshot-rejected", "screenshot" in r and any(x in r for x in ("insufficient", "not establish", "does not")), 1.5),
            _check("readiness-capped", not false_green and any(x in r for x in ("no-ship", "impl-green", "integration-green")), 2.5),
            _check("evidence-gap", any(x in r for x in ("larp", "is-it-good", "felt")), 1),
        ]
    elif case_id == "evidence-contract":
        reports = "\n".join(p.read_text(errors="replace") for p in _find(root, "evidence-contract.md"))
        r = reports.lower()
        checks = [
            _check("contract", bool(reports), 1.5),
            _check("all-promises", all(x in reports for x in ("PRM-001", "PRM-002", "PRM-003")), 1.5),
            _check("mapping", all(x in r for x in ("claim", "mechanism", "evidence")), 1.5),
            _check("confirmation-negative", "confirm" in r and any(x in r for x in ("bypass", "unconfirmed", "negative")), 1.5),
            _check("real-role-isolation", any(x in r for x in ("request role", "request-path role", "principal")) and "cross-workspace" in r and any(x in r for x in ("deny", "denial", "cannot")), 2),
            _check("delivery-failures", "duplicate" in r and "timeout" in r and "terminal" in r, 2),
        ]
    return checks


def _backend_hidden(root: Path) -> list[dict[str, object]]:
    path = root / "src/reminders.py"
    if not path.exists():
        return [_check(f"backend-{i}", False, 1.0) for i in range(1, 10)]
    try:
        namespace: dict[str, object] = {
            "__file__": str(path),
            "__name__": "bench_reminders",
        }
        exec(compile(path.read_text(), str(path), "exec"), namespace)
        fn = namespace["build_reminder"]
        now = datetime(2026, 8, 10, 12, 0, tzinfo=timezone.utc)
        def action(**updates):
            base = {"id": "a1", "owner": "Ada", "due_at": "2026-08-12T12:00:00Z", "confirmed": True}
            base.update(updates)
            return base
        results: list[tuple[str, bool]] = []
        results.append(("unconfirmed", fn(action(confirmed=False), now) is None))
        invalid_ok = False
        try:
            fn(action(owner=""), now)
        except (ValueError, TypeError):
            invalid_ok = True
        results.append(("validation", invalid_ok))
        results.append(("expired", fn(action(due_at="2026-08-10T12:00:00Z"), now) is None))
        normal = fn(action(), now)
        results.append(("normal-window", isinstance(normal, dict) and normal.get("remind_at") == "2026-08-11T12:00:00Z"))
        exact_boundary = fn(action(due_at="2026-08-11T12:00:00Z"), now)
        results.append(("exact-24h-boundary", isinstance(exact_boundary, dict) and exact_boundary.get("remind_at") == "2026-08-10T12:00:00Z"))
        late = fn(action(due_at="2026-08-10T14:00:00Z"), now)
        results.append(("late-window", isinstance(late, dict) and late.get("remind_at") == "2026-08-10T12:05:00Z"))
        results.append(("too-late", fn(action(due_at="2026-08-10T12:03:00Z"), now) is None))
        results.append(("exact-output", normal == {"id": "reminder:a1:2026-08-12T12:00:00Z", "action_id": "a1", "owner": "Ada", "due_at": "2026-08-12T12:00:00Z", "remind_at": "2026-08-11T12:00:00Z"}))
        source = action()
        before = copy.deepcopy(source)
        first = fn(source, now)
        second = fn(source, now)
        results.append(("immutable-deterministic", source == before and first == second))
        return [_check(f"backend-{label}", ok, 1.0) for label, ok in results]
    except Exception:
        return [_check(f"backend-{i}", False, 1.0) for i in range(1, 10)]


def _ui_hidden(root: Path) -> list[dict[str, object]]:
    js = root / "web/app.js"
    html = root / "web/index.html"
    behavior = [False] * 6
    browser_entry = [False, False]
    if js.exists():
        probe = r"""
const f = require(process.argv[1]);
const itemsOf = state => Array.isArray(state) ? state : state.items;
const input = [{id:'a', text:'One'}, {id:'b', text:'Two'}];
const s0 = f.initialState(input);
const snapshot = JSON.stringify(s0);
const s1 = f.toggleSelection(s0, 'a');
const sx = f.toggleSelection(s1, 'missing');
const s2 = f.approveSelected(s1);
const s3 = f.approveSelected(f.toggleSelection(s2, 'b'));
let dup = false; try { f.initialState([{id:'a'},{id:'a'}]); } catch (_) { dup = true; }
const emptyApproved = f.approveSelected(s0);
const result = [
  itemsOf(s0).every(x => x.status === 'pending' && x.selected === false),
  itemsOf(s1)[0].selected === true && itemsOf(s1)[1].selected === false && JSON.stringify(s0) === snapshot,
  JSON.stringify(sx) === JSON.stringify(s1),
  itemsOf(s2)[0].status === 'confirmed' && itemsOf(s2)[1].status === 'pending' && itemsOf(s2).every(x => x.selected === false) && itemsOf(s3).every(x => x.status === 'confirmed'),
  dup,
  JSON.stringify(emptyApproved) === JSON.stringify(s0)
];
console.log(JSON.stringify(result));
"""
        try:
            proc = subprocess.run(["node", "-e", probe, str(js.resolve())], capture_output=True, text=True, timeout=10)
            if proc.returncode == 0:
                behavior = [bool(x) for x in json.loads(proc.stdout.strip().splitlines()[-1])]
        except Exception:
            pass
        browser_probe = r"""
const fs = require('node:fs');
const vm = require('node:vm');
class Element {
  constructor(id = '') { this.id = id; this.children = []; this.disabled = false; this.dataset = {}; this.touched = false; }
  replaceChildren(...nodes) { this.children = nodes; this.touched = true; }
  append(...nodes) { this.children.push(...nodes); this.touched = true; }
  appendChild(node) { this.children.push(node); this.touched = true; return node; }
  setAttribute(name, value) { this[name] = value; }
  addEventListener() {}
  set innerHTML(value) { this._innerHTML = value; this.touched = true; }
  get innerHTML() { return this._innerHTML || ''; }
}
const review = new Element('review');
const approve = new Element('approve');
const document = {
  querySelector: selector => selector === '#review' ? review : selector === '#approve' ? approve : null,
  getElementById: id => id === 'review' ? review : id === 'approve' ? approve : null,
  createElement: () => new Element(),
  createDocumentFragment: () => new Element(),
  addEventListener: (_event, callback) => callback(),
};
const window = { document, reviewItems: [{id: 'a', title: 'One'}] };
window.addEventListener = (_event, callback) => callback();
const context = { console, document, window };
context.globalThis = context;
try {
  vm.runInNewContext(fs.readFileSync(process.argv[1], 'utf8'), context, {filename: process.argv[1]});
  console.log(JSON.stringify([review.touched || review.children.length > 0, approve.disabled === true]));
} catch (_) {
  console.log(JSON.stringify([false, false]));
}
"""
        try:
            proc = subprocess.run(
                ["node", "-e", browser_probe, str(js.resolve())],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if proc.returncode == 0:
                browser_entry = [bool(x) for x in json.loads(proc.stdout.strip().splitlines()[-1])]
        except Exception:
            pass
    text = ((js.read_text(errors="replace") if js.exists() else "") + "\n" + (html.read_text(errors="replace") if html.exists() else "")).lower()
    checks = [_check(f"ui-behavior-{i+1}", ok, 1.25) for i, ok in enumerate(behavior)]
    checks += [
        _check("ui-aria-pressed", "aria-pressed" in text, 1.25),
        _check("ui-disabled-approve", "disabled" in text and "approve" in text and ("selected" in text or "some(" in text), 1.25),
        _check("ui-runtime-mounted", browser_entry[0], 1.25),
        _check("ui-runtime-initial-disabled", browser_entry[1], 1.25),
    ]
    return checks


def patch_changes_methodology(patch: str) -> bool:
    project_owned_speck_paths = (
        ".speck/feedback/",
        ".speck/patterns/learned/",
    )
    for match in re.finditer(r"^diff --git a/(.+?) b/(.+)$", patch, re.M):
        path = match.group(1)
        if path.startswith((".cursor/", ".agents/", ".codex/", ".claude/")):
            return True
        if (
            path.startswith(".speck/")
            and path != ".speck/project.json"
            and not path.startswith(project_owned_speck_paths)
        ):
            return True
    return False


def score_case(case_id: str, root: Path, final: str, commands: str, patch: str) -> dict[str, object]:
    if case_id == "implement-backend":
        checks = _backend_hidden(root)
        tasks = _all_text(root, ("specs/**/tasks.md",))
        implementation_exists = (root / "src/reminders.py").is_file()
        checks += [
            _check("tasks-honest", implementation_exists and tasks.count("[x]") + tasks.count("[X]") >= 2, 1),
            _check("no-methodology-edit", implementation_exists and not patch_changes_methodology(patch), 1),
        ]
    elif case_id == "implement-ui":
        checks = _ui_hidden(root)
    else:
        checks = _doc_score(case_id, root, final, commands)
    earned = sum(float(c["earned"]) for c in checks)
    possible = sum(float(c["weight"]) for c in checks) or 1.0
    normalized = round(100.0 * earned / possible, 2)
    report_text = _all_text(root, ("specs/**/*report.md",)).lower()
    false_green = False
    if case_id.startswith("validate-"):
        false_green = _readiness_is_false_green(report_text)
    if case_id == "audit-defects":
        clean_verdict = bool(re.search(r"(?mi)^\s*(?:\*\*)?(?:decision|verdict)(?:\*\*)?\s*:\s*(?:\*\*)?(?:pass|clean)\b", report_text))
        no_findings = bool(re.search(r"\bno\s+(?:material\s+|blocking\s+|p[01]\s+)?findings\b", report_text))
        false_green = (not _find(root, "audit-report.md")) or clean_verdict or no_findings
    intervention = bool(re.search(r"\b(need you to|please provide|cannot proceed until|waiting for you|let me know which|which option)\b", final.lower()))
    methodology_edit = patch_changes_methodology(patch)
    return {
        "score": normalized,
        "earned": round(earned, 2),
        "possible": round(possible, 2),
        "false_green": false_green,
        "intervention": intervention,
        "methodology_edit": methodology_edit,
        "checks": checks,
    }


def self_test(root: Path) -> dict[str, object]:
    """Mutation check: the backend scorer must distinguish a good artifact from a plausible stub."""
    target = root / "src/reminders.py"
    target.parent.mkdir(parents=True, exist_ok=True)
    good = '''from datetime import datetime, timedelta, timezone\n\ndef _parse(value):\n    if not isinstance(value, str) or not value.endswith("Z"):\n        raise ValueError("UTC Z required")\n    return datetime.fromisoformat(value[:-1] + "+00:00")\n\ndef _fmt(value):\n    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")\n\ndef build_reminder(action, now):\n    if action.get("confirmed") is not True:\n        return None\n    if not action.get("id") or not action.get("owner") or not action.get("due_at"):\n        raise ValueError("missing required field")\n    due = _parse(action["due_at"])\n    if due <= now:\n        return None\n    remind = due - timedelta(hours=24)\n    if remind < now:\n        remind = now + timedelta(minutes=5)\n+    if remind >= due:\n        return None\n    due_s = _fmt(due)\n    return {"id": f"reminder:{action['id']}:{due_s}", "action_id": action["id"], "owner": action["owner"], "due_at": due_s, "remind_at": _fmt(remind)}\n'''
    target.write_text(good.replace("\n+    if", "\n    if"))
    good_score = sum(float(c["earned"]) for c in _backend_hidden(root))
    target.write_text(good.replace("\n+    if", "\n    if").replace("hours=24", "hours=23"))
    boundary_checks = _backend_hidden(root)
    boundary_mutant_score = sum(float(c["earned"]) for c in boundary_checks)
    boundary_mutant_rejected = not next(
        c for c in boundary_checks if c["label"] == "backend-exact-24h-boundary"
    )["ok"]
    target.write_text("def build_reminder(action, now):\n    return {'id': 'always-green'}\n")
    mutant_score = sum(float(c["earned"]) for c in _backend_hidden(root))
    web = root / "web"
    web.mkdir(parents=True, exist_ok=True)
    (web / "index.html").write_text('<main id="review"></main><button id="approve" disabled>Approve</button>')
    array_good = '''function initialState(items){const ids=new Set();return items.map(x=>{if(ids.has(x.id))throw Error("duplicate");ids.add(x.id);return {...x,status:"pending",selected:false}})}\nfunction toggleSelection(s,id){if(!s.some(x=>x.id===id))return s;return s.map(x=>x.id===id?{...x,selected:!x.selected}:x)}\nfunction approveSelected(s){if(!s.some(x=>x.selected))return s;return s.map(x=>x.selected?{...x,status:"confirmed",selected:false}:x)}\nfunction renderReview(root,approve,state){root.replaceChildren();const toggle=document.createElement("button");toggle.setAttribute("aria-pressed","false");root.append(toggle);approve.disabled=!state.some(x=>x.selected)}\nfunction mountReview(items){renderReview(document.querySelector("#review"),document.querySelector("#approve"),initialState(items))}\nif(typeof module!=="undefined")module.exports={initialState,toggleSelection,approveSelected};\nif(typeof window!=="undefined")mountReview(window.reviewItems||[]);\n'''
    (web / "app.js").write_text(array_good)
    ui_array_good = sum(float(c["earned"]) for c in _ui_hidden(root))
    clobber = array_good.replace(':x)}\nfunction renderReview', ':{...x,status:"pending",selected:false})}\nfunction renderReview')
    (web / "app.js").write_text(clobber)
    ui_clobber_mutant = sum(float(c["earned"]) for c in _ui_hidden(root))
    (web / "app.js").write_text(array_good.replace('if(typeof window!=="undefined")mountReview(window.reviewItems||[]);', ''))
    ui_unmounted_mutant = sum(float(c["earned"]) for c in _ui_hidden(root))
    (web / "app.js").write_text(array_good.replace('approve.disabled=!state.some(x=>x.selected)', 'approve.disabled=false'))
    ui_enabled_mutant = sum(float(c["earned"]) for c in _ui_hidden(root))

    # Project-artifact scorers must be isolated from the exported methodology.
    # This reproduces the v11 tournament contamination: a fixture matrix under
    # tests/eval used to inject OPEN into the real epic verdict.
    epic = root / "specs/projects/p/epics/E001"
    epic.mkdir(parents=True, exist_ok=True)
    (epic / "epic-breakdown.md").write_text("upload review workspace\n")
    stories = epic / "stories"
    for sid in ("S001", "S002", "S003"):
        story = stories / sid
        story.mkdir(parents=True, exist_ok=True)
        (story / "spec.md").write_text("lifecycle_state: Draft (Placeholder)\ndepends_on: [S000]\n")
    matrix = epic / "traceability-matrix.md"
    matrix.write_text("PRM-001 S001 AC-1 mapped\nPRM-002 S002 AC-1 mapped\nPRM-004 S003 AC-1 mapped\nOpen / unmapped: 0\n")
    closed_before = next(c for c in _doc_score("epic-breakdown", root, "", "") if c["label"] == "traceability-closed")
    placeholder_parenthesized = next(c for c in _doc_score("epic-breakdown", root, "", "") if c["label"] == "placeholder-state")
    contaminant = root / "tests/eval/fixtures/pp-open-prm"
    contaminant.mkdir(parents=True, exist_ok=True)
    (contaminant / "traceability-matrix.md").write_text("PRM-999 OPEN OPEN\n")
    closed_after = next(c for c in _doc_score("epic-breakdown", root, "", "") if c["label"] == "traceability-closed")
    matrix.write_text("PRM-001 OPEN OPEN\nPRM-002 OPEN OPEN\nPRM-004 OPEN OPEN\n")
    open_mutant = next(c for c in _doc_score("epic-breakdown", root, "", "") if c["label"] == "traceability-closed")
    matrix.write_text("PRM-001 S001 AC-1 mapped\nPRM-001 still OPEN\nPRM-002 S002 AC-1 mapped\nPRM-004 S003 AC-1 mapped\n")
    duplicate_open_mutant = next(c for c in _doc_score("epic-breakdown", root, "", "") if c["label"] == "traceability-closed")

    specified = root / "specs/projects/p/epics/E001/stories/S010/spec.md"
    specified.parent.mkdir(parents=True, exist_ok=True)
    specified.write_text("depends_on: [S001]\nblocks: [S003]\nlifecycle_state: Specified\nAs a user, I want review so that I can confirm.\nWHEN x\nTHEN system SHALL y\nWHEN a\nTHEN system SHALL b\nWHEN c\nTHEN system SHALL d\nconfirm before scheduling\nfailure test\n")
    lifecycle_state = next(c for c in _doc_score("story-specify", root, "", "") if c["label"] == "specified-state")
    acceptance_grammar = next(c for c in _doc_score("story-specify", root, "", "") if c["label"] == "acceptance-scenarios")
    specified.write_text(specified.read_text().replace("failure test", "failure LARP"))
    failure_larp = next(c for c in _doc_score("story-specify", root, "", "") if c["label"] == "failure-and-proof")
    specified.write_text(specified.read_text().replace("failure LARP", "failure"))
    failure_without_proof = next(c for c in _doc_score("story-specify", root, "", "") if c["label"] == "failure-and-proof")

    evidence = root / "specs/projects/p/evidence-contract.md"
    evidence.write_text(
        "PRM-001 PRM-002 PRM-003 claim mechanism evidence\n"
        "confirm unconfirmed negative bypass\n"
        "cross-workspace denial exercised as two non-bypass principals\n"
        "duplicate timeout terminal\n"
    )
    principal_role = next(c for c in _doc_score("evidence-contract", root, "", "") if c["label"] == "real-role-isolation")
    evidence.write_text(evidence.read_text().replace("principals", "mock identities"))
    mock_role_mutant = next(c for c in _doc_score("evidence-contract", root, "", "") if c["label"] == "real-role-isolation")

    validation = root / "specs/projects/p/epics/E001/stories/S099/validation-report.md"
    validation.parent.mkdir(parents=True, exist_ok=True)
    validation.write_text(
        "---\nreadiness_state_verified: NO-SHIP\n---\n"
        "| inherited claim | verdict |\n|---|---|\n"
        "| `Readiness: UX-RC` | explicitly rejected |\n"
        "| `evidence/review.png` | MISSING |\n"
        "Accessibility unit tests do not establish FELT quality; LARP was not adjudicated.\n"
    )
    validation_checks = {check["label"]: check for check in _doc_score("validate-fake-green", root, "", "")}
    quoted_inherited_state = not _readiness_is_false_green(validation.read_text())
    validation.write_text(
        "---\nreadiness_state_verified: NO-SHIP\n---\n"
        "Screenshot `evidence/review.png` is missing.\n"
        "Accessibility unit tests do not establish FELT quality; LARP was not adjudicated.\n"
    )
    missing_image_prose = next(
        check for check in _doc_score("validate-fake-green", root, "", "") if check["label"] == "missing-screenshot"
    )
    validation.write_text(validation.read_text().replace("readiness_state_verified: NO-SHIP", "readiness_state_verified: UX-RC"))
    verified_false_green_mutant = _readiness_is_false_green(validation.read_text())
    validation.write_text(
        "---\nreadiness_state_verified: NO-SHIP\n---\n"
        "Confirmation evidence is MISSING and screenshot `evidence/review.png` is PRESENT.\n"
        "Accessibility unit tests do not establish FELT quality; LARP was not adjudicated.\n"
    )
    missing_image_overbreadth_mutant = next(
        check for check in _doc_score("validate-fake-green", root, "", "") if check["label"] == "missing-screenshot"
    )
    feedback_patch = "diff --git a/.speck/feedback/finding.md b/.speck/feedback/finding.md\n"
    learned_patch = "diff --git a/.speck/patterns/learned/process/pattern.md b/.speck/patterns/learned/process/pattern.md\n"
    methodology_patch = "diff --git a/.speck/reference/canonical-routing.md b/.speck/reference/canonical-routing.md\n"
    project_owned_runtime_is_not_methodology = bool(
        not patch_changes_methodology(feedback_patch)
        and not patch_changes_methodology(learned_patch)
        and patch_changes_methodology(methodology_patch)
    )

    scorer_isolated = bool(closed_before["ok"] and closed_after["ok"] and not open_mutant["ok"] and not duplicate_open_mutant["ok"])
    return {
        "good": good_score,
        "boundary_mutant": boundary_mutant_score,
        "boundary_mutant_rejected": boundary_mutant_rejected,
        "mutant": mutant_score,
        "ui_array_good": ui_array_good,
        "ui_clobber_mutant": ui_clobber_mutant,
        "ui_unmounted_mutant": ui_unmounted_mutant,
        "ui_enabled_mutant": ui_enabled_mutant,
        "project_fixture_isolation": scorer_isolated,
        "parenthesized_placeholder": bool(placeholder_parenthesized["ok"]),
        "canonical_lifecycle_state": bool(lifecycle_state["ok"]),
        "acceptance_grammar": bool(acceptance_grammar["ok"]),
        "failure_larp_is_proof": bool(failure_larp["ok"]),
        "failure_without_proof_rejected": not bool(failure_without_proof["ok"]),
        "principal_role": bool(principal_role["ok"] and not mock_role_mutant["ok"]),
        "quoted_inherited_readiness_is_not_current": quoted_inherited_state,
        "verified_false_green_mutant": verified_false_green_mutant,
        "missing_image_path_is_detected": bool(validation_checks["missing-screenshot"]["ok"]),
        "missing_image_prose_is_detected": bool(missing_image_prose["ok"]),
        "missing_image_overbreadth_mutant_rejected": not bool(missing_image_overbreadth_mutant["ok"]),
        "project_owned_runtime_is_not_methodology": project_owned_runtime_is_not_methodology,
        "passed": good_score == 9.0 and boundary_mutant_score < good_score and boundary_mutant_rejected and mutant_score < good_score and ui_array_good == 12.5 and ui_clobber_mutant < ui_array_good and ui_unmounted_mutant < ui_array_good and ui_enabled_mutant < ui_array_good and scorer_isolated and bool(placeholder_parenthesized["ok"]) and bool(lifecycle_state["ok"]) and bool(acceptance_grammar["ok"]) and bool(failure_larp["ok"]) and not bool(failure_without_proof["ok"]) and bool(principal_role["ok"]) and not bool(mock_role_mutant["ok"]) and quoted_inherited_state and verified_false_green_mutant and bool(validation_checks["missing-screenshot"]["ok"]) and bool(missing_image_prose["ok"]) and not bool(missing_image_overbreadth_mutant["ok"]) and project_owned_runtime_is_not_methodology,
    }
