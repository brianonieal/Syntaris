# Syntaris Multi-Runtime Targets

Syntaris is built for Claude Code (Tier 1, full enforcement), and ships adapter scaffolds for seven other AI coding harnesses at reduced enforcement tiers.

## Tier model

The tiers reflect what each runtime can actually enforce, not marketing optimism.

### Tier 1 - Full enforcement
**Targets:** Claude Code

The reference runtime. Shell hooks block dangerous commands and enforce tests-before-code at the tool-call level. Memory writes are mechanical. Approval words trigger PreToolUse/PostToolUse logic. Subagents have full SubagentStop semantics. The calibration loop runs every gate close. This is what Syntaris was designed for, and where the methodology has the strongest evidence.

### Tier 2 - Partial enforcement
**Targets:** Cursor, Windsurf

These runtimes load methodology as rules + auto-applied context (Cursor's `alwaysApply`, Windsurf's frontmatter) but do not have a hook system equivalent to Claude Code's. Approval words trigger context injection through rules files rather than tool-call blocking. HumanLayer research suggests advisory-only methodology achieves 60-70% compliance in practice; rules-driven Tier 2 should be slightly higher because the rules can be auto-applied to specific file globs.

What works on Tier 2:
- Foundation files load as project context
- Skills load as auto-applied rules
- The five approval words gate skill behavior (no hook enforcement)
- Memory files persist across sessions
- The calibration loop runs at gate close (manual writes; no PreCompact hook)

What does NOT work on Tier 2:
- Mechanical block on test failures (Cursor doesn't have the hook surface)
- Auto-strip of co-author commit trailers (advisory only)
- PreToolUse danger-blocking
- Subagent isolation (Cursor and Windsurf use single-context model)

### Tier 3 - Advisory only
**Targets:** Codex CLI, Gemini CLI, Aider, Kiro, OpenCode

These runtimes consume methodology as text in CLAUDE.md / AGENTS.md / equivalent. There's no rule auto-application, no hooks, no subagent isolation. The agent reads the methodology when it loads context and is expected to follow it on the honor system. Per HumanLayer research, advisory-only methodology achieves roughly 50-60% compliance.

What works on Tier 3:
- Foundation files load when the agent reads them
- The five approval words are recognized when the user types them
- Memory files can be read and written if the agent chooses to
- The calibration loop's reflexion entries can be written manually

What does NOT work on Tier 3:
- Any mechanical enforcement
- Auto-loading of skills based on triggers
- Hook-blocking
- Reliable cross-session memory (depends on agent behavior)

## Why this honesty matters

It would be more impressive to claim "Syntaris works equally well on all 7 runtimes." It would also be false. Past audits identified that overclaiming is the single biggest credibility risk for Syntaris, and multi-runtime parity is exactly the kind of claim where overclaiming is tempting.

The compatibility matrix below replaces marketing claims with mechanical truth. Users on Tier 2 and Tier 3 get methodology that helps but doesn't enforce; the documentation says so explicitly.

## Compatibility matrix

| Capability | Claude Code | Cursor | Windsurf | Codex CLI | Gemini CLI | Aider | Kiro | OpenCode |
|---|---|---|---|---|---|---|---|---|
| Foundation file loading | Full | Full | Full | Manual | Manual | Manual | Manual | Manual |
| Skills auto-trigger | Full | Partial (rules) | Partial (rules) | None | None | None | None | None |
| Hook-based tool blocking | Full | None | None | None | None | None | None | None |
| Memory file persistence | Full | Full | Full | Manual | Manual | Manual | Manual | Manual |
| Subagent isolation | Full | None | None | None | None | None | None | None |
| Approval word recognition | Hook-enforced | Rule-driven | Rule-driven | Honor system | Honor system | Honor system | Honor system | Honor system |
| Calibration loop (reflexion) | Auto at gate close | Manual at gate close | Manual at gate close | Manual | Manual | Manual | Manual | Manual |
| Personal/client billing | Full (auto-prompt) | Full (rule-triggered) | Full (rule-triggered) | Manual | Manual | Manual | Manual | Manual |

## Per-target details

Each target has its own directory under `targets/<runtime>/` with:

- **`README.md`** - runtime-specific install instructions
- **`adapter.md`** - methodology adaptations (what changes for this runtime)
- **`AGENTS.md` or equivalent** - runtime-native config that loads Syntaris

## Install commands

For Tier 1 (Claude Code):
```bash
bash install.sh --target claude-code
# or
./install.ps1 --target claude-code
```

For Tier 2 (Cursor or Windsurf):
```bash
bash install.sh --target cursor
bash install.sh --target windsurf
```

For Tier 3 (any other supported runtime):
```bash
bash install.sh --target codex-cli
bash install.sh --target gemini-cli
bash install.sh --target aider
bash install.sh --target kiro
bash install.sh --target opencode
```

If no target is specified, the installer auto-detects via `.claude/lib/detect-runtime.sh` and proceeds with that target. To override detection, use the `--target` flag explicitly.

## Status of each adapter

The v0.3.0 release ships:
- **Claude Code adapter:** complete and tested (this is the reference implementation)
- **Cursor adapter:** rules generated, install logic complete; runtime-validation pending (BUILD_NEXT.md task for Claude Code session)
- **Windsurf adapter:** scaffold only; rules generation logic written, runtime-validation pending
- **Codex CLI adapter:** scaffold with AGENTS.md emission; runtime-validation pending
- **Gemini CLI, Aider, Kiro, OpenCode adapters:** scaffolds only; methodology emission tested by Claude Code session

The first task in BUILD_NEXT.md is for Claude Code on the user's machine to install each Tier 2/3 adapter against a real instance of that runtime, validate that the methodology loads correctly, and update each adapter's README with verified status.
