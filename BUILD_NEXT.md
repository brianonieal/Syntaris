# BUILD_NEXT.md

What's planned after v0.4.0. This file is a working planning doc, not a
contract — items here may be reordered, dropped, or moved between
versions as evidence accumulates.

Last updated: 2026-05-07 (v0.5.1 ship)

---

## Shipped in v0.5.1 ✓

- Gate model evolution: project-level `BUILD APPROVED` (locks the
  full version roadmap once), per-gate `CONFIRMED → ROADMAP APPROVED
  → MOCKUPS APPROVED → FRONTEND APPROVED → GO`
- `SCOPE CONFIRMED` and `TESTS APPROVED` retired
- New conversational `/start` rewrite (matches the v0.5.0 user-supplied
  text)
- Foundation, hook, skill, and methodology docs aligned to the new
  gate model

---

## Shipped in v0.5.0 ✓

- Pattern extraction (`extract-patterns.sh`): 4 of 5 pattern types
  (project-systemic, error-introduction, source bias, gate-type
  variance). Recovery patterns deferred to v0.5.1/v0.6.0.
- `/health --review-patterns` conversational accept/reject/edit flow
- MEMORY_SEMANTIC.md format extension (Auto-extracted, Human-reviewed,
  Data points fields)
- Outcomes (template + manual grading + spec-reviewer extension)
- Build-rules gate-close protocol updated (Outcomes grading step)

---

## ~~v0.5.0~~ (now historical reference)

Pattern extraction and Outcomes (manual-grading slice) shipped.
Recovery patterns and the automated Outcomes retry loop moved to
v0.6.0. The 30-task benchmark is still scoped here as research work
gated on Tier 2 adapter validation.

The original v0.5.0 scope below is preserved as historical context;
the "Shipped in v0.5.0" list above is what actually landed.

---

## v0.5.0 (original scope, now partially shipped)

### Thrust 1: Pattern extraction (headline)

#### Goal

The v0.4.0 ESTIMATION line in MEMORY_CORRECTIONS.md is structured and
numeric. Today no one reads it programmatically — it accumulates and
the user reviews it via `/health`. v0.5.0 closes that loop: a hook
extracts patterns from accumulated ESTIMATION data and writes them as
PATTERN entries in MEMORY_SEMANTIC.md with confidence scores.

This is the same problem Anthropic Managed Agents "Dreaming" solves,
with two structural differences worth keeping:
- **Boundary**: Syntaris extracts patterns at gate close (structural)
  rather than between sessions (temporal). Gate-tied means each
  pattern is anchored to a specific predicted-vs-actual data point.
- **Format**: Patterns are numeric (variance percentages, error
  deltas, gate types) rather than descriptive ("recurring mistakes").
  Both have value; Syntaris should keep the numeric flavor.

#### Pattern types to extract

After ≥5 ESTIMATION entries, the extractor proposes patterns of
these shapes:

1. **Gate-type variance bias.** "Gates with [pattern in name] run
   +X% over estimate, last N gates." Match gate names against keyword
   sets (auth, RLS, migration, agent, deployment, CRUD).
2. **Error-introduction variance.** "Gates where errors_close >
   errors_open ran avg +X% variance, last N gates." Quantifies the
   correlation between accumulating errors during a gate and runtime
   overrun.
3. **Source-of-actuals bias.** "TIMELOG-source variance averages +X%,
   git-source averages +Y%." Tells the user when their TIMELOG is
   accurate vs when they're letting git infer.
4. **Recovery patterns.** "Gates after a STOP EVENT in MEMORY_EPISODIC
   ran +X% variance vs cold gates." Quantifies context-switch cost.
5. **Project-level systemic bias.** "Across all gates of project X,
   actual runs avg N% over predicted. Apply 1+(N/100) multiplier to
   future estimates."

Each extracted pattern lands in MEMORY_SEMANTIC.md with confidence
based on data points:
- LOW: 2-3 data points
- MEDIUM: 4-6 data points
- HIGH: 7+ data points

#### Where it lives

Two-piece architecture:

**Piece 1: extraction script** at `.claude/lib/extract-patterns.sh`.
Reads MEMORY_CORRECTIONS.md, parses ESTIMATION lines, reads
MEMORY_EPISODIC.md for STOP EVENT context. Writes proposed patterns
to a staging file at `.syntaris/proposed-patterns.md`. Idempotent —
re-runs produce the same output.

