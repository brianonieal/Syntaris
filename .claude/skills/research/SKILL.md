---
name: research
description: "This skill runs competitive intelligence and framework documentation research. Use when starting a new project, evaluating tech stack options, or when the user types /research. Checks memory first to avoid redundant searches."
---

# RESEARCH SKILL -- Blueprint v11
# Invoke: /research

## STEP 1: CHECK MEMORY FIRST

Read MEMORY_SEMANTIC.md before searching.
If research on this topic exists and is under 90 days old: use it.
If stale or missing: run Phase A then Phase B.

## PHASE A: COMPETITIVE RESEARCH

Research top 5-10 competitors across:
- Core features and differentiators
- UX patterns and user complaints
- AI/ML tech stack
- Pricing model
- What they are bad at (most important -- find the gaps)

## PHASE B: FRAMEWORK AND LIBRARY RESEARCH

For every technology in the project stack, research:
- Current stable version
- Breaking changes in last 6 months
- Known bugs or gotchas relevant to this project
- Community-recommended patterns

## STALENESS RULES

Research expires at 90 days. Framework notes at 60 days.
Auto-prompt refresh when stale research is accessed.

## CRITICAL THINKER HANDOFF

After research completes, pass findings to /critical-thinker.
