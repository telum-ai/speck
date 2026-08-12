# Valid proof source examples (JIT)

Copy/adapt into evidence-contract §2 for this product.

## 2. Valid Proof Sources (per platform)

*What runtime evidence COUNTS as proof of UX-RC, SHIP-RC, or SHIP for THIS product.*

### Platform: [e.g., iOS]
- ✅ Standalone simulator build with production-like bundle ID
- ✅ TestFlight build for live account / payment proof
- ✅ AXe screenshots and accessibility trees from named sim
- ✅ Native logs showing no redbox or crash
- ✅ Real Sentry events from the build (production environment)
- ✅ Real Supabase/Stripe/RevenueCat events from the build's environment

### Platform: [e.g., Web]
- ✅ Production bundle served behind reverse-proxy lookalike (nginx / serve --single)
- ✅ Playwright recordings against the built bundle (NOT dev server)
- ✅ Lighthouse audit against the production-like build
- ✅ Real auth + real backend evidence (not mocked)

### Platform: [e.g., CLI/API]
- ✅ Shell transcripts from binary built with `cargo build --release` (or equivalent)
- ✅ Integration tests against the binary (NOT the source tree)
- ✅ Recorded API responses against deployed staging/prod

### 2c. What "client bundle" MEANS — the enumerated leak surface

*Load-bearing wherever a gate says "no secret reaches the client bundle". The phrase carries an implicit **Pages-Router-era** definition — static JS chunks — and a scan written to that definition reports CLEAN over a real leak. Measured: a Server Component rendering `process.env.<SERVER_ONLY_VAR>` delivered the value to the browser via prerendered HTML and the RSC flight payload while a `.next/static/**`-only scan printed CLEAN. The gate was wired, canaried and live; its **subject set** was wrong.*

**Rule: "client bundle" = everything the browser can receive.** Enumerate the surfaces for YOUR framework in the gate's Scope cell (§6a) — never leave it to the phrase.

| Framework | Enumerated browser-delivered surfaces |
|---|---|
| Next.js App Router | `.next/static/**` (JS/CSS chunks) · `.next/server/app/**/*.html` (prerendered HTML) · `.next/server/app/**/*.rsc`, `*.segment.rsc` (RSC flight payload) |
| Next.js Pages Router | `.next/static/**` · `.next/server/pages/**/*.html` |
| Vite / CRA / SPA | `dist/**` · `build/**` (all emitted assets, incl. sourcemaps if shipped) |
| SvelteKit / Nuxt / Astro | the adapter's client output dir **plus** any prerendered HTML and serialized-payload files |

*Why RSC matters specifically:* a decrypted value passed as a **prop** to a `"use client"` component serializes into the flight payload. It never appears in a chunk, and it is delivered to the browser on every request.

**One self-test direction PER enumerated surface.** A leak gate must prove it bites on each path it claims to cover, separately. A single self-test that exercises an already-covered path proves the **machinery**, not the **coverage** — the shape that let the original hole ship: the gate had a liveness self-test, and the self-test only planted a canary where the scan already looked. Declare each direction in §6a's Subject cell (e.g. `self_test_directions==3`), and observe each one bite.

### 2a. The claim-type axis — which INSTRUMENT is admissible for which KIND of claim

*Everything above is indexed by **platform**. Platform answers "which build"; it never answers "which instrument can observe this claim." That gap is the whole mechanism behind a recurring defect class: a green, honestly-authored, mutation-verified suite gets cited for a claim it is **structurally incapable of observing**, and nothing written down was violated. #87 gave evidence a **grain** field (at what altitude it was collected); this gives it **admissibility** (which substrate may back which claim at all).*

**How to route a claim.** Read the claim's verb → find its row → cite a substrate from **Admissible**. Citing anything in that row's **Does NOT count** column is anti-proof (§3) no matter how green it is, and caps the claim at surrogate proof (§13). A claim whose verb matches no row below is routed by the same test: *what would have to be true for this instrument to be able to see this claim being false?*

