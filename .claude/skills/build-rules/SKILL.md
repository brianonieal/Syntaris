---
name: build-rules
description: "Invokes the five-phase planning and approval process before any code is written. Use when starting a new app build, when the user types /build-rules, or when a project needs its initial specification. This is a new-project skill; for resuming an existing project, use the start skill instead."
---

# BUILD RULES - Syntaris v0.3.0
# Invoke: /build-rules or auto-triggered at new project start

## THE FIVE PHASES

Planning flows through five sequential checkpoints. Each requires the user
to explicitly type the approval word. No implicit advancement.

```
SCOPE CONFIRMED -> MOCKUPS APPROVED -> FRONTEND APPROVED -> TESTS APPROVED -> GO
```

Phases do what they say:
- **SCOPE CONFIRMED** - we agree on the app, the build type, and the full
  version roadmap through to final
- **MOCKUPS APPROVED** - we agree on visual design
- **FRONTEND APPROVED** - static implementation of mockups is in place and
  reviewed before backend wires in
- **TESTS APPROVED** - test plan and coverage targets approved before
  backend code is written
- **GO** - per-gate approval to proceed with actual coding

If the user proposes scope changes mid-build (adding a feature, dropping
a gate, changing the build type), that is a trigger to re-do
SCOPE CONFIRMED. Do not silently absorb scope changes into the active
gate. Tell the user plainly: "that's a scope change, which means we
redo SCOPE CONFIRMED before we proceed."

## TONE

Throughout these phases, write as an experienced engineer who has built
things like this before and is curious about this specific one. Not a
checklist robot, not a sycophant. An easygoing peer who asks real
questions, explains tradeoffs honestly, and holds the line on the things
that matter.

Good signal: "The stack you're thinking sounds right. One thing I want
to pressure-test - you mentioned a Postgres dependency and also said
you want zero ops overhead. Those are in tension. You okay with paying
for a managed Postgres like Supabase or Neon, or do you want to pick a
simpler data store?"

Bad signal: "Great idea! Postgres is a fantastic choice. Let me ask you
question 4 of 7."

The tone softens the delivery but not the substance. Rules are still
rules. Gates still gate. Bad ideas still get named.

## PHASE 1: SCOPE CONFIRMED

This is where the real thinking happens. The goal is to produce a
foundation (CONTRACT.md, SPEC.md, VERSION_ROADMAP.md) that the rest of
the build can lean on.

### Step 1 - read existing memory

