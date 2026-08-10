#!/usr/bin/env python3
"""Skill-catalog + agent-prose half of validate-corpus-budget.sh"""
from __future__ import annotations

import json
import itertools
import re
import sys
from pathlib import Path

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
POINTER_ONLY = re.compile(
    r"Read and fully execute `?references/procedure\.md`?",
    re.I,
)

MAX_REF_LINES = 120
MAX_REF_BYTES = 8192
MAX_ROUTER_BODY = 80
LOCAL_REF_EDGE = re.compile(
    r"(?<![A-Za-z0-9_./-])references/([A-Za-z0-9_./<>#*-]+\.md)"
)
AUTO_DESCRIPTION_TRIGGER = re.compile(
    r"^(?:when|after|before|at|for|only|while|during|whenever)\b",
    re.I,
)
DESCRIPTION_PRONOUN = re.compile(r"\b(?:I|me|my|we|our|you|your)\b", re.I)
THIRD_PERSON_ACTION = re.compile(r"^[A-Z][A-Za-z-]*s\b")
MIN_DESCRIPTION_WHAT = 20
MIN_DESCRIPTION_TRIGGER = 24


def router_owns_ref(body: str, rel: str) -> bool:
    """A DAG node must be directly reachable from its router, not another node."""
    if f"references/{rel}" in body:
        return True
    if rel.startswith("states/") and "references/states/<kebab>.md" in body:
        return True
    if rel.startswith("lenses/L") and "references/lenses/L#.md" in body:
        return True
    return False


