---
name: health
description: "Audits Syntaris installation and project foundation files. Use when checking system integrity, after long breaks from a project, or when the user types /health. The 22-file read happens in an isolated subagent."
---

# HEALTH SKILL - Syntaris v0.5.3
# Invoke: /health  (full audit)
#         /health --review-patterns  (walk through proposed patterns)

## STEP 1: DELEGATE TO HEALTH-AGENT

Invoke the health-agent subagent. It will:
- Read all three memory files (`MEMORY_SEMANTIC`, `MEMORY_EPISODIC`, `MEMORY_CORRECTIONS`)
- Check the 22 standard foundation files
- Audit hook installation (`.git/hooks/commit-msg` for the strip-coauthor content)
- Apply the operational pattern-quality criteria (stale | contradicted | stuck)
- Check research staleness

Wait for its structured report.

## STEP 2: PRESENT THE REPORT TO THE USER

The subagent returns a formatted health report. Show it to the user as-is, then add one line of summary:

> "Overall: <HEALTHY | NEEDS_ATTENTION | UNHEALTHY>. <One sentence on what stands out.>"

## STEP 3: HANDLE FINDINGS

If the report is HEALTHY: stop. Move on.

If NEEDS_ATTENTION or UNHEALTHY, ask the user one question:

> "Want to address any of these now, or just log them and continue?"

For each item the user wants to address, do the work yourself (or hand off to the right skill):
- Stale patterns → ask the user if the pattern still applies; if yes, update `last_validated` in MEMORY_SEMANTIC.md; if no, mark deprecated
- Contradicted patterns → read the contradicting REFLEXION; ask the user which version is correct; update MEMORY_SEMANTIC.md accordingly
- Stuck patterns (low confidence) → consider whether the pattern is actually wrong; either revise it or remove it
- Missing foundation files → create from foundation templates if pre-v0.0.0 expected; investigate if v0.5.0+
- Hook installation broken → run `bash ~/.claude/hooks/strip-coauthor.sh` (via hook-wrapper) to reinstall
- Research stale → invoke `/research` to refresh

## STEP 4: WRITE THE OUTCOME

After addressing the items the user picked, append a one-line entry to `MEMORY_EPISODIC.md`:

```
HEALTH CHECK: <date> - <X items addressed, Y items deferred>
```

Do not let the subagent write this. You write it.

## --review-patterns MODE (v0.5.0+)

When the user invokes `/health --review-patterns`, skip the full audit
and run this flow instead:

### Step A: Read the proposed patterns

Open `.syntaris/proposed-patterns.md`. If it doesn't exist, tell the user
"No proposed patterns yet. Pattern extraction runs at gate close once
there are 5+ ESTIMATION entries in MEMORY_CORRECTIONS.md." Stop.

### Step B: Walk each entry conversationally

For each `### PAT-NNN` block, present the entry to the user and ask:

> "Pattern PAT-NNN proposes [one-sentence summary]. Confidence: [X],
> based on [N] data points. Accept, reject, or edit?"

If accepted:
- Copy the block to `foundation/MEMORY_SEMANTIC.md` under `## PATTERNS`
- Update `Human-reviewed:` field to `yes (accepted by <user> <today>)`
- Confirm with the user

If rejected:
- Skip it. The next extract-patterns run will re-propose if data still
  supports it; the user can reject again.

If edit:
- Ask the user what to change (typically the description text or
  confidence level)
- Apply the edit, then write to MEMORY_SEMANTIC.md as if accepted

### Step C: Clear or preserve the staging file

After all entries are walked through:

- If at least one was accepted, the staging file's contents are now in
  MEMORY_SEMANTIC.md. Leave the staging file in place so the user can
  re-read it; it will be overwritten on next extract-patterns run.
- If everything was rejected, no harm done; staging file stays.

### Step D: Log the review

Append to MEMORY_EPISODIC.md:
```
PATTERN REVIEW: <date> - <X accepted, Y rejected, Z edited> from <N proposals>
```

## RULES

- The subagent is read-only. It returns findings; you decide whether to act.
- If the subagent reports something the user disagrees with (e.g., "this pattern is stale" but the user says it's still validated), do not overrule the subagent silently. Update the pattern's `last_validated` date in MEMORY_SEMANTIC.md to reflect the user's confirmation. Next health check will see the fresh date.
- Never bypass the subagent. Reading 22 files in the main thread is the noise this refactor was designed to eliminate.
- If the subagent fails or times out, fall back to a minimal manual check: just verify the three memory files exist and the strip-coauthor hook is installed. Tell the user the full audit needs the subagent and propose retry.
