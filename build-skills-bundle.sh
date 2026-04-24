#!/bin/bash
# build-skills-bundle.sh
# Build individual skill zip files for upload to claude.ai
#
# Claude.ai requires each custom skill to be uploaded as a separate zip
# containing a single folder at the root with a SKILL.md file.
# This script packages each of the 16 Blueprint skills that way.
#
# Output: dist/claude-ai-bundle/
#   <skill-name>.zip         (one per skill, 16 total)
#   CLAUDEAI-README.md       (upload instructions)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/claude-skills"
OUT_DIR="$SCRIPT_DIR/dist/claude-ai-bundle"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: claude-skills/ directory not found at $SRC_DIR" >&2
  echo "Run this script from the Blueprint v11 repo root." >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "ERROR: 'zip' command not found." >&2
  echo "  macOS: pre-installed (should be in /usr/bin/zip)" >&2
  echo "  Linux: sudo apt install zip  OR  sudo yum install zip" >&2
  exit 1
fi

echo ""
echo "============================================"
echo "  Blueprint v11 - claude.ai skills bundle"
echo "============================================"
echo ""

# Clean output dir
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Package each skill
count=0
for skill_dir in "$SRC_DIR/"*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    echo "  [SKIP] $skill_name (no SKILL.md)"
    continue
  fi

  # Validate skill name: must be lowercase + hyphens + digits only
  if [[ ! "$skill_name" =~ ^[a-z0-9-]+$ ]]; then
    echo "  [WARN] $skill_name contains non-standard characters; claude.ai may reject it"
  fi

  # Zip the folder (with the folder itself at the root, as claude.ai requires)
  out_zip="$OUT_DIR/${skill_name}.zip"
  ( cd "$SRC_DIR" && zip -qr "$out_zip" "$skill_name" )
  size_kb=$(( $(wc -c < "$out_zip") / 1024 ))
  echo "  [OK] ${skill_name}.zip (${size_kb} KB)"
  count=$((count + 1))
done

echo ""
echo "Packaged $count skill(s) to: $OUT_DIR"

# Write the README into the bundle
cat > "$OUT_DIR/CLAUDEAI-README.md" <<'README_EOF'
# Blueprint v11 - claude.ai skills bundle

This directory contains 16 skill zip files ready to upload to **claude.ai**
(the web app at claude.ai, and the Claude mobile app for iOS and Android).

## What you're getting

**Included:** the 16 skill definitions that make up Blueprint's methodology
layer - the five-gate build-rules, critical-thinker, freelance billing,
and so on. These give Claude skill-based guidance in chat.

**NOT included** (because claude.ai doesn't support them):

- **Hooks.** No mechanical blocking of dangerous commands or test-before-code
  enforcement. The approval gates fall back to CLAUDE.md advisory rules only.
- **Foundation templates.** No CONTRACT.md, DECISIONS.md, MEMORY_SEMANTIC.md,
  or other per-project artifacts.
- **Memory network.** No cross-session memory persistence.
- **MCP servers.** No GitHub or Playwright integration.
- **Subagents.** No spec-reviewer, test-writer, or security-auditor.

If you want any of those, install the full Blueprint on desktop Claude Code
(see the top-level README.md for `install.sh` / `install.ps1`).

## How to upload

1. Open **claude.ai** in a browser (or the Claude mobile app).
2. Go to **Settings -> Features -> Skills** (or **Capabilities -> Skills**
   depending on your plan).
3. Make sure **code execution** is enabled in Settings -> Capabilities.
4. Click **"+ Create skill"** and upload **one zip at a time**.
5. Repeat for all 16 zips.

Custom skills are private to your individual account. On Team/Enterprise
plans, an org owner can enable sharing if you want to distribute these
to a whole organization.

## Which skills to upload first

If 16 uploads feels like too much, start with these 4 - they deliver most
of the value:

1. `build-rules.zip` - the five-gate approval workflow
2. `critical-thinker.zip` - pressure-tests technical decisions
3. `start.zip` - session orchestration entry point
4. `global-rules.zip` - baseline coding rules

Add the rest as you need them (billing, onboard, etc.).

## Verifying an upload worked

After uploading a skill:

1. Open a new claude.ai conversation.
2. Try a prompt that should trigger the skill. For example, after uploading
   `build-rules.zip`:

   > I want to build a simple todo app. Use the build-rules skill.

3. Claude should enter the interrogation phase of Blueprint's five-gate
   process instead of jumping straight into code.

If Claude ignores the skill, the description field may need a "pushier"
trigger phrase. Edit SKILL.md inside the zip, re-zip, re-upload.

## Versioning

These zips are built from this repo's `claude-skills/` directory. When you
pull the latest Blueprint and want updated skills, re-run
`./build-skills-bundle.sh` (or the PowerShell variant) and re-upload the
zips. claude.ai does not auto-sync.

## Back to full Blueprint

The full desktop install gets you hooks, foundation templates, memory network,
and MCP integration. See the top-level README.md for install.ps1 / install.sh.
README_EOF

echo "Wrote: $OUT_DIR/CLAUDEAI-README.md"
echo ""
echo "Next steps:"
echo "  1. Open claude.ai -> Settings -> Features -> Skills"
echo "  2. Upload each .zip from $OUT_DIR one at a time"
echo "  3. Read CLAUDEAI-README.md for full instructions"
echo ""
