# Claude Code Target - Tier 1 (Reference)

This is Syntaris's reference runtime. Full enforcement: hooks, skills, agents, memory, all wired correctly.

## Install

```bash
bash ../../install.sh --target claude-code
```

## What this target installs

- All 14 skills to `~/.claude/skills/` or `.claude/skills/`
- All 7 subagents to `~/.claude/agents/` or `.claude/agents/`
- 20 hook scripts + `hooks/hooks.json` for plugin form, `settings.json` for install.sh form
- 22 foundation file templates
- Personal overlay at `~/Syntaris/personal-overlay/`

## Validation

Run `bash verify.sh` after install. Expected: all 14 skills, 20 hook scripts, 7 agents, hooks installed, JSON valid.

## Verified status: COMPLETE
