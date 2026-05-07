# Syntaris Subagents Reference

Syntaris v0.4.0 ships 7 subagents in `.claude/agents/`. Three were inherited from v0.1.0; four were added in v0.3.0 to migrate the noisiest skills out of the main conversation context.

This document explains what each one does, what tools it has, what it returns, and the architectural rule that governs how parent skills interact with them.

---

## The architectural rule

**Subagents return structured output. Parent skills write to memory files.**

This is the single most important rule in the v0.3.0 subagent layer. Subagents run in fresh, isolated conversations and do not have access to the main thread's prior context. If a subagent wrote to `MEMORY_SEMANTIC.md` directly, the main thread would not see the write happen, breaking the reflexion-and-calibration loop. So instead:

1. The parent skill (running in the main thread) decides when to delegate to a subagent.
2. The subagent does the heavy reading or analysis in its isolated context.
3. The subagent returns a structured response (the `TARGET:`, `DIAGNOSIS:`, `STRONGEST_OBJECTIONS:`, etc. blocks documented in each subagent file).
4. The parent skill receives the structured response and writes any memory updates itself, in the main thread, where the user and other skills can see them.

Subagents in v0.3.0 are **read-only** with respect to memory files. If you observe a subagent directly writing to `RESEARCH.md`, `ERRORS.md`, `MEMORY_*`, or `DECISIONS.md`, that's a regression and should be reported.

---

## Subagent catalog

### `spec-reviewer` (gate-close QA)

**Used by:** the build-rules skill at gate close, when screens were built this gate.
**Job:** compare `FRONTEND_SPEC.md` against `MOCKUPS.md` and the actual implementation. Reports PASS / DRIFT / MISSING for each component.
**Tools:** Read, Grep, Glob.
**Returns:** a per-component compliance report, no narrative.
**Memory writes:** none. The parent skill decides whether to retry the gate close based on the report.

### `test-writer` (gate-close QA)

**Used by:** the testing skill at gate close.
**Job:** identify components that lack tests and write the missing tests using the project's testing framework (vitest, pytest, jest).
**Tools:** Read, Write, Grep, Glob, Bash.
**Returns:** a list of files written and the tests they contain.
**Memory writes:** the subagent does write test files (since tests are the deliverable, not memory). It does NOT write to `TESTS.md`; the parent does that.

### `security-auditor` (gate-close QA)

**Used by:** the security skill before production deployments and at v1.0.0.
**Job:** audit code for OWASP-class vulnerabilities, especially injection, auth bypass, and secrets-in-code.
**Tools:** Read, Grep, Glob.
**Returns:** structured findings with severity and remediation steps.
**Memory writes:** none. The parent writes to `SECURITY.md`.

### `research-agent` (v0.3.0)

**Used by:** the `/research` skill.
**Job:** perform competitive intelligence and framework documentation research. Web fetches, prior-research checks, multi-source synthesis.
**Tools:** Read, Grep, Glob, WebFetch, WebSearch.
**Returns:** a structured 600-800 word summary with `TARGET`, `SUMMARY`, `FINDINGS`, `LIMITATIONS_OBSERVED`, `RECOMMENDATION`, `OPEN_QUESTIONS` sections.
**Memory writes:** none. The parent writes to `RESEARCH.md`.

**Why it exists:** before v0.3.0, the `/research` skill did web fetches and multi-source reading in the main conversation, accumulating context that the user paid for in token budget across the rest of the session. The subagent contains all that reading.

### `debug-agent` (v0.3.0)

**Used by:** the `/debug` skill (and auto-triggered after 3 consecutive failures on the same problem).
**Job:** read `ERRORS.md` for prior diagnoses, grep the codebase, parse logs, form a root-cause hypothesis with confidence rating.
**Tools:** Read, Grep, Glob, Bash (read-only commands).
**Returns:** a structured diagnosis with `PROBLEM`, `SEVERITY`, `DIAGNOSIS` (direct + underlying cause), `EVIDENCE`, `RECOMMENDED_FIX`, and `NEW_ERRORS_ENTRY` (draft).
**Memory writes:** none. The parent writes the new ERR entry to `ERRORS.md` after the user approves the fix.

**Why it exists:** debug sessions tend to involve many file reads and grep operations. Containing them in a subagent keeps the main thread focused on the conversation about which fix to apply.

### `health-agent` (v0.3.0)

**Used by:** the `/health` skill.
**Job:** audit the project's foundation files (up to 22), the three memory files, the strip-coauthor hook installation, and the pattern quality in `MEMORY_SEMANTIC.md`.
**Tools:** Read, Grep, Glob, Bash (read-only).
**Returns:** a structured health report with sections for Memory Network, Foundation Files, Hook Installation, Pattern Quality, Research Staleness, and an `OVERALL` rating.
**Memory writes:** none. The parent appends a one-line `HEALTH CHECK` entry to `MEMORY_EPISODIC.md` and decides whether to address findings.

