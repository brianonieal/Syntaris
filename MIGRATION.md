# Syntaris Migration Guide

Four paths are covered here.

0. **Upgrading from Syntaris v0.2.0 to v0.3.0** - multi-runtime, personal/client branch, billing skill consolidation.
1. **Coming from a private Syntaris v11.x (Blueprint) install** - what changes, what to back up, what to expect.
2. **Upgrading from Syntaris v0.1.0 to v0.2.0** - subagent migration and plugin manifest.
3. **Re-installing Syntaris over an existing Syntaris install** - what gets clobbered, what survives.

---

## Path 0: v0.2.0 → v0.3.0

The v0.3.0 release is mostly additive (new multi-runtime layer, new recipes, new docs) but two things require active migration: the consolidated `billing` skill and the `CONTRACT.md` field renames.

### What's additive (no action needed)

- Multi-runtime support across 8 targets. If you're on Claude Code, your install continues working as before; the new tier model is just documentation that names what was already the case.
- New `recipes/` hierarchy with starter recipes. Doesn't affect existing projects.
- `docs/COMPATIBILITY.md`. New documentation only.
- Vocabulary reframe in README. No behavioral change.
- Casual coder onboarding mode. Existing projects keep `ONBOARDING_MODE: standard`; only new projects can opt into concise mode.

### What requires action: `billing` skill consolidation

The three v0.2.0 extension skills (`freelance-billing`, `onboard`, `handoff`) have been moved to `archive/v0.2-extensions/syntaris-freelance/` and replaced by a single consolidated `billing` skill in `core/skills/billing/`.

If your v0.2.0 project is a personal project (no client work), no action needed. The `billing` skill won't activate.

If your v0.2.0 project is client work and was using the old extension skills:

```bash
# From the project root, run the migration script
bash scripts/migrate-billing-v0.2-to-v0.3.sh
```

The script:
1. Detects your existing INVOICES.md format (legacy v0.2.0 schema or new v0.3.0 schema).
2. If legacy, prompts for confirmation, then converts entries to the v0.3.0 schema.
3. Reads any client info from old onboarding artifacts and writes a v0.3.0 `foundation/CLIENTS.md`.
4. Updates `foundation/CONTRACT.md`: replaces `CLIENT_TYPE: CLIENT` with `PROJECT_TYPE: client` and `CLIENT_REF: foundation/CLIENTS.md`.

The script is idempotent: running it twice produces the same result as running it once.

### What requires action: CONTRACT.md field renames

Any project on v0.2.0 has these fields in `foundation/CONTRACT.md`:

```
CLIENT_TYPE:           PERSONAL | CLIENT
CLIENT_CODE:           [code] | N/A
```

These are replaced in v0.3.0 with:

```
PROJECT_TYPE:          personal | client
CLIENT_REF:            [link to foundation/CLIENTS.md] | N/A
RECIPE:                [recipe path]
ONBOARDING_MODE:       concise | standard
RUNTIME_TIER:          1 | 2 | 3
```

The migration script handles `CLIENT_TYPE`/`CLIENT_CODE` automatically. The new fields (`RECIPE`, `ONBOARDING_MODE`, `RUNTIME_TIER`) get sensible defaults based on the existing project (`RECIPE: bring-your-own`, `ONBOARDING_MODE: standard`, `RUNTIME_TIER: 1`). You can override after migration.

### Verifying the upgrade

After running the migration script:

```bash
bash verify.sh
```

Expected output: all checks pass, with a note that the project is on v0.3.0.

If verification fails, see `TROUBLESHOOTING.md` section "v0.2.0 to v0.3.0 migration issues."

### Rollback

If migration breaks something, the script leaves a backup at `foundation/CONTRACT.md.v0.2.bak` and `foundation/INVOICES.md.v0.2.bak`. Restore manually:

```bash
mv foundation/CONTRACT.md.v0.2.bak foundation/CONTRACT.md
mv foundation/INVOICES.md.v0.2.bak foundation/INVOICES.md
```

Then continue using v0.2.0. The new v0.3.0 features (multi-runtime, recipes) are mostly additive and don't depend on the field renames.

---

## Path 0a: Syntaris v0.1.0 → Syntaris v0.2.0 (then proceed to v0.3.0)

