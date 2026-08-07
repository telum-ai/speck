#!/usr/bin/env bash
# canary-lib.sh — shared helpers for the gate-liveness canary probe (issue #88, Phase 2).
#
# Sourced by gate-liveness-probe.sh. Holds the safety envelope (worktree lifecycle, destructive-verb
# denylist, env sandbox, $ROOT integrity snapshot) and the canary PROVIDERS (what to inject per gate
# domain + the red-fingerprint that attributes a failure to the injected defect).
#
# NOTHING here ever writes the real working tree ($ROOT). All mutation happens inside a throwaway
# git worktree the probe owns. Every function returns 0 on the normal path (bash 3.2 + set -e safe).
#
# Portable bash 3.2 / macOS. No associative arrays, no mapfile.

# --- gate-probe safety classifier ----------------------------------------------------------------
# A mutation probe must NEVER run a gate that deploys / mutates prod / a live DB / destroys infra.
# Denylists fail open on the command you forgot; a pure allowlist can't tell a safe no-op "dark gate"
# from an unknown binary. So we classify into three: "unsafe" (a destructive verb is present — refuse),
# "unknown" (command family not recognized as safe — refuse, fail-closed), "safe" (a known read/lint/
# test/format-check family, a Speck-owned script, or a pure no-op — run it). Refuse == fail-closed.

# The destructive-verb pattern, in ONE place so the runtime probe and the recipe-time lint can never
# drift. Boundaried; sees the verb wherever it appears in the invocation/body text.
#
# VENDOR NAMES ARE VERB-SCOPED (#114 §2). `supabase` and a bare `migrate` used to sit in this list
# alone, while every other alternative is `<tool> <destructive-verb>`. A bare vendor name does not
# model danger, it models a vendor: `supabase status` — which prints connection details and mutates
# nothing — classified exactly as `supabase db push`, and so did the container name in
# `docker exec supabase_db_odd psql …`. The consequence was structural, not cosmetic: NO admissible
# applier existed for any DB-migration guard, because the denylist refused the CLI and the allowlist
# refused the raw client, so a grant/RLS posture — the class of guard that most needs mutation
# evidence — could never be witnessed at all. Scoped to the verbs that actually push state, a local
# `supabase db reset` against a disposable stack is admissible, which is what unblocks that class.
CL_DESTRUCTIVE_RE='(^|[^a-z-])(deploy|publish|upgrade|destroy|provision|db[ _-]?push|prisma[ ]+migrate|drizzle-kit[ ]+push|supabase[ ]+(db[ ]+(push|remote|dump)|link|projects|secrets|functions|branches)|terraform[ ]+(apply|destroy)|pulumi[ ]+(up|destroy)|railway[ ]+up|flyctl|fly[ ]+deploy|kubectl|helm[ ]+(install|upgrade|uninstall)|wrangler|npm[ ]+publish|yarn[ ]+publish|pnpm[ ]+publish|twine[ ]+upload|gh[ ]+release|vercel|netlify[ ]+deploy|docker[ ]+(push|compose[ ]+push)|git[ ]+(commit|push)|alembic[ ]+(upgrade|downgrade)|goose[ ]+(up|down)|manage\.py[ ]+migrate|rails[ ]+db:migrate|dropdb|createdb|aws[ ]+(s3|lambda|ecs|cloudformation|deploy)|gcloud|az[ ]+|rm[ ]+-rf)([^a-z]|$)'

# Pure STRING check for a destructive verb.
cl_looks_destructive() {
  printf '%s' "$1" | grep -qiE "$CL_DESTRUCTIVE_RE"
}

# cl_destructive_match <text> — echo the matched substring, or nothing. The refusal message's whole
# job is to be diagnosable: "unsafe" sends the operator to read a 40-alternative regex, while
# "matched 'deploy'" is actionable in one read (#114 §1.3, §2.4, §3 Gap-2.3 — the same ask arrived
# from three independent stories).
cl_destructive_match() {
  printf '%s' "$1" | grep -oiE "$CL_DESTRUCTIVE_RE" | head -n1 | sed -E 's/^[^a-zA-Z]+//; s/[^a-zA-Z0-9]+$//'
}

