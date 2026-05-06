# Syntaris Compatibility Matrix

This is the single source of truth for what Syntaris can and cannot do on each runtime. If you find a discrepancy between this document and other Syntaris docs, this document is correct.

## Tier definitions

**Tier 1 - Full enforcement.** Hooks block tool calls. Rules auto-apply. Memory writes are mechanical. Subagents have isolated contexts. Approval words trigger PreToolUse/PostToolUse logic. The reference runtime.

**Tier 2 - Partial enforcement.** Rules auto-apply via runtime-native rule systems. No hooks. No subagent isolation. Approval words trigger context injection but cannot block writes. Methodology compliance is rule-driven, not mechanical.

**Tier 3 - Advisory only.** Methodology loads as text the agent reads. No auto-application. No hooks. No subagent isolation. Honor-system enforcement.

## Per-runtime status

| Runtime | Tier | Status (v0.3.0) |
|---|---|---|
| Claude Code | 1 | Reference, fully tested |
| Cursor | 2 | Adapter shipped, runtime validation pending |
| Windsurf | 2 | Scaffold shipped, validation pending |
| Codex CLI | 3 | Scaffold shipped, validation pending |
| Gemini CLI | 3 | Scaffold shipped, validation pending |
| Aider | 3 | Scaffold shipped, validation pending |
| Kiro | 3 | Scaffold shipped, validation pending |
| OpenCode | 3 | Scaffold shipped, validation pending |

## Capability matrix

The matrix below lists what works on each runtime. "Manual" means the user does it themselves; the agent will not auto-apply.

| Capability | Claude Code | Cursor | Windsurf | Codex CLI | Gemini CLI | Aider | Kiro | OpenCode |
|---|---|---|---|---|---|---|---|---|
| Foundation file loading | Auto | Auto | Auto | Manual | Manual | Manual | Manual | Manual |
| Skills auto-trigger | Hook-based | Rule-based | Rule-based | None | None | None | None | None |
| Hook-based tool blocking | Yes | No | No | No | No | No | No | No |
| Memory file persistence | Auto | Auto | Auto | Manual | Manual | Manual | Manual | Manual |
| Subagent isolation | Yes | No | No | No | No | No | No | No |
| Approval word recognition | Hook-enforced | Rule-driven | Rule-driven | Honor system | Honor system | Honor system | Honor system | Honor system |
| Calibration loop (reflexion) | Auto at gate close | Manual at gate close | Manual at gate close | Manual | Manual | Manual | Manual | Manual |
| Personal/client billing | Auto-prompt | Rule-triggered | Rule-triggered | Manual | Manual | Manual | Manual | Manual |
| LSP simulation hook (v0.4.0) | Yes | Possible (TBD) | Possible (TBD) | No | No | No | No | No |
| Mutation testing (v0.4.0) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

## What this means in practice

If you are building on Claude Code (Tier 1), you get the methodology as designed. The hook system mechanically enforces gate transitions, blocks tool calls that would break tests, and writes memory files automatically.

If you are building on Cursor or Windsurf (Tier 2), you get the methodology as auto-applied rules. The agent reads the rules on every relevant file edit. Gate words still work because the rules tell the agent how to behave when it sees them. But there's no hook to mechanically block a bad write - the agent has to choose to obey the rule. In practice, this gets you to roughly 60-70% compliance with the methodology, which is significantly higher than ad-hoc rules but lower than Tier 1.

If you are building on a Tier 3 runtime, you get the methodology as a document the agent reads when it loads project context. Compliance depends entirely on the agent's behavior. Some agents (Codex CLI in particular) are reasonably consistent; others drift more. Plan to verify gate transitions manually rather than trust the runtime to enforce.

## Why we don't claim parity

Past audits of Syntaris repeatedly identified overclaiming as the largest credibility risk. Multi-runtime parity is exactly the kind of claim where overclaiming is tempting and damaging. The honest framing - Tier 1 is the reference, Tier 2 is partial, Tier 3 is advisory - is the framing.

If this matrix shows fewer capabilities than another framework claims for the same runtimes, the difference is honesty about enforcement, not capability. Other frameworks may assert that their methodology "works equally well on all runtimes." The mechanical reality of hook systems, rule auto-application, and subagent isolation says otherwise.

## How to upgrade tiers

You cannot upgrade a runtime's tier. Cursor cannot become Tier 1 because Cursor doesn't have Claude Code's hook system. The tier reflects what the runtime supports, not what Syntaris ships.

What you can do is run Syntaris on multiple runtimes for the same project. Some users use Cursor (Tier 2) for fast iteration on small edits and Claude Code (Tier 1) for gate-bounded build work. The foundation files are runtime-neutral; they sync via git like any other project file.
