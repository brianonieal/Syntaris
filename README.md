# Syntaris

[![validate](https://github.com/brianonieal/Syntaris/actions/workflows/validate.yml/badge.svg)](https://github.com/brianonieal/Syntaris/actions/workflows/validate.yml)

**v0.4.1** | A compilation-stage knowledge layer and harness engineering implementation for AI coding agents.

Syntaris breaks software projects into five mechanically-gated phases, accumulates structured calibration data across sessions so estimates improve with each gate, and runs across eight AI coding harnesses at three enforcement tiers.

This is a methodology, not a tool. It works on Claude Code with full hook-based enforcement (Tier 1), on Cursor and Windsurf with rule-based partial enforcement (Tier 2), and on Codex CLI / Gemini CLI / Aider / Kiro / OpenCode as advisory text (Tier 3).

---

## What this is

**Syntaris is a compilation-stage knowledge layer.** Foundation files in `foundation/` (CONTRACT.md, DECISIONS.md, MEMORY_*.md, SPEC.md, VERSION_ROADMAP.md, etc.) are compiled artifacts: written once, read many times, updated mechanically at gate close. They give the agent durable state surfaces that survive context resets and `/clear`.

**Syntaris is a harness engineering implementation.** Per OpenAI's Lopopolo (Feb 2026) and Martin Fowler's "Harness engineering for coding agent users" (April 2026), a harness is the system around the model that handles context resets, structured handoff artifacts, phase gates, and verification loops. Syntaris implements all four: shell-hook gates on Claude Code, rule-driven gates on Cursor/Windsurf, advisory gates everywhere else.

**Syntaris is built for two audiences.** If you're building something for yourself, `/start` asks what you want to build, researches the competitive landscape, recommends a stack, and gets to work. If you're building for a client, it adds billing, time-tracking, and invoice generation on top of the same flow.

**Syntaris is opinionated where it has evidence and stack-flexible where it doesn't.** The reference Next.js + FastAPI + Supabase + LangGraph stack ("Brian's reference stack") has 12 gates of calibration data from Forge Finance. Other stacks ship as recipes - populated where I've used them (Next.js + Supabase, Vite + Express, Python CLI), as community-fillable scaffolds where I haven't.

---

## What this is not

**Not a benchmark or evidence-based ranking.** Calibration data is single-operator and applies to the user who logs the reflexion entries. The pilot benchmark in v0.3.0 (one task, three runtimes, one day) is one published number, not a comparison study.

**Not a multi-runtime parity claim.** Tier 1 gets full hook enforcement. Tier 2 gets ~60-70% rule-based compliance. Tier 3 gets honor-system advisory mode. The compatibility matrix in `docs/COMPATIBILITY.md` is the truth source. Other frameworks may claim runtime parity; Syntaris doesn't, because hook systems and rule auto-application differ mechanically across runtimes.

**Not finished.** Public version started at v0.1.0 in May 2026 after private iteration as Blueprint v8 through v11.4. v1.0.0 is reserved for stable API plus three-stack calibration data, which doesn't exist yet.

---

## How this relates to Anthropic's Claude Managed Agents

Anthropic announced three additions to Managed Agents in May 2026: Dreaming (between-session memory hygiene), Outcomes (success-criteria + grader + retry), and Multiagent orchestration (lead splits across specialists). There is real overlap with Syntaris on one of those surfaces, partial overlap on a second, and basically none on the third.

| Managed Agents feature | Overlap with Syntaris | Honest read |
|---|---|---|
| Dreaming | High | Both run reflexion over predicted-vs-actual outcomes. Syntaris fires on **gate close** (structural boundary), Managed Agents on **between sessions** (temporal). Syntaris's ESTIMATION format is numeric and structured; auto-pattern-extraction is on the v0.5.0 roadmap (today the data is collected mechanically, surfacing is human-reviewed). |
| Outcomes | Partial | Syntaris has gate-level approval (binary, manual) and a circuit breaker (3 failures → /debug). Task-level success criteria with automated grading and retry is a real gap, scoped for v0.5.0+ in `BUILD_NEXT.md`. |
| Multiagent orchestration | Already there | Syntaris ships 7 subagents with structured handoff (`research-agent`, `debug-agent`, `health-agent`, `critical-thinker-agent`, `spec-reviewer`, `test-writer`, `security-auditor`). Architecture is sequential delegation, not parallel split. |

**Where Syntaris doesn't overlap.** Managed Agents is locked to Anthropic's runtime. Syntaris ships across eight runtimes at three enforcement tiers, with foundation files as portable compilation-stage artifacts that survive context resets and `/clear`. The five-phase gate model with mechanical approval words and the personal/client billing branch are also outside Managed Agents' scope. The compilation-stage knowledge layer framing (per VentureBeat / Karpathy / Pinecone Nexus) is a different positioning than Managed Agents' "smart agent runtime" framing.

If you're using Managed Agents and only Managed Agents, you may not need Syntaris. If you're working across multiple harnesses, want gate-tied calibration with structured numeric output, or need the personal/client branch, Syntaris is built for that.

---

## How it works

### Five-phase gate model

```
CONFIRMED  →  ROADMAP APPROVED  →  MOCKUPS APPROVED  →  FRONTEND APPROVED  →  GO
    ↓                ↓                     ↓                     ↓                ↓
CONTRACT.md   VERSION_ROADMAP.md    FRONTEND_SPEC.md      Working UI         Ship
SPEC.md       COSTS.md              DESIGN_SYSTEM.md      Screenshots        Tests pass
DECISIONS.md  DEPLOYMENT locked     Components locked     Tests > 0          Deploy
```

On Tier 1 (Claude Code), each arrow is a `PreToolUse` shell hook. The hook exits 2 if the prior phase's exit artifacts are missing or the human approval word has not been entered. On Tier 2, the same logic runs as auto-applied rules without the mechanical block. On Tier 3, it's advisory text the agent reads.

### Three-layer memory

- **`MEMORY_SEMANTIC.md`** - validated patterns across projects with confidence scores
- **`MEMORY_EPISODIC.md`** - session events, gate outcomes, stop events
- **`MEMORY_CORRECTIONS.md`** - predicted-vs-actual reflexion entries, calibration data

Memory persists across `/clear` and sessions. Patterns earn confidence through repeated successful application; they lose it through reflexion entries that contradict them. This pattern is from Reflexion (Shinn et al., NeurIPS 2023) extended to multi-project work.

### Calibration loop

At every gate close, a structured ESTIMATION entry is appended to `MEMORY_CORRECTIONS.md`:

```
ESTIMATION: gate=v0.3.0 estimated=4h actual=6.00h variance=+50% source=timelog errors_open=2 errors_close=4 date=2026-05-06T18:36:19Z
```

Predicted hours come from `VERSION_ROADMAP.md`. Actual hours come from `TIMELOG.md` (preferred) or git commit timestamps (fallback). Error delta comes from counting `ERR-` entries in `ERRORS.md` at session start vs gate close. When variance exceeds 30%, a heads-up message fires and a longer reflexion is required.

The Forge Finance build produced consistent variance data across 12 gates: real hours ran 83-95% under naive raw estimates once Syntaris's pre-decided schemas and managed-SDK adjustments were factored in. That is one project on one stack — calibration of your own builds will produce different numbers.

The data accumulates mechanically. **Pattern extraction from accumulated ESTIMATION data is on the v0.5.0 roadmap** (see `BUILD_NEXT.md`) — today the data is structured but human-reviewed; v0.5.0 auto-surfaces patterns like "RLS gates run +35% over estimate, last 4 gates" into `MEMORY_SEMANTIC.md`.

### What `/start` does

`/start` detects your runtime, checks if you're resuming an existing project, then asks the one question that matters: *what do you want to build?* After you describe your idea, it researches the competitive landscape (top 5 similar products, where they fall short, how yours can stand out), recommends a tech stack with trade-offs, and asks whether this is personal or client work. Client projects get billing fields collected conversationally and automatic invoicing at gate close.

---

## What's in the box

### Multi-runtime tier model

Syntaris runs across eight AI coding harnesses at three enforcement tiers.

| Tier | Runtimes | What works |
|------|----------|-----------|
| 1 - Full enforcement | Claude Code | Hooks block. Skills auto-trigger. Subagent isolation. Memory writes mechanical. Calibration loop runs at gate close. Approval words enforced via PreToolUse. |
| 2 - Partial enforcement | Cursor, Windsurf | Methodology loads as auto-applied rules. No hooks. Approval words trigger context injection but not blocking. Roughly 60-70% compliance per HumanLayer research. |
| 3 - Advisory only | Codex CLI, Gemini CLI, Aider, Kiro, OpenCode | Methodology loads as text the agent reads. No auto-application. Honor-system enforcement. Roughly 50-60% compliance. |

The compatibility matrix in `docs/COMPATIBILITY.md` is the single source of truth on capability per runtime. Other Claude Code frameworks may claim equal support across all runtimes; Syntaris doesn't, because hook systems, rule auto-application, and subagent isolation differ mechanically.

### What ships in v0.4.0

- **15 skills** in `.claude/skills/` covering session orchestration (`start`), build rules (`build-rules`), critical thinking (`critical-thinker`), research (`research`), costs (`costs`), testing (`testing`), security (`security`), performance (`performance`), deployment (`deployment`), debug (`debug`), health (`health`), billing (consolidated), rollback (`rollback`), global rules (`global-rules`), and the new harness validation suite (`validate`, 103 tests)
- **20 hook scripts** in `.claude/hooks/` (10 bash + 10 PowerShell pairs), with the v0.4.0 diagnostic delta in `gate-close-calibration` and `session-start`
- **7 subagents** in `.claude/agents/`: `spec-reviewer`, `test-writer`, `security-auditor`, `research-agent`, `debug-agent`, `health-agent`, `critical-thinker-agent`
- **23 foundation file templates** in `foundation/` covering contract, spec, decisions, memory, costs, components (now with `Test File` column for spec-to-test traceability), frontend spec, design system, examples, etc., plus `CLIENTS.md.template` for client work
- **8 target adapters** in `targets/` (one per supported runtime, with per-target install logic)
- **6 recipe families** in `recipes/`: `web-app-starter` with React/Vue/Svelte/Plain sub-recipes, `api-starter` with TypeScript/Python/Go sub-recipes, `python-cli`, `mobile-starter` with platform sub-recipes, `bring-your-own`, `_template`
- **Runtime detection** at `.claude/lib/detect-runtime.sh` and `.ps1`
- **Compatibility doc** at `docs/COMPATIBILITY.md`
- **Archive** at `archive/v0.2-extensions/` containing the v0.2 `freelance-billing`, `onboard`, and `handoff` skills (now consolidated into the v0.3 `billing` skill, kept here for reference)
- **Install / uninstall / verify / diagnostics** scripts in both bash and PowerShell, all target-aware


---

## Install

### One command (Claude Code)

Open Claude Code and type:

```
/plugin install syn@brianonieal
```

That's it. Then open any project and type `/syn:start`.

### Clone and install (all runtimes)

For the full install with hooks, or if you're using Cursor, Windsurf, Codex CLI, or another supported runtime:

```bash
git clone https://github.com/brianonieal/Syntaris.git
cd Syntaris
bash install.sh       # macOS / Linux
./install.ps1         # Windows
```

The installer auto-detects your runtime and installs accordingly. Then open any project and type `/start`.

To uninstall: `bash uninstall.sh` or `./uninstall.ps1`.

### Which should I use?

| Method | Best for | Slash commands |
|--------|----------|---------------|
| `/plugin install` | Fastest setup, sharing with others | `/syn:start`, `/syn:research`, etc. |
| `install.sh` / `install.ps1` | Full hook enforcement, personal config, non-Claude Code runtimes | `/start`, `/research`, etc. |

Both methods install the same skills, hooks, and agents. You can use both at the same time.

---

## What hooks do

Syntaris hooks fire automatically on Claude Code events. Each one has a single job. The wrapper handles cross-platform fallback so the same `settings.json` works on macOS, Linux, and Windows.

| Hook | Fires on | Job |
|---|---|---|
| `session-start` | session start | Reset turn counter, prep state directory |
| `strip-coauthor` | every Bash command | Install git commit-msg hook that strips `Co-Authored-By: Claude` |
| `enforce-tests` | Write/Edit/MultiEdit | Block writes to source files when tests are failing |
| `block-dangerous` | Bash | Block `rm -rf /`, force pushes to main, destructive SQL, direct prod database access |
| `context-check` | after every tool use | Warn at 80 turns, hard-stop at 120 |
| `pre-compact` | before `/compact` | Write important context to `PLANS.md` so it survives the compact |
| `writethru-episodic` | session stop | Record session events and unfinished tasks to `MEMORY_EPISODIC.md` |
| `gate-close-calibration` | gate close | Write predicted-vs-actual variance entry to `MEMORY_CORRECTIONS.md` |
| `skill-telemetry` | skill invocation | Log which skills fired, when, on what project |
| `hook-wrapper` | all of the above | Try project-local hook first, fall back to user-global, fall back to PowerShell |

Hooks that can block tool calls (exit 2): `enforce-tests`, `block-dangerous`. Everything else exits 0 and only logs or warns.

---

## Subagents

Syntaris ships 7 subagents. The first 3 are gate-close QA helpers (write to specific files, run specific checks). The other 4 are analytical heavy-lifters introduced in v0.3.0 to keep main-thread context clean for the noisiest skills.

| Subagent | Used by | Purpose |
|---|---|---|
| `spec-reviewer` | gate close | Compare FRONTEND_SPEC.md against MOCKUPS.md for compliance |
| `test-writer` | testing skill | Write missing tests for components built this gate |
| `security-auditor` | security skill | Audit code for OWASP-class vulnerabilities |
| `research-agent` | `/research` | Web fetches, RESEARCH.md reads, returns structured summary |
| `debug-agent` | `/debug` | Log parsing, ERRORS.md reads, returns root-cause diagnosis |
| `health-agent` | `/health` | 23-file foundation audit, returns structured report |
| `critical-thinker-agent` | `/critical-thinker` | Reads research and prior decisions, returns structured critique |

**Why the four new subagents matter.** The skills they wrap are the most context-hungry in the system. `/research` does web fetches and reads RESEARCH.md. `/debug` reads ERRORS.md and greps the codebase. `/health` reads up to 22 foundation files. `/critical-thinker` reads RESEARCH.md, MEMORY_SEMANTIC.md, DECISIONS.md, and MEMORY_CORRECTIONS.md. Before v0.3.0 all of that read activity happened in your main conversation, accumulating context until you hit the warn threshold. Now the heavy reading happens inside an isolated subagent and only the structured summary returns to your main thread.

**The architectural rule.** Subagents return structured output. The parent skill writes to memory files. This keeps the reflexion-and-calibration loop coherent in one place (the main thread sees every memory write) while still getting the context-isolation win for the noisy reads.

**Critical-thinker is hybrid.** The conversation back-and-forth (you defend a decision, the skill pushes back, you revise) stays in the main thread because that's where the conversation happens. The analytical critique (reading research, finding patterns, surfacing prior REFLEXION entries) runs in the subagent.

---

## Project structure

```
Syntaris/
  .claude-plugin/
    plugin.json             Plugin manifest (used by /plugin install path)
  .claude/
    skills/                 14 skills, each as <name>/SKILL.md
    hooks/                  20 hook scripts (bash + PowerShell)
    hooks/hooks.json        Hook event bindings (used by plugin path)
    agents/                 7 subagents
    settings.json           Hook event bindings (used by install.sh path)
  foundation/               23 templates (CLAUDE.md, CONTRACT.md, CLIENTS.md.template, MEMORY_*, etc.)
  personal-overlay/         Template for per-user config
  docs/                     HOOKS.md and other reference docs
  install.sh, install.ps1
  uninstall.sh, uninstall.ps1
  verify.sh, verify.ps1
  collect-diagnostics.sh, collect-diagnostics.ps1
  README.md, CHANGELOG.md, MIGRATION.md, TROUBLESHOOTING.md, LICENSE
```

---

## Versioning

Syntaris uses a fresh `0.x` version line. Internal predecessor versions (Syntaris v8 through v11.4) are documented in `CHANGELOG.md` and `MIGRATION.md` for users coming from a private install.

- **v0.1.0** - first public release; README cleanup, security baseline, version reset
- **v0.3.0** - multi-runtime support (8 targets, 3 tiers), personal/client branch, billing skill consolidation, vocabulary reframe, stack-flexible recipes, pilot benchmark
- **v0.4.0** - diagnostic delta in calibration, spec-to-test traceability, `/validate` skill (103 tests), conversational `/start` rewrite, competitive landscape mode in `/research`, README install simplification, install.sh CRLF fix
- **v0.4.1** - wire `/validate` into the methodology: build-rules gate-close integration (Layer 1), GitHub Actions CI on every push (Layer 2), health-agent freshness check via skill-telemetry log (Layer 3). **This version.**
- **v0.5.0** - planned: pattern extraction from MEMORY_CORRECTIONS.md (auto-surface variance patterns into MEMORY_SEMANTIC.md), task-level Outcomes (success criteria + grader + retry within a gate), full 30-task benchmark
- **v0.6.0** - planned: telemetry (cost, model routing, stuck-loop guards) plus `/start --quick` mode
- **v0.7.0** - planned: calibration evidence (auto-generated learning curve from accumulated patterns, populated MEMORY_CORRECTIONS.md example)
- **v1.0.0** - when calibration data exists across at least three different stacks AND the API is stable enough to commit to backward compatibility

---

## License

MIT. See [LICENSE](LICENSE).

## Migration from Syntaris v11.x

If you're coming from a private Syntaris v11 install, see [MIGRATION.md](MIGRATION.md).

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common installation and runtime issues.