If you're upgrading from v0.1.0, this is the intermediate stop. After completing this path, run Path 0 above (v0.2.0 → v0.3.0) to reach the current version.

v0.2.0 was purely additive over v0.1.0. Four new subagents, a plugin manifest, and four skills rewritten to delegate to subagents. No breaking changes to file paths, slash command names (in install.sh path), gate model, or memory file format.

### What's new in v0.2.0

- 4 new subagent files in `.claude/agents/`: `research-agent.md`, `debug-agent.md`, `health-agent.md`, `critical-thinker-agent.md`. Total subagents: 7 (was 3).
- New plugin manifest at `.claude-plugin/plugin.json`. Enables `/plugin install syn@brianonieal` distribution path.
- New plugin-form hook bindings at `.claude/hooks/hooks.json`. Used only by the plugin install path; install.sh path still uses `settings.json`.
- The four skills `research`, `debug`, `health`, and `critical-thinker` now delegate their heavy reading to the new subagents. Skill names, slash command invocations, and trigger conditions are unchanged.

### What's not new (in v0.2.0)

- All 16 skill names and slash commands. (Note: v0.3.0 consolidates 3 of these into 1 billing skill, so the v0.3.0 count is 14.)
- All 20 hook scripts.
- All 22 foundation file templates.
- The five-phase gate model.
- The three-layer memory system.
- `settings.json` schema (the install.sh path still uses it).
- The install.sh / uninstall.sh / verify.sh / collect-diagnostics.sh entry points.

### Migration steps (v0.1.0 → v0.2.0)

If you're already on v0.1.0 and just want v0.2.0 as an intermediate:

```bash
cd /path/to/Syntaris
git pull   # or download and extract the v0.2.0 ZIP
bash install.sh   # re-run; clobbers old skills, copies new ones
```

The install is clobber-by-design (see Path 2 below). Your foundation file edits in `~/Syntaris/foundation/` survive. Your project foundation files inside individual project directories are unaffected.

After install, verify:

```bash
bash verify.sh
# v0.2.0 should report 16 skills, 20 hooks, 7 agents
```

If you want to also enable the plugin install path:

```bash
# From within Claude Code:
/plugin install syn@brianonieal
```

You can run with both paths active at once. Slash commands like `/research` invoke the install.sh-installed skill, and `/syn:research` invokes the plugin-installed copy. Both delegate to the same `research-agent` subagent.

### Then proceed to Path 0

After v0.2.0 is installed and verified, follow Path 0 above for v0.2.0 → v0.3.0. That path handles the billing skill consolidation (3 skills become 1) and the CONTRACT.md field renames. After both paths complete, your install will be on v0.3.0 with 14 skills, 20 hooks, 7 agents, and target adapters for 8 runtimes.

### Slash command behavior changes (none for install.sh path)

- `bash install.sh` users: `/research`, `/debug`, `/health`, `/critical-thinker` work exactly as before. Internally, they now delegate to subagents, but the user-visible behavior is the same: ask the user what they need, do the work, return a result, optionally hand off.
- `/plugin install syn@brianonieal` users: same skills are accessible as `/syn:research`, `/syn:debug`, `/syn:health`, `/syn:critical-thinker`. Behavior identical except for the name prefix.

### Why the four skills changed implementation

Before v0.2.0, those four skills did all their reading and synthesis in the main conversation, accumulating context tokens for every file read, every grep result, every web fetch. v0.2.0 moves that work into isolated subagent contexts. Only the structured summary returns to the main thread. For multi-skill sessions, this delays the context warn/hard threshold significantly.

You will notice the change as: the same skills produce the same outputs, but your main conversation stays cleaner across long sessions.

---

## Path 1: Syntaris v11.x (private Blueprint) → Syntaris v0.3.0

Syntaris v0.3.0 is the current public release of what was internally Syntaris v11.4. The methodology, gate model, hook architecture, and three-layer memory are unchanged. What changed is the name, the directory paths, the README's positioning, and a set of audit fixes.

### What's renamed

