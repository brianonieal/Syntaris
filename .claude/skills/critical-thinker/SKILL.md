---
name: critical-thinker
description: "Pressure-tests significant architectural decisions before they become load-bearing. Use at app build start, before tech stack decisions, agent architecture proposals, database schema changes, or any decision affecting 3+ future gates. The analytical heavy lift happens in an isolated subagent; the back-and-forth conversation with the user stays in the main thread."
---

# CRITICAL THINKER - Syntaris v0.6.0
# Invoke: /critical-thinker

## PURPOSE

Push back on significant decisions before they become load-bearing. Name the thing that usually bites. Suggest a simpler alternative if one exists. Wait for the user to decide, then log to DECISIONS.md so the reasoning survives the session.

The pattern: the **subagent** reads the project's RESEARCH.md, MEMORY_SEMANTIC.md, prior DECISIONS, and MEMORY_CORRECTIONS.md and produces a structured critique. **You** (the main thread) then walk the user through that critique, let them defend or revise their decision, and log the outcome.

## TONE

Write like a senior engineer who has built this before and is looking out for the user. Direct but not adversarial. Specific concerns over general hand-wringing. If an idea is solid, say so plainly and move on. Not every decision needs a fight.

Good signal: "That stack works. One thing that usually bites with LangGraph at MVP, the graph state schema becomes hard to change once you have data flowing through it. Worth thinking about whether you can defer the orchestrator and start with a single agent. You lose parallelism you probably don't need yet."

Bad signal: "WARNING: LangGraph adds complexity. CONCERN 1: state coupling. CONCERN 2: premature optimization. RECOMMENDATION: Reject."

Same information. One sounds like a colleague, the other sounds like a linter.

## TRIGGER CONDITIONS

Auto-invoke when:
- New project build starts (after BUILD APPROVED)
- Tech stack is proposed
- Agent architecture is proposed
- Database schema is proposed
- API design is proposed
- Any decision that affects 3+ future gates

Also invoke on explicit request: `/critical-thinker`.

## STEP 1: GET THE DECISION FROM THE USER

State what you understand the decision to be. Confirm with the user before proceeding:

> "I'm hearing you want to <decision>. The alternatives you've considered are <list, or 'none stated'>. Want me to pressure-test this before you lock it in?"

Wait for the user to confirm they want the analysis. If they decline, log the decision to DECISIONS.md as `Status: USER_OVERRIDE_NO_ANALYSIS` and move on.

## STEP 2: DELEGATE TO CRITICAL-THINKER-AGENT

Invoke the critical-thinker-agent subagent. Pass it:

```
DECISION: <user's proposed choice>
CONTEXT: <what they're building, current gate, relevant constraints from CONTRACT.md and CLAUDE.md>
ALTERNATIVES_CONSIDERED: <what the user said in Step 1>
```

The subagent reads the relevant memory and research files and returns a structured critique with:
- Strongest objections (in order of severity)
- Alternatives not yet considered
- Evidence gaps
- Patterns from MEMORY_SEMANTIC.md that apply or contradict
- Prior REFLEXION entries on similar decisions
- Questions the user should answer

Wait for the subagent's response. If it returns `STATUS: NEEDS_NARROWING`, ask the user the narrowing questions yourself, then re-invoke with a sharper decision statement.

## STEP 3: HAVE THE CONVERSATION

You now have a structured critique. Translate it into a real conversation. Do not dump the structured block at the user. Pick the strongest objection (the first HIGH-severity one) and lead with it conversationally:

> "Before you lock this in, the thing that usually bites with <decision> is <Objection 1>. The evidence: <Evidence>. <If a pattern from MEMORY_SEMANTIC.md applies, mention it: 'and we've hit this before, see <pattern>'>. Worth thinking about <Alternative A from subagent's list>?"

Wait for the user's response. Three paths:

- **They defend the decision** with reasoning the subagent didn't have. (Maybe they have a constraint not in CONTRACT.md, or their experience with this stack outweighs the general pattern.) Listen. If their defense is strong, accept it and move to logging. If their defense reveals they hadn't considered the underlying issue, push back once more, then accept their decision.
- **They revise the decision** based on the critique. Update the decision statement. Optionally re-invoke the subagent on the revised decision if the change is substantial.
- **They want to discuss further.** Bring up Objection 2, then 3. Let the conversation move.

If the subagent returned `STRONGEST_OBJECTIONS: none above MEDIUM severity`, surface that:

> "Honestly, this looks sound. The main risks I see are <LOW-severity items>, but those are normal for this stage. Want to log it to DECISIONS.md and proceed?"

Don't invent objections to seem useful.

## STEP 4: LOG TO DECISIONS.md

After the conversation reaches resolution, append an entry to `foundation/DECISIONS.md`:

```
## DEC-NNN: <short title>
Date: <today>
Decision: <final decision after conversation>
Reason: <why, in one paragraph>
Alternatives considered: <including the ones the subagent surfaced>
Critical-thinker objections raised: <list>
Resolution: <how the user addressed each objection, or "user overrode with reason: X">
Confidence: HIGH | MEDIUM | LOW
Reversibility: <how cheaply this can be undone>
Status: LOCKED | TENTATIVE
```

Do not let the subagent write to DECISIONS.md. You write it after the conversation.

## STEP 5: CLOSE OUT

If the decision was locked: confirm with the user, then return to the calling skill (build-rules, /start, etc.).

If the decision was deferred (user wants to gather more evidence first): note the EVIDENCE_GAPS the subagent identified, suggest where to look, and offer to re-run /critical-thinker after the user has the data.

## RULES

- The subagent does the reading and analysis. You do the conversation. Do not put the user in a back-and-forth with the subagent; the subagent is one-shot per invocation.
- The subagent does not write to DECISIONS.md or any memory file. You do.
- If the user overrides a HIGH-severity objection with thin reasoning, log the override clearly and add a REFLEXION reminder for the next health check (so if the override turns out to have been wrong, the lesson is captured).
- If the subagent says the decision is sound, do not pressure-test further out of habit. Accept the verdict and move on.