**Piece 2: gate-close hook integration.** Extend
`gate-close-calibration.sh` (and `.ps1`) to call the extractor after
writing the ESTIMATION line. If new patterns are proposed, append
them to the gate-close stderr message:

```
=== Pattern detected ===
PAT-005: RLS gates run +35% over estimate, last 3 gates (LOW confidence)
  See .syntaris/proposed-patterns.md for full text.
  Run /health --review-patterns to accept/reject.
```

**Piece 3: /health extension.** A new `--review-patterns` flag opens
the proposed patterns file, walks through each one with the user
(accept / reject / edit), and writes accepted ones to
MEMORY_SEMANTIC.md.

The reason for the staged file: auto-writing to MEMORY_SEMANTIC.md
without human review violates the "memory writes are mechanical and
visible" rule. Patterns are a higher-trust artifact (they get applied
to future estimates) so they should pass through human review even
when extraction is mechanical.

#### Output format in MEMORY_SEMANTIC.md

Existing format extended with auto-extraction metadata:

```
### PAT-005: RLS gates run +35% over estimate
Confidence: MEDIUM
Source: 4 gates: v0.2.0, v0.3.0, v0.5.0 of project Forge Finance
Description: Gates whose names or features include row-level security
policies historically run 30-40% over estimate. When a future gate
includes RLS work, multiply baseline by 1.35.
Last validated: 2026-08-12
Auto-extracted: yes (extract-patterns.sh, run 2026-08-12T10:30:00Z)
Human-reviewed: yes (accepted by user 2026-08-12)
Data points:
  - v0.2.0 estimated=4h actual=5.2h variance=+30%
  - v0.3.0 estimated=6h actual=8.4h variance=+40%
  - v0.5.0 estimated=3h actual=4.0h variance=+33%
```

Existing manually-authored patterns keep working — the new fields
(`Auto-extracted`, `Human-reviewed`, `Data points`) are additive.

#### Effort estimate

- Extension of gate-close-calibration to write a "pattern-data" file: 1h
- extract-patterns.sh script (read MEMORY_CORRECTIONS, parse, group, propose): 3h
- /health --review-patterns flag and conversational acceptance flow: 2h
- Tests in /validate (`tests/11-pattern-extraction.sh`): 2h
- Documentation updates (HOOKS.md, README): 1h

**Total: 8-10 hours.** This is a clean v0.5.0 thrust. No breaking
changes — additive over v0.4.0.

#### Acceptance criteria

- After 5 gates of accumulated data, /health --review-patterns
  proposes ≥1 pattern that the operator agrees is meaningful.
- Auto-extracted patterns include source data point references so
  the operator can audit the inference.
- Existing manually-authored patterns survive untouched.
- Re-runs are idempotent (same input → same proposed output, no
  duplicates).

---

### Thrust 2: Outcomes — task-level success criteria

#### Goal

Today Syntaris's checkpoints fire at gate boundaries (CONFIRMED,
MOCKUPS APPROVED, FRONTEND APPROVED, GO; v0.5.1 retired TESTS APPROVED). Within a
gate, individual tasks succeed or fail without structured criteria.
The circuit breaker (3 failures → /debug) is the only sub-gate
recovery primitive.

Anthropic Managed Agents Outcomes adds: define success criteria for
ONE task, separate grader checks, agent retries up to N. This is a
real gap in Syntaris that isn't fixed by gate-level approval words.

#### Proposed shape

A new file format `OUTCOMES.md` (per-project, written during gate
work, checked at gate close):

```
## OUT-001: Implement /api/budgets endpoint
Gate: v0.4.0
Status: PENDING | PASSED | FAILED | RETRY-1 | RETRY-2
Success criteria:
  - Endpoint returns 200 for authed user with valid input
  - Returns 401 for unauthenticated request
  - Returns 403 for cross-user RLS violation
  - Returns 422 for invalid input
  - Latency p50 < 100ms on local test data
Grader: spec-reviewer subagent reads OUTCOMES.md, runs tests,
        verifies p50 latency, returns PASS/FAIL with reason.
Retries: max 2 retries. After 2 failures, escalate to /debug.
```

The grader runs as a subagent (already a Syntaris primitive). The
retry loop is bounded. Failed outcomes block gate close.

