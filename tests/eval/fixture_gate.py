#!/usr/bin/env python3
"""Evaluate one seeded artifact and prove its owning Speck instruction is reachable."""
from __future__ import annotations

import argparse
import functools
import importlib.util
import itertools
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Callable


CORPUS_ANCHORS: dict[str, tuple[str, tuple[str, ...]]] = {
    "banned-language": ("story-implement", (r"banned-language",)),
    # \b-anchored: bare `cit(e|ation|ed|ing|es)` (no word boundary) is satisfied by
    # any word merely CONTAINING that substring — "excited", "elicited", "solicited" —
    # none of which is an evidence-citation instruction (v11 audit L7 finding 1 repair,
    # round 2). Every pattern for a class must now be found together in one real
    # session (see assert_corpus_anchor) so this pairs with "evidence" per-session,
    # not as an independent cross-session union.
    "fabricated-evidence": ("story-validate", (r"evidence", r"\bcit(?:e|ed|es|ing|ation|ations)\b")),
    "fake-green": ("story-validate", (r"IS-IT-GOOD|adjudicat",)),
    "phantom-promise": ("story-validate", (r"PRM|promise discharge",)),
    "self-audit": ("speck-audit", (r"Auditor.*implementer|separate.*(?:auditor|subagent|session|model)",)),
    "unreachable-excuse": ("story-validate", (r"logged reproduced|attempt log|reproduced.*(?:failure|attempt)",)),
}

# Defect classes with exactly one shipped, standalone validator script. Deleting
# or blanking that script is a distinct mutation from deleting the skill prose
# the corpus anchor above checks, so it needs its own guard (assert_validator_alive).
VALIDATOR_LIVENESS: dict[str, tuple[str, ...]] = {
    "banned-language": (".speck/scripts/banned-language-lint.sh",),
    "fabricated-evidence": (".speck/scripts/validation/validators/validate-evidence-citations.sh",),
    "phantom-promise": (".speck/scripts/validation/validators/validate-traceability-matrix.sh",),
}

# fake-green, self-audit, and unreachable-excuse have no single shipped validator
# to check liveness against (their enforcement is procedural/cross-cutting, not
# one script). They stay covered by assert_corpus_anchor + defect_present alone.
# This is a real, disclosed gap, not a silent one — see score.py's report.
NOT_VALIDATOR_BACKED: frozenset[str] = frozenset(CORPUS_ANCHORS) - frozenset(VALIDATOR_LIVENESS)

MIN_VALIDATOR_CHARS = 200

# Real behavioral liveness probes, one per VALIDATOR_LIVENESS entry. A file-length
# check alone is defeated by neutering rather than deleting a validator: replace the
# body with a short `exit 0` no-op that still clears MIN_VALIDATOR_CHARS (v11 audit
# L7 finding 2/5 repair, round 2). Each probe below runs the real validator TWICE —
# once against a minimal fixture it is KNOWN to flag, and once against a minimal
# fixture it is KNOWN to pass — and requires BOTH verdicts. Checking only the
# flag-it direction is itself neutered by the neighbouring stub `exit 1` (always
# fail): that trivially "flags" the bad fixture without ever having run real logic,
# and would silently break every legitimately clean project. Requiring the pass
# direction too closes both directions of stub.
_PROBE_TIMEOUT_SECONDS = 30


def _run_probe(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd, cwd=str(cwd), capture_output=True, text=True, timeout=_PROBE_TIMEOUT_SECONDS
    )


