---
name: debug
description: "Structured root cause analysis with a circuit-breaker rule. Use after 3 consecutive failures on the same problem, when the user types /debug, or when diagnosing any persistent error. Heavy reading happens in an isolated subagent."
---

# DEBUG SKILL - Syntaris v0.5.1
# Invoke: /debug or auto-triggered after 3 consecutive failures

## TONE

Debugging is frustrating for the user. The easygoing SME slows down, works the problem methodically, doesn't blame the user, and doesn't pretend to know what they don't know. When a fix works, move on without celebration. When a hypothesis fails, say so and try the next one.

## CIRCUIT BREAKER

Three consecutive failures on the same problem means stop and run this protocol. Do not attempt a fourth variation without going through the steps below. Spraying fixes at an undiagnosed problem wastes time and hides the real cause.

## STEP 1 - GATHER THE PROBLEM STATEMENT

Ask the user to share what's broken. You need at minimum:
- What they expected to happen
- What actually happened (error message, stack trace, log output, observed behavior)
- When it started (after what change, if known)

If they paste a long log or stack trace, that's fine. Do not summarize it before delegating; the subagent will read it.

## STEP 2 - DELEGATE TO DEBUG-AGENT

Invoke the debug-agent subagent. Pass it:
- The problem statement from Step 1
- The full error output / stack trace / log content the user provided
- The relevant files the user named (if any)

The subagent will:
- Check `foundation/ERRORS.md` for prior diagnoses of similar errors
- Grep the codebase, read implicated files, check recent git history
- Form a root-cause hypothesis with confidence rating
- Return a structured diagnosis

Wait for its response. The intermediate file reads and grep output stay inside the subagent; you only receive the final diagnosis.

## STEP 3 - VERIFY THE DIAGNOSIS BEFORE FIXING

A fix applied to the wrong diagnosis is noise. The subagent will return a confidence level (HIGH | MEDIUM | LOW). Apply this rule:

- **HIGH confidence**: present the diagnosis to the user, propose the recommended fix, ask permission, apply it, run the test that demonstrates the fix.
- **MEDIUM confidence**: present the diagnosis, explain the alternative hypotheses the subagent listed, ask the user which they think is most likely given context the subagent doesn't have, then proceed.
- **LOW confidence**: do not propose a code change yet. Surface the evidence gaps to the user. Gather the missing data (running a specific command, reading a specific file the subagent didn't have access to, asking the user a specific question), then re-invoke the debug-agent with the new evidence.

## STEP 4 - APPLY THE FIX

After the user approves the fix:
1. Make the change.
2. Run the test that demonstrates the bug, verify it now passes.
3. Run the full test suite, verify no regressions.
4. If a test does not exist for the bug yet, write one before considering the fix complete.

## STEP 5 - WRITE THE NEW ERR ENTRY

If the bug was novel (subagent returned `PRIOR_ENTRY: none`), write the new entry to `foundation/ERRORS.md`. The subagent returns a draft `NEW_ERRORS_ENTRY` block; you append it as `ERR-NNN`. Format:

```
## ERR-NNN: <one-line title>
Date: <today>
Symptom: <how it appeared>
Root cause: <what was actually wrong>
Fix: <what was changed>
Prevention: <if a pattern, what would prevent it next time>
```

Do not let the subagent write to ERRORS.md. You write it.

## RULES

- Always check ERRORS.md (via the subagent) before guessing. Re-diagnosing a solved problem wastes time.
- Never let the subagent run write-mode bash commands (no `rm`, no migrations, no installers). The subagent's tools should already be restricted, but verify if its returned EVIDENCE references state changes.
- If the subagent's confidence is LOW, do not pressure it to commit. Gather more evidence and re-invoke.
- If the user wants to skip this protocol and "just try X," remind them of the circuit breaker. Three failures already happened. The fourth variation has no better odds than the first three.