#### Effort estimate

- OUTCOMES.md template: 0.5h
- /testing skill extension to read OUTCOMES.md: 2h
- spec-reviewer extension to act as grader: 2h
- Retry loop logic in build-rules: 2h
- Tests in /validate: 2h
- Documentation: 1h

**Total: ~10 hours.** Could split: ship the template + manual
grading in v0.5.0, automated grader + retry in v0.6.0.

#### Open question

Does this duplicate the testing skill? Probably not — testing tracks
that a test exists and passes; Outcomes tracks that a *behavior* was
verified, which may include latency, security, or correctness checks
beyond what unit tests cover. But there's overlap with /testing's
spec-to-test traceability (v0.4.0). Worth designing carefully so the
two don't fight each other.

---

### Thrust 3: 30-task benchmark

This is deferred from the original v0.5.0 roadmap. Pilot ran in v0.3.0
(one task, three runtimes, one day). Full benchmark is 30 tasks across
3 runs per (runtime × task) condition with audited task selection.

This is research work, not engineering. No code; outcome is a published
results table and a methodology doc.

#### Effort estimate

**~30 hours of operator time** spread across 4-6 weeks, gated on Tier
2 adapter validation (Cursor, Windsurf) being complete first.

#### Open question

Should the benchmark wait for v0.5.0 pattern extraction to be in place
so calibration data has a chance to converge before the comparison
runs? Probably yes — running benchmark on uncalibrated estimates
muddies the signal.

---

## v0.6.0 - Telemetry + /start --quick

### Telemetry

- Cost tracking: which model is being routed for which skill, what's
  the per-skill cost trend
- Stuck-loop guards: detect when the agent is repeatedly editing the
  same file without progress, surface as a warning before the
  context-warn threshold
- Skill invocation patterns: which skills fire most, which never fire,
  which are mis-triggered

Lands as a new hook (`telemetry.sh`/`.ps1`) plus a new skill
(`/telemetry`) for review.

### /start --quick mode

For the user who knows their stack and just wants to scaffold without
the full conversational flow. Skips the competitive landscape research,
uses CONTRACT.md defaults, asks for project name + version + recipe
and hands off to /build-rules. ~2-minute setup vs ~15-minute setup.

---

## v0.7.0 - Calibration evidence

Once v0.5.0 pattern extraction has been running on three different
projects across three different stacks for a few months, the data
should support an auto-generated learning curve: "operator's
estimation accuracy improved from ±50% variance at gate 1 to ±15%
variance at gate 30."

This is the marketing artifact for v1.0.0. Without it, "calibration
loop" is a claim. With it, calibration becomes evidence.

---

## v1.0.0 — Stable API + three-stack calibration

Two preconditions:

1. **Calibration data exists across at least three different stacks.**
   Today only Brian's reference stack (Next.js + FastAPI + Supabase +
   LangGraph) has the Forge Finance 12-gate dataset. Two more stacks
   need similar coverage before the methodology can claim general
   applicability.
2. **API is stable enough to commit to backward compatibility.**
   No more breaking renames. Foundation file schema is locked.
   Hook contracts are locked. Recipe format is locked.

Tentative timeline: late 2026 / early 2027. No commitment.

---

## Candidates pending real-world feedback

Designed and drafted, not yet assigned to a version. Held until
evidence from real-project use of the existing system tells us
whether they're worth building, what they need to do differently
than the current draft, and where they slot in the version arc.

---

### `/mockup` skill — target HTML mockups for project versions

**Status:** drafted 2026-05-07, held pending first real-project /start runs.

**Purpose.** Generate standalone HTML mockup files showing what the
app is being built toward at each version. Not "what the current code
looks like" but "what we're aiming at." Each version in the roadmap
gets its own mockup state. Visual fidelity progresses across versions
so the user can *see* the difference between MVP and polished, not
just read about it in a feature table.

**Design intent.** Two mockups by default at `BUILD APPROVED` time:
v1.0 (the MVP, functional tier) and v-final (the polished build,
polished tier). Intermediate versions interpolate. Output to
`foundation/MOCKUPS/<version>.html` plus a `foundation/MOCKUPS/index.html`
showroom.

**Architecture.** Matches the `/critical-thinker` pattern — main
thread orchestrates, `mockup-agent` subagent does HTML generation,
main thread writes files. Subagent stays read-only.