def _probe_banned_language(root: Path, validator: Path) -> None:
    def _fixture(tmp_path: Path, term_in_copy: bool) -> None:
        proj = tmp_path / "specs" / "projects" / "probe"
        proj.mkdir(parents=True)
        (proj / "product-contract.md").write_text(
            "# Product Contract\n\n"
            "## 7. Banned Language / System Anti-Patterns\n\n"
            "| Banned Term | Where it appears | Why it's banned | Use instead |\n"
            "|---|---|---|---|\n"
            "| speckprobeterm | UI | liveness probe | replacement |\n"
        )
        (tmp_path / ".speck").mkdir()
        (tmp_path / ".speck" / "project.json").write_text(
            json.dumps({"project_id": "probe", "play_level": "sprint"})
        )
        src = tmp_path / "src"
        src.mkdir()
        copy = "speckprobeterm" if term_in_copy else "clean copy"
        (src / "probe.ts").write_text(f'export const tagline = "{copy}";\n')

    with tempfile.TemporaryDirectory() as tmp:
        dirty = Path(tmp) / "dirty"
        dirty.mkdir()
        _fixture(dirty, term_in_copy=True)
        dirty_result = _run_probe(["bash", str(validator)], cwd=dirty)
        clean = Path(tmp) / "clean"
        clean.mkdir()
        _fixture(clean, term_in_copy=False)
        clean_result = _run_probe(["bash", str(validator)], cwd=clean)

    if dirty_result.returncode != 1 or "speckprobeterm" not in (dirty_result.stdout + dirty_result.stderr):
        raise RuntimeError(
            f"shipped validator not enforcing (liveness probe failed): {validator} "
            f"(probe expected exit 1 flagging a seeded banned term, got exit {dirty_result.returncode})"
        )
    if clean_result.returncode != 0:
        raise RuntimeError(
            f"shipped validator not enforcing (liveness probe failed): {validator} "
            f"(probe expected exit 0 on term-free copy — a validator that always fails "
            f"would also 'flag' the seeded term without checking anything, got exit "
            f"{clean_result.returncode})"
        )


def _probe_evidence_citations(root: Path, validator: Path) -> None:
    template = root / ".speck" / "templates" / "project" / "evidence-contract-template.md"
    if not template.is_file():
        raise RuntimeError(f"evidence-contract template missing for liveness probe: {template}")
    template_text = template.read_text()

    def _fixture(dest: Path, citation: str) -> None:
        dest.write_text(
            template_text
            + "\n\n### 11a. Standard Probe Library\n\n"
            "| Probe ID | Claim type | Discharge artifact | Exception |\n"
            "|---|---|---|---|\n"
            f"| PROBE:legacy | `visibility` | `{citation}` | — |\n"
        )

    with tempfile.TemporaryDirectory() as tmp:
        mismatched = Path(tmp) / "mismatched.md"
        _fixture(mismatched, "test:specs/logs/x.test.ts")
        bad_result = _run_probe(["bash", str(validator), "--strict", str(mismatched)], cwd=Path(tmp))
        admissible = Path(tmp) / "admissible.md"
        _fixture(admissible, "live-probe:specs/logs/x.log")
        clean_result = _run_probe(["bash", str(validator), "--strict", str(admissible)], cwd=Path(tmp))

    if bad_result.returncode != 1 or "PROBE_SUBSTRATE_MISMATCH.P1" not in (bad_result.stdout + bad_result.stderr):
        raise RuntimeError(
            f"shipped validator not enforcing (liveness probe failed): {validator} "
            f"(probe expected exit 1 with PROBE_SUBSTRATE_MISMATCH.P1 on a mismatched "
            f"visibility citation, got exit {bad_result.returncode})"
        )
    if clean_result.returncode != 0:
        raise RuntimeError(
            f"shipped validator not enforcing (liveness probe failed): {validator} "
            f"(probe expected exit 0 on an admissible visibility citation — a validator "
            f"that always fails would also raise P1 on this one, got exit "
            f"{clean_result.returncode})"
        )


