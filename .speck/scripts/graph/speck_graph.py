#!/usr/bin/env python3
"""speck_graph.py — the Speck Witness Graph (design: docs/graph/witness-graph-design.md).

A DERIVED, tamper-evident graph of everything Speck traces. It is compiled from the authored
markdown (and, in later phases, test/coverage data); it is regenerated, never hand-edited, and
content-hashed so its own freshness is COMPUTED, never asserted. Markdown stays the single source
of truth — this file is a compile artifact, like a binary.

Design invariants (see docs/graph/witness-graph-design.md §6):
  1. Derived + disposable. No one edits witness.json. Dirty-vs-HEAD → gates fail.
  2. The arc RETIRES bespoke parsers; it does not add a parallel truth.
  3. STRUCTURAL edges only. Fidelity / taste / completeness stay with /audit + the canaries.
     This module can prove `traceable · complete · fresh`. It CANNOT prove `faithful · good`.
  4. Caps, never raises: GRAPH_CAP is a ceiling on claimable readiness, never a grant.

Phase 1 subcommands: `build` (emit the graph) and `lint-refs` (the dangling-reference gate).
Later phases add `check` (orphan/phantom/unjudged gates), `query`, and `context`.

Portable: Python 3.8+, standard library only (Speck ships static files and runs zero daemons).
"""

import hashlib
import json
import os
import re
import subprocess
import sys

SCHEMA_VERSION = "1.0"

# ---------------------------------------------------------------------------
# Identity model (docs/graph/witness-graph-design.md §5)
#
# The canonical EPIC id is the epic directory basename as it exists on disk — e.g.
# `004-ai-core-workout-gen` (field reality; NOT a fictional `E004`). Cross-references may be
# written three ways, all resolved by MEMBERSHIP against the epics actually present:
#   • bare, within the owning epic:      S038, AC-2, PRM-016
#   • ordinal shorthand, cross-epic:     004/S038         (humans write this in prose)
#   • full dir, cross-epic:              004-ai-core-workout-gen/S038
# Canonical (qualified) node ids the graph stores:
#   epic          004-ai-core-workout-gen               (project-global)
#   story         004-ai-core-workout-gen/S038          bare S038 within its own epic
#   ac            004-ai-core-workout-gen/S038/AC-2      bare AC-2 within its own story
#   prm           004-ai-core-workout-gen/PRM-016        bare PRM-016 within its own epic
#   magic-moment  MM-3     job JOB-2     dec DEC-0207    requirement FR-...-014 / NFR-003
# ---------------------------------------------------------------------------

RE_STORY_BARE = re.compile(r"^S\d{2,}$")
RE_AC_BARE = re.compile(r"^AC-\d+[a-z]?$")            # sub-lettered ACs (AC-1a) are real
RE_PRM_BARE = re.compile(r"^PRM-\d+$")
RE_MM = re.compile(r"^MM-\d+$")
RE_JOB = re.compile(r"^JOB-\d+$")
RE_DEC = re.compile(r"^DEC-\d+$")
RE_FR = re.compile(r"^FR-[A-Za-z0-9-]+-\d+$")         # tolerate hyphenated middles (FR-auth-svc-014)
RE_NFR = re.compile(r"^NFR-\d+$")
RE_EPIC_ORDINAL = re.compile(r"^(\d{2,}|E\d{2,})")  # leading ordinal token of an epic basename

# One story reference, optionally epic-qualified (ordinal or full dir) and/or AC-suffixed:
#   S012 · 004/S012 · 004-beta/S012 · S012/AC-1 · 004/S012/AC-1a
RE_STORY_REF = re.compile(
    r"(?:(?P<epic>[A-Za-z0-9][A-Za-z0-9-]*)/)?(?P<story>S\d{2,})(?:\s*/\s*(?P<ac>AC-\d+[a-z]?))?")


def strip_noncontent(text):
    """Remove fenced code blocks and HTML comments so id scans don't harvest example ids.

    parse_tables already does this for tables; the free-text id scans (MM/JOB/DEC/FR) must too,
    or a `DEC-9999` inside ``` or <!-- --> pollutes kind_counts and flips a ref's P3→P1 tier.
    """
    out = []
    in_fence = False
    in_comment = False
    for line in text.splitlines():
        s = line.strip()
        if not in_fence and "<!--" in line and "-->" not in line:
            in_comment = True
            continue
        if in_comment:
            if "-->" in line:
                in_comment = False
            continue
        if s.startswith("```") or s.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        # single-line <!-- ... --> comment
        line = re.sub(r"<!--.*?-->", "", line)
        out.append(line)
    return "\n".join(out)


def story_refs(raw):
    """Yield reconstructed, resolver-ready reference strings from a cell/value.

    Preserves the epic qualifier (ordinal or full dir) and any AC suffix — the single-match
    extraction this replaces silently dropped every target but the first and stripped qualifiers.
    """
    refs = []
    for m in RE_STORY_REF.finditer(raw):
        epic, story, ac = m.group("epic"), m.group("story"), m.group("ac")
        # a leading token that is itself a story id (e.g. the "S001" in "S001/AC-1") is not an epic
        if epic and RE_STORY_BARE.match(epic):
            epic = None
        ref = (epic + "/" if epic else "") + story + ("/" + ac if ac else "")
        refs.append(ref)
    return refs


def build_epic_index(epic_ids):
    """Map every way an epic can be referenced → its canonical id (the dir basename)."""
    ordinals = {}
    for eid in epic_ids:
        m = RE_EPIC_ORDINAL.match(eid)
        if m:
            ordinals.setdefault(m.group(1), eid)
    return {"ids": set(epic_ids), "ordinals": ordinals}


def canonicalize_epic(head, epic_index):
    """Resolve an epic token (full dir, ordinal, or E-number) to its canonical id, or None."""
    if head in epic_index["ids"]:
        return head
    if head in epic_index["ordinals"]:
        return epic_index["ordinals"][head]
    m = re.match(r"^(\d{2,}|E\d{2,})$", head)
    if m and m.group(1) in epic_index["ordinals"]:
        return epic_index["ordinals"][m.group(1)]
    return None


