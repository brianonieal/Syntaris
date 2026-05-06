---
name: start
description: "Session orchestration entry point. Branches between personal and client work, between new-user concise mode and experienced power-user flow, between starting a new project and resuming an existing one. Detects the harness runtime (Claude Code, Cursor, etc.) and announces enforcement tier. Always the first command at the start of any project session."
---

# START SKILL - Syntaris v0.3.0
# Invoke: /start

## TONE

You are the front door of Syntaris. Be welcoming but efficient. A casual coder needs more handholding than a freelance AI engineer who has done this before; the skill detects which they are and adjusts. Don't lecture experienced users. Don't assume casual coders know what gates are.

## STEP 0: HARNESS DETECTION AND TIER ANNOUNCEMENT

Before asking anything, detect which runtime you're operating in. The detection logic lives in `.claude/lib/detect-runtime.sh` (bash) or `.claude/lib/detect-runtime.ps1` (PowerShell). Run it and capture the result.

Possible runtimes:
- `claude-code` (Tier 1, full enforcement)
- `cursor`, `windsurf` (Tier 2, partial enforcement via rules)
- `codex-cli`, `gemini-cli`, `aider`, `kiro`, `opencode` (Tier 3, advisory only)
- `unknown` (fall through to Tier 3 with a warning)

Print one line announcing the detected runtime and tier:

> "Syntaris running on Claude Code - Tier 1 (full enforcement)"
>
> or
>
> "Syntaris running on Cursor - Tier 2 (partial enforcement, hooks unavailable)"
>
> or
>
> "Syntaris running on Codex CLI - Tier 3 (advisory only, no mechanical gate enforcement)"

For Tier 2 and 3, also print a short sentence pointing to `docs/COMPATIBILITY.md` for what's reduced.

## STEP 1: NEW PROJECT OR CONTINUING?

Ask:

> "New project, or continuing an existing one?"

**If continuing:** read `foundation/MEMORY_EPISODIC.md` for the most recent session entry and reconstruct state. Print a summary of where the project left off (current gate, last commit, any unresolved STOP events). Confirm with the user before proceeding. Skip the rest of this skill.

**If new:** continue to Step 2.

## STEP 2: PERSONAL OR CLIENT?

Ask:

> "Is this a personal project or client work?"

This question gates everything downstream. The answer is recorded in CONTRACT.md as `PROJECT_TYPE: personal` or `PROJECT_TYPE: client`.

**If client:** continue to Step 2a (collect client info before anything else).

**If personal:** skip to Step 3.

### Step 2a: Client information collection

This happens before any project-scope questions. The user is in a billing-and-paperwork mindset; respect that.

Collect the following fields and write them to `foundation/CLIENTS.md`:

1. **Client name** - legal entity or individual name. (Required)
2. **Primary contact** - person you'll communicate with. (Required)
3. **Contact email** - invoice and handoff destination. (Required)
4. **Contact phone** - for urgent issues. (Optional)
5. **Billing address** - for invoices. (Optional but typical)
6. **Tax ID** - EIN, VAT, etc. for cross-border or legal entity work. (Optional)
7. **Project code** - internal short code (e.g., `ACME-001`) for tracking. The skill suggests a default like `<CLIENT-INITIALS>-001` but lets the user override.
8. **Hourly rate** - number in USD. (Required)
9. **Payment terms** - Net-15, Net-30, Net-45, Due-on-receipt, or Custom. (Required)
10. **Invoice cadence** - per-gate, monthly, project-end, or custom. Determines how the `billing` skill behaves.
11. **Contract date** - when work begins.
12. **Signed contract document** - path to file if it exists. (Optional)

Confirm all fields back to the user. Write to `foundation/CLIENTS.md` using the schema documented in `core/skills/billing/SKILL.md`.

Then proceed to Step 3.

## STEP 3: NEW TO SYNTARIS?

Ask:

> "New to Syntaris? (y/n)"

This is the experienced-user-vs-casual-coder branch. The first time someone runs Syntaris, the answer is `y`. Veterans answer `n`.

**If yes (casual coder mode):** for the rest of `/start`, also for the gates that follow, run in **concise mode**: explain each step in 2-3 sentences as it happens, with a "What just happened?" summary after each gate close.

**If no (experienced mode):** assume the user knows the gate model. Skip explanatory sentences. Move faster.

The flag is recorded in `foundation/CLAUDE.md` as `ONBOARDING_MODE: concise` or `ONBOARDING_MODE: standard`. Future sessions read this and behave accordingly.

## STEP 4: WHAT ARE YOU BUILDING?

Ask:

> "What are you building? (web app / API / CLI tool / mobile app / other / specify recipe directly)"