| Claim type (the verb) | Admissible | Does NOT count |
|---|---|---|
| **"What can this principal SEE?"** — visibility, authorization, tenancy, RLS | A **live read executed as the real principal, in both directions**: one principal who must see the row, one who must not, against the real security layer | A green suite, however mutation-verified · a read performed by a **bypass-capable** (`service_role`/superuser) or **mocked** client · a 404 from an endpoint (refusals are 404-shaped by design, so an endpoint is not a membership oracle) |
| **"Does the deployment ACCEPT this?"** — request/payload/schema conformance | The request issued **against the deployed target (or the real engine)** and observed at that boundary — the response the deployment actually returns | A mocked client (a mock encodes what we *believe* the deployment accepts, so it can only ever confirm our own belief) · a hand-written vendor fixture with no provenance — a vendor payload fixture is admissible only when **cited to the vendor's own field reference (URL + retrieval date on the fixture)** |
| **"Did the walk actually WRITE it?"** — persistence | A **pre-walk baseline query** plus a post-walk read-back **out of the datastore** | A screenshot of a success state · a post-walk read **with no baseline** (rows persist across seeds and fires, so stale rows read as a green pass) |
| **"Does it FIT / is it reachable / is it announced?"** — geometry, platform announcement | Measured on a **running screen from a baked build**: a **platform AX dump** (the OS tree assistive tech actually walks) **plus container-vs-content geometry at ≥3 widths, with the numbers in the artifact**, from a harness that refuses to print a number unless its subject is present | A **rule-engine pass** (an a11y engine evaluates the node it is handed and has no model of containment or overflow) · a **props-level** a11y assertion (props are not the platform tree; and jsdom performs no layout, so every `getBoundingClientRect` there is zeros and every geometric claim is an arithmetic model of the CSS rather than the CSS's behaviour) · an un-measured screenshot |
| **"Does a prompt change BEHAVIOUR?"** — generative surfaces | **Control-vs-treatment on the composed prompt with the shipped model, n reported** | A source-text assertion that the rule string is present in the prompt |

**The three scars these rows are earned from** (each cost a shipped defect, none was visible to a green suite):
- *Principal.* A server-side Supabase client built from the **anon key carries no JWT**, so an RLS policy of the form `auth.uid() = <col>` returned **zero rows for every user, always** — silently, with no error. The read looks exactly like "no record exists." Paying subscribers read as free, hit the free cap, and were told to upgrade to the tier they had already bought. Two mutation-verified suites could not see it; a live read as each principal settled it in one query.
- *Geometry.* A week grid whose content came to `34px gutter + 7×44px cells + 6×6px gaps = 378px in a 343px box` spilled and was cut away by `overflow-clip` — one column lost its border and ~5px of hit area, on every phone, for months. Full-page axe was **0/0/0/0 and a11y 9/9, identical before and after the fix**: contrast, roles, names and focus order were all genuinely fine. *(Scope fact worth stating with every axe number: `landmark-one-main` is tagged `cat.semantics`/`best-practice`, **not** `wcag2a`/`wcag2aa`. An "axe: 0 violations" report scoped to `wcag2aa` is silent about an entire tag class — always report the tag scope alongside the count.)*
- *Boundary.* Mocked clients are blind to what a deployment **accepts**: the mock passes because it was written from the same belief the code was written from. Only the real boundary can contradict that belief.

**Two standing rules.**
- **Never inherit a magnitude from a report — measure it.** The naive fix to a mis-measured defect is routinely a worse defect (shrinking the grid's gap would have kept the unyieldable `min-width` and moved the amputation to a narrower phone).
- **A green suite remains the right and sufficient instrument for CORRECTNESS claims.** This is an admissibility rule for the claim a report *makes* — not a requirement to collect every substrate for every AC. The sin is citing one row's instrument for another row's claim.

### 2b. Typed citations — the closed vocabulary and the admissibility table

*§2a is the rule stated for a human reader. This is the same rule stated so a machine can apply it, and the two halves must not drift: `validate-evidence-citations.sh --check-contract <this file>` diffs the table below against the Speck-owned one compiled into the validator and reports `CITATION_TABLE_DRIFT.P2` when they disagree.*

**Why the citation format had to change first.** A citation written `path@sha` carries **no type**. Nothing in that string says whether it points at a green suite, a live read as a real principal, or a screenshot — so no validator can compute whether the instrument was capable of observing the claim. Admissibility is a property of the *pair* (claim type, citation type), and half the pair was never written down. Typing the citation is upstream of every admissibility check; a registry built before it would be another section of prose that cannot fail a build.

**Syntax.** A typed citation is `<citation-type>:<path>[@<sha>]` — e.g. `live-probe:supabase/tests/webhook_claim_proof.sql@89468af1`. The prefix must be one of the tokens below, spelled exactly; a leading token that is not in the vocabulary is not a type (a bare `https://…` or a Windows drive letter is read as an untyped path, never as a bogus type). A citation with no recognized prefix is **legacy-untyped**: `CITATION_UNTYPED.P3` — a nudge, never a block, because every artifact authored before this section is untyped by construction and a P1 here would brick every project on upgrade day. Stamp what can be derived with `validate-evidence-citations.sh --stamp-types --write <path>`.

**The closed citation-type vocabulary.** Speck-owned. A project does not add tokens — an unknown token reads as untyped, so inventing one degrades to a nudge rather than manufacturing a false admissibility verdict.

| Token | The instrument | Where it already appears in this contract |
|---|---|---|
| `test` | A unit/integration suite run in the project's own harness. Mocks and props-level assertions live here. | §8 IMPL-GREEN; validation-report Gate Criteria (`test-output.txt`) |
| `mutation-guard` | A guard whose removal was **watched** to redden it — `mutate-guard.sh`, verdict `GUARD_MUTATION_PROVEN`. | validation-report §Mutation Record |
| `live-probe` | A request/read/write issued **against the deployed target or the real engine**, as a named principal, and observed at that boundary. | §2 "Real Supabase/Stripe/RevenueCat events"; §7; §8 Real-Integration Smoke Check |
| `db-catalog` | Introspection of the live datastore's catalog, or a **baselined** read-back out of the datastore. | §8 Live-Schema Parity Check (`validate-schema-drift.sh`), Real Write-Path Smoke Check |
| `ax-dump` | The **platform** accessibility tree from a baked build — the OS tree assistive tech walks, not props. | §2 "AXe screenshots and accessibility trees"; §6; §9 `ax-trees/` |
| `geometry` | Measured **container-vs-content** numbers from a running screen, at ≥3 widths, numbers in the artifact. | §2a row 4 |
| `capture` | A screenshot, recording, or LARP transcript. Evidence of *what was on screen*, adjudicated or not. | §6; §9 `screenshots/`, `larp-recordings/`, `transcripts/` |
| `device-walk` | A human attestation on a real device or the baked artifact. | §8 Verifiability Tiering; `larp-recordings/<sha>-human-attestation.md` |
| `model-eval` | Control-vs-treatment on the **composed** prompt with the **shipped** model, n reported. | §2a row 5 |
| `static` | A source-text, lint, type-check or grep assertion over the tree. Reads the source; never runs it. | §8 lint/type gates; `banned-language-lint.sh output` |

**The admissibility table.** Claim type → which citation types may discharge it. **Admissible is a whitelist**: a type absent from a row's Admissible cell is inadmissible for that claim and raises `PROBE_SUBSTRATE_MISMATCH.P1`. The third column names the ones that were earned by a shipped defect, so nobody re-litigates them.

| Claim type | Admissible citation types | Inadmissible here — and the scar that earned it |
|---|---|---|
| `correctness` | `test` `mutation-guard` `live-probe` `db-catalog` `static` `ax-dump` `geometry` `capture` `device-walk` `model-eval` | *(nothing — a green suite is the right and sufficient instrument for a correctness claim; this row can never fire)* |
| `visibility` | `live-probe` `db-catalog` `device-walk` | `test` · `mutation-guard` — an anon-key server client carries no JWT, so `auth.uid() = <col>` returned **zero rows for every user, always**, silently. Two mutation-verified suites could not see it; a live read as each principal settled it in one query. Also `static`, `capture` |
| `acceptance` | `live-probe` `db-catalog` `device-walk` | `test` — a **mocked client** encodes what we *believe* the deployment accepts, so it can only ever confirm our own belief. Only the real boundary can contradict it. Also `mutation-guard`, `static`, `capture` |
| `persistence` | `live-probe` `db-catalog` | `capture` — a screenshot of a success state is not a written row; and a post-walk read with **no pre-walk baseline** cannot tell a fresh write from a stale seed. Also `test`, `mutation-guard`, `static` |
| `fit` | `ax-dump` `geometry` `device-walk` | `test` — a **props-level a11y assertion** reads props, not the platform tree, and jsdom performs no layout. A rule engine is structurally blind to containment: axe was **0/0/0/0 and a11y 9/9, identical before and after** a grid amputated a column on every phone. Also `static`, `capture`, `mutation-guard` |
| `behaviour` | `model-eval` `device-walk` | `static` — asserting the rule string is **present in the source** of a prompt is not evidence the composed prompt changed what the shipped model does. Also `test`, `capture` |

*A claim whose type is none of the six is **unrouted**: the validator reports it and moves on. Degrade-to-honest, never a false P1 — a wrong routing produces a confident wrong verdict, which is worse than an admitted gap.*

**Where a typed citation appears — the citation site.** Admissibility is only computable where the claim type and the citation sit in the *same row*, so the site is a markdown table carrying **both** a column whose header starts with `Claim` and a column whose header starts with `Evidence` / `Citation` / `Discharge artifact` / `Proof` / `Substrate`. Any table in any Speck artifact with that shape is scanned; any table without it is ignored. That is why the two definition tables above are inert — their columns are `Admissible…` / `Inadmissible…`, so the contract can never report findings against its own documentation. A discharge table that adds a `Claim type` column becomes machine-checkable the moment it does, with no change to this validator.

| Claim type | Discharge artifact | Notes |
|---|---|---|
| `visibility` | `live-probe:specs/.../logs/<sha>-rls-as-principal.log` | *(example row — replace or delete)* |

---