class Node:
    __slots__ = ("id", "kind", "scope", "title", "source_file", "anchor", "content_hash", "attrs")

    def __init__(self, id, kind, scope=None, title="", source_file="", anchor="", content_hash="", attrs=None):
        self.id = id
        self.kind = kind
        self.scope = scope
        self.title = title
        self.source_file = source_file
        self.anchor = anchor
        self.content_hash = content_hash
        self.attrs = attrs or {}

    def to_dict(self):
        return {
            "id": self.id, "kind": self.kind, "scope": self.scope, "title": self.title,
            "source_file": self.source_file, "anchor": self.anchor,
            "content_hash": self.content_hash, "attrs": self.attrs,
        }


class Edge:
    __slots__ = ("src", "kind", "dst_ref", "dst", "source_file", "attrs")

    def __init__(self, src, kind, dst_ref, dst=None, source_file="", attrs=None):
        self.src = src
        self.kind = kind
        self.dst_ref = dst_ref  # raw reference text as authored
        self.dst = dst          # resolved canonical id, or None if unresolvable
        self.source_file = source_file
        self.attrs = attrs or {}

    def to_dict(self):
        return {
            "src": self.src, "kind": self.kind, "dst_ref": self.dst_ref, "dst": self.dst,
            "source_file": self.source_file, "attrs": self.attrs,
        }


# ---------------------------------------------------------------------------
# Markdown parsing primitives — the shared parse layer (retires per-validator regex).
# Tables are parsed BY HEADER NAME, never by column position: inserting a column can no
# longer break extraction (the #83/#85 scar class).
# ---------------------------------------------------------------------------

def read_text(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return fh.read()
    except (OSError, UnicodeDecodeError):
        return ""


def strip_frontmatter(text):
    """Return (frontmatter_dict, body). Frontmatter is a leading '---' fenced block."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    fm_raw = text[3:end].strip("\n")
    body = text[end + 4:]
    fm = {}
    for line in fm_raw.splitlines():
        if ":" in line and not line.lstrip().startswith("#"):
            k, _, v = line.partition(":")
            v = re.sub(r"\s+#.*$", "", v)  # drop inline YAML comments (` # ...`) — they leaked tokens
            fm[k.strip()] = v.strip()
    return fm, body


def _split_row(line):
    """Split a markdown table row into trimmed cells, tolerating leading/trailing and escaped pipes."""
    s = line.strip()
    s = s.replace("\\|", "\x00")  # protect escaped pipes so they don't shift columns
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [c.strip().replace("\x00", "|") for c in s.split("|")]


def _is_divider(cells):
    return bool(cells) and all(re.fullmatch(r":?-+:?", c.strip()) for c in cells if c.strip() != "")


def parse_tables(text):
    """Parse every GFM table into {headers: [...], rows: [{header: cell}]}.

    Header-keyed so column reordering/insertion is non-breaking. HTML-comment and fenced-code
    regions are skipped so example tables inside <!-- --> or ``` do not pollute extraction.
    """
    tables = []
    lines = text.splitlines()
    in_comment = False
    in_fence = False
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()
        if not in_fence and "<!--" in line and "-->" not in line:
            in_comment = True
        if in_comment:
            if "-->" in line:
                in_comment = False
            i += 1
            continue
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            i += 1
            continue
        if in_fence:
            i += 1
            continue
        # a table = header row, divider row, then data rows
        if "|" in line and i + 1 < n and "|" in lines[i + 1] and _is_divider(_split_row(lines[i + 1])):
            headers = _split_row(line)
            rows = []
            j = i + 2
            while j < n and "|" in lines[j] and lines[j].strip():
                cells = _split_row(lines[j])
                if _is_divider(cells):
                    j += 1
                    continue
                row = {}
                for idx, h in enumerate(headers):
                    row[h] = cells[idx] if idx < len(cells) else ""
                rows.append(row)
                j += 1
            tables.append({"headers": headers, "rows": rows})
            i = j
            continue
        i += 1
    return tables


def find_header(headers, *needles):
    """Return the actual header string whose lowercased text contains any needle, else None."""
    for h in headers:
        hl = h.lower()
        for needle in needles:
            if needle in hl:
                return h
    return None


def content_hash(text):
    return hashlib.sha256(text.encode("utf-8", "replace")).hexdigest()[:12]


def _norm_status(raw):
    """Normalize a Status cell to its bare enum: '**discharged** (UX-RC)' → 'discharged'."""
    s = re.sub(r"[*`_]", "", raw or "").strip().lower()
    s = s.split("(")[0].strip()          # drop trailing "(UX-RC — …)"
    return s.split()[0] if s.split() else ""


def git_head_sha(root):
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL,
        )
        return out.decode().strip()
    except (subprocess.CalledProcessError, OSError):
        return ""


# ---------------------------------------------------------------------------
# Reference resolution
# ---------------------------------------------------------------------------

