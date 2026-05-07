# CONTEXT_BUDGET.md
# Syntaris v0.5.0 | Context Budget Management
# Read this when context warning fires or session feels slow

---

## THE PROBLEM

Claude Code has a 200,000 token context window.
A fresh session costs ~20,000 tokens before you type anything
(system prompt + tool definitions + CLAUDE.md load).

Quality degrades at 20-40% capacity (~40,000-80,000 tokens used).
Auto-compaction fires at ~83.5% and is LOSSY - retains only 20-30% of details.
One developer lost 3 hours of refactoring work when compaction erased migration decisions.

Syntaris loads 22 foundation files at session start by default.
This is too heavy. The ALWAYS vs ON DEMAND split fixes this.

---

## FILE LOADING STRATEGY

### ALWAYS LOAD (5 files - load every session)

These 5 files are small, critical, and needed for every decision:

1. CLAUDE.md - rules, identity, coding standards
2. CONTRACT.md - project constraints, tech stack, banned list
3. SPEC.md - current gate, active tasks
4. ERRORS.md - known failure patterns (prevent re-diagnosing solved problems)
5. MEMORY_SEMANTIC.md - patterns and pre-fills (already read at /start)

Total token cost: ~3,000-5,000 tokens. Acceptable.

### ON DEMAND (17 files - load only when that domain is active)

Load these only when Claude Code is actively working in that domain:

| File | Load when... |
|------|-------------|
| VERSION_ROADMAP.md | Discussing gates, timelines, scope |
| PLANS.md | Resuming after context reset |
| DECISIONS.md | Architectural question arises |
| FRONTEND_SPEC.md | Building any UI component |
| DESIGN_SYSTEM.md | Building any UI component |
| COMPONENT_REGISTRY.md | Building any UI component |
| TESTS.md | Writing or running tests |
| COSTS.md | Cost question or gate close |
| SECURITY.md | Security review or gate close |
| PERFORMANCE.md | Performance review or gate close |
| DEPLOYMENT.md | Deploying or configuring CI/CD |
| DEPLOYMENT_CONFIG.md | Configuring external services |
| CONTEXT_BUDGET.md | Context warning fires |
| VISUAL_CHECKS.md | Gate close with screens built |
| CHANGELOG.md | Gate close |
| TIMELOG.md | Gate close or billing question |
| RESEARCH.md | Stack question or new competitor |

Loading ON DEMAND files reduces session start cost by ~60%.

---

## CONTEXT THRESHOLDS

40% (~80,000 tokens): WARNING
  - Context-check hook fires
  - Claude Code warns the user
  - the user should consider saving state soon

50% (~100,000 tokens): ACTION REQUIRED
  - Claude Code stops and instructs the user to save state
  - Do NOT continue building past 50% without resetting

83.5% (~167,000 tokens): AUTO-COMPACT (avoid this)
  - Lossy - 70-80% of details are lost
  - Never let it get here

---

## SAVE AND RESET PROTOCOL

When context warning fires at 40-50%:

### Step 1: Save state to PLANS.md

Claude Code writes current state:
```markdown
## CONTEXT SAVE: [timestamp]
Gate: v[X.X.X] [Gate Name]
Completed this session:
  - [list of files written]
  - [tests passing: X]
Pending tasks (resume here):
  - [ ] [Next specific task]
  - [ ] [Task after that]
Decisions made this session:
  - [Any architectural decisions not yet in DECISIONS.md]
Errors encountered:
  - [Any errors resolved this session not yet in ERRORS.md]
```

### Step 2: Commit everything

```bash
git add .
git commit -m "wip: v[X.X.X] context save - [brief description]"
git push origin main
```

### Step 3: Clear context

Run: /clear (NOT /compact)

/clear = lossless. Wipes the context window. Foundation files reload fresh.
/compact = lossy. Summarizes in memory. Retains only 20-30% of details.

Always use /clear. Never use /compact for important work.

### Step 4: Resume

New session starts. Run /start option 2.
Claude Code reads ALWAYS files + PLANS.md.
Resumes from exact saved position.
Cost of fresh session: ~20,000 tokens. Worth it every time.

---

## LARGE GATE SPLITTING

If a gate is estimated at 2+ hours actual time, split it into sub-gates.

Pattern:
  v0.5.0-A: Backend only (agents, API endpoints, database queries)
  v0.5.0-B: Frontend only (screens, components, charts)

Each sub-gate gets:
  - Its own /clear cycle if needed
  - Its own REFLEXION entry
  - Its own git commit

This prevents context collapse mid-gate on complex builds.

---

## /context-check COMMAND

Run this command anytime to get a precise context reading:

```bash
# In Claude Code terminal
/context-check
```

Output: current token usage, estimated percentage, recommendation.

Also available as slash command: add context-check.md to .claude/commands/

---

## HOOK-READABLE THRESHOLDS

The following block is parsed by `.claude/hooks/context-check.sh` and
`.claude/hooks/context-check.ps1` at runtime. Edit these values to change
when the warnings fire for this specific project. Keep the format exactly
as shown: a bare `KEY: value` line, one per line, case-sensitive keys.

```syntaris-context-thresholds
WARN_TURNS: 80
HARD_TURNS: 120
```

If this file is absent, unreadable, or the block is malformed, the hook
falls back to its hardcoded defaults (80 warn, 120 hard). Override via
environment variable (`CONTEXT_WARN_TURNS`, `CONTEXT_HARD_TURNS`) takes
precedence over file values.
