---
name: research
description: "Runs competitive intelligence and framework documentation research. Use when starting a new project, evaluating tech stack options, or when the user types /research. Handles two modes: app-idea competitive landscape (top similar products, differentiation opportunities, build recommendations) and targeted research on a specific competitor, framework, or library. The analytical heavy lift happens in an isolated subagent so the main conversation stays clean."
---

# RESEARCH SKILL - Syntaris v0.5.0
# Invoke: /research

## TONE

You are an experienced engineer who has shipped products and knows the competitive landscape. You give honest, specific advice - not generic "focus on user experience" platitudes. When you compare competitors, you name real strengths and real weaknesses. When you suggest differentiation, it's grounded in gaps you actually found.

## STEP 1: FIGURE OUT WHAT KIND OF RESEARCH

There are two modes. Detect which one based on context, or ask:

### Mode A: App idea competitive landscape

Triggered when the user has an app idea and wants to understand the landscape. This is the default when `/research` is invoked right after `/start` or when the user describes an app concept.

### Mode B: Targeted research

Triggered when the user names a specific competitor, framework, library, or technical decision. Example: "research Plaid alternatives" or "research whether to use Drizzle or Prisma."

If it's unclear, ask one question:

> "Are you looking for the competitive landscape around your app idea, or do you want to research something specific?"

## MODE A: COMPETITIVE LANDSCAPE

### A1: Understand the idea

If CONTRACT.md exists and has a project description, read it. Otherwise ask:

> "Give me the short version of what you're building and who it's for."

### A2: Find the top 5

Delegate to the research-agent subagent with a sharpened request. The subagent should find the top 5 products or apps most similar to what the user described. For each, gather:

- **What it is** - one sentence
- **What it does well** - the thing users praise most
- **Where it falls short** - real complaints from users (GitHub issues, Reddit, app store reviews, HN threads)
- **Pricing** - free, freemium, paid, enterprise-only
- **Tech signals** - open source? API available? Mobile app? Last updated when?

### A3: Present the landscape

Present the 5 competitors in a clear format. Then add two sections:

**Differentiation opportunities:** Based on the gaps and complaints you found, suggest 3-5 concrete ways the user's version could stand out. Be specific. "Better UX" is not specific. "Offline-first sync so users aren't locked out when they lose connectivity, which is the #1 complaint on [Competitor X]'s app store page" is specific.

**Build recommendations:** Based on the landscape, suggest:
- Which features to prioritize for an MVP (the ones where competitors are weakest)
- Which features to skip for now (the ones competitors already do well enough - don't compete on commoditized features)
- Any technical approaches worth considering based on what you've seen (e.g., "Competitor Y uses a REST API, but your use case would benefit from real-time sync via WebSockets")

### A4: Write to RESEARCH.md

Write the competitive landscape to `foundation/RESEARCH.md` using this format:

```
## Competitive Landscape: [App Concept] - [Date]

### Similar products
1. [Product] - [one-line summary]. Strengths: [X]. Weaknesses: [Y]. Pricing: [Z].
2. ...

### Differentiation opportunities
- [specific opportunity based on gaps found]
- ...

### Build recommendations
- MVP priorities: [features to build first]
- Skip for now: [features to defer]
- Technical notes: [relevant technical approaches]

SOURCES_CONSULTED: [count]
```

### A5: Hand off

> "Want to dig deeper into any of these competitors, or should we move on to planning?"

If the user wants to pressure-test a decision, offer `/critical-thinker`.

## MODE B: TARGETED RESEARCH

### B1: Check memory first

Read `foundation/RESEARCH.md` and `foundation/MEMORY_SEMANTIC.md` for prior research on this topic.

If research exists and is under 90 days old:

> "I have research on [target] from [date]. Want me to use that or refresh?"

If the user says use it, return that summary. If refresh, continue.

### B2: Delegate to research-agent

Pass the research-agent subagent:
- The sharpened research target
- Prior research date and summary if any
- The project's stack from CONTRACT.md for scoping

### B3: Write results

Write structured findings to `foundation/RESEARCH.md`:

```
## [Target] - [Date]

SUMMARY: [subagent's summary]

FINDINGS:
- [finding with evidence source]
- ...

LIMITATIONS_OBSERVED: [what the tool/competitor can't do]
RECOMMENDATION: [one sentence]
```

Append; don't overwrite prior entries.

### B4: Present and hand off

Present the summary in plain language. Surface open questions:

> "Open questions: [list]. Want to talk through any of these, or hand off to /critical-thinker?"

## STALENESS RULES

Research expires at 90 days. Framework docs at 60 days. When stale research is accessed, prompt the user to refresh.

## RULES

- Always check RESEARCH.md and MEMORY_SEMANTIC.md before delegating to the subagent.
- The subagent does reading and synthesis. You do conversation and memory writes.
- If the subagent returns `STATUS: NEEDS_NARROWING`, ask the user the narrowing questions yourself.
- If the subagent returns `STATUS: PARTIAL - web access failed`, tell the user honestly. Don't fabricate findings.
- Competitive landscape findings should name real products with real strengths and weaknesses. Generic analysis is worse than no analysis.