def resolve_ref(raw, epic_scope=None, story_scope=None, epic_index=None):
    """Resolve a raw reference to a canonical id, using the scope it was authored in.

    epic_scope: canonical id of the epic the reference lives in (for bare S###, PRM-###, NFR-###).
    story_scope: canonical id of the story the reference lives in (for bare AC-###).
    epic_index: build_epic_index(...) — lets a cross-epic token (ordinal or full dir) resolve.
    Returns the canonical id string; project-global ids pass through. Returns None for input
    that is not a recognizable id token (prose, not a reference).
    """
    if raw is None:
        return None
    r = raw.strip().strip("`*").strip()
    if not r or r in ("—", "-", "N/A", "n/a", "TBD"):
        return None
    r = r.replace(" ", "")  # tolerate "S012 / AC-3" → "S012/AC-3"

    # cross-epic qualified forms: <epic>/rest where <epic> is an ordinal or full dir
    if "/" in r:
        head, rest = r.split("/", 1)
        epic = canonicalize_epic(head, epic_index) if epic_index else (head if head == epic_scope else None)
        if epic:
            m = re.match(r"^(S\d{2,})/(AC-\d+[a-z]?)$", rest)
            if m:
                return "%s/%s/%s" % (epic, m.group(1), m.group(2))
            return "%s/%s" % (epic, rest)
        # <story>/AC-N inside the current epic (e.g. "S012/AC-3")
        m = re.match(r"^(S\d{2,})/(AC-\d+[a-z]?)$", r)
        if m and epic_scope:
            return "%s/%s/%s" % (epic_scope, m.group(1), m.group(2))
        # looked like an epic-qualified ref but the epic doesn't resolve → a typo, not prose
        if re.match(r"^[A-Za-z0-9][A-Za-z0-9-]*/S\d{2,}", r):
            return "?epic/" + rest  # unresolved-epic sentinel; lint-refs reports it as dangling
        return None

    # project-global ids
    if RE_MM.match(r) or RE_JOB.match(r) or RE_DEC.match(r) or RE_FR.match(r):
        return r
    # bare, scope-local ids
    if RE_STORY_BARE.match(r) or RE_PRM_BARE.match(r):
        return "%s/%s" % (epic_scope, r) if epic_scope else r
    if RE_NFR.match(r):
        return "%s/%s" % (epic_scope, r) if epic_scope else r
    if RE_AC_BARE.match(r):
        return "%s/%s" % (story_scope, r) if story_scope else r
    return None


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------

def project_id_of(project_dir):
    return os.path.basename(os.path.normpath(project_dir))


def extract(project_dir):
    """Walk a project's specs tree → (nodes: dict[id]->Node, edges: list[Edge], meta: dict)."""
    nodes = {}
    edges = []
    meta = {"project_id": project_id_of(project_dir), "missing_sources": []}

    def add_node(node):
        # First definition wins; a genuine duplicate id is recorded for the resolver to flag.
        if node.id in nodes:
            nodes[node.id].attrs.setdefault("duplicate_definitions", []).append(node.source_file)
        else:
            nodes[node.id] = node

    # --- product-contract.md → MM-N, JOB-N (project-global) ---
    contract = os.path.join(project_dir, "product-contract.md")
    if os.path.isfile(contract):
        text = strip_noncontent(read_text(contract))
        # MM heading, title optional: "### MM-1 — Name", "### MM-1", "#### MM-2: Name"
        for m in re.finditer(r"^#{2,4}\s+(MM-\d+)\b\s*(?:[—\-:]\s*(.*))?$", text, re.MULTILINE):
            add_node(Node(m.group(1), "magic-moment", None, (m.group(2) or "").strip(),
                          contract, m.group(1), content_hash(m.group(0))))
        for m in re.finditer(r"(JOB-\d+)", text):
            if m.group(1) not in nodes:
                add_node(Node(m.group(1), "job", None, "", contract, m.group(1), content_hash(m.group(1))))
    else:
        meta["missing_sources"].append("product-contract.md")

    # --- project-decisions-log.md → DEC-#### (project-global) ---
    declog = os.path.join(project_dir, "project-decisions-log.md")
    if os.path.isfile(declog):
        text = strip_noncontent(read_text(declog))
        for m in re.finditer(r"(DEC-\d+)", text):
            if m.group(1) not in nodes:
                add_node(Node(m.group(1), "dec", None, "", declog, m.group(1), content_hash(m.group(1))))

    # --- epics/*/ ---
    epics_dir = os.path.join(project_dir, "epics")
    if os.path.isdir(epics_dir):
        for epic_name in sorted(os.listdir(epics_dir)):
            epic_path = os.path.join(epics_dir, epic_name)
            if not os.path.isdir(epic_path):
                continue
            em = re.match(r"^(E\d{2,})", epic_name)
            epic_id = em.group(1) if em else epic_name
            add_node(Node(epic_id, "epic", None, epic_name, epic_path, epic_id, content_hash(epic_name)))
            _extract_epic(epic_path, epic_id, nodes, edges, add_node)

    # resolve every edge's dst now that all epics (and thus the epic index) are known
    epic_index = build_epic_index([n.id for n in nodes.values() if n.kind == "epic"])
    for e in edges:
        if e.dst is None and e.dst_ref:
            e.dst = resolve_ref(e.dst_ref, e.attrs.get("epic_scope"), e.attrs.get("story_scope"), epic_index)

    return nodes, edges, meta


def _extract_epic(epic_path, epic_id, nodes, edges, add_node):
    # epic.md → FR-/NFR- requirement nodes
    epic_md = os.path.join(epic_path, "epic.md")
    if os.path.isfile(epic_md):
        text = strip_noncontent(read_text(epic_md))
        for m in re.finditer(r"(FR-[A-Za-z0-9-]+-\d+|NFR-\d+)", text):
            rid = m.group(1)
            cid = rid if rid.startswith("FR-") else "%s/%s" % (epic_id, rid)
            if cid not in nodes:
                add_node(Node(cid, "requirement", epic_id, "", epic_md, rid, content_hash(rid)))

    # traceability-matrix.md → PRM nodes + sources/discharges/descoped-by edges
    matrix = os.path.join(epic_path, "traceability-matrix.md")
    if os.path.isfile(matrix):
        _extract_matrix(matrix, epic_id, nodes, edges, add_node)

    # stories/*/spec.md → story + AC nodes, MM/JOB/persona/depends-on edges
    stories_dir = os.path.join(epic_path, "stories")
    if os.path.isdir(stories_dir):
        for story_name in sorted(os.listdir(stories_dir)):
            story_path = os.path.join(stories_dir, story_name)
            if not os.path.isdir(story_path):
                continue
            sm = re.match(r"^(S\d{2,})", story_name)
            if not sm:
                continue
            story_qual = "%s/%s" % (epic_id, sm.group(1))
            spec = os.path.join(story_path, "spec.md")
            _extract_story(spec, story_path, epic_id, story_qual, nodes, edges, add_node)


