---
name: start
description: "Orchestrates session startup for Blueprint v11 projects. Use at the beginning of every coding session, when resuming work, or when the user types /start."
---

# START SKILL - Blueprint v11
# Invoke: /start

## TONE

This skill is the user's first interaction of a session. Write like an
easygoing engineer who just walked into the room with coffee. Ask the
one question that matters, listen to the answer, then do the right thing.
Don't monologue. Don't narrate your process.

## STEP 1 - read memory network (always)

Read all three memory files in order:
1. MEMORY_SEMANTIC.md - patterns, pre-fills, confidence scores
2. MEMORY_EPISODIC.md - session log, gate outcomes, stop events
3. MEMORY_CORRECTIONS.md - reflexion entries, calibration data

If any file is missing: create it from the foundation template.

## STEP 2 - ask the one question

Ask simply:

> "Hey - we starting something fresh, or picking up where we left off?"

That's it. Wait for the answer. The phrasing can adapt to context but
the substance is the same: new project or continuing?

### If they say new (or equivalent)

Hand off to `build-rules` for the full five-phase interrogation. Don't
try to do the interrogation yourself from this skill; `build-rules` is
where that lives.

For client projects (CONTRACT.md CLIENT_TYPE = CLIENT), also invoke
these skills before handoff to `build-rules`:
- `/research` - competitive intelligence
- `/critical-thinker` - stack pressure-test

For personal or exploratory projects, skip the pre-skills unless the
stack looks unfamiliar or expensive. The easygoing SME does not run
every user through every skill; they read the situation.

After `build-rules` produces a SCOPE CONFIRMED roadmap, invoke the
remaining skills at appropriate times:
- `/costs` - at SCOPE CONFIRMED (before mockups)
- `/testing` - at TESTS APPROVED
- `/security` and `/performance` - before production deploy

### If they say continuing (or equivalent)

Reconstruct project state without ceremony.

1. Read ALWAYS-load files:
   `CLAUDE.md`, `CONTRACT.md`, `SPEC.md`, `ERRORS.md`, `MEMORY_SEMANTIC.md`

2. Read ON DEMAND (only if that domain is active):
   `VERSION_ROADMAP.md`, `PLANS.md`, `DECISIONS.md`, `FRONTEND_SPEC.md`,
   `DESIGN_SYSTEM.md`, `COMPONENT_REGISTRY.md`, `TESTS.md`, `COSTS.md`,
   `SECURITY.md`, `PERFORMANCE.md`, `DEPLOYMENT.md`, `DEPLOYMENT_CONFIG.md`,
   `CONTEXT_BUDGET.md`, `VISUAL_CHECKS.md`, `CHANGELOG.md`, `TIMELOG.md`,
   `RESEARCH.md`

3. Reconstruct state from SPEC.md (current gate), TESTS.md (test
   status), git log (last commit), PLANS.md (pending tasks).

4. Tell the user what you see, conversationally:

   > "Okay - you're on todo-cli, v0.3 in progress. 12 tests passing.
   > Next up on your list: wire the delete command to the DB layer.
   > That still where your head is at?"

   Not a formal checklist. A brief human recap that confirms you
   actually read the state. Wait for confirmation or correction.

5. If you find a STOP EVENT in MEMORY_EPISODIC.md, read PLANS.md first
   and surface what stopped the user last time:

   > "Heads up - last session stopped on a Supabase migration issue
   > that's logged in PLANS.md. Want to pick that back up, or is
   > something else on your mind?"

## STEP 3 - install hooks (every session start)

Run: `bash ~/.claude/hooks/strip-coauthor.sh`

This installs the commit-msg hook if not already present. Silent unless
something goes wrong.

## RULES

- Never start building without confirming current state with the user
- Never skip reading MEMORY_CORRECTIONS.md (it holds calibration data)
- Never load all foundation files at once; use the ALWAYS + ON DEMAND
  split
- If a STOP EVENT appears in MEMORY_EPISODIC.md, read PLANS.md first
  before doing anything else
- Context warning fires at 80 turns; don't ignore it
