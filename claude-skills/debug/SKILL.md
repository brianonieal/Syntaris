---
name: debug
description: "Structured root cause analysis with a circuit-breaker rule. Use after 3 consecutive failures on the same problem, when the user types /debug, or when diagnosing any persistent error."
---

# DEBUG SKILL - Blueprint v11
# Invoke: /debug or auto-triggered after 3 consecutive failures

## TONE

Debugging is frustrating for the user. The easygoing SME slows down,
works the problem methodically, doesn't blame the user, and doesn't
pretend to know what they don't know. When a fix works, move on without
celebration. When a hypothesis fails, say so and try the next one.

## CIRCUIT BREAKER

Three consecutive failures on the same problem means stop and run this
protocol. Do not attempt a fourth variation without going through the
steps below. Spraying fixes at an undiagnosed problem wastes time and
hides the real cause.

## STEP 1 - check ERRORS.md first

Before anything else, read ERRORS.md. Search for the exact error message
or the pattern you are seeing. If there is a match, apply the documented
fix. Do not re-diagnose a problem someone already solved.

## STEP 2 - diagnose root cause

Read the full error output. Not the first line; the full output. Many
errors have the real cause two or three stack frames down.

Classify the error into one of:
- Code error (bug in the source)
- Config error (env var, missing file, wrong path)
- Environment error (wrong versions, missing system dependency)
- Integration error (two parts that used to work are out of sync)

Common patterns worth checking:
- Async/sync mix, missing `await`, wrong import path
- Wrong env var name or format (e.g., `CORS_ORIGINS` expects JSON array,
  not comma-separated string)
- Missing dependency in requirements.txt or package.json
- Migration out of sync with models
- A recent change in one file that broke an assumption in another

## STEP 3 - verify the diagnosis before fixing

A fix applied to the wrong diagnosis is noise. Verify cheaply:

```bash
cat error.log | tail -50
python --version && node --version
printenv | grep <relevant_prefix>
alembic current && alembic history   # if using alembic
```

Only apply a fix once you have evidence for the root cause, not just
a hypothesis.

## STEP 4 - fix and validate

Apply exactly one fix. Run the failing test or command immediately to
verify. Do not apply multiple fixes at once - if something works, you
need to know which change caused it.

If the fix works: move to step 5.
If the fix fails: document what you tried, say so plainly, move to the
next hypothesis.

## STEP 5 - document in ERRORS.md

```markdown
## ERR-[NNN]: [Short title]
Date: [date]
Gate: [vX.X.X]
Symptom: [What the user saw]
Root cause: [What actually caused it]
Fix applied: [Exact fix]
Attempts that failed: [What did not work and why]
Prevention: [How to avoid in future]
```

The "Attempts that failed" field matters. Future sessions will thank
you for documenting the wrong paths as well as the right one.

## KNOWN STACK ERRORS

Seed these into ERRORS.md at project start so the first hit is already
covered:

- **ERR-001: ModuleNotFoundError: No module named 'jose'**
  Fix: Add `python-jose[cryptography]` to requirements.txt.

- **ERR-002: DATABASE_URL asyncpg prefix wrong**
  Fix: Change `postgres://` to `postgresql+asyncpg://`.

- **ERR-003: Co-Authored-By blocks hosting deploy on Hobby plan**
  Fix: The strip-coauthor hook installs a commit-msg hook that removes
  the line automatically. If it's not installed, run
  `bash ~/.claude/hooks/strip-coauthor.sh` once.

- **ERR-004: Alembic autogenerate produces wrong migration**
  Fix: Never use autogenerate without reading the output. Write
  migrations manually and review.

## RULES

- Never attempt a fourth fix variation without running this protocol
- Never skim error output; read it all
- Never apply two fixes at once
- Never skip logging to ERRORS.md; the next session inherits the pain
  otherwise
- Never blame the user for the bug; blame the situation