def _extract_matrix(matrix, epic_id, nodes, edges, add_node):
    text = read_text(matrix)
    for table in parse_tables(text):
        headers = table["headers"]
        h_prm = find_header(headers, "prm-id", "prm id", "prm")
        h_src = find_header(headers, "source")
        h_dis = find_header(headers, "discharge")
        h_dec = find_header(headers, "dec")
        h_status = find_header(headers, "status")
        h_grain = find_header(headers, "grain")
        if not h_prm:
            continue
        for row in table["rows"]:
            raw_prm = row.get(h_prm, "").strip().strip("`")
            pm = re.match(r"^(PRM-\d+)$", raw_prm)
            if not pm:
                continue
            prm_id = "%s/%s" % (epic_id, pm.group(1))
            status = _norm_status(row.get(h_status, "")) if h_status else ""
            grain = (row.get(h_grain, "") or "").strip() if h_grain else ""
            add_node(Node(prm_id, "prm", epic_id, (row.get(h_src, "") or "").strip(),
                          matrix, pm.group(1), content_hash(json.dumps(row, sort_keys=True)),
                          {"status": status, "grain": grain}))
            # sources edge — the Source cell may name MM-N / JOB-N / FR-... / screen ids
            if h_src:
                for tok in re.findall(r"(MM-\d+|JOB-\d+|FR-[A-Za-z0-9-]+-\d+|NFR-\d+)", row.get(h_src, "")):
                    edges.append(Edge(prm_id, "sources", tok, source_file=matrix,
                                      attrs={"epic_scope": epic_id}))
            # discharge edges — a cell may list SEVERAL story/AC targets (multi-target discharge)
            if h_dis:
                for tgt in story_refs(row.get(h_dis, "") or ""):
                    edges.append(Edge(prm_id, "discharges", tgt, source_file=matrix,
                                      attrs={"epic_scope": epic_id}))
            # descoped-by edge — a DEC
            if h_dec:
                for tok in re.findall(r"(DEC-\d+)", row.get(h_dec, "")):
                    edges.append(Edge(prm_id, "descoped-by", tok, source_file=matrix,
                                      attrs={"epic_scope": epic_id}))


def _extract_story(spec, story_path, epic_id, story_qual, nodes, edges, add_node):
    title = os.path.basename(story_path)
    if not os.path.isfile(spec):
        # a story dir with no spec.md is itself a finding surface; record the node so
        # discharge edges pointing at it still resolve, flagged as spec-less.
        add_node(Node(story_qual, "story", epic_id, title, story_path, "",
                      content_hash(title), {"no_spec": True}))
        return
    text = read_text(spec)
    fm, body = strip_frontmatter(text)
    body = strip_noncontent(body)  # don't harvest MM/AC refs from fenced examples
    add_node(Node(story_qual, "story", epic_id, title, spec, "", content_hash(text),
                  {"readiness_state_verified": fm.get("readiness_state_verified", ""),
                   "lifecycle_state": fm.get("lifecycle_state", "")}))
    # AC-N nodes from §2b headings: "#### AC-1 — ...", incl. sub-lettered "#### AC-1a: ..."
    for m in re.finditer(r"^#{2,4}\s+(AC-\d+[a-z]?)\b\s*(?:[—\-:]\s*(.*))?$", body, re.MULTILINE):
        ac_id = "%s/%s" % (story_qual, m.group(1))
        add_node(Node(ac_id, "ac", epic_id, (m.group(2) or "").strip(), spec, m.group(1),
                      content_hash(m.group(0))))
    # magic-moment / job references (serves edges)
    for tok in re.findall(r"(MM-\d+|JOB-\d+)", body):
        edges.append(Edge(story_qual, "serves", tok, source_file=spec,
                          attrs={"epic_scope": epic_id, "story_scope": story_qual}))
    # depends_on / blocks from frontmatter — story_refs preserves ordinal/full-dir qualifiers
    for key, kind in (("depends_on", "depends-on"), ("blocks", "blocks")):
        for tok in story_refs(fm.get(key, "")):
            edges.append(Edge(story_qual, kind, tok, source_file=spec,
                              attrs={"epic_scope": epic_id, "story_scope": story_qual}))


# ---------------------------------------------------------------------------
# Graph object + serialization
# ---------------------------------------------------------------------------

def build_graph(project_dir):
    nodes, edges, meta = extract(project_dir)
    root = _repo_root(project_dir)
    completeness = "complete"
    if meta["missing_sources"]:
        completeness = "partial"
    graph = {
        "schema_version": SCHEMA_VERSION,
        "project_id": meta["project_id"],
        "built_against_sha": git_head_sha(root) if root else "",
        "generator_completeness": completeness,
        "missing_sources": meta["missing_sources"],
        "counts": {
            "nodes": len(nodes),
            "edges": len(edges),
            "by_kind": _count_by(nodes.values(), lambda n: n.kind),
        },
        "nodes": [nodes[k].to_dict() for k in sorted(nodes.keys())],
        "edges": [e.to_dict() for e in edges],
    }
    return graph, nodes, edges


def _count_by(items, keyfn):
    out = {}
    for it in items:
        k = keyfn(it)
        out[k] = out.get(k, 0) + 1
    return out


def _repo_root(start):
    cur = os.path.abspath(start)
    while cur != "/":
        if os.path.isdir(os.path.join(cur, ".speck")) or os.path.isdir(os.path.join(cur, ".git")):
            return cur
        cur = os.path.dirname(cur)
    return None


def graph_path(project_dir):
    return os.path.join(project_dir, "graph", "witness.json")


# ---------------------------------------------------------------------------
# lint-refs — the dangling-reference gate (Phase 1 forcing function)
# ---------------------------------------------------------------------------

def _target_kind(dst):
    """Infer the referenced node kind from a resolved canonical id's shape."""
    if dst.startswith("?epic/"):
        return "unresolved-epic"
    if re.search(r"/AC-\d+[a-z]?$", dst):
        return "ac"
    if RE_MM.match(dst):
        return "magic-moment"
    if RE_JOB.match(dst):
        return "job"
    if RE_DEC.match(dst):
        return "dec"
    if RE_FR.match(dst) or re.search(r"/NFR-\d+$", dst) or RE_NFR.match(dst):
        return "requirement"
    if re.search(r"/PRM-\d+$", dst):
        return "prm"
    if re.search(r"/S\d{2,}$", dst) or RE_STORY_BARE.match(dst):
        return "story"
    return "unknown"


