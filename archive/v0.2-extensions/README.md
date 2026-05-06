# Archive: v0.2 Extensions

These were three separate skill folders in v0.2.0 (`freelance-billing`, `onboard`, `handoff`). They've been consolidated into a single `core/skills/billing/` skill in v0.3.0, driven by the `PROJECT_TYPE` flag set during `/start`.

## What changed

In v0.2.0, freelance work required the user to remember to install the `syntaris-freelance` extension and explicitly invoke `/onboard` at project start, `/freelance-billing` for invoices, and `/handoff` at v1.0.0. Three skills, three commands, three places things could drift.

In v0.3.0, `/start` asks "Personal or Client?" as its first question. If client, it collects billing info upfront and writes to `CLIENTS.md` plus a `PROJECT_TYPE: client` flag in `CONTRACT.md`. The new unified `billing` skill activates conditionally based on that flag - generating invoices at gate close, producing handoff artifacts at v1.0.0 - with no separate skill invocation required.

## Why these are kept here

This folder is `.gitignore`d for distribution but committed to repo history. Reasons for keeping rather than deleting:

1. **Reference for migration.** Users on v0.2.0 upgrading to v0.3.0 may want to see what the old behavior looked like.
2. **Debugging fallback.** If something breaks in the new `billing` skill, the old reference implementation is here.
3. **Honest provenance.** Syntaris was iterated heavily before public release. Archiving rather than erasing matches the v0.1.0 changelog discipline of disclosing iteration history.

## What's NOT loaded

These archived skills are not loaded by:
- The v0.3.0+ install scripts (`install.sh`, `install.ps1`)
- The plugin manifest (`.claude-plugin/plugin.json`)
- Any `verify.sh` checks
- The Claude Code session at `/start`

They exist here as artifacts only.

## If you genuinely want the old behavior

You can copy any of the three skill folders from `archive/v0.2-extensions/syntaris-freelance/<skill-name>/` to `.claude/skills/<skill-name>/` and they will load like any other skill. But the `billing` skill in v0.3.0 supersedes them, and running both will cause overlapping prompts and duplicate invoice entries.
