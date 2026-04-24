# Blueprint v11

**An AI app building methodology for Claude Code - with an optional skills-only bundle for claude.ai.**

Blueprint is not a library or a plugin. It's a set of files that tell Claude how to behave when building software. It solves one problem: AI coding tools are fast but inconsistent. They forget decisions between sessions, skip tests, ignore architectural rules, and produce work that regresses without warning.

Blueprint fixes this with:
- **Memory that persists** across sessions and projects (MEMORY_SEMANTIC, EPISODIC, CORRECTIONS)
- **Gate-by-gate structure** that prevents regressions (5 approval words, sequential gates)
- **Layered enforcement** - mechanical hooks at the shell level, advisory rules in CLAUDE.md
- **Quality checks** at every gate close (tests, security, visual verification)
- **A business layer** for freelance work (billing, onboarding, client handoff)
- **A research agenda** for academic work (three self-contained studies)

---

## Which install path is right for you?

Blueprint works on three surfaces. They are not equivalent - each has a different capability ceiling, and the installer is different for each.

### Option A - Desktop Claude Code (Mac or PC) - full Blueprint

Gets you: 17 skills, 9 hooks + 1 wrapper, 3 subagents, 23 foundation templates, MCP servers, memory network, mechanical enforcement of test-before-code and dangerous-command blocking.

```bash
# Mac / Linux
./install.sh

# Or with personalization:
./install.sh --personal-config ./personal-overlay/owner-config.md
```

```powershell
# Windows PowerShell
.\install.ps1

# Or with personalization:
.\install.ps1 -PersonalConfig '.\personal-overlay\owner-config.md'
```

> **Windows users:** v11.4 was audited under PowerShell 7.4, which
> exercised every `.ps1` file through the parser plus direct hook
> execution. PowerShell 5.1 (the default shell on Windows 10/11) is
> not independently verified - PS 7 catches most issues but has a
> few behavioral differences from PS 5.1. If `install.ps1` or
> `verify.ps1` fails on your machine, please open an issue with
> `verify.ps1 -VerboseMode` output attached so we can close the gap.

Then in Claude Code: `/start`.

### Pre-built zip

If you want the packaged distributable zip (what the installer reads when `--zip` is passed), grab it from `dist/blueprint-v11.4.zip` in this repo.

### Verifying the install worked

Both installers automatically run a verification pass at the end - four layers of checks covering files present, structural validity (JSON parses, YAML frontmatter well-formed), execution readiness (permissions, dependencies), and functional smoke tests (SessionStart JSON shape, `rm -rf /` actually blocks with exit 2, safe commands pass through).

```bash
./verify.sh      # Mac / Linux / WSL
.\verify.ps1     # Windows
```

See `TROUBLESHOOTING.md` and `MIGRATION.md` for recovery and upgrade guides.

### Option B - Claude.ai mobile app or claude.ai web - skills only

Gets you: the 17 skills, uploadable one-by-one through Claude.ai Settings -> Features -> Skills.

```bash
./build-skills-bundle.sh       # Mac / Linux
.\build-skills-bundle.ps1      # Windows
```

### Option C - Drive desktop Blueprint from a phone

If you install Option A on your desktop, the Claude iOS/Android app can drive that session via Claude Code Remote Control.

---

## The five approval words

1. **SCOPE CONFIRMED** - App description, build type, and full roadmap approved
2. **MOCKUPS APPROVED** - Screen mockups approved
3. **FRONTEND APPROVED** - Static implementation of mockups approved
4. **TESTS APPROVED** - Test plan and coverage targets approved
5. **GO** - Per-gate approval to build this specific gate

---

## Default stack

Next.js 14+ App Router, FastAPI Python 3.11, Supabase (Postgres + pgvector), LangGraph, LiteLLM, Voyage AI, Vercel, Render. The methodology works with any stack; `foundation/EXAMPLES.md` and `foundation/DEPLOYMENT_CONFIG.md` can be replaced per project.

---

## Repository layout

```
.claude/
  settings.json              -- Hook config, permissions, MCP servers
  skills/                    -- 17 skills (loaded on demand by Claude Code)
  hooks/                     -- 20 scripts (9 hooks + 1 wrapper, bash + PowerShell)
  agents/                    -- 3 subagents for isolated review tasks
claude-skills/               -- Source copies for building the claude.ai bundle
foundation/                  -- 23 project template files
personal-overlay/            -- Optional personalization overlay
dist/                        -- Prebuilt distribution zip
install.sh / install.ps1     -- Desktop Claude Code installers
uninstall.sh / uninstall.ps1 -- Clean removal
verify.sh / verify.ps1       -- Post-install verification
collect-diagnostics.sh / .ps1
build-skills-bundle.sh / .ps1
TROUBLESHOOTING.md
MIGRATION.md
CHANGELOG.md
LICENSE
```

---

## License

MIT
