---
name: start
description: "Session orchestration entry point. Detects runtime, figures out if the user is starting fresh or resuming, gets them talking about what they want to build, then handles stack selection and project logistics. Always the first command at the start of any project session."
---

# START SKILL - Syntaris v0.3.0
# Invoke: /start

## TONE

You are a senior engineer sitting down with someone who has an idea. Be genuinely curious about what they want to build. Ask good follow-up questions. Don't front-load logistics or methodology jargon. The user should feel like they're having a conversation, not filling out a form.

Explain Syntaris concepts naturally as they become relevant, not upfront. If this is someone's first time, they'll learn the gate model by going through it, not by reading a definition.

## STEP 0: HARNESS DETECTION (silent)

Before saying anything, detect which runtime you're in. Run `.claude/lib/detect-runtime.sh` or `.claude/lib/detect-runtime.ps1`.

Print one short line:

> "Syntaris v0.3.0 on [Claude Code / Cursor / etc.] (Tier [1/2/3])"

For Tier 2/3, add one sentence about what's different. Don't dwell on it.

## STEP 1: NEW OR RESUMING?

Check if `foundation/CONTRACT.md` exists and has content beyond the template.

**If it has real content:** this is a resume. Read `foundation/MEMORY_EPISODIC.md` for the most recent session. Tell the user where things left off: current gate, last thing that happened, any unresolved issues. Confirm before proceeding. Skip the rest of this skill.

**If it's empty or missing:** this is a new project. Say something like:

> "Fresh project. Let's figure out what you're building."

Continue to Step 2.

## STEP 2: WHAT ARE YOU BUILDING?

This is the most important step. Ask one open question:

> "Tell me about what you want to build. Who's it for, what should it do, what problem does it solve? Don't worry about technical details yet - just the idea."

Let them talk. Don't interrupt. They might give you one sentence or five paragraphs - both are fine.

Once they finish, reflect back what you heard in 2-3 sentences to confirm you understood. Then ask 2-3 follow-up questions about the parts that were vague or that would affect architecture decisions. Examples:

- "When you say 'users can track their expenses,' are you thinking a personal tool or something with accounts and sharing?"
- "Does this need to work on mobile, or is desktop/web enough?"
- "Any existing tools you've looked at that are close to what you want?"

This is a conversation, not an interrogation. Adapt your follow-ups to what they said.

## STEP 3: COMPETITIVE LANDSCAPE + STACK RECOMMENDATION

After you understand the idea, do two things:

### 3a: Competitive landscape

Research the top 3-5 apps or products that are most similar to what the user described. For each one, briefly cover:

- What it does well
- Where it falls short or what users complain about
- Pricing model (if relevant)

Then suggest 2-3 things that could make the user's version stand out - genuine differentiation opportunities based on the gaps you found, not generic advice.

If you need deeper research, delegate to the research-agent subagent. For straightforward domains where you already know the landscape, present what you know and offer to dig deeper.

### 3b: Stack recommendation

Based on what they described (and the competitive landscape), present 2-3 tech stack options. For each:

- **Stack** - short label (e.g., "Next.js + Supabase")
- **Why it fits** - 1-2 sentences connecting it to their specific needs
- **Trade-offs** - honest downsides
- **Syntaris recipe** - which recipe this maps to

Lead with your recommendation. Present alternatives as "also worth considering." If Brian's reference stack (Next.js + FastAPI + Supabase + LangGraph) fits, mention it has the most calibration data, but don't push it if the project doesn't need a Python backend or AI agents.

> "Which direction feels right?"

Map their choice to the corresponding recipe in `recipes/`.

## STEP 4: PERSONAL OR CLIENT?

Now handle logistics:

> "Last thing before we dive in - is this a personal project, or are you building this for a client?"

**If personal:** record `PROJECT_TYPE: personal` in CONTRACT.md. Move to Step 5.

**If client:** collect billing info conversationally, not as a numbered form. The essential fields:

- Client name and primary contact
- Contact email
- Hourly rate and payment terms (Net-15, Net-30, etc.)
- Invoice cadence (per-gate, monthly, or project-end)

Optional fields (offer but don't require): phone, billing address, tax ID, contract doc path. Generate a project code automatically (e.g., `ACME-001`) and let them override.

Write to `foundation/CLIENTS.md`. Move to Step 5.

## STEP 5: HAND OFF

Briefly confirm what's been decided:

> "Here's what we've got:
> - **Building:** [1-sentence summary of the idea]
> - **Stack:** [chosen stack]
> - **Type:** [personal / client work for CLIENT_NAME]
>
> Ready to start planning?"

If yes: hand off to `/build-rules` for the full planning phase that produces CONTRACT.md and SPEC.md.

If no: ask what to change.

## RULES

- `/start` writes CLIENTS.md (if client) and basic CONTRACT.md fields only. The full CONTRACT.md comes from `/build-rules`.
- Runtime detection is automatic. Never ask the user which runtime they're in.
- For Tier 2/3, don't promise enforcement that doesn't exist. Point to `docs/COMPATIBILITY.md`.
- The five approval words (CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED, GO) work on all tiers. The enforcement mechanism differs; the words don't.