def lint_load_budgets(root: Path, err) -> None:
    """Enforce byte ceilings for declared branch-specific execution paths."""
    budget_path = root / ".speck" / "reference" / "skill-load-budgets.json"
    if not budget_path.is_file():
        return
    try:
        data = json.loads(budget_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        err(f"invalid skill load budget file: {exc}")
        return

    cases = data.get("cases")
    if not isinstance(cases, list):
        err("skill load budget file must contain a cases list")
        return

    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            err("skill load budget case must be an object")
            continue
        case_id = case.get("id")
        files = case.get("files")
        max_bytes = case.get("max_bytes")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            err(f"invalid or duplicate skill load budget id: {case_id!r}")
            continue
        seen.add(case_id)
        if not isinstance(files, list) or not files or not all(isinstance(p, str) for p in files):
            err(f"skill load budget {case_id} requires a non-empty files list")
            continue
        if not isinstance(max_bytes, int) or max_bytes <= 0:
            err(f"skill load budget {case_id} requires positive max_bytes")
            continue

        total = 0
        valid = True
        for rel in files:
            path = (root / rel).resolve()
            try:
                path.relative_to(root.resolve())
            except ValueError:
                err(f"skill load budget {case_id} escapes repository: {rel}")
                valid = False
                continue
            if not path.is_file():
                err(f"skill load budget {case_id} missing path: {rel}")
                valid = False
                continue
            total += path.stat().st_size
        if not valid:
            continue
        print(f"load_path={case_id} bytes={total} (max {max_bytes})")
        if total > max_bytes:
            err(f"skill load path {case_id} bytes {total} > {max_bytes}")


def lint_load_contracts(root: Path, err) -> dict[str, set[str]]:
    """Validate executable JIT contracts and return entrypoint-owned paths."""
    contract_path = root / ".speck" / "reference" / "skill-load-contracts.json"
    if not contract_path.is_file():
        return {}
    try:
        data = json.loads(contract_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        err(f"invalid skill load contract file: {exc}")
        return {}
    if data.get("schema_version") != 1 or not isinstance(data.get("profiles"), dict):
        err("skill load contracts require schema_version 1 and a profiles object")
        return {}

    budgets: dict[str, dict[str, object]] = {}
    budget_path = root / ".speck" / "reference" / "skill-load-budgets.json"
    try:
        budget_data = json.loads(budget_path.read_text())
        budgets = {
            case["id"]: case
            for case in budget_data.get("cases", [])
            if isinstance(case, dict) and isinstance(case.get("id"), str)
        }
    except (OSError, json.JSONDecodeError):
        pass

    owned: dict[str, set[str]] = {}
    root_resolved = root.resolve()

    def normalize(profile_id: str, rel: object) -> str | None:
        if not isinstance(rel, str) or not rel:
            err(f"skill load contract {profile_id} has invalid path {rel!r}")
            return None
        clean = rel.replace("\\", "/")
        while clean.startswith("./"):
            clean = clean[2:]
        path = (root / clean).resolve()
        try:
            path.relative_to(root_resolved)
        except ValueError:
            err(f"skill load contract {profile_id} escapes repository: {rel}")
            return None
        if not path.is_file():
            err(f"skill load contract {profile_id} missing path: {clean}")
            return None
        return clean

    for profile_id, entry in sorted(data["profiles"].items()):
        if not isinstance(profile_id, str) or not isinstance(entry, dict):
            err(f"invalid skill load contract profile: {profile_id!r}")
            continue
        entrypoint = normalize(profile_id, entry.get("entrypoint"))
        required_raw = entry.get("required_files")
        forbidden_raw = entry.get("forbidden_files", [])
        gates = entry.get("post_write_gates")
        all_gates = entry.get("post_write_gates_all", [])
        if not isinstance(required_raw, list) or not all(isinstance(x, str) and x for x in required_raw):
            err(f"skill load contract {profile_id} required_files must be a string list")
            continue
        if not isinstance(forbidden_raw, list):
            err(f"skill load contract {profile_id} forbidden_files must be a list")
            continue
        read_only = entry.get("read_only", False)
        if not isinstance(read_only, bool):
            err(f"skill load contract {profile_id} read_only must be boolean")
            read_only = False
        if not isinstance(gates, list) or not all(isinstance(x, str) and x for x in gates):
            err(f"skill load contract {profile_id} post_write_gates must be a string list")
        elif read_only and gates:
            err(f"read-only skill load contract {profile_id} cannot declare post_write_gates")
        elif not read_only and not gates:
            err(f"mutating skill load contract {profile_id} requires non-empty post_write_gates")
        if not isinstance(all_gates, list) or not all(isinstance(x, str) and x for x in all_gates):
            err(f"skill load contract {profile_id} post_write_gates_all must be a string list")
        elif read_only and all_gates:
            err(f"read-only skill load contract {profile_id} cannot declare post_write_gates_all")
        required = [p for p in (normalize(profile_id, x) for x in required_raw) if p]
        forbidden = [p for p in (normalize(profile_id, x) for x in forbidden_raw) if p]
        overlap = sorted(set(required) & set(forbidden))
        if overlap:
            err(f"skill load contract {profile_id} requires and forbids the same paths: {overlap}")
        all_owned = set(required) | set(forbidden)
        all_required = set(required)
        selectors = entry.get("selectors", {})
        if not isinstance(selectors, dict):
            err(f"skill load contract {profile_id} selectors must be an object")
            selectors = {}
        selector_values: list[tuple[str, list[tuple[str, dict[str, object]]]]] = []
        for key, selector in selectors.items():
            if not isinstance(selector, dict) or not isinstance(selector.get("values"), dict):
                err(f"skill load contract {profile_id} selector {key!r} requires values")
                continue
            values: list[tuple[str, dict[str, object]]] = []
            for value, branch in selector["values"].items():
                if not isinstance(branch, dict):
                    err(f"skill load contract {profile_id} selector {key}={value} must be an object")
                    continue
                branch_required_raw = branch.get("required_files", [])
                branch_forbidden_raw = branch.get("forbidden_files", [])
                branch_all_gates = branch.get("post_write_gates_all", [])
                if not isinstance(branch_required_raw, list) or not isinstance(branch_forbidden_raw, list):
                    err(f"skill load contract {profile_id} selector {key}={value} paths must be lists")
                    continue
                if not isinstance(branch_all_gates, list) or not all(isinstance(x, str) and x for x in branch_all_gates):
                    err(f"skill load contract {profile_id} selector {key}={value} post_write_gates_all must be a string list")
                branch_required = [p for p in (normalize(profile_id, x) for x in branch_required_raw) if p]
                branch_forbidden = [p for p in (normalize(profile_id, x) for x in branch_forbidden_raw) if p]
                all_owned.update(branch_required)
                all_owned.update(branch_forbidden)
                all_required.update(branch_required)
                values.append((str(value), {"required_files": branch_required}))
            if selector.get("required", False) and not values:
                err(f"skill load contract {profile_id} selector {key} has no values")
            selector_values.append((str(key), values))

        if entrypoint:
            owned.setdefault(entrypoint, set()).update(all_owned)
            if "speck_context.py" not in (root / entrypoint).read_text():
                err(f"skill load contract {profile_id} entrypoint does not invoke speck_context.py")
            instruction_files = {entrypoint, *(path for path in all_required if path.endswith(".md"))}
            for owner in instruction_files:
                text = (root / owner).read_text()
                for target in all_required - {owner}:
                    duplicate_edge = any(
                        target in line
                        and re.search(r"\b(?:read|load|open)\b", line, re.IGNORECASE)
                        and not re.search(r"\b(?:do not|don't|never)\s+(?:re-?)?(?:read|load|open)\b", line, re.IGNORECASE)
                        for line in text.splitlines()
                    )
                    if duplicate_edge:
                        err(
                            f"skill load contract {profile_id} file {owner} restates contract path {target} — "
                            "use the receipted bytes; do not create a second load edge"
                        )

        if not all_required:
            err(f"skill load contract {profile_id} resolves no required context files")

        if selector_values:
            max_bytes = entry.get("max_bytes")
            if not isinstance(max_bytes, int) or max_bytes <= 0:
                err(f"dynamic skill load contract {profile_id} requires positive max_bytes")
            else:
                groups = [values for _, values in selector_values]
                worst_total = -1
                worst_label = ""
                for combination in itertools.product(*groups):
                    paths = ([entrypoint] if entrypoint else []) + required[:]
                    selected_label: list[str] = []
                    for (key, _), (value, branch) in zip(selector_values, combination):
                        selected_label.append(f"{key}={value}")
                        paths.extend(branch["required_files"])
                    unique = list(dict.fromkeys(paths))
                    total = sum((root / path).stat().st_size for path in unique)
                    if total > worst_total:
                        worst_total = total
                        worst_label = ",".join(selected_label)
                print(f"load_contract={profile_id}[worst:{worst_label}] bytes={worst_total} (max {max_bytes})")
                if worst_total > max_bytes:
                    err(f"skill load contract {profile_id}[{worst_label}] bytes {worst_total} > {max_bytes}")
        else:
            budget = budgets.get(profile_id)
            combined = ([entrypoint] if entrypoint else []) + required
            if not budget:
                err(f"static skill load contract {profile_id} has no matching load budget")
            elif budget.get("files") != combined:
                err(f"skill load contract {profile_id} files drift from load budget")
    return owned


def load_skill_catalog_policy(root: Path, err) -> tuple[set[str], set[str], dict[str, dict[str, list[str]]]]:
    """Return expected user-only skills, compatibility shims, and family declarations."""
    path = root / ".speck" / "reference" / "skill-catalog-policy.json"
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        err(f"invalid skill catalog policy: {exc}")
        return set(), set(), {}
    if data.get("schema_version") != 1 or not isinstance(data.get("families"), dict):
        err("skill catalog policy requires schema_version 1 and a families object")
        return set(), set(), {}

    explicit = data.get("explicit_user_only", [])
    top_shims = data.get("compatibility_shims", [])
    if not isinstance(explicit, list) or not all(isinstance(x, str) and x for x in explicit):
        err("skill catalog policy explicit_user_only must be a string list")
        explicit = []
    if not isinstance(top_shims, list) or not all(isinstance(x, str) and x for x in top_shims):
        err("skill catalog policy compatibility_shims must be a string list")
        top_shims = []

    disabled = set(explicit) | set(top_shims)
    shims = set(top_shims)
    families: dict[str, dict[str, list[str]]] = {}
    claimed: dict[str, str] = {}
    for family, raw in sorted(data["families"].items()):
        if not isinstance(family, str) or not isinstance(raw, dict):
            err(f"invalid skill catalog family {family!r}")
            continue
        normalized: dict[str, list[str]] = {}
        for key in ("auto_entrypoints", "user_only_routers", "compatibility_shims"):
            values = raw.get(key, [])
            if not isinstance(values, list) or not all(isinstance(x, str) and x for x in values):
                err(f"skill catalog family {family} {key} must be a string list")
                values = []
            normalized[key] = values
            for name in values:
                previous = claimed.setdefault(name, family)
                if previous != family:
                    err(f"skill catalog entry {name} belongs to both {previous} and {family}")
        if not normalized["auto_entrypoints"]:
            err(f"skill catalog family {family} requires at least one auto entrypoint")
        overlap = set(normalized["auto_entrypoints"]) & (
            set(normalized["user_only_routers"]) | set(normalized["compatibility_shims"])
        )
        if overlap:
            err(f"skill catalog family {family} marks entries auto and user-only: {sorted(overlap)}")
        disabled.update(normalized["user_only_routers"])
        disabled.update(normalized["compatibility_shims"])
        shims.update(normalized["compatibility_shims"])
        families[family] = normalized
    return disabled, shims, families


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


def lint_auto_description(name: str, desc: str, err) -> None:
    """Enforce the cheap half of ADR-0008; model routing owns semantic fitness."""
    if not desc:
        err(f"automatic skill {name} requires a description")
        return
    if DESCRIPTION_PRONOUN.search(desc):
        err(f"automatic skill {name} description must use third person: {desc}")
    if not THIRD_PERSON_ACTION.match(desc):
        err(f"automatic skill {name} description WHAT must start with a third-person action: {desc}")
    if desc.count(". Use ") != 1 or not desc.endswith("."):
        err(f"automatic skill {name} description must be '<WHAT>. Use <WHEN>.': {desc}")
        return
    what, trigger = desc.split(". Use ", 1)
    trigger = trigger[:-1]
    if len(what) < MIN_DESCRIPTION_WHAT:
        err(f"automatic skill {name} description WHAT is too vague ({len(what)} chars): {what}")
    if len(trigger) < MIN_DESCRIPTION_TRIGGER:
        err(f"automatic skill {name} description WHEN is too vague ({len(trigger)} chars): {trigger}")
    if not AUTO_DESCRIPTION_TRIGGER.match(trigger):
        err(f"automatic skill {name} description WHEN lacks a concrete trigger/context preposition: {trigger}")


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

    expected_disabled, compatibility_shims, catalog_families = load_skill_catalog_policy(root, err)
    contract_owned = lint_load_contracts(root, err)
    seen_skills: set[str] = set()

    for skill_md in sorted(skills.glob("*/SKILL.md")):
        name = skill_md.parent.name
        seen_skills.add(name)
        text = skill_md.read_text()
        fm, body = parse_fm(text)
        desc = description(fm)
        disabled = bool(re.search(r"^disable-model-invocation:\s*true\s*$", fm, re.M))

        expected_user_only = name in expected_disabled
        if disabled != expected_user_only:
            state = "true" if expected_user_only else "false/absent"
            err(f"skill {name} disable-model-invocation must be {state} per skill-catalog-policy.json")
        if not disabled:
            auto += 1
            dlen = len(desc)
            desc_sum += dlen
            lint_auto_description(name, desc, err)
            if dlen > max_desc:
                err(f"skill {name} description length {dlen} > {max_desc}: {desc[:80]}...")

        refs = skill_md.parent / "references"
        ref_mds = sorted(refs.rglob("*.md")) if refs.is_dir() else []
        n_refs = len(ref_mds)

        # Anti-theater: single procedure.md pointer (ADR-0005)
        if n_refs == 1 and ref_mds[0].name == "procedure.md":
            err(
                f"skill {name} has single references/procedure.md — "
                "inline into SKILL.md or split into a real load DAG (≥2 refs) (ADR-0005)"
            )
        elif n_refs == 1 and POINTER_ONLY.search(body):
            err(f"skill {name} is a single-ref pointer theater pattern (ADR-0005)")

        for ref in ref_mds:
            rel = ref.relative_to(refs).as_posix()
            repo_rel = ref.relative_to(root).as_posix()
            entrypoint = skill_md.relative_to(root).as_posix()
            if not router_owns_ref(body, rel) and repo_rel not in contract_owned.get(entrypoint, set()):
                err(
                    f"skill ref {name}/references/{rel} is not directly owned by its router or executable contract — "
                    "declare the edge in SKILL.md/skill-load-contracts.json or delete the orphan (ADR-0005/0006)"
                )

        # Ban predicate-hiding routers (ADR-0005): agent must know the branch
        # without reading the ref.
        if re.search(
            r"when that domain applies|Read `references/[^`]+` when that domain|"
            r"Read `references/[^`]+` when applicable|"
            r"Read `references/[^`]+` if relevant",
            body,
            re.I,
        ):
            err(
                f"skill {name} hides branch predicates ('when domain applies') — "
                "state cheap keys inline in SKILL.md (ADR-0005)"
            )

        # Ban always-all fake DAGs: ≥2 refs but every Read is unconditional MUST
        # with no If/Else/Only/Cheap keys — that is always-path; inline instead.
        if n_refs >= 2:
            has_pred = bool(
                re.search(
                    r"Cheap keys:|\bIf\b|\bElse\b|Only (after|when|before)|"
                    r"Do not Read|matching `|Skip if|UI-bearing|play_level|"
                    r"archetype|claimed_state|Backend/",
                    body,
                )
            )
            if not has_pred:
                err(
                    f"skill {name} has {n_refs} refs but no inline branch predicates — "
                    "inline always-path into SKILL.md or add cheap keys (ADR-0005)"
                )

        body_lines = len(body.splitlines())
        if name in compatibility_shims:
            if n_refs:
                err(f"compatibility shim {name} owns references; route to the canonical skill instead")
            if body_lines > 25:
                err(f"compatibility shim {name} body lines {body_lines} > 25")
        body_cap = MAX_ROUTER_BODY if n_refs >= 2 else max_body
        if body_lines > body_cap:
            gf_key = name if n_refs < 2 else f"{name}#router"
            if gf_key in grandfather or name in grandfather:
                print(f"WARN grandfather body {name} lines={body_lines} cap={body_cap}")
            else:
                err(f"skill {name} body lines {body_lines} > {body_cap} (refs={n_refs})")

        lint_agent_prose(skill_md, body, err)

        for ref in ref_mds:
            rtext = ref.read_text()
            rlines = len(rtext.splitlines())
            key = f"{name}/references/{ref.relative_to(refs).as_posix()}"
            if not rtext.strip():
                err(f"skill ref {key} is empty — a load edge must carry executable instruction")
            nested_edges = LOCAL_REF_EDGE.findall(rtext)
            if nested_edges:
                err(
                    f"skill ref {key} routes to {', '.join(sorted(set(nested_edges)))} — "
                    "all load edges must be declared in SKILL.md (ADR-0005)"
                )
            if rlines > MAX_REF_LINES:
                if key in grandfather:
                    print(f"WARN grandfather ref {key} lines={rlines}")
                else:
                    err(f"skill ref {key} lines {rlines} > {MAX_REF_LINES}")
            rbytes = len(rtext.encode())
            if rbytes > MAX_REF_BYTES:
                err(f"skill ref {key} bytes {rbytes} > {MAX_REF_BYTES}")
            lint_agent_prose(ref, rtext, err)

    declared = set(expected_disabled)
    for family in catalog_families.values():
        declared.update(family["auto_entrypoints"])
    missing = sorted(declared - seen_skills)
    if missing:
        err(f"skill catalog policy names missing skills: {missing}")

    ref_root = root / ".speck" / "reference"
    if ref_root.is_dir():
        for ref in sorted(ref_root.glob("*.md")):
            lint_agent_prose(ref, ref.read_text(), err, strict=False)

    print(f"auto_skills={auto} desc_sum={desc_sum} (max {max_sum})")
    if desc_sum > max_sum:
        err(f"description sum {desc_sum} > {max_sum}")

    lint_load_budgets(root, err)

    if gf_path.is_file():
        for name in sorted(grandfather):
            if "/" in name:
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