**Why it exists:** `/health` reads up to 22 files. That's a lot of context to pull into the main thread for a periodic audit. The subagent reads, summarizes, and returns a fixed-format report.

### `critical-thinker-agent` (v0.3.0, hybrid pattern)

**Used by:** the `/critical-thinker` skill.
**Job:** read `RESEARCH.md`, `MEMORY_SEMANTIC.md`, `DECISIONS.md`, `MEMORY_CORRECTIONS.md`. Produce a structured critique of a proposed decision.
**Tools:** Read, Grep, Glob.
**Returns:** structured `DECISION_UNDER_REVIEW`, `STRONGEST_OBJECTIONS`, `ALTERNATIVES_NOT_YET_CONSIDERED`, `EVIDENCE_GAPS`, `PATTERNS_THAT_APPLY`, `PATTERNS_THAT_CONTRADICT`, `PRIOR_REFLEXION`, `QUESTIONS_FOR_THE_USER` sections.
**Memory writes:** none. The parent has the conversation with the user and writes the resulting `DEC-NNN` entry to `DECISIONS.md`.

**Why it's hybrid:** `/critical-thinker` is fundamentally a back-and-forth: you propose a decision, the skill pressures you, you defend or revise. That conversation belongs in the main thread because that's where the user is. But the analytical work behind the critique (reading research, finding contradicting patterns, surfacing prior reflexion entries) is heavy reading and belongs in the subagent. The skill in v0.3.0 splits the responsibility cleanly: subagent produces critique, main thread runs the conversation.

---

## Patterns the subagent layer enables

### "Subagent for the heavy lift, main thread for the conversation"

This pattern is canonical in `/critical-thinker` and applies whenever a skill needs both deep analysis AND human conversation. The subagent does the analysis once. The parent then runs as many turns of conversation with the user as needed. If the user revises the question substantially, the parent re-invokes the subagent with the sharper input.

Use this pattern for any future skill that needs both depth and interactivity.

### "Check the subagent's confidence before applying"

`debug-agent` returns confidence as HIGH, MEDIUM, or LOW. The parent skill applies different protocols depending:

- HIGH: present diagnosis, ask permission, apply fix.
- MEDIUM: present diagnosis with alternatives, ask the user to choose.
- LOW: gather more evidence first, do not propose code changes.

This prevents the user from accepting a confident-sounding but actually weak diagnosis. Use this pattern wherever a subagent's output drives an action with real cost (code change, deployment, irreversible memory write).

### "STATUS: NEEDS_NARROWING"

When a parent passes the subagent a vague request ("research AI"), the subagent returns `STATUS: NEEDS_NARROWING` plus narrowing questions. The parent then asks the user the questions itself and re-invokes with a sharper input.

This keeps the subagent from guessing. It also keeps the user-facing conversation in the parent skill where it belongs.

---

## When NOT to write a subagent

Subagents add overhead. A skill that only reads 1-2 files and returns a one-paragraph response should run inline in the main thread. The four skills that became subagents in v0.3.0 (research, debug, health, critical-thinker) all share these traits:

- They read at least 5 files (and sometimes 22).
- They invoke external tools (web fetch, grep, bash).
- Their value is the synthesis of many sources, not the conversation about one source.
- They're invoked frequently enough that context accumulation is real.

Skills that don't have all of these traits should stay inline. Adding subagent overhead to small skills produces worse latency without context savings.

---

## Tool restrictions in the plugin form

When Syntaris is installed via the plugin path (`/plugin install syn@brianonieal`), the subagents have one restriction the install.sh form does not: per Anthropic's plugin spec, plugin subagents do not support the `hooks`, `mcpServers`, or `permissionMode` frontmatter fields.

This affects future subagents that need to attach their own hooks or MCP server connections. None of the v0.3.0 subagents use these fields, so the plugin form is fully equivalent for now. Future versions that introduce subagents with these capabilities will need to keep them in the install.sh form or split them into separate distribution.

---

## How to add a subagent

1. Create `.claude/agents/<name>.md` with YAML frontmatter:
   ```yaml
   ---
   name: <name>
   description: <when to invoke; this is what Claude Code matches against>
   model: sonnet
   tools: Read, Grep, Glob   # restrict to what the subagent actually needs
   ---
   ```
2. Write the body as a system prompt for the subagent. It will run in a fresh conversation with no context except this prompt and what the parent passes it.
3. Specify the structured output format the subagent returns. The parent skill needs to know the format.
4. Update the parent skill to delegate to the subagent and write any memory updates itself.
5. Add the subagent name to `verify.sh` and `verify.ps1` agent lists, and bump the count in `install.sh` and `install.ps1` summary.
6. Add the subagent to the README's "Subagents" table and to this file.
7. Bump the version in `.claude-plugin/plugin.json` and `CHANGELOG.md`.