def _probe_traceability(root: Path, validator: Path) -> None:
    header = (
        "# Promise Traceability Matrix: Probe\n\n"
        "## 2. Traceability Matrix\n\n"
        "| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) |"
        " Discharge (story-id + AC-ref) | DEC (if descoped) |"
        " Backing (fine-grained PRM/audit refs) | Status |\n"
        "|--------|------------------------------------|------------------------|"
        "-------------------------------|-------------------|"
        "---------------------------------------|--------|\n"
    )
    with tempfile.TemporaryDirectory() as tmp:
        bad = Path(tmp) / "unbacked.md"
        bad.write_text(header + "| PRM-001 | probe | promise text | — | — | — | pilot-gated |\n")
        bad_result = _run_probe(
            ["bash", str(validator), "--require-evidence", "--status-only", str(bad)], cwd=Path(tmp)
        )
        clean = Path(tmp) / "discharged.md"
        clean.write_text(
            header + "| PRM-001 | probe | promise text | S001 / AC-1 | — | — | discharged |\n"
        )
        clean_result = _run_probe(
            ["bash", str(validator), "--require-evidence", "--status-only", str(clean)], cwd=Path(tmp)
        )

    if bad_result.returncode != 1:
        raise RuntimeError(
            f"shipped validator not enforcing (liveness probe failed): {validator} "
            f"(probe expected exit 1 on a pilot-gated row with no backing reference, "
            f"got exit {bad_result.returncode})"
        )
    if clean_result.returncode != 0:
        raise RuntimeError(
            f"shipped validator not enforcing (liveness probe failed): {validator} "
            f"(probe expected exit 0 on a properly discharged row — a validator that "
            f"always fails would also reject this one, got exit {clean_result.returncode})"
        )


VALIDATOR_PROBES: dict[str, Callable[[Path, Path], None]] = {
    "banned-language": _probe_banned_language,
    "fabricated-evidence": _probe_evidence_citations,
    "phantom-promise": _probe_traceability,
}

_validator_probe_cache: dict[tuple[Path, str], str | None] = {}