**Fidelity tiers (drafted):**

- **Wireframe** — v0.x. Light styling, neutral palette, system fonts,
  visible structure. Looks intentionally early.
- **Functional** — v1.0 MVP. Tailwind CDN, real product styling,
  contextual placeholder data. Looks like a shipped product, narrow
  scope.
- **Polished** — v-final. Presentation-quality, refined typography,
  considered visual identity. Looks like something a person would
  pay for.

**Auto + manual invocation:**

- Auto from `/build-rules` after the version table, before
  `BUILD APPROVED`. Default targets: v1.0 + v-final.
- Manual: `/mockup` (regenerate defaults), `/mockup v2.0`
  (specific version), `/mockup all` (every version in roadmap).

**Five things that need to change before this ships:**

1. **`mockup-agent` doesn't exist yet.** Skill delegates to it; first
   invocation fails without it. Build alongside the skill. Tools:
   Read, Glob (read-only). Returns either HTML string or
   `DOMAIN_UNCLEAR: <question>` signal for the main thread to
   handle.
2. **Per-gate `MOCKUPS APPROVED` relationship is ambiguous.** Two
   mockup concepts now: target mockups (this skill, locked at
   BUILD APPROVED) vs per-gate mockups (current /build-rules PHASE 3,
   locked at MOCKUPS APPROVED). The draft only addresses the first.
   Decision deferred: leave per-gate mockups ad-hoc (option A,
   recommended for first ship), or extend `/mockup` to also fire at
   per-gate time (option B, deferred follow-up).
3. **Domain-unclear flow needs explicit handling.** Subagent can't
   ask the user directly. Skill must route the `DOMAIN_UNCLEAR`
   signal back to the main thread, which asks the user, then
   re-invokes with the answer in DOMAIN_CONTEXT.
4. **`/build-rules` needs an explicit `/mockup` invocation step.**
   Between version-table generation and waiting for BUILD APPROVED.
   Without this, auto-invocation never fires.
5. **/validate updates.** Skill count `15 → 16`, agent list adds
   `mockup-agent`, new `tests/13-mockup.sh` covering skill+agent
   presence and build-rules integration.

**Tailwind via CDN (decided).** Single `<script>` tag dependency for
functional/polished tiers. The portability concern is real but
mockups are presentation artifacts, not deployable apps. Hand-written
CSS for offline use would lose 80% of what makes the polished tier
look polished.

**Why held, not shipped.** v0.5.1 is the seventh release of the day
on a system that hasn't been used on a fresh project yet. Claude can
already produce HTML mockups conversationally during /build-rules.
Codifying it as a skill before anyone has felt the friction of the
un-codified version risks building the wrong abstraction. The right
moment to ship `/mockup` is after the first real `/start` run cold
where mockups would obviously help — at that point the design will
be informed by evidence rather than intuition.

**What would unblock shipping:**

- 1+ fresh project taken through `/start` → `/build-rules`
- Concrete observation of where mockups would help, what fidelity
  tier was wanted, what content the subagent needed to know
- Confirmation (or revision) of the auto-invocation point and
  default version set

**Where the draft lives.** Skill text and `mockup-agent` design notes
are in this session's transcript. Full skill markdown ready to paste
into `.claude/skills/mockup/SKILL.md` when the time comes.

---

## Out of scope (intentional)

These have been considered and rejected for v1.0.0:

- **Hosted Syntaris service.** Methodology is portable. Hosting it
  would conflict with the multi-runtime portability claim.
- **Auto-PR generation.** Would require runtime credentials Syntaris
  shouldn't have.
- **Slack/Discord integration.** Out of scope for a methodology layer.
- **Custom IDE extensions beyond what the runtimes already provide.**
  Same reason as hosting.

---

## Tracked gaps from /validate

The /validate skill explicitly does NOT cover:

- Network-dependent tests (web fetches, API calls)
- Tier-2/3 install paths (Cursor, Windsurf, Codex, Aider, Kiro,
  OpenCode adapters) running end-to-end against real harness instances
- Migration script behavior on a real v0.2.0 project structure
- PowerShell-only paths run end-to-end (we test PS1 syntax + the PS1
  calibration hook directly, but full PS1 install round-trip needs
  `verify.ps1` instead)

These are tracked here for v0.5.0+ scope decisions.