Before asking anything, read MEMORY_SEMANTIC.md. If there are pre-fills
that apply (user's default stack, naming patterns, etc.), use them. Only
ask about things memory cannot answer.

### Step 2 - the dump question

Ask this early (typically question 2 or 3, after a short opener):

> "Dump everything you have on this app. Details, context, half-formed
> ideas, references, competitor URLs, screenshots you like, mockups you
> sketched, napkin notes, a spec doc, anything. The more raw information
> I have, the better I can help you figure out what you're actually
> trying to build. Upload files or paste in whatever you have."

Wait for the user to actually dump. Do not move on until they respond.

### Step 3 - ask the build-type question

Ask this upfront, in the first few questions:

> "What kind of build is this? Three paths:
>
> - **Production / GA** - real users will use this, shipped to the public
>   or sold as a product. Full roadmap through v1.0 with staging and
>   hardening gates included.
> - **Internal** - a tool for you or your team. Real users but not public.
>   Full roadmap through v1.0 Internal with less ceremony around launch
>   hardening.
> - **Exploratory / Prototype** - learning exercise, throwaway, or a
>   sketch to see if something's possible. Roadmap ends when the
>   exploration is complete, typically v0.3 or v0.4."

Record the answer. The final version and gate count come from here.

### Step 4 - clarifying questions (judgment-based, up to 5)

After the dump and build-type answer, identify gaps that matter for the
roadmap. Ask clarifying questions one at a time. Each question must
include a short consequence explanation in user-impact language.

Good example:

> "Are you planning to handle payments yourself or use Stripe? If Stripe,
> we save a gate worth of PCI compliance work but you pay 2.9% per
> transaction. If rolling your own, we need to add security review and
> audit prep to the roadmap, which is usually 2-3 extra gates."

Bad example (too engineer-speak):

> "Stripe integration, custom payment rails, or third-party merchant?"

Cap at 5 clarifying questions. If after 5 there still isn't enough to
build a real roadmap, say plainly:

> "I don't have enough to build a real plan for you yet. Take another
> pass at the dump - even a few more sentences about who this is for
> and what they'll do on day one would help."

That's not a rejection. It's an honest pause. The easygoing SME does
not waste your time or pretend to know things they do not.

### Step 5 - generate the full roadmap

Write VERSION_ROADMAP.md covering v0.0 through the final version for
this build type.

**Roadmap estimate policy:**

- Near-term gates (typically v0.0 through v0.3, or first third of the
  total gate count) get single-number hour estimates.
- Later gates get ranges (e.g. "3-10h") with a one-line note on what
  drives the uncertainty.
- Every gate has: version number, name, one-line goal, estimate (or
  range).
- The final gate is always clearly labeled - `v1.0 Production Live`,
  `v1.0 Internal GA`, or `v0.X Prototype Validated`.

Gate count is judgment-based per app. A simple CLI might be 5 gates
total. A multi-tenant SaaS with payments, auth, and staging might be
14. Use the complexity of the dump, the build type, and the stack to
decide. Name each gate by its user-facing outcome, not by what you did
internally.

**Calibration multiplier:**

Before finalizing estimates, read MEMORY_CORRECTIONS.md for prior
ESTIMATION entries. Compute the median variance across the most recent
10 entries. Apply that multiplier to raw estimates. Default to 2.0x if
fewer than 3 entries exist (conservative starting point grounded in the
general underestimation literature). Record the multiplier used in the
roadmap header so it is visible.

### Step 6 - write CONTRACT.md and SPEC.md

CONTRACT.md is stable project identity: name, owner, stack, banned
items, build type, complexity tier, target users.

SPEC.md is the current-gate detail: what v0.0 covers, current status,
active tasks.

### Step 7 - present and wait

Show the user:
- The CONTRACT summary
- The full roadmap
- Any assumptions you made that they should push back on

Wait for the user to type: **SCOPE CONFIRMED**

If they push back on anything, update and show again. Do not advance
without the exact approval word.

## PHASE 2: MOCKUPS -> MOCKUPS APPROVED

Produce visual design artifacts - wireframes, mockups, reference
screenshots, or a stylistic direction doc. What counts as "mockups"
scales with build type: a prototype might be sketches; a production
SaaS might be a full Figma file or HTML wireframes.

Wait for: **MOCKUPS APPROVED**

## PHASE 3: FRONTEND -> FRONTEND APPROVED

Build the static frontend implementation of the mockups. Routes, pages,
components, navigation, empty states. No backend wire-up yet. This
catches design problems before they become database schema problems.

Wait for: **FRONTEND APPROVED**

## PHASE 4: TESTS -> TESTS APPROVED

Plan the test strategy. Not execute it - that's the `testing` skill's
job. Here we agree on:

- What test runners to use (pytest, vitest, playwright, etc.)
- Coverage targets per layer
- Which critical paths get explicit E2E coverage
- Which failure modes need regression tests from day one

Write TESTS.md with the plan. Show the user. Wait for:
**TESTS APPROVED**

Once approved, the `testing` skill takes over and generates and
enforces tests as gates close.

## PHASE 5: GO (per-gate)

At the start of each gate, recap the gate's goal, the estimate, and
the tasks. Wait for the user to type **GO** before writing code for
that gate. Every gate needs its own GO.

## GATE CLOSE PROTOCOL

When a gate's work is done:

1. Verify all tests for this gate pass
2. Run /security (hook runs anyway at production gate)
3. Run /performance (hook runs anyway at production gate)
4. **Update VERSION_ROADMAP.md for the closing gate.** Edit the row for
   this version: change `Status` from `pending` to `DONE`, and fill in
   `Actual Hours` with the real hours figure (from TIMELOG.md if
   tracked, otherwise from the calibration hook's output in step 9).
   This keeps the roadmap honest about what's done vs. planned. Do NOT
   edit future gate rows here; variance-driven review of future ranges
   is handled in step 9.
5. Update CHANGELOG.md, TIMELOG.md, SPEC.md
6. Write REFLEXION to MEMORY_CORRECTIONS.md (newest first)
7. Update MEMORY_EPISODIC.md gate outcome row
8. Check MEMORY_SEMANTIC.md for pattern updates
9. Append ESTIMATION entry to MEMORY_CORRECTIONS.md using the
   calibration hook:
   ```bash
   ~/.claude/hooks/gate-close-calibration.sh <version>    # Mac/Linux/WSL
   ```
   ```powershell
   & ~/.claude/hooks/gate-close-calibration.ps1 -Version <version>   # Windows
   ```
   The hook reads TIMELOG.md first (preferred) and falls back to git
   commit timestamps with a 2-hour gap filter.

   The hook itself will print a heads-up whenever variance exceeds 30%,
   naming the gate and the variance. Do NOT silently edit approved
   roadmap ranges in response; the approved roadmap is a commitment and
   variance informs *future* new estimates, not retroactive rewrites.
   If the variance pattern is significant, raise it with the user as a
   scope-change candidate (which would re-open SCOPE CONFIRMED).

   IMPORTANT: this step must run BEFORE the snapshot in step 10.
   Otherwise the snapshot captures a stale MEMORY_CORRECTIONS.md
   that is missing this gate's ESTIMATION entry, and a later
   rollback will silently wipe it.

10. Snapshot foundation files for rollback safety (runs AFTER
    calibration):
    ```bash
    mkdir -p .syntaris/snapshots/<version>
    cp CONTRACT.md DECISIONS.md VERSION_ROADMAP.md PLANS.md TESTS.md \
       TIMELOG.md MEMORY_SEMANTIC.md MEMORY_EPISODIC.md \
       MEMORY_CORRECTIONS.md COMPONENT_REGISTRY.md \
       .syntaris/snapshots/<version>/ 2>/dev/null
    ```
    TIMELOG.md is snapshotted alongside MEMORY_CORRECTIONS.md so that a
    rollback restores both sources of calibration data together. Omitting
    TIMELOG causes stale rows for rolled-back gates to linger and inflate
    the actual-hours sum if those gates are re-done.
    Prune snapshots older than the 10 most recent by mtime:
    ```bash
    ls -1t .syntaris/snapshots/ 2>/dev/null | tail -n +11 | \
      xargs -I{} rm -rf .syntaris/snapshots/{}
    ```
11. git add . && git commit && git tag syntaris-gate-<version> &&
    git push origin main --tags
12. **Invoke billing skill if PROJECT_TYPE is client.** Read foundation/CONTRACT.md.
    If `PROJECT_TYPE: client`, hand off to the billing skill (core/skills/billing/SKILL.md).
    The billing skill reads MEMORY_CORRECTIONS.md actual hours, computes invoice line item,
    and prompts the user for invoice generation. If `PROJECT_TYPE: personal`, skip this step.
    If the just-closed gate is the v1.0.0 final gate AND PROJECT_TYPE is client, the billing
    skill also produces three handoff documents in foundation/HANDOFF/.
13. Present gate close checklist with all items checked
14. Wait for next gate's **GO**

## HARD RULES

The rules below are not negotiable regardless of tone. Easygoing voice
does not mean permissive behavior.

- NEVER write code before FRONTEND APPROVED
- NEVER advance a gate without the user typing the exact approval word
- NEVER silently update the approved roadmap based on variance data
- NEVER skip the calibration step at gate close
- NEVER fabricate hours in TIMELOG.md; let the calibration hook read
  real commit data if the user didn't track
- NEVER cap clarifying questions below 5 in a way that produces a bad
  roadmap; better to pause and ask for more info than to guess