# cl_redact_path_args <invocation> — blank out tokens that are FILESYSTEM PATHS, not verbs.
#
# #114 §1: `cl_looks_destructive` was handed the whole invocation, arguments included, and
# `src/app/api/health/deploy-workflow.test.ts` matches `deploy` (preceded by `/`, followed by `-`,
# both satisfying the boundary). So `npx vitest run <that path>` was "unsafe" while the identical
# command on `sha.test.ts` was "safe" — same runner, same flags, same worktree, the only difference
# a directory name. And it bites hardest exactly where mutation evidence matters most: a guard
# protecting a deploy pipeline, a migration runner or a publish step almost always lives in a file
# named after the thing it guards.
#
# A token is path-shaped when it holds a `/` and is not a flag. Redaction is applied ONLY when the
# operative tool is already on the read/lint/test allowlist (see cl_probe_safety), so a compound
# invocation like `vitest run x && supabase db push` still has its second half read in full.
cl_redact_path_args() {
  local inv="$1" out="" tok first=true
  for tok in $inv; do
    if [[ "$first" == true ]]; then first=false; out="$tok"; continue; fi
    case "$tok" in
      -*)  out="$out $tok" ;;
      */*) out="$out PATH" ;;
      *)   out="$out $tok" ;;
    esac
  done
  printf '%s' "$out"
}

# Known-safe first-token families (read/lint/test/format-check). Extend as needed — adding here is
# an explicit safety decision, unlike a denylist where forgetting a verb silently fails open.
cl_is_safe_tool() {
  case "$1" in
    ruff|flake8|pyflakes|black|isort|mypy|pylint|pytest|tox|bandit|\
    eslint|biome|tsc|prettier|stylelint|jest|vitest|mocha|ava|\
    cargo|clippy|rustfmt|go|gofmt|golangci-lint|staticcheck|\
    rubocop|rspec|phpunit|phpstan|psalm|pint|\
    dart|ktlint|detekt|swiftlint|swiftformat|\
    grep|rg|ag|test|true|:|exit|echo|cat|ls|shellcheck|shfmt) return 0 ;;
  esac
  return 1
}

# Classify an invocation for probe-safety. Echoes: safe | unsafe | unknown.
#   unsafe  = a destructive verb is present anywhere in the invocation OR a resolvable wrapper body.
#   safe    = we could READ the full body (a `bash <script>` we can open / an `npm run <name>` script
#             string / a Speck-owned script) and it is non-destructive; OR the operative tool is a
#             known read/lint/test/format-check family; OR a pure no-op.
#   unknown = an opaque command we cannot read and cannot recognize (e.g. a bespoke compiled binary)
#             → fail-closed: refuse to run it.
#
# CL_SAFETY_REASON is set on every call: the token that fired, or the tool that was not recognized.
cl_probe_safety() {
  local inv="$1" wt="$2"
  local first second eff="$inv" resolved_body=false target name
  CL_SAFETY_REASON=""
  first="$(printf '%s' "$inv" | awk '{print $1}')"
  second="$(printf '%s' "$inv" | awk '{print $2}')"
  case "$first" in
    bash|sh|zsh|source|.)
      target="${second#./}"
      if [[ -n "$target" && -f "$wt/$target" ]]; then eff="$inv
$(cat "$wt/$target" 2>/dev/null || true)"; resolved_body=true; fi ;;
    npm|pnpm|yarn|bun)
      if [[ "$second" == "run" ]]; then
        name="$(printf '%s' "$inv" | awk '{print $3}')"
        if [[ -f "$wt/package.json" ]]; then eff="$inv
$(grep -E "\"$name\"[[:space:]]*:" "$wt/package.json" 2>/dev/null || true)"; resolved_body=true; fi
      fi ;;
  esac

  # Resolve the operative tool FIRST (#114 §1.1). A known read/lint/test runner does not become
  # destructive because of an argument — but the arguments are still scanned, with only the
  # path-shaped tokens redacted, so a compound `vitest run x && supabase db push` is still refused.
  local op=""
  if [[ "$resolved_body" == false ]]; then
    set -- $inv
    while [[ $# -gt 0 ]]; do
      case "$1" in
        env|time) shift ;;
        timeout|gtimeout) shift; [[ "${1:-}" =~ ^[0-9] ]] && shift ;;
        npx) shift ;;
        python|python3) shift; [[ "${1:-}" == "-m" ]] && shift ;;
        *) break ;;
      esac
    done
    op="${1:-}"; op="${op##*/}"
    if cl_is_safe_tool "$op"; then
      eff="$(cl_redact_path_args "$inv")"
    fi
  fi

  if cl_looks_destructive "$eff"; then
    CL_SAFETY_REASON="matched destructive token '$(cl_destructive_match "$eff")'"
    printf 'unsafe'; return 0
  fi
  # We read the full wrapper body and it carries no destructive verb → safe to run in the worktree.
  [[ "$resolved_body" == true ]] && { printf 'safe'; return 0; }
  # A Speck-owned script is reviewed → safe.
  case "$first" in .speck/*|*/.speck/*|./.speck/*) printf 'safe'; return 0 ;; esac
  cl_is_safe_tool "$op" && { printf 'safe'; return 0; }
  CL_SAFETY_REASON="operative tool '${op:-?}' is not on the known read/lint/test allowlist (fail-closed)"
  printf 'unknown'
  return 0
}

# --- worktree lifecycle ---------------------------------------------------------------------------
# Sweep stale probe worktrees from prior crashed runs (self-heal at START, not via a dead run's trap).
cl_selfheal() {
  local root="$1"
  git -C "$root" worktree prune >/dev/null 2>&1 || true
  local base="${TMPDIR:-/tmp}"
  # Remove leftover speck-liveness dirs from CRASHED runs — but never a dir owned by a probe still
  # alive (the dir name carries the owner PID: speck-liveness-<pid>). Skips this run's own dir too.
  ls -d "${base%/}"/speck-liveness-* 2>/dev/null | while IFS= read -r d; do
    [[ -d "$d" ]] || continue
    local pid; pid="$(basename "$d" | sed -E 's/^speck-liveness-//')"
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then continue; fi   # owner still running
    rm -rf "$d" 2>/dev/null || true
  done
  return 0
}

# Create a detached worktree at HEAD. Echoes the worktree path. Empty on failure.
cl_worktree_add() {
  local root="$1" runid="$2"
  local wt="${TMPDIR:-/tmp}/speck-liveness-${runid}"
  wt="${wt%/}"
  rm -rf "$wt" 2>/dev/null || true
  if git -C "$root" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
    printf '%s' "$wt"
  fi
  return 0
}

cl_worktree_remove() {
  local root="$1" wt="$2"
  [[ -z "$wt" ]] && return 0
  git -C "$root" worktree remove --force "$wt" >/dev/null 2>&1 || true
  rm -rf "$wt" 2>/dev/null || true
  git -C "$root" worktree prune >/dev/null 2>&1 || true
  return 0
}

# Provide node_modules to the worktree without an npm install (slow, network, and it would change
# what is being measured).
#
# SYMLINK IS THE DEFAULT AND IS RIGHT FOR ALMOST EVERYTHING — Vitest, Jest and pytest resolve through
# it happily. Turbopack does not (#114 §3): it resolves the project root first and then REFUSES any
# symlink that escapes it —
#     Error [TurbopackInternalError]: Symlink [project]/node_modules is invalid,
#     it points out of the filesystem root
# — so the build dies at package resolution before any test runs, the `--red` invocation is already
# red BEFORE the mutation, and the whole e2e layer of a Next 16 project loses mutation evidence for a
# harness reason that reads like a project problem.
#
# So: clone instead of linking when the project declares a build tool known to reject escaping
# symlinks. `cp -c` (APFS) and `cp -al` (Linux hardlink) are near-free — no bytes are copied, only
# directory entries — and both degrade to a plain symlink if unavailable rather than failing the run.
cl_needs_real_node_modules() {
  local root="$1" sub="$2"
  local pkg="$root/${sub:+$sub/}package.json"
  [[ -f "$pkg" ]] || return 1
  grep -qE '"(next|turbopack|@vercel/turbopack[^"]*)"[[:space:]]*:' "$pkg" 2>/dev/null
}

cl_link_node_modules() {
  local root="$1" wt="$2" sub="$3"   # sub = "" for repo root, or e.g. "frontend"
  local src="$root/${sub:+$sub/}node_modules"
  local dst="$wt/${sub:+$sub/}node_modules"
  [[ -d "$src" && ! -e "$dst" ]] || return 0
  if cl_needs_real_node_modules "$root" "$sub"; then
    # Copy-on-write / hardlink clone, cheapest first. Any success wins; otherwise fall through.
    cp -c -R "$src" "$dst" 2>/dev/null && return 0
    cp -al "$src" "$dst" 2>/dev/null && return 0
    cp -R "$src" "$dst" 2>/dev/null && return 0
  fi
  ln -s "$src" "$dst" 2>/dev/null || true
  return 0
}

# --- harness failure vs. blind guard (#114 §3.2) -------------------------------------------------
# When a `--red` invocation is already red before the mutation, the honest verdict is "nothing was
# measured" — but the REASON has to say WHOSE fault it was. `GUARD_UNMUTATED.P2` with the reason
# "already red" reads as a project problem, and an author who trusts it concludes their e2e guard is
# worthless: they delete it, or — worse — tune something until it goes green. The doctrine correctly
# forbids tuning the mutation; it should not be this easy to arrive at the temptation.
#
# These signatures say the HARNESS could not run the guard, not that the guard is blind.
cl_harness_failure_signature() {
  local out="$1"
  printf '%s' "$out" | grep -oiE 'Symlink .* points out of the filesystem root|TurbopackInternalError|Cannot find module|command not found|ENOENT: no such file or directory|executable file not found' | head -n1
}

# Digest helper with a fallback chain. NEVER collapses to a constant on a missing tool (that would
# make INVARIANT-ZERO fail OPEN); the last resort embeds the raw content so any change is detectable.
cl_digest() {
  local data="$1"
  if command -v shasum >/dev/null 2>&1; then printf '%s' "$data" | shasum -a 1 2>/dev/null | awk '{print $1}'
  elif command -v sha1sum >/dev/null 2>&1; then printf '%s' "$data" | sha1sum 2>/dev/null | awk '{print $1}'
  elif command -v md5sum >/dev/null 2>&1; then printf '%s' "$data" | md5sum 2>/dev/null | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then printf '%s' "$data" | openssl md5 2>/dev/null | awk '{print $NF}'
  else printf 'RAW:%s:%s' "$(printf '%s' "$data" | wc -c | tr -d ' ')" "$data"; fi
  return 0
}

# --- $ROOT integrity snapshot (INVARIANT-ZERO) ---------------------------------------------------
# The real tree's tracked+untracked (non-ignored) files must be identical after the probe. Snapshots
# HEAD + porcelain digest; verified at the end. (Gitignored caches are out of scope — the probe reaches
# node_modules via a read-only symlink and never writes $ROOT; all mutation happens inside the worktree.)
cl_root_snapshot() {
  local root="$1" porc
  porc="$(git -C "$root" status --porcelain 2>/dev/null | LC_ALL=C sort)"
  printf '%s|%s' "$(git -C "$root" rev-parse HEAD 2>/dev/null || echo NOHEAD)" "$(cl_digest "$porc")"
  return 0
}

# --- gate execution (sandboxed env) --------------------------------------------------------------
# Run the gate invocation inside the worktree. Args: <wt> <cwd_subdir> <invocation> <out_file>.
# Echoes the exit code. NEVER inherits/writes $ROOT; hooks neutralized via env (not `git config`).
# Preserves the real PATH so the gate's own subprocesses (python3, node, rg) resolve.
cl_run_gate() {
  local wt="$1" sub="$2" inv="$3" out="$4"
  local cwd="$wt${sub:+/$sub}"
  local rc=0
  local runner="bash -c"
  # timeout wrapper if available (GNU coreutils `timeout` or macOS `gtimeout`)
  local TO=""
  if command -v timeout >/dev/null 2>&1; then TO="timeout 300"; elif command -v gtimeout >/dev/null 2>&1; then TO="gtimeout 300"; fi
  (
    cd "$cwd" 2>/dev/null || exit 127
    # Sandbox: worktree-local HOME/TMP, cache-busting, hooks neutralized via GIT_CONFIG env overlay
    # (NEVER `git config core.hooksPath` — worktrees share .git/config; that would disarm the
    # developer's real hooks). Real PATH preserved on purpose.
    export HOME="$wt/.speck-canary-home"; mkdir -p "$HOME" 2>/dev/null || true
    export XDG_CACHE_HOME="$HOME/.cache" XDG_CONFIG_HOME="$HOME/.config"
    export TMPDIR="$wt/.speck-canary-tmp"; mkdir -p "$TMPDIR" 2>/dev/null || true
    export PYTEST_ADDOPTS="-p no:cacheprovider"
    # Neutralize the developer's git hooks for the gate run via an env overlay (git >= 2.31) — NEVER
    # `git config core.hooksPath` (worktrees share .git/config; that would permanently disarm the real
    # hooks). GIT_CONFIG_COUNT is a no-op on older git, so applying it unconditionally is safe.
    if git --version >/dev/null 2>&1; then
      export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null
    fi
    set +e
    # </dev/null: the gate must never consume the probe's own stdin (the caller's `while read <<<` here-string).
    if [[ -n "$TO" ]]; then $TO $runner "$inv" >"$out" 2>&1 </dev/null; else $runner "$inv" >"$out" 2>&1 </dev/null; fi
    exit $?
  )
  rc=$?
  printf '%s' "$rc"
  return 0
}

# --- product-contract §7 banned term -------------------------------------------------------------
# Pull one real banned term from the project's product-contract.md §7 so the canary is a TRUE positive
# for THIS project (not a hard-coded word the gate might legitimately not ban). Echoes the term, empty
# if none resolvable.
cl_banned_term() {
  local project_dir="$1" pc=""
  for pc in "$project_dir/product-contract.md" "$project_dir"/../product-contract.md; do
    [[ -f "$pc" ]] && break
  done
  [[ -f "$pc" ]] || { printf ''; return 0; }
  # Extract the first bulleted/quoted term under a "Banned Language" / "## 7" section.
  awk '
    /^##[[:space:]]*7\.|Banned Language|Banned Phrases/ { ins=1; next }
    ins && /^##[[:space:]]/ { ins=0 }
    ins && /`[^`]+`/ { if (match($0,/`[^`]+`/)) { t=substr($0,RSTART+1,RLENGTH-2); print t; exit } }
  ' "$pc" 2>/dev/null | head -n1
  return 0
}

# ================================================================================================
# PROVIDERS — each canary key resolves to <key-fn>_plan + <key-fn>_write.
#   _plan  <wt> <project_dir> <invocation>  -> emits surface lines "EXT|RELPATH|FINGERPRINT"
#                                              or a single "DEGRADE|<reason>" line.
#   _write <wt> <relpath> <ext> <project_dir> <term> -> writes the injection file at $wt/$relpath.
# The probe tests each surface INDEPENDENTLY (add file -> git add -> run gate -> classify -> remove).
# ================================================================================================

# Return the required-scope dirs that actually exist in the worktree (space-separated).
cl_present_scope_dirs() {
  local wt="$1" scope="$2" d out=""
  for d in $scope; do [[ -d "$wt/$d" ]] && out="$out $d"; done
  printf '%s' "$(printf '%s' "$out" | sed -E 's/^ +//')"
  return 0
}

# --- banned-language (Tier A, the reference / catches #85) ----------------------------------------
provide_banned_language_plan() {
  local wt="$1" project_dir="$2"
  local term; term="$(cl_banned_term "$project_dir")"
  [[ -z "$term" ]] && { printf 'DEGRADE|no product-contract §7 banned term to inject\n'; return 0; }
  local dirs; dirs="$(cl_present_scope_dirs "$wt" "$CANARY_REQUIRED_SCOPE")"
  [[ -z "$dirs" ]] && { printf 'DEGRADE|no required-scope surface dirs present (%s)\n' "$CANARY_REQUIRED_SCOPE"; return 0; }
  # One representative file per extension-class PRESENT under the scope dirs (multi-surface).
  local ext firstdir; firstdir="$(printf '%s' "$dirs" | awk '{print $1}')"
  local emitted=0
  for ext in $CANARY_EXT_CLASSES; do
    # only inject an ext-class that already appears somewhere under a scope dir (real surface).
    # `-print -quit` stops find at the first match → exit 0, no pipe, no SIGPIPE-141 under pipefail
    # (a false-absent here would silently skip a real surface = the DARK-reads-LIVE bug #88 fixes).
    local present=false d
    for d in $dirs; do
      if [ -n "$(find "$wt/$d" -type f -name "*.$ext" -print -quit 2>/dev/null)" ]; then present=true; break; fi
    done
    [[ "$present" == true ]] || continue
    printf '%s|%s/__speck_canary__.%s|%s\n' "$ext" "$d" "$ext" "$term"
    emitted=$((emitted + 1))
  done
  if [[ "$emitted" -eq 0 ]]; then
    # No matching ext-class present; fall back to the single most-common ext under the first dir.
    printf 'DEGRADE|no injectable extension-class present under scope (%s)\n' "$CANARY_EXT_CLASSES"
  fi
  # export the term so _write and the probe's fingerprint agree
  CANARY_TERM="$term"
  return 0
}
provide_banned_language_write() {
  local wt="$1" rel="$2" ext="$3" project_dir="$4" term="$5"
  mkdir -p "$(dirname "$wt/$rel")" 2>/dev/null || true
  # The injected defect has to be a defect ON THE SURFACE IT IS INJECTED INTO. From v10 the
  # gate reads user-visible strings rather than whole files, so a bare line of prose in a
  # .ts/.py/.go file is NOT copy — it is a run of identifiers. Writing one there produced a
  # gate that stayed (correctly) green and a canary that read that green as GATE_DISARMED.P1,
  # on every source extension class at once. A canary whose "defect" the gate is right to
  # ignore measures nothing; it just manufactures a P1.
  #
  # So the term is placed where a USER would see it, per surface family: a string literal in
  # source, a text node in markup, a bare line in prose (where every line is copy).
  case "$ext" in
    md|mdx|markdown|txt|rst|adoc)
      printf 'Speck gate-liveness canary — banned term below (safe, worktree-only):\n%s\n' "$term" > "$wt/$rel"
      ;;
    html|htm|astro|vue|svelte|templ|php|erb|ejs|hbs|njk|twig|xml)
      printf '<p>Speck gate-liveness canary (safe, worktree-only): %s</p>\n' "$term" > "$wt/$rel"
      ;;
    json|arb)
      printf '{ "__speck_canary__": "Speck gate-liveness canary: %s" }\n' "$term" > "$wt/$rel"
      ;;
    yaml|yml)
      printf '__speck_canary__: "Speck gate-liveness canary: %s"\n' "$term" > "$wt/$rel"
      ;;
    *)
      # Source families. A quoted literal reads as a string in every lexer Speck models
      # (C-like and hash-like alike), which is all this file needs to be.
      printf 'const __speck_canary__ = "Speck gate-liveness canary (safe, worktree-only): %s";\n' "$term" > "$wt/$rel"
      ;;
  esac
  return 0
}

# --- lint-error (Tier B) -------------------------------------------------------------------------
provide_lint_error_plan() {
  local wt="$1" project_dir="$2" inv="$3"
  local dirs; dirs="$(cl_present_scope_dirs "$wt" "$CANARY_REQUIRED_SCOPE")"
  local d; d="$(printf '%s' "$dirs" | awk '{print $1}')"
  [[ -z "$d" ]] && { printf 'DEGRADE|no source dir present for a lint canary\n'; return 0; }
  # Inject a config-INDEPENDENT defect (a parse/syntax error) the linter cannot rule-suppress — so a
  # green-after-mutation is genuinely DISARMED, not "the project didn't enable the unused-import rule".
  case "$inv" in
    *ruff*|*flake8*|*pyflakes*)
      printf 'py|%s/__speck_canary__.py|E999|SyntaxError|invalid syntax\n' "$d" ;;
    *eslint*|*biome*|*" tsc"*)
      printf 'ts|%s/__speck_canary__.ts|SyntaxError|Parsing error|error\n' "$d" ;;
    *)
      printf 'DEGRADE|linter not recognized in invocation (%s) — need ruff/flake8/eslint/biome/tsc\n' "$inv" ;;
  esac
  return 0
}
provide_lint_error_write() {
  local wt="$1" rel="$2" ext="$3"
  mkdir -p "$(dirname "$wt/$rel")" 2>/dev/null || true
  case "$ext" in
    py) printf 'def __speck_canary__(:\n    return  # deliberate syntax error (config-independent)\n' > "$wt/$rel" ;;
    ts) printf 'export const __speck_canary__ : = ;  // deliberate parse error (config-independent)\n' > "$wt/$rel" ;;
  esac
  return 0
}

# --- unit-tripwire (Tier B, universal weak floor: proves the runner is invoked) -------------------
provide_unit_tripwire_plan() {
  local wt="$1" project_dir="$2" inv="$3"
  local dirs; dirs="$(cl_present_scope_dirs "$wt" "$CANARY_REQUIRED_SCOPE")"
  local d; d="$(printf '%s' "$dirs" | awk '{print $1}')"
  [[ -z "$d" ]] && d="."
  case "$inv" in
    *pytest*|*" py "*|*python*-m*pytest*)
      printf 'py|%s/test___speck_canary__.py|SPECK_CANARY_TRIPWIRE\n' "$d" ;;
    *vitest*|*jest*|*" test"*|*mocha*)
      printf 'ts|%s/__speck_canary__.test.ts|SPECK_CANARY_TRIPWIRE\n' "$d" ;;
    *)
      printf 'DEGRADE|test runner not recognized in invocation (%s)\n' "$inv" ;;
  esac
  return 0
}
provide_unit_tripwire_write() {
  local wt="$1" rel="$2" ext="$3"
  mkdir -p "$(dirname "$wt/$rel")" 2>/dev/null || true
  case "$ext" in
    py) printf 'def test_speck_canary_tripwire():\n    assert False, "SPECK_CANARY_TRIPWIRE"\n' > "$wt/$rel" ;;
    ts) printf 'import { test, expect } from "vitest"\ntest("speck canary tripwire", () => { throw new Error("SPECK_CANARY_TRIPWIRE") })\n' > "$wt/$rel" ;;
  esac
  return 0
}

# --- declared-but-degrading canaries (ship the vocabulary; honest UNVERIFIED until seeded) --------
provide_a11y_role_plan() {
  printf 'DEGRADE|a11y-role needs a project-declared component↔role-test target (not seeded)\n'; return 0
}
provide_a11y_role_write() { return 0; }
provide_integration_invariant_plan() {
  printf 'DEGRADE|integration-invariant is infra-bound (live DB) — UNVERIFIED in a sandbox\n'; return 0
}
provide_integration_invariant_write() { return 0; }