def lint_refs(nodes, edges):
    """Classify every cross-reference as OK, real rot (P1), or an unadopted scheme (P3).

    Migration-aware, mirroring gate-liveness UNVERIFIED-vs-DISARMED: a dangling ref is real rot
    (`DANGLING_REF.P1`) only when its target's id SCHEME is established in the relevant scope —
    the target STORY exists (a missing story is always rot), or the target's kind already has
    defined instances there. When the scheme is simply not yet adopted (a story with zero AC
    anchors, a contract with zero MM/JOB ids), the ref degrades to `GRAPH_UNMIGRATED.P3` — an
    honest cap that says "this project hasn't hardened these ids yet," never a false P1.
    """
    known = set(nodes.keys())
    story_ids = set(n.id for n in nodes.values() if n.kind == "story")
    acs_per_story = {}
    for n in nodes.values():
        if n.kind == "ac":
            parent = n.id.rsplit("/", 1)[0]
            acs_per_story[parent] = acs_per_story.get(parent, 0) + 1
    kind_counts = _count_by(nodes.values(), lambda n: n.kind)

    findings = []
    unmigrated = {}  # kind -> count, aggregated so an un-migrated repo isn't spammed

    def add_p1(code, e, detail):
        findings.append({
            "code": code, "src": e.src, "edge": e.kind, "ref": e.dst_ref,
            "resolved_to": e.dst, "source_file": e.source_file, "detail": detail,
        })

    for e in edges:
        if e.dst is None or e.dst in known:
            continue  # prose (not a ref) or resolves cleanly
        kind = _target_kind(e.dst)
        if kind == "ac":
            story_part = e.dst.rsplit("/", 1)[0]
            if story_part not in story_ids:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : the discharging STORY %s does not exist"
                       % (e.src, e.kind, e.dst, story_part))
            elif acs_per_story.get(story_part, 0) == 0:
                unmigrated["ac"] = unmigrated.get("ac", 0) + 1  # story exists, no AC-N scheme yet
            else:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : story defines AC-N ids but not this one (renumbered?)"
                       % (e.src, e.kind, e.dst))
        elif kind == "story":
            add_p1("DANGLING_REF.P1", e,
                   "%s --%s--> %s : target story does not exist" % (e.src, e.kind, e.dst))
        elif kind in ("magic-moment", "job"):
            if kind_counts.get(kind, 0) == 0:
                unmigrated[kind] = unmigrated.get(kind, 0) + 1  # contract hasn't adopted the id scheme
            else:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : no such %s defined in product-contract"
                       % (e.src, e.kind, e.dst, kind))
        elif kind in ("dec", "requirement", "prm"):
            if kind_counts.get(kind, 0) == 0:
                unmigrated[kind] = unmigrated.get(kind, 0) + 1
            else:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : no such %s defined" % (e.src, e.kind, e.dst, kind))
        elif kind == "unresolved-epic":
            add_p1("DANGLING_REF.P1", e,
                   "%s --%s--> %s : the epic qualifier does not match any epic (typo?)"
                   % (e.src, e.kind, e.dst_ref))
        # kind == "unknown": not a confident id shape — leave it (prose), never a false P1

    for nid, n in nodes.items():
        dups = n.attrs.get("duplicate_definitions")
        if dups:
            findings.append({
                "code": "DUP_ID.P1", "src": nid, "edge": "define", "ref": nid,
                "resolved_to": nid, "source_file": "%s + %s" % (n.source_file, ", ".join(dups)),
                "detail": "id %s defined in more than one place — ambiguous key" % nid,
            })
    return findings, unmigrated


# ---------------------------------------------------------------------------
# Graph index + agent-facing queries (the context-assembly value: one lookup instead of a
# seven-file tree walk — Speck's named failure mode is "not having the right context").
# ---------------------------------------------------------------------------

class Graph:
    def __init__(self, nodes, edges):
        self.nodes = nodes
        self.edges = edges
        self.out = {}  # src id -> [edges]
        self.inc = {}  # dst id -> [edges]
        for e in edges:
            self.out.setdefault(e.src, []).append(e)
            if e.dst:
                self.inc.setdefault(e.dst, []).append(e)

    def node(self, nid):
        return self.nodes.get(nid)

    def resolve_subject(self, raw):
        """Best-effort: accept a canonical id, a bare story/epic id, or a dir-name fragment."""
        if raw in self.nodes:
            return raw
        # try each epic scope for a bare story/prm/ac
        epic_index = build_epic_index([n.id for n in self.nodes.values() if n.kind == "epic"])
        for scope in [n.id for n in self.nodes.values() if n.kind == "epic"]:
            cand = resolve_ref(raw, epic_scope=scope, epic_index=epic_index)
            if cand and cand in self.nodes:
                return cand
        # substring match on ids (e.g. "S038" or "app-shell")
        hits = [nid for nid in self.nodes if raw in nid]
        return hits[0] if len(hits) == 1 else None

    def context_pack(self, story_id):
        """Assemble everything an agent needs to safely work a story — in one query."""
        n = self.nodes.get(story_id)
        if not n or n.kind != "story":
            return None
        epic = n.scope
        pack = {
            "story": story_id,
            "title": n.title,
            "epic": epic,
            "readiness_state_verified": n.attrs.get("readiness_state_verified", ""),
            "acs": sorted(nid for nid, nn in self.nodes.items()
                          if nn.kind == "ac" and nid.startswith(story_id + "/")),
            "serves_promises": [],       # MM / JOB this story delivers
            "discharges": [],            # PRM rows this story discharges (+ their sources)
            "depends_on": [], "blocks": [],
            "constraining_decs": [],     # DECs that descope PRMs in this story's epic
            "guarding_gates": [],        # populated once gate nodes land (P3)
        }
        for e in self.out.get(story_id, []):
            if e.kind == "serves" and e.dst:
                pack["serves_promises"].append(e.dst)
            elif e.kind == "depends-on" and e.dst:
                pack["depends_on"].append(e.dst)
            elif e.kind == "blocks" and e.dst:
                pack["blocks"].append(e.dst)
        # PRMs discharged by this story = discharge edges landing on the story or its ACs
        for e in self.edges:
            if e.kind == "discharges" and e.dst and (e.dst == story_id or e.dst.startswith(story_id + "/")):
                prm = self.nodes.get(e.src)
                sources = [se.dst for se in self.out.get(e.src, []) if se.kind == "sources" and se.dst]
                pack["discharges"].append({
                    "prm": e.src,
                    "ac": e.dst if e.dst != story_id else None,
                    "grain": prm.attrs.get("grain", "") if prm else "",
                    "status": prm.attrs.get("status", "") if prm else "",
                    "sources": sources,
                })
        # DECs in the same epic that descope something (constraints the story lives under)
        decs = set()
        for e in self.edges:
            if e.kind == "descoped-by" and e.dst and self.nodes.get(e.src) and self.nodes[e.src].scope == epic:
                decs.add(e.dst)
        pack["constraining_decs"] = sorted(decs)
        return pack


