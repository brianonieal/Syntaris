# Blueprint v11

An AI app-building methodology for Claude Code, with an optional skills-only bundle for Claude.ai.

Blueprint is not a library or a plugin. It's a set of files that tell Claude how to behave when building software. The problem it addresses: AI coding tools are fast but inconsistent. They forget decisions between sessions, skip tests, ignore architectural rules, and produce work that regresses without warning.

## What's in it

- **Persistent memory** across sessions and projects (`MEMORY_SEMANTIC.md`, `MEMORY_EPISODIC.md`, `MEMORY_CORRECTIONS.md`)
- **Gate-by-gate structure** with five approval words and a reflexion entry written at each gate close
- **Layered enforcement**: mechanical shell hooks at the OS level, advisory rules in `CLAUDE.md`
- **Quality checks** at every gate close (tests, security, visual verification)
- **Freelance business layer** (billing, onboarding, client handoff)

## Status

Early stage. v11.4 is the most exercised path. The methodology is stable. Counts and calibration data are preliminary and based on a small number of runs on a narrow stack.

## Install

Blueprint works on three surfaces. Each has a different capability ceiling.

### Desktop Claude Code (Mac, Linux, or PC) full install

Includes 16 skills, 9 hooks plus 1 wrapper (in both bash and PowerShell), 3 subagents, 22 foundation templates, MCP server configuration, the memory network, and mechanical enforcement of test-before-code and dangerous-command blocking.

```bash
# Mac / Linux
./install.sh
# with personalization
./install.sh --personal-config ./personal-overlay/owner-config.md
```

```powershell
# Windows PowerShell
.\install.ps1
# with personalization
.\install.ps1 -PersonalConfig '.\personal-overlay\owner-config.md'
```

Then, inside your project directory, open Claude Code and run `/start`.

A pre-built distributable zip is available at `dist/blueprint-v11.4.zip`.

### Claude.ai web or mobile app, skills only

Builds a bundle of the 16 skills that you upload one-by-one via Claude.ai Settings > Features > Skills. No hooks or agents on this path.

```bash
./build-skills-bundle.sh       # Mac / Linux
.\build-skills-bundle.ps1      # Windows
```

### Drive a desktop install from a phone

With the full desktop install in place, the Claude iOS or Android app can drive the same session via Claude Code Remote Control.

## Verify

Both installers run a four-layer verification pass at the end: files present, structural validity (JSON parses, YAML frontmatter well-formed), execution readiness (permissions, dependencies), and functional smoke tests (SessionStart JSON shape, `rm -rf /` blocked with exit 2, safe commands pass through).

```bash
./verify.sh      # Mac / Linux / WSL
.\verify.ps1     # Windows
```

See `TROUBLESHOOTING.md` and `MIGRATION.md` for recovery and upgrade.

**Windows note.** v11.4 was audited under PowerShell 7.4. PowerShell 5.1 (the default on Windows 10/11) is not independently verified. If `install.ps1` or `verify.ps1` fails, please open an issue with `verify.ps1 -VerboseMode` output attached.

## The five approval words

1. **SCOPE CONFIRMED**: app description, build type, and full roadmap approved
2. **MOCKUPS APPROVED**: screen mockups approved
3. **FRONTEND APPROVED**: static implementation of mockups approved
4. **TESTS APPROVED**: test plan and coverage targets approved
5. **GO**: per-gate approval to build this specific gate

## Default stack

Next.js 14+ App Router, FastAPI (Python 3.11), Supabase (Postgres with pgvector), LangGraph, LiteLLM, Voyage AI, Vercel, Render. The methodology works with any stack; `foundation/EXAMPLES.md` and `foundation/DEPLOYMENT_CONFIG.md` can be replaced per project.

## Repository layout

```
.claude/
  settings.json              Hook config, permissions, MCP servers
  skills/                    16 skills (loaded on demand by Claude Code)
  hooks/                     20 scripts (9 hooks + 1 wrapper, bash + PowerShell)
  agents/                    3 subagents for isolated review tasks
claude-skills/               Source copies for building the Claude.ai bundle
foundation/                  22 project template files
personal-overlay/            Optional personalization overlay
dist/                        Prebuilt distribution zip
install.{sh,ps1}             Desktop installers
uninstall.{sh,ps1}           Clean removal
verify.{sh,ps1}              Post-install verification
collect-diagnostics.{sh,ps1} Diagnostic bundle generator
build-skills-bundle.{sh,ps1} Claude.ai bundle builder
TROUBLESHOOTING.md
MIGRATION.md
CHANGELOG.md
LICENSE
```

## License

MIT
