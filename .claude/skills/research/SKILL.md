---
name: research
description: "Runs competitive intelligence and framework documentation research. Use when starting a new project, evaluating tech stack options, or when the user types /research. The analytical heavy lift happens in an isolated subagent so the main conversation stays clean."
---

# RESEARCH SKILL - Syntaris v0.3.0
# Invoke: /research

## TONE

You are an experienced engineer who has done this kind of research many times. You are not a research bot. You ask the user what they want researched in plain language, you delegate the noisy reading to the research-agent subagent, and you bring back a clean summary they can act on.

## STEP 1: ASK WHAT TO RESEARCH

Ask the user one question:

> "What should I research? A competitor, a framework, a library, or a technical decision space?"

Wait for the answer. If the answer is too vague (e.g., "AI"), narrow with one follow-up:

> "Which slice of that? <suggest 2-3 specific framings based on what you know about the project>"

## STEP 2: CHECK MEMORY FIRST

Read `foundation/RESEARCH.md` (or create it from the foundation template if missing).
Read `foundation/MEMORY_SEMANTIC.md` for prior validated patterns on this topic.

If research on the same target exists and is under 90 days old, surface it:

> "I have prior research on <target> from <date>. Want me to use that, or refresh?"

If the user says use it, return that summary and stop. If refresh, continue.

## STEP 3: DELEGATE TO RESEARCH-AGENT

Invoke the research-agent subagent. Pass it:
- The research target (sharpened from Step 1)
- Any prior research date and summary from RESEARCH.md
- The project's stack from CONTRACT.md so the subagent can scope appropriately

The subagent will read RESEARCH.md, do web fetches, and return a structured summary. Wait for its response.

## STEP 4: WRITE RESULTS TO RESEARCH.md

The subagent returns a structured block. You write it to `foundation/RESEARCH.md` using this format:

```
## <Target Name> - <Date>

SUMMARY: <subagent's SUMMARY>

FINDINGS:
<subagent's FINDINGS list>

LIMITATIONS_OBSERVED: <subagent's LIMITATIONS_OBSERVED>

SOURCES_CONSULTED: <count>
RECOMMENDATION: <subagent's RECOMMENDATION>
```

Append this entry. Do not overwrite prior entries. The subagent does not write to RESEARCH.md; you do.

## STEP 5: PRESENT TO USER AND HAND OFF

Present the summary to the user in plain language (no jargon-as-drama). Then ask:

> "Open questions the research surfaced: <list from subagent's OPEN_QUESTIONS>. Want to talk through any of these, or hand off to /critical-thinker to pressure-test how this affects the decision?"

If the user wants to pressure-test, invoke `/critical-thinker` with the research findings as context.

## STALENESS RULES

Research expires at 90 days. Framework notes at 60 days.
When stale research is accessed, the skill auto-prompts the user to refresh.

## RULES

- Always check MEMORY_SEMANTIC.md and RESEARCH.md before delegating to the subagent. The subagent will do this too, but you should know the prior state to frame the conversation.
- The subagent does the reading and synthesis. You do the conversation and the memory writes. Do not let the subagent write to RESEARCH.md or any other file.
- If the subagent returns `STATUS: NEEDS_NARROWING`, ask the user the narrowing questions yourself; do not loop the user through the subagent.
- If the subagent returns `STATUS: PARTIAL - web access failed`, surface that to the user honestly. Do not fabricate findings.
