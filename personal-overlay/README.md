# Personal Overlay

This directory contains owner-specific configuration that personalizes
the Blueprint v11 foundation templates. The core Blueprint methodology
(skills, hooks, foundation structure) is generic; this overlay is where
your individual identity lives.

## Setup (one-time)

1. **Copy the template to a live config file:**

   ```bash
   # Mac/Linux
   cp personal-overlay/owner-config.template.md personal-overlay/owner-config.md
   ```

   ```powershell
   # Windows
   Copy-Item personal-overlay\owner-config.template.md personal-overlay\owner-config.md
   ```

2. **Edit `owner-config.md`** with your own name, email, rate, git identity,
   and other personal details.

3. **Run the installer with the `-PersonalConfig` flag:**

   ```powershell
   # Windows
   .\install.ps1 -PersonalConfig '.\personal-overlay\owner-config.md'
   ```

   ```bash
   # Mac/Linux
   ./install.sh --personal-config ./personal-overlay/owner-config.md
   ```

   The installer replaces every `{{VARIABLE}}` placeholder in foundation
   files and skills with the values from your config.

## Privacy

`owner-config.md` is listed in `.gitignore` - your personal values will
not be committed if you push this repo back to GitHub. Only the sanitized
template (`owner-config.template.md`) is tracked in git.

## What gets personalized

The installer substitutes `{{VARIABLE}}` placeholders in these files:

- `foundation/DECISIONS.md` - `{{OWNER_NAME}}` in the decision log ownership fields
- `foundation/TEAM.md` - `{{OWNER_NAME}}` in solo-mode defaults
- Any skill file under `claude-skills/` that references owner variables

## Skipping personalization

If you just want to try Blueprint without personalizing it, run the
installer without `-PersonalConfig`. You'll see literal `{{OWNER_NAME}}`
strings in a few places, and the installer warns about the count of
unreplaced placeholders. Re-run with `-PersonalConfig` whenever you're
ready to personalize.