The five options funnel into recipe selection without forcing the user to know stack jargon.

### Option: web app

Default recipe: `web-app-starter`. Then ask follow-up:

> "Frontend framework? (React / Vue / Svelte / Plain HTML)"

Selection loads sub-recipe:
- React → `recipes/web-app-starter/react/`
- Vue → `recipes/web-app-starter/vue/`
- Svelte → `recipes/web-app-starter/svelte/` *(populated by Claude Code build, see BUILD_NEXT.md)*
- Plain HTML → `recipes/web-app-starter/plain/` *(populated by Claude Code build)*

For React, ask one more:

> "Full-stack stack? (Next.js + Supabase / Next.js + FastAPI + Supabase (Brian's reference stack) / Vite + Express / I'll configure manually)"

The "Brian's reference stack" framing is honest about provenance. Casual coders skip it; power users recognize it.

### Option: API

Default recipe: `api-starter`. Follow-up:

> "Language? (TypeScript / Python / Go / Other)"

Sub-recipes load accordingly. Python defaults to FastAPI, TypeScript to Express or Fastify (asked), Go to Gin or Echo (asked).

### Option: CLI tool

Default recipe: `python-cli`. No follow-up - Python CLI is the simplest path. If the user wants a different language, they can pick "specify recipe directly."

### Option: mobile app

Default recipe: `mobile-starter`. Follow-up:

> "Native or cross-platform? (Swift / Kotlin / React Native / Flutter)"

*(Note: mobile sub-recipes are populated by Claude Code build per BUILD_NEXT.md - for v0.3.0 zip release, mobile-starter is a stub.)*

### Option: other

Load `recipes/bring-your-own/`. Tell the user this is the empty recipe - they'll fill in CONTRACT.md fields manually during the interrogation.

### Option: specify recipe directly

List all available recipes (read from `recipes/` directory). Let the user pick by name. This is the power-user escape hatch.

## STEP 5: CONFIRM AND HAND OFF

Confirm the configuration:

> "Setting up Syntaris with:
>   - Project type: [personal | client (CLIENT_NAME)]
>   - Mode: [concise | standard]
>   - Runtime: [DETECTED_RUNTIME] (Tier [N])
>   - Recipe: [RECIPE_NAME] / [SUB_RECIPE_NAME]
>
> Ready to begin interrogation? (y/n)"

If yes: hand off to `/build-rules` for the full interrogation that produces CONTRACT.md and SPEC.md.

If no: ask what to change. Loop back to the relevant step.

## RULES

- **`/start` writes CLIENTS.md and CONTRACT.md (basic fields only).** The full CONTRACT.md is produced by `/build-rules` interrogation. `/start` writes only `PROJECT_TYPE`, `RECIPE`, and (if client) basic client linkage.
- **Concise mode is sticky.** Once set, every subsequent skill invocation in this project reads `ONBOARDING_MODE` from CLAUDE.md and adjusts. The user can change it manually by editing CLAUDE.md.
- **Runtime detection is automatic.** Don't ask the user which runtime they're in. Detect it. If detection fails, fall through to Tier 3 with a warning.
- **For Tier 2 and Tier 3 runtimes, do not promise enforcement that doesn't exist.** Be explicit about what works and what doesn't. The compatibility matrix in `docs/COMPATIBILITY.md` is the truth source.
- **Don't run hooks on Tier 2/3.** The hook scripts assume Claude Code's PreToolUse/PostToolUse model. Other runtimes get rules-based or advisory-only enforcement.
- **The five approval words still work on all tiers.** CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED, GO are case-insensitive matches that gate-aware skills detect. On Tier 1 they trigger hooks. On Tier 2 they trigger rules-based context injection. On Tier 3 they're honor-system. The skill's behavior is the same; the enforcement layer differs.

## CASUAL MODE EXPLANATIONS

When `ONBOARDING_MODE: concise` is set, after every major branch above, print a brief explanation of what just happened. Examples:

After Step 1 ("New project"):
> "We're starting from scratch. Syntaris will walk you through five approval gates before any code is written, then build gate by gate. The point is to catch big decisions before they cost time."

After Step 2 ("Client work"):
> "Because this is client work, we'll collect billing info now. Syntaris will generate invoices automatically at gate close based on actual hours from the calibration loop. You review every invoice before sending."

After Step 4 ("Web app, React, Next.js + FastAPI + Supabase"):
> "You picked Brian's reference stack. This is the most heavily-tested combination in Syntaris. If you're not sure, this is a safe default. You can change later by editing CONTRACT.md."

These explanations are 1-3 sentences each. Don't lecture. The casual coder learns by doing.
