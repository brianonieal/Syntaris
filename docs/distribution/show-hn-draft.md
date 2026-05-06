<!-- DRAFT. Brian decides if and when to post. Do not send without approval. -->

# Show HN draft - Syntaris v0.3.0

## Title

Show HN: Multi-runtime methodology for AI coding agents (Claude Code, Cursor, Codex, Gemini CLI)

## Body

The problem that started this: AI coding agents forget between sessions. A decision locked down in phase 1 gets silently un-made by the agent in session 4 when it hasn't seen the context. Add a context reset and you can lose days reconstructing state you already had.

Syntaris wraps around the agent to hold project state. Five gated phases (CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED, GO) enforced by shell hooks that block tool calls until each phase is explicitly approved. Three-layer memory (validated patterns, session events, calibration data) that persists across resets. A loop that records predicted vs actual hours at every gate close.

v0.3.0 adds two things. First, multi-runtime support: Claude Code gets full hook enforcement (Tier 1), Cursor and Windsurf get rule-based partial enforcement (Tier 2), Codex CLI, Gemini CLI, Aider, Kiro, and OpenCode get advisory text (Tier 3). The compatibility matrix in the repo names exactly what's enforced where -- I considered claiming parity across all eight, decided overclaiming was the bigger risk.

Second, a client/personal branch: if you're doing freelance work, Syntaris collects billing details at session start and generates invoices at gate close from actual calibration-loop hours. At v1.0.0 it produces three handoff documents. Nothing auto-sends.

Calibration data is single-operator (one production build, 12 gates). v1.0.0 is reserved for three-stack calibration data, which doesn't exist yet. The pilot benchmark in v0.3.0 is one task, three runtimes, one published number -- not a comparison study.

Repo: https://github.com/brianonieal/Syntaris

## Notes

- Avoid "evidence-based" framing in title or body. Past audits flagged it as overclaim.
- Keep body under 250 words. HN posts that read fast get more engagement.
- Don't post during peak hours (10am-12pm EST is the worst); aim for early morning or weekend.
- After posting, don't respond defensively to skeptical comments. Acknowledge limitations honestly.
