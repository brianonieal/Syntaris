# Blueprint v11 Migration Guide

This document describes what happens when you re-run `install.sh` or
`install.ps1` over an existing Blueprint install. Read it before
upgrading from one v11.x version to another.

---

## Core principle

Blueprint's install flow is **clobber-by-design**. When a re-install
detects an existing install, everything under `~/.claude/skills/`,
`~/.claude/hooks/`, and `~/.claude/agents/` is removed and replaced
with the new version. This is deliberate: it prevents stale files from
earlier versions from polluting a newer install.

The tradeoff: any files you personally edited in those directories are
overwritten. Blueprint warns you before this happens and requires
explicit confirmation (or `--yes` / `-Force` to skip the prompt).

---

## What gets removed on re-install

Everything under these paths is deleted before the new version is copied:

- `~/.claude/skills/` (all 17 skills)
- `~/.claude/hooks/` (all hook `.sh` and `.ps1` files plus wrappers)
- `~/.claude/agents/` (all 3 subagents)

`settings.json` is backed up to `settings.json.bak` before being
overwritten, so prior custom settings can be recovered by hand if
needed.

## What is preserved across re-installs

These are never touched by the installer:

- **Foundation templates** at `~/Blueprint-v11/foundation/`. These are
  the 23 starter files for new projects. Your edits here survive
  re-install.
- **Source copies** at `~/Blueprint-v11/claude-skills/`. Used by the
  bundle builder for claude.ai uploads.
- **Personal overlay** at `personal-overlay/owner-config.md`. Your
  personal config. If you used `--personal-config` at install time, it
  was merged into the installed skills; that merge is redone at
  re-install against whatever owner-config.md currently contains.
- **Per-project foundation files** inside your actual projects (the
  `CONTRACT.md`, `DECISIONS.md`, `MEMORY_EPISODIC.md`, etc. that each
  project maintains). Blueprint's installer never reaches into project
  directories.
- **Rollback snapshots** at `<project>/.blueprint/snapshots/`. These
  live with the projects, not the install.
- **Hook error logs** in `$TMPDIR` or `$env:TEMP`. These auto-expire
  and are not touched by the installer.
- **Telemetry log** at `~/.claude/state/skill-log.jsonl`. Preserved
  across re-installs so calibration and usage data compound.

---

## Upgrade procedure

**The safe way** (recommended for any version jump):

1. Run `collect-diagnostics.sh` or `collect-diagnostics.ps1` first. This
   captures your current install state including the list of files
   present. If something goes wrong, the diagnostics are a reference
   point.
2. Back up anything you customized. In practice this means:
   - `~/.claude/settings.json` (already gets a `.bak`, but making your
     own copy costs nothing)
   - Any skill files you hand-edited. Usually this is nothing; if you
     know you changed something, copy that file somewhere safe now.
3. Pull the new version. If you cloned the repo, `git pull`. If you
   installed from a zip, download the new zip.
4. Re-run the installer. The installer will detect the existing install,
   show what will be clobbered, and prompt for confirmation.
5. After install, run `verify.sh` / `verify.ps1` manually to confirm
   the new version is healthy.
6. Re-apply your customizations by hand.

**The fast way** (for when you know nothing was customized):

```bash
# Mac / Linux / WSL
./install.sh --yes

# Windows
.\install.ps1 -Force
```

`--yes` / `-Force` skips the clobber confirmation. Use this in CI, in
scripts, or when you have confirmed that no customizations exist.

---

## Uninstalling

If you want to remove Blueprint entirely rather than upgrade:

```bash
# Mac / Linux / WSL
./uninstall.sh

# Windows
.\uninstall.ps1
```

The uninstaller removes the same things the installer would clobber
(`~/.claude/skills/`, `hooks/`, `agents/`, `settings.json`, `state/`)
and restores `settings.json.bak` if present. Foundation templates and
per-project files are preserved.

Use `--dry-run` to see what would be removed without removing it.

---

## Side-specific installs (Windows + WSL)

If you use both native Windows and WSL, Blueprint treats them as two
separate installs with independent state.

