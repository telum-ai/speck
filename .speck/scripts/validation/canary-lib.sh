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

# Pure STRING check for a destructive verb (shared by the runtime probe AND the recipe-time lint, so
# they never drift). Boundaried; sees the verb wherever it appears in the invocation/body text.
cl_looks_destructive() {
  printf '%s' "$1" | grep -qiE '(^|[^a-z-])(deploy|publish|migrate|upgrade|destroy|provision|db[ _-]?push|prisma[ ]+migrate|drizzle-kit[ ]+push|supabase|terraform[ ]+(apply|destroy)|pulumi[ ]+(up|destroy)|railway[ ]+up|flyctl|fly[ ]+deploy|kubectl|helm[ ]+(install|upgrade|uninstall)|wrangler|npm[ ]+publish|yarn[ ]+publish|pnpm[ ]+publish|twine[ ]+upload|gh[ ]+release|vercel|netlify[ ]+deploy|docker[ ]+(push|compose[ ]+push)|git[ ]+(commit|push)|alembic[ ]+(upgrade|downgrade)|goose[ ]+(up|down)|dropdb|createdb|aws[ ]+(s3|lambda|ecs|cloudformation|deploy)|gcloud|az[ ]+|rm[ ]+-rf)([^a-z]|$)'
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
cl_probe_safety() {
  local inv="$1" wt="$2"
  local first second eff="$inv" resolved_body=false target name
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
  cl_looks_destructive "$eff" && { printf 'unsafe'; return 0; }
  # We read the full wrapper body and it carries no destructive verb → safe to run in the worktree.
  [[ "$resolved_body" == true ]] && { printf 'safe'; return 0; }
  # A Speck-owned script is reviewed → safe.
  case "$first" in .speck/*|*/.speck/*|./.speck/*) printf 'safe'; return 0 ;; esac
  # Otherwise classify the operative tool, peeling leading runners.
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
  local op="${1:-}"; op="${op##*/}"
  cl_is_safe_tool "$op" && { printf 'safe'; return 0; }
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

# Symlink node_modules into the worktree when the lockfiles match (never npm install — slow/network).
cl_link_node_modules() {
  local root="$1" wt="$2" sub="$3"   # sub = "" for repo root, or e.g. "frontend"
  local src="$root/${sub:+$sub/}node_modules"
  local dst="$wt/${sub:+$sub/}node_modules"
  [[ -d "$src" && ! -e "$dst" ]] || return 0
  ln -s "$src" "$dst" 2>/dev/null || true
  return 0
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
  # A plain user-visible line carrying the banned term (the gate scans textual surfaces).
  printf 'Speck gate-liveness canary — banned term below (safe, worktree-only):\n%s\n' "$term" > "$wt/$rel"
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