| Was (Blueprint v11) | Now (Syntaris v0.3.0) |
|---|---|
| `Blueprint v11` | `Syntaris v0.3.0` |
| `~/Blueprint-v11/` | `~/Syntaris/` |
| `BLUEPRINT_VERSION` env var | `SYNTARIS_VERSION` env var |
| `BLUEPRINT_DEBUG` env var | `SYNTARIS_DEBUG` env var |
| `claude-skills/` directory | (deleted) |
| `build-skills-bundle.sh/.ps1` | (deleted) |
| Stderr prefixes like `BLUEPRINT v11 HOOK:` | (removed; plain conversational language) |

### What's unchanged

- The five-phase gate model (`SCOPE CONFIRMED → MOCKUPS APPROVED → FRONTEND APPROVED → TESTS APPROVED → GO`)
- The skill names and purposes that survived to v0.3.0 (note: v0.3.0 has 14 skills total - 3 of v11.x's freelance-billing/onboard/handoff were consolidated into 1 billing skill)
- All 10 hook scripts (per platform), now wrapped through `hook-wrapper.sh/.ps1`
- All 22 foundation templates
- The `.claude/` install root (still `~/.claude/skills/`, `~/.claude/hooks/`, `~/.claude/agents/`)
- `settings.json` schema, matchers, and hook routing

### What's added since v11.x

- 7 subagents (v11.x had 3; v0.2.0 added 4 more)
- Plugin manifest at `.claude-plugin/plugin.json` for `/plugin install` distribution
- Multi-runtime support across 8 harnesses with three enforcement tiers (added in v0.3.0)
- Personal/client branch in `/start` with consolidated `billing` skill (added in v0.3.0)
- Stack-flexible recipe funnel (added in v0.3.0)

### Migration steps

1. **Back up your foundation files.** If you have edits in `~/Blueprint-v11/foundation/`, copy that directory somewhere safe before continuing. The Syntaris installer creates `~/Syntaris/` fresh and does not migrate from `~/Blueprint-v11/`.
2. **Back up your project memory files.** Each Syntaris project has `MEMORY_SEMANTIC.md`, `MEMORY_EPISODIC.md`, `MEMORY_CORRECTIONS.md`, `DECISIONS.md`, etc. inside the project's `foundation/` directory (not the user-global one). These are project-specific and the installer doesn't touch them, but a backup is cheap insurance.
3. **Uninstall Syntaris v11.** From your Syntaris v11 source: `bash uninstall.sh` (or `./uninstall.ps1`). This removes `~/.claude/skills/`, `~/.claude/hooks/`, `~/.claude/agents/`, backs up `~/.claude/settings.json` to `settings.json.bak`, and offers to remove `~/Blueprint-v11/`.
4. **Install Syntaris v0.3.0.** Clone the public repo, run `bash install.sh` (or `./install.ps1`). The installer copies the new artifacts to `~/.claude/` and creates `~/Syntaris/foundation/` from the templates.
5. **Restore your foundation file edits.** Copy any personal edits from your backup into `~/Syntaris/foundation/` for new-project starts. Project-specific foundation files inside individual project directories are unaffected.
6. **Restore settings.json customizations** if any. The installer wrote a fresh `settings.json` and saved your old one as `settings.json.bak` on uninstall. If you had custom MCP servers, custom env vars, or custom permissions, merge them into the new file.
7. **Verify.** Run `bash verify.sh` (or `./verify.ps1`). It checks that all 14 skills, 20 hook scripts, 7 subagents, and `settings.json` are present and structurally valid.

### What if I'm on Syntaris v10 or earlier?

Same migration path. Uninstall the old version, install Syntaris v0.3.0. The internal version differences (v10, v11.0, v11.1, v11.2, v11.3) are documented in the pre-public section of `CHANGELOG.md` for reference, but the installer doesn't care which prior version you had.

---

## Path 2: Re-installing Syntaris over an existing Syntaris install

### Core principle

Syntaris's install flow is **clobber-by-design**. When a re-install detects an existing install, everything under `~/.claude/skills/`, `~/.claude/hooks/`, and `~/.claude/agents/` is removed and replaced with the new version. This is deliberate: it prevents stale files from earlier versions from polluting a newer install.

The tradeoff: any files you personally edited in those directories are overwritten. Syntaris warns you before this happens and requires explicit confirmation (or `--yes` / `-Force` to skip the prompt).

### What gets removed on re-install

Everything under these paths is deleted before the new version is copied:

- `~/.claude/skills/` (all 14 skills)
- `~/.claude/hooks/` (all hook `.sh` and `.ps1` files plus the wrapper)
- `~/.claude/agents/` (all 7 subagents)

`settings.json` is backed up to `settings.json.bak` before being overwritten, so prior custom settings can be recovered by hand if needed.

### What is preserved across re-installs

These are never touched by the installer:

- **Foundation templates** at `~/Syntaris/foundation/`. The 22 starter files for new projects. Your edits here survive re-installs. The installer creates this directory only if it doesn't exist.
- **Project foundation files** inside individual project directories. Each project has its own `foundation/` directory with its own memory files, decisions, version roadmap, etc. The installer never touches project directories.
- **State directory** at `~/.claude/state/` (turn counters, telemetry logs).
- **Personal overlay** at `personal-overlay/owner-config.md` (if you created one).

### How to back up before a re-install

If you've personally edited any installed skill, hook, or subagent:

```bash
# Back up
cp -r ~/.claude/skills ~/.claude/skills.backup-$(date +%Y%m%d)
cp -r ~/.claude/hooks ~/.claude/hooks.backup-$(date +%Y%m%d)
cp -r ~/.claude/agents ~/.claude/agents.backup-$(date +%Y%m%d)
cp ~/.claude/settings.json ~/.claude/settings.json.backup-$(date +%Y%m%d)

# Re-install
cd /path/to/Syntaris
bash install.sh

# After re-install, manually merge anything you want to keep from the backups
```

On Windows / PowerShell:

```powershell
$ts = Get-Date -Format "yyyyMMdd"
Copy-Item -Recurse "$HOME\.claude\skills" "$HOME\.claude\skills.backup-$ts"
Copy-Item -Recurse "$HOME\.claude\hooks" "$HOME\.claude\hooks.backup-$ts"
Copy-Item -Recurse "$HOME\.claude\agents" "$HOME\.claude\agents.backup-$ts"
Copy-Item "$HOME\.claude\settings.json" "$HOME\.claude\settings.json.backup-$ts"
```

### Why clobber instead of merge

Merging is harder than it looks. Skills evolve in subtle ways: a hook script changes its stdin parsing, a skill's frontmatter `description` is rewritten to fix triggering, a subagent's tool list is narrowed. A merge that preserves "your edits" risks keeping the broken pre-fix version of a file Syntaris explicitly fixed. Clobber-and-restore-from-backup is loud but predictable.

If you have a personal pattern you want to preserve across upgrades, the right place for it is your `personal-overlay/owner-config.md` (which the installer reads but never overwrites), or a custom skill in `~/.claude/skills/` that the upstream Syntaris install doesn't ship (the installer only removes skills it knows about, not arbitrary ones - but verify this against `verify.sh`'s skill list before relying on it).