- **Windows-side install** lives at `%USERPROFILE%\.claude\` and
  `%USERPROFILE%\Blueprint-v11\`.
- **WSL-side install** lives at `/home/<user>/.claude/` and
  `/home/<user>/Blueprint-v11/`.

These are on different filesystems. Re-installing on one side does not
affect the other. Upgrade or uninstall each side separately.

---

## What to do if an upgrade breaks

1. Run `verify.sh` or `verify.ps1`. If it fails, the failure message
   will point to the specific file or check that broke.
2. Check `settings.json.bak` against `settings.json` to see whether any
   settings you relied on were reset.
3. Run `collect-diagnostics.sh` or `collect-diagnostics.ps1` and read
   the output. It captures environment, install contents, and recent
   hook error logs.
4. If the new version is worse, uninstall it and reinstall the previous
   version from a tagged release. Blueprint uses semver-ish version
   tags like `v11.2`, `v11.3`; you can check out a prior tag and
   re-install from there.
5. If you report the issue, include the diagnostics bundle.

---

## Version-to-version notes

### v11.3 -> v11.4

Rewrites:

- `build-rules/SKILL.md` - new five-phase structure, new interrogation
  flow, full-roadmap generation at SCOPE CONFIRMED
- `start/SKILL.md` - SME voice, hands off to build-rules cleanly
- `critical-thinker/SKILL.md` - SME voice, concrete "things that bite"
  section
- `debug/SKILL.md` - SME voice
- `foundation/CLAUDE.md` - SME tone, updated phase names, calibration
  in gate-close protocol
- `foundation/CONTRACT.md` - new `BUILD_TYPE` and `FINAL_VERSION` fields
- `foundation/VERSION_ROADMAP.md` - full-roadmap structure, calibration
  multiplier section

Behavior changes:

- **Phase names changed.** `CONFIRMED` becomes `SCOPE CONFIRMED`.
  `ROADMAP APPROVED` is removed - its function merged into
  `SCOPE CONFIRMED`. `TESTS APPROVED` is new, between
  `FRONTEND APPROVED` and `GO`.
- **Full roadmap generated at SCOPE CONFIRMED.** Users see the complete
  v0.0 through final version ladder at planning time. Near-term gates
  get single-hour estimates, later gates get ranges.
- **Build type asked upfront** (Production / Internal / Exploratory).
  Final version is labeled explicitly per build type.
- **Calibration variance > 30% prints a heads-up** but does NOT silently
  edit the approved roadmap.
- **Hook output softened.** No shouting caps. Same firmness, just
  conversational phrasing.

No data migration needed. Projects started under v11.3 phase names
continue to work; you can update CONTRACT.md status manually if you
want the new phase names, or let them age out as projects close.

### v11.2 -> v11.3

New files added:

- `uninstall.sh`, `uninstall.ps1`
- `.claude/hooks/gate-close-calibration.sh`, `.ps1`
- `.claude/hooks/skill-telemetry.sh`, `.ps1`
- `TROUBLESHOOTING.md`, `MIGRATION.md`

Behavior changes:

- `install.sh` / `install.ps1` now prompt before clobbering an existing
  install. Use `--yes` / `-Force` to skip.
- `verify.sh` / `verify.ps1` now clean up their own test artifacts
  (counter files, verify-session telemetry rows).
- Gate close protocol now invokes `gate-close-calibration` to write
  ESTIMATION entries automatically. If you have existing
  MEMORY_CORRECTIONS.md files, new entries will append without
  disturbing prior content.
- Rollback snapshots are pruned to the 10 most recent per project.

No breaking changes. Skills, hooks, and agents from v11.2 are replaced
wholesale by v11.3 equivalents. If you customized any of those files,
back them up before running the installer.

### v11.1-public -> v11.2

New file added:

- `claude-skills/rollback/SKILL.md` and `.claude/skills/rollback/SKILL.md`

Behavior changes:

- 17 skills total (up from 16); verify.sh / verify.ps1 pass count went
  from 82 to 84.
- `context-check` hook now reads `CONTEXT_BUDGET.md` for thresholds.
- All `.md` files normalized to ASCII punctuation. If you copied text
  from Blueprint docs into your own notes and relied on specific
  Unicode characters, they have been replaced.

No breaking changes.