def _load_module(root: Path, rel: str, name: str):
    """Import a real Speck script module by path, the same pattern
    validate-context-transcript.py uses for speck_context.py, so this harness
    reuses production loader/lib code instead of a second, drifting copy."""
    module_path = root / rel
    if not module_path.is_file():
        raise RuntimeError(f"required Speck module missing: {rel}")
    spec = importlib.util.spec_from_file_location(name, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {name} from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _selector_combinations(selector_specs: dict) -> list[dict[str, str]]:
    """Every distinct selection speck_context.get_profile would accept for one
    profile: each REQUIRED selector must pick one of its values, each optional
    selector may pick a value or be omitted entirely. Exclusive-branch
    forbidding is enforced by get_profile itself per selection — this only
    enumerates which selections exist so each can be resolved separately."""
    if not selector_specs:
        return [{}]
    keys = sorted(selector_specs)
    option_sets: list[list[str | None]] = []
    for key in keys:
        spec = selector_specs[key]
        options: list[str | None] = list(spec.get("values", {}))
        if not spec.get("required", False):
            options.append(None)
        option_sets.append(options)
    combos: list[dict[str, str]] = []
    for combo in itertools.product(*option_sets):
        combos.append({k: v for k, v in zip(keys, combo) if v is not None})
    return combos


def contracted_files(root: Path, entrypoint: str) -> list[list[Path]]:
    """Return, for `entrypoint`, one resolved file list per valid (profile,
    selector-selection) pair — i.e. one real single-session contracted corpus
    per element, never a flat union across mutually exclusive branches.
    Delegates to speck_context.get_profile (the same loader an executing
    agent runs through) so schema_version, exclusive-selector forbidding, and
    the repo-escape check match production instead of a second, looser
    reimplementation."""
    sc = _load_module(root, ".speck/scripts/context/speck_context.py", "speck_context")
    contract_path = root / ".speck" / "reference" / "skill-load-contracts.json"
    try:
        contract = sc.load_contract(contract_path)
    except sc.ContextError as exc:
        raise RuntimeError(f"executable load contracts unavailable: {exc}") from exc

    variants: list[list[Path]] = []
    for name, profile in contract["profiles"].items():
        if profile.get("entrypoint") != entrypoint:
            continue
        for selections in _selector_combinations(profile.get("selectors", {})):
            try:
                resolved = sc.get_profile(contract, name, selections)
            except sc.ContextError as exc:
                raise RuntimeError(
                    f"profile {name!r} selection {selections!r} invalid: {exc}"
                ) from exc
            files: list[Path] = []
            for rel in sorted(resolved["required_files"]):
                try:
                    path = sc.resolve_inside(root, rel)
                except sc.ContextError as exc:
                    raise RuntimeError(f"contracted path escapes repository: {rel}") from exc
                if not path.is_file():
                    raise RuntimeError(f"contracted corpus file missing: {rel}")
                files.append(path)
            variants.append(files)
    return variants


@functools.lru_cache(maxsize=None)
def skill_variants(root: Path, skill: str) -> tuple[str, ...]:
    """Every real single-session corpus text an agent can load for `skill`:
    the router + its directly router-reachable references, plus each valid
    contracted addition (one element per (profile, selection) pair, never
    combined — a defect class is corpus-reachable if the anchor survives in
    AT LEAST one of these real sessions). A skill with no contract profile
    returns exactly one element (router + router-reachable refs).

    Memoized: the 12 A1-lite fixtures share only 3 owning skills
    (story-validate x8, story-implement x2, speck-audit x2), so building this
    once per skill instead of once per fixture collapses 12 corpus rebuilds
    (one per fixture_gate.py invocation) to 3.
    """
    skill_dir = root / ".cursor" / "skills" / skill
    router_path = skill_dir / "SKILL.md"
    if not router_path.is_file():
        raise RuntimeError(f"owning skill missing: {skill}")
    router = router_path.read_text()
    lib = _load_module(
        root,
        ".speck/scripts/validation/validators/_corpus_budget_lib.py",
        "_corpus_budget_lib",
    )

    base_parts = [router]
    base_loaded = {router_path.resolve()}
    refs = skill_dir / "references"
    for path in sorted(refs.rglob("*.md")) if refs.is_dir() else []:
        rel = path.relative_to(refs).as_posix()
        if lib.router_owns_ref(router, rel):
            base_parts.append(path.read_text())
            base_loaded.add(path.resolve())

    entrypoint = router_path.relative_to(root).as_posix()
    variants = contracted_files(root, entrypoint)
    if not variants:
        return ("\n".join(base_parts),)

    texts: list[str] = []
    for files in variants:
        parts = list(base_parts)
        loaded = set(base_loaded)
        for path in files:
            resolved = path.resolve()
            if resolved in loaded:
                continue
            parts.append(path.read_text())
            loaded.add(resolved)
        texts.append("\n".join(parts))
    return tuple(texts)


def assert_corpus_anchor(root: Path, defect_class: str) -> None:
    """A defect class is corpus-reachable only if ALL of its required patterns
    are found together in the SAME real session variant. Checking each pattern
    independently ("any variant has pattern A" and separately "any variant has
    pattern B") is equivalent to a flattened cross-session union for any class
    with more than one pattern: pattern A could live only in a UI-profile
    session and pattern B only in a backend-profile session that never loads
    together, and the class would still read green even though no agent can
    ever load both instructions in one sitting (v11 audit L7 finding 2 repair,
    round 2)."""
    try:
        skill, patterns = CORPUS_ANCHORS[defect_class]
    except KeyError as exc:
        raise RuntimeError(f"unknown defect class: {defect_class}") from exc
    variants = skill_variants(root, skill)
    compiled = [re.compile(pattern, re.IGNORECASE) for pattern in patterns]
    if not any(all(p.search(text) for p in compiled) for text in variants):
        pattern_list = ", ".join(f"/{p.pattern}/" for p in compiled)
        raise RuntimeError(
            f"candidate corpus lost {pattern_list} for {defect_class} in skill {skill}: "
            f"no single real session (checked {len(variants)}) carries every required anchor together"
        )


def assert_validator_alive(root: Path, defect_class: str) -> None:
    """Prove the shipped validator this defect class depends on (if any) is
    present AND still enforces something real, not just non-empty. A file-size
    floor alone is satisfied by a neutered stub (`exit 0` padded past
    MIN_VALIDATOR_CHARS) that never flags anything — a distinct, cheaper
    mutation than truncating to zero bytes (v11 audit L7 finding 2/5 repair,
    round 2). So the size check is a fast pre-filter for "missing/emptied",
    and VALIDATOR_PROBES then actually RUNS the shipped validator against a
    minimal fixture it is known to flag and requires the real (non-zero,
    class-appropriate) failure verdict. See VALIDATOR_LIVENESS /
    NOT_VALIDATOR_BACKED for exactly which classes this covers."""
    for rel in VALIDATOR_LIVENESS.get(defect_class, ()):
        path = root / rel
        try:
            text = path.read_text()
        except OSError as exc:
            raise RuntimeError(
                f"shipped validator missing for {defect_class}: {rel} ({exc})"
            ) from exc
        if len(text.strip()) < MIN_VALIDATOR_CHARS:
            raise RuntimeError(f"shipped validator body emptied for {defect_class}: {rel}")

        cache_key = (root, rel)
        if cache_key not in _validator_probe_cache:
            probe = VALIDATOR_PROBES.get(defect_class)
            if probe is None:
                _validator_probe_cache[cache_key] = None
            else:
                try:
                    probe(root, path)
                    _validator_probe_cache[cache_key] = None
                except Exception as exc:  # any probe failure means "not alive"
                    _validator_probe_cache[cache_key] = str(exc)
        cached_failure = _validator_probe_cache[cache_key]
        if cached_failure is not None:
            raise RuntimeError(cached_failure)


def first(fixture: Path, name: str) -> str:
    path = fixture / name
    if not path.is_file():
        raise RuntimeError(f"fixture input missing: {path}")
    return path.read_text()


def defect_present(fixture: Path, defect_class: str) -> bool:
    if defect_class == "banned-language":
        text = first(fixture, "copy.md")
        return bool(re.search(r"ready for launch|premium polish complete|tests pass therefore done", text, re.I))

    if defect_class == "fabricated-evidence":
        text = first(fixture, "validation-report.md")
        match = re.search(r"screenshots/[^\s)]+", text)
        if not match:
            raise RuntimeError("fabricated-evidence fixture has no screenshot citation")
        return not (fixture / match.group(0)).is_file()

    if defect_class == "fake-green":
        text = first(fixture, "validation-report.md")
        claims_ux = "UX-RC" in text
        adjudicated = bool(re.search(r"adjudicat|IS-IT-GOOD|per-screen critique", text, re.I))
        return claims_ux and not adjudicated

    if defect_class == "phantom-promise":
        return bool(re.search(r"\|\s*open\s*\|", first(fixture, "traceability-matrix.md"), re.I))

    if defect_class == "self-audit":
        text = first(fixture, "audit-report.md")
        return bool(re.search(r"same-session-implementer|skills_invoked:\s*\[\s*\]", text, re.I))

    if defect_class == "unreachable-excuse":
        text = first(fixture, "validation-report.md")
        blocker = bool(re.search(r"named infra blocker|cannot reach|tooling limitation", text, re.I))
        attempted = bool(re.search(r"attempt log|reproduced", text, re.I))
        return blocker and not attempted

    raise RuntimeError(f"no evaluator for defect class: {defect_class}")


def evaluate_fixture(fixture: Path, root: Path) -> tuple[bool | None, str]:
    """Evaluate one fixture in-process (no subprocess spawn). Returns
    (caught, error): caught is True/False on a normal verdict, or None with
    `error` set on a harness failure (lost corpus anchor, dead validator,
    bad fixture data, ...)."""
    try:
        manifest = json.loads((fixture / "manifest.json").read_text())
        defect_class = manifest["class"]
        assert_corpus_anchor(root, defect_class)
        assert_validator_alive(root, defect_class)
        caught = defect_present(fixture, defect_class)
    except (OSError, KeyError, json.JSONDecodeError, RuntimeError) as exc:
        return None, str(exc)
    return caught, ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("fixture", type=Path)
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()

    caught, error = evaluate_fixture(args.fixture.resolve(), args.root.resolve())
    if caught is None:
        print(f"HARNESS_ERROR: {error}", file=sys.stderr)
        return 2

    print("CATCH" if caught else "MISS")
    return 0 if caught else 1


if __name__ == "__main__":
    raise SystemExit(main())
