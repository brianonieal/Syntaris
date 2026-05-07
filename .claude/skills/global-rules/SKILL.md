---
name: global-rules
description: "This skill defines universal coding standards, communication style, and context management rules for all Syntaris sessions. Referenced by other skills. Use when checking project conventions or when the user types /global-rules."
---

# GLOBAL RULES - Syntaris v0.5.1
# Always referenced by other skills. Invoke: /global-rules

## IDENTITY

I am Claude Code operating under Syntaris methodology.
Owner identity is configured in CONTRACT.md per project.

## CODING RULES

Language defaults:
- Frontend: TypeScript strict mode (never JavaScript)
- Backend: Python 3.11+ with type hints
- Styling: Tailwind CSS with CSS custom property tokens
- Never use any technology on the project's BANNED list in CONTRACT.md

Quality gates (enforced, not optional):
- Tests written before or alongside implementation (never after)
- TypeScript: zero errors, zero `any` types
- Python: ruff clean, mypy passing
- No hardcoded secrets, URLs, or magic numbers

Anti-regression protocol:
- Read the file before editing it
- Make surgical edits, never rewrite entire files unless required
- Run tests after every significant change
- If tests fail after an edit: revert, diagnose, try again

## COMMUNICATION STYLE

- Lead with the answer, never with preamble
- Bold key decisions, use bullets for lists
- Never use em dashes as separators
- Never say "spearheading" or "dogfooding"
- Never say "straightforward" or "honestly"

## GIT RULES

- Commit format: "feat: v[X.X.X] [Gate Name] - [summary]"
- Never commit with Co-Authored-By trailer (hook enforces this)
- Never force push to main without user's explicit instruction
- Always push after gate close

## CONTEXT MANAGEMENT

- Session start: load ALWAYS files only (5 files)
- Load ON DEMAND files only when that domain is active
- At 80 turns: warn user, save state to PLANS.md
- At 120 turns: stop, save state, instruct user to /clear and restart
- Never use /compact for important work; use /clear (lossless vs lossy)

## MEMORY UPDATE RULES

After every gate close:
- MEMORY_CORRECTIONS.md: new REFLEXION entry above previous (newest first)
- MEMORY_EPISODIC.md: gate outcome row added
- MEMORY_SEMANTIC.md: update pattern confidence if gate validated or invalidated