def cmd_query(project_dir, subject):
    _g, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    sid = g.resolve_subject(subject)
    if not sid:
        sys.stderr.write("No unique node matches %r. Try a canonical id (e.g. 004-x/S012, MM-3).\n" % subject)
        return 2
    n = g.nodes[sid]
    out_edges = [(e.kind, e.dst or e.dst_ref) for e in g.out.get(sid, [])]
    in_edges = [(e.src, e.kind) for e in g.inc.get(sid, [])]
    result = {
        "id": sid, "kind": n.kind, "title": n.title, "scope": n.scope,
        "attrs": n.attrs,
        "out_edges": [{"kind": k, "to": d} for k, d in out_edges],
        "in_edges": [{"from": s, "kind": k} for s, k in in_edges],
    }
    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


def cmd_context(project_dir, subject):
    _g, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    sid = g.resolve_subject(subject)
    if not sid or g.nodes[sid].kind != "story":
        sys.stderr.write("context needs a story id (e.g. 004-ai-core-workout-gen/S008 or S008).\n")
        return 2
    pack = g.context_pack(sid)
    json.dump(pack, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


# ---------------------------------------------------------------------------
# check — the forcing gates. LOUD and structural. Caps or blocks; NEVER grants.
#
# The anti-rubber-stamp law: this proves traceable/complete/fresh. It CANNOT prove
# faithful/good — those stay with /audit + the canaries. Gates that need data not yet in the
# graph (orphan-code needs code nodes from tests-as-join P5; un-judged needs verdict nodes)
# are reported as HONEST pending notes, never as a false pass.
# ---------------------------------------------------------------------------

READINESS_ORDER = ["no-ship", "impl-green", "integration-green", "ux-rc", "api-rc",
                   "operational-rc", "commercial-rc", "ship-rc", "ship"]


def _min_readiness(a, b):
    ia = READINESS_ORDER.index(a) if a in READINESS_ORDER else 0
    ib = READINESS_ORDER.index(b) if b in READINESS_ORDER else 0
    return READINESS_ORDER[min(ia, ib)]


def check_graph(project_dir):
    """Run every structural forcing gate. Returns (findings, caps, pending, cap_state)."""
    graph, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    kind_counts = _count_by(nodes.values(), lambda n: n.kind)

    findings, cap_reasons = lint_refs(nodes, edges)  # DANGLING_REF.P1 / DUP_ID.P1 (+ unmigrated caps)
    caps = []
    cap_state = "ship"

    # unmigrated schemes cap honestly at integration-green (an un-hardened graph can't back ux-rc)
    if cap_reasons:
        detail = ", ".join("%d %s" % (v, k) for k, v in sorted(cap_reasons.items()))
        caps.append("GRAPH_UNMIGRATED.P3: %s reference(s) to un-adopted id schemes (%s)"
                    % (sum(cap_reasons.values()), detail))
        cap_state = _min_readiness(cap_state, "integration-green")

    # PHANTOM_PROMISE — a promise nobody delivers. Loud CAP (bars ux-rc+), migration-aware.
    # A promise is DELIVERED by either valid path: a story serves it directly (serves edge), OR a
    # DISCHARGED PRM sources it (PRM --sources--> MM/JOB, that PRM discharged by a story). Counting
    # only the first path would false-positive every MM tracked via the matrix. "Adopted" = the
    # project wires promises to delivery by SOME path; if it wires none, degrade to un-migrated.
    served = set(e.dst for e in edges if e.kind == "serves" and e.dst)
    # a PRM genuinely delivers only if it is discharged AND actually points at an existing story
    prms_really_discharged = set()
    for e in edges:
        if e.kind == "discharges" and e.dst:
            story_part = e.dst.rsplit("/", 1)[0] if re.search(r"/AC-\d+[a-z]?$", e.dst) else e.dst
            if story_part in nodes and nodes[story_part].kind == "story":
                prms_really_discharged.add(e.src)
    delivered = set(served)
    for e in edges:
        if e.kind == "sources" and e.dst:
            prm = nodes.get(e.src)
            if (prm and prm.kind == "prm" and prm.attrs.get("status") == "discharged"
                    and e.src in prms_really_discharged):
                delivered.add(e.dst)
    wired_kinds = set()
    for e in edges:
        if e.kind == "serves" and e.dst and nodes.get(e.dst):
            wired_kinds.add(nodes[e.dst].kind)
        if e.kind == "sources" and e.dst and nodes.get(e.dst):
            wired_kinds.add(nodes[e.dst].kind)
    for kind in ("magic-moment", "job"):
        present = [n for n in nodes.values() if n.kind == kind]
        if not present:
            continue
        if kind not in wired_kinds:  # no delivery path wired at all → not yet adopted
            caps.append("GRAPH_UNMIGRATED.P3: %d %s(s) defined but nothing wires to any (no story "
                        "serves them and no discharged PRM sources them yet)" % (len(present), kind))
            cap_state = _min_readiness(cap_state, "integration-green")
            continue
        for n in present:
            if n.id not in delivered:
                findings.append({
                    "code": "PHANTOM_PROMISE.P1", "src": n.id, "edge": "serves", "ref": n.id,
                    "resolved_to": n.id, "source_file": n.source_file,
                    "detail": "%s '%s' is promised in the contract but NO story delivers it — no "
                              "story serves it and no discharged PRM sources it (build the right thing)"
                              % (n.id, n.title),
                })

    # GRAPH_STALE — the on-disk graph must equal a fresh compile (freshness computed, not asserted)
    on_disk = graph_path(project_dir)
    if os.path.isfile(on_disk):
        try:
            saved = json.load(open(on_disk, encoding="utf-8"))
            # compare full CONTENT (nodes incl. their content_hash, + edges), not just ids/counts —
            # a title/hash change or a repointed edge that keeps the id-set must still read STALE
            # (design invariant §6.1: freshness is computed, never asserted).
            def _sig(gr):
                return content_hash(json.dumps(
                    {"nodes": gr.get("nodes", []), "edges": gr.get("edges", [])}, sort_keys=True))
            if _sig(graph) != _sig(saved):
                caps.append("GRAPH_STALE.P2: committed witness.json differs from a fresh compile — "
                            "regenerate with `speck_graph.py build` (never hand-edit it)")
                cap_state = _min_readiness(cap_state, "integration-green")
        except (ValueError, OSError):
            caps.append("GRAPH_STALE.P2: witness.json is unreadable — regenerate with `build`")
    else:
        caps.append("GRAPH_STALE.P2: no committed witness.json — run `speck_graph.py build`")

    # HONEST pending gates — needed data not yet in the graph; never a false pass
    pending = [
        "ORPHAN_CODE: pending tests-as-join (P5) — needs code nodes to prove every code entity "
        "traces to a promise. NOT evaluated (cannot claim 'no orphan code' yet).",
        "UNJUDGED_SURFACE: pending verdict extraction (P3/P4) — needs IS-IT-GOOD verdict nodes to "
        "prove every magic moment was judged. NOT evaluated. Taste itself stays owned by /audit + LARP.",
    ]

    hard = [f for f in findings if f["code"].endswith(".P1")]
    if hard:
        cap_state = "no-ship"
    return findings, caps, pending, cap_state


def cmd_check(project_dir):
    findings, caps, pending, cap_state = check_graph(project_dir)
    hard = [f for f in findings if f["code"].endswith(".P1")]
    sys.stdout.write("Speck Witness Graph — forcing gates (structural: traceable · complete · fresh)\n")
    sys.stdout.write("(faithful · good · excellent are NOT graph-provable — owned by /audit + LARP)\n\n")
    if hard:
        sys.stdout.write("❌ %d hard finding(s) — BLOCK:\n\n" % len(hard))
        for f in hard:
            sys.stdout.write("  %s  %s\n      %s\n      in %s\n\n"
                             % (f["code"], f["ref"], f["detail"], f["source_file"]))
    if caps:
        sys.stdout.write("⚠️  caps (surfaced loud; fold into MAX-claimable at /epic-validate):\n")
        for c in caps:
            sys.stdout.write("  • %s\n" % c)
        sys.stdout.write("\n")
    sys.stdout.write("ℹ️  not-yet-evaluated (honest — never counted as a pass):\n")
    for p in pending:
        sys.stdout.write("  • %s\n" % p)
    sys.stdout.write("\nGRAPH_CAP = %s  (the ceiling this graph can back; caps never grant)\n"
                     % cap_state.upper())
    return 1 if hard else 0


# ---------------------------------------------------------------------------
# migrate — generic identity hardening for ANY existing Speck project
#
# Non-destructive by design: dry-run is the DEFAULT (reports the diff); only `--apply` writes.
# Confident auto-transform: number acceptance scenarios as AC-N (idempotent — existing AC-N
# headings are respected and continue the count). Heterogeneous surfaces (magic moments, jobs)
# are REPORTED for human review, never blindly rewritten — the honest, safe boundary.
# ---------------------------------------------------------------------------

RE_SCENARIO = re.compile(r"^(#{3,4})\s+Scenario:\s*(.*)$")
RE_AC_HEADING = re.compile(r"^(#{3,4})\s+(AC-\d+)\b")


def migrate_ac_numbering(text):
    """Rewrite acceptance-scenario headings to `#### AC-N — <name>`, scoped to §2.

    Returns (new_text, n_changed). Idempotent: an already-migrated file changes 0 lines.
    Numbering runs in document order within the acceptance section; an existing AC-N heading
    adopts its own number and the counter continues from it.
    """
    lines = text.splitlines(keepends=True)
    out = []
    in_acc = False
    counter = 0
    changed = 0
    for line in lines:
        stripped = line.rstrip("\n")
        # section tracking: §2 is the acceptance section
        if re.match(r"^##\s+2[\.\s]", stripped):
            in_acc = True
        elif re.match(r"^##\s+\d", stripped) and not re.match(r"^##\s+2[\.\s]", stripped):
            in_acc = False
        if in_acc:
            m_ac = RE_AC_HEADING.match(stripped)
            if m_ac:
                counter = int(m_ac.group(2).split("-")[1])
                out.append(line)
                continue
            m_sc = RE_SCENARIO.match(stripped)
            if m_sc:
                counter += 1
                nl = "%s AC-%d — %s\n" % (m_sc.group(1), counter, m_sc.group(2).strip())
                out.append(nl)
                changed += 1
                continue
        out.append(line)
    return "".join(out), changed


def report_missing_ids(project_dir):
    """Report surfaces that still need manual id-hardening (never auto-rewritten)."""
    notes = []
    contract = os.path.join(project_dir, "product-contract.md")
    if os.path.isfile(contract):
        text = read_text(contract)
        if not re.search(r"^#{2,4}\s+MM-\d+\b", text, re.MULTILINE):
            # count §5 heading entries that look like magic moments
            n = len(re.findall(r"^#{3,4}\s+(?:Magic Moment|Milestone)", text, re.MULTILINE))
            notes.append("product-contract §5: %d magic-moment heading(s) need `MM-N —` ids "
                         "(review + add manually; heterogeneous headings are not auto-rewritten)" % n)
        if not re.search(r"\bJOB-\d+\b", text):
            notes.append("product-contract §2/§4: JTBD needs a `JOB-1` id (add manually)")
    return notes


def cmd_migrate(project_dir, apply=False):
    story_specs = []
    epics_dir = os.path.join(project_dir, "epics")
    if os.path.isdir(epics_dir):
        for ep in sorted(os.listdir(epics_dir)):
            sdir = os.path.join(epics_dir, ep, "stories")
            if os.path.isdir(sdir):
                for st in sorted(os.listdir(sdir)):
                    spec = os.path.join(sdir, st, "spec.md")
                    if os.path.isfile(spec):
                        story_specs.append(spec)
    total_changed = 0
    files_touched = 0
    for spec in story_specs:
        text = read_text(spec)
        new_text, n = migrate_ac_numbering(text)
        if n > 0:
            files_touched += 1
            total_changed += n
            rel = os.path.relpath(spec, project_dir)
            sys.stdout.write("  %s  %s: %d scenario heading(s) → AC-N\n"
                             % ("APPLIED" if apply else "would change", rel, n))
            if apply:
                with open(spec, "w", encoding="utf-8") as fh:
                    fh.write(new_text)
    mode = "APPLIED" if apply else "DRY-RUN (no files written — pass --apply to write)"
    sys.stdout.write("\n%s: %d AC heading(s) across %d file(s).\n"
                     % (mode, total_changed, files_touched))
    notes = report_missing_ids(project_dir)
    if notes:
        sys.stdout.write("\nManual id-hardening still needed (not auto-rewritten):\n")
        for nt in notes:
            sys.stdout.write("  • %s\n" % nt)
    sys.stdout.write("\nNext: run `speck_graph.py lint-refs %s` to confirm anchors resolve.\n"
                     % project_dir)
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _resolve_project_dir(arg):
    if not arg:
        return None
    if os.path.isdir(arg) and os.path.basename(os.path.normpath(arg)):
        return os.path.abspath(arg)
    return None


def cmd_build(project_dir, write=True):
    graph, nodes, edges = build_graph(project_dir)
    if write:
        out = graph_path(project_dir)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", encoding="utf-8") as fh:
            json.dump(graph, fh, indent=2, sort_keys=False)
            fh.write("\n")
        c = graph["counts"]
        sys.stderr.write("✅ Wrote %s (%d nodes, %d edges, completeness: %s)\n"
                         % (out, c["nodes"], c["edges"], graph["generator_completeness"]))
    else:
        json.dump(graph, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


def cmd_lint_refs(project_dir):
    _graph, nodes, edges = build_graph(project_dir)
    findings, unmigrated = lint_refs(nodes, edges)
    if not findings and not unmigrated:
        sys.stdout.write("✅ lint-refs: all cross-references resolve (%d nodes, %d edges)\n"
                         % (len(nodes), len(edges)))
        return 0
    if findings:
        sys.stdout.write("❌ lint-refs: %d real dangling/ambiguous reference(s) (P1)\n\n" % len(findings))
        for f in findings:
            sys.stdout.write("  %s  %s\n      %s\n      in %s\n\n"
                             % (f["code"], f["ref"], f["detail"], f["source_file"]))
    if unmigrated:
        total = sum(unmigrated.values())
        detail = ", ".join("%d %s" % (v, k) for k, v in sorted(unmigrated.items()))
        sys.stdout.write("⚠️  GRAPH_UNMIGRATED.P3: %d reference(s) to id schemes this project "
                         "hasn't adopted yet (%s).\n    Not rot — run the identity migration "
                         "(`speck-graph-migrate.sh`) to harden these anchors.\n\n" % (total, detail))
    # Real dangling refs BLOCK (exit 1); an unadopted scheme alone degrades to honest (exit 0, capped).
    return 1 if findings else 0


USAGE = """speck_graph.py — the Speck Witness Graph

Usage:
  speck_graph.py build     <PROJECT_DIR> [--stdout]   Compile the graph → graph/witness.json
  speck_graph.py lint-refs <PROJECT_DIR>              Fail on any dangling/ambiguous reference
  speck_graph.py migrate   <PROJECT_DIR> [--apply]    Harden ids (AC-N numbering); dry-run by default
  speck_graph.py query     <PROJECT_DIR> <node-id>    Raw in/out edges of a node (story, MM-N, DEC…)
  speck_graph.py context   <PROJECT_DIR> <story-id>   The story's context pack — one lookup, no tree walk
  speck_graph.py check     <PROJECT_DIR>              Forcing gates: dangling/dup BLOCK; phantom/stale CAP

PROJECT_DIR is a specs/projects/<id> directory. The graph is DERIVED — never hand-edit witness.json.
"""


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        sys.stdout.write(USAGE)
        return 0
    cmd = argv[1]
    args = argv[2:]
    project_dir = _resolve_project_dir(args[0]) if args else None
    if cmd == "build":
        if not project_dir:
            sys.stderr.write("ERROR: build requires an existing PROJECT_DIR\n")
            return 2
        return cmd_build(project_dir, write="--stdout" not in args)
    if cmd == "lint-refs":
        if not project_dir:
            sys.stderr.write("ERROR: lint-refs requires an existing PROJECT_DIR\n")
            return 2
        return cmd_lint_refs(project_dir)
    if cmd == "migrate":
        if not project_dir:
            sys.stderr.write("ERROR: migrate requires an existing PROJECT_DIR\n")
            return 2
        return cmd_migrate(project_dir, apply="--apply" in args)
    if cmd in ("query", "context"):
        if not project_dir or len(args) < 2:
            sys.stderr.write("ERROR: %s requires <PROJECT_DIR> <node-id>\n" % cmd)
            return 2
        subject = args[1]
        return cmd_query(project_dir, subject) if cmd == "query" else cmd_context(project_dir, subject)
    if cmd == "check":
        if not project_dir:
            sys.stderr.write("ERROR: check requires an existing PROJECT_DIR\n")
            return 2
        return cmd_check(project_dir)
    sys.stderr.write("Unknown command: %s\n\n%s" % (cmd, USAGE))
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