### What to do if a re-install breaks something

```bash
# Roll back to the backup
rm -rf ~/.claude/skills ~/.claude/hooks ~/.claude/agents
mv ~/.claude/skills.backup-YYYYMMDD ~/.claude/skills
mv ~/.claude/hooks.backup-YYYYMMDD ~/.claude/hooks
mv ~/.claude/agents.backup-YYYYMMDD ~/.claude/agents
mv ~/.claude/settings.json.bak ~/.claude/settings.json
```

Then file an issue with the diagnostic bundle from `bash collect-diagnostics.sh`.

---

## Frequently asked

**Q: Will my running Forge Finance / [other v11 project] still work after migrating to Syntaris v0.3.0?**

Yes. Project foundation files are project-local and unaffected. The installed skills, hooks, and subagents in `~/.claude/` are functionally compatible: same gate names, same memory file names, same hook interface. Only the brand strings in stderr messages and comments change.

**Q: Do I need to update `BLUEPRINT_VERSION` env var references in my project scripts?**

If your project shells out to read `$BLUEPRINT_VERSION`, yes - it's now `$SYNTARIS_VERSION`. The settings.json sets the new name. Old projects that hardcoded the old name will see an empty string.

**Q: I have a `~/Blueprint-v11/` directory I edited heavily. Can I keep using it?**

You can leave it on disk; nothing in Syntaris reads it. New projects you start with `/start` will look in `~/Syntaris/foundation/` for templates. If you want your edits to apply to new projects, copy them into `~/Syntaris/foundation/` after install.
