# Cursor Target - Tier 2 (Partial Enforcement)

Cursor loads Syntaris as `.cursor/rules/` files plus auto-applied context. No hooks. Approval words gate skill behavior via rule injection.

## Install

```bash
bash ../../install.sh --target cursor
```

## What this target installs

- `.cursor/rules/syntaris-core.mdc` - methodology + skills as Cursor rules
- `.cursor/rules/syntaris-billing.mdc` - billing skill (loaded if PROJECT_TYPE: client)
- `.cursor/agents/ecc-syntaris-*.md` - translated agent definitions
- `foundation/*.md` - same foundation templates as Tier 1
- No hook installation (Cursor doesn't support PreToolUse-style blocking)

## Adapter logic

The install script reads canonical SKILL.md files from `.claude/skills/` and translates them into Cursor's `.mdc` format with appropriate `globs:` and `alwaysApply:` frontmatter. Translation logic in `targets/cursor/translate-skills.sh`.

## Validation

Open Cursor in a Syntaris project and prompt: "What gates does Syntaris use?" Expected: agent responds with five-phase ladder (CONFIRMED, ROADMAP APPROVED, etc.).

## Verified status: PENDING (BUILD_NEXT.md task)

Install logic complete but unvalidated against live Cursor instance. Validation is the user's responsibility on their machine.
