# build-skills-bundle.ps1
# Build individual skill zip files for upload to claude.ai
#
# Claude.ai requires each custom skill to be uploaded as a separate zip
# containing a single folder at the root with a SKILL.md file.
# This script packages each of the 16 Blueprint skills that way.
#
# Output: dist\claude-ai-bundle\
#   <skill-name>.zip         (one per skill, 16 total)
#   CLAUDEAI-README.md       (upload instructions)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$SrcDir = Join-Path $ScriptDir "claude-skills"
$OutDir = Join-Path $ScriptDir "dist\claude-ai-bundle"

if (-not (Test-Path $SrcDir)) {
    Write-Host "ERROR: claude-skills directory not found at $SrcDir" -ForegroundColor Red
    Write-Host "Run this script from the Blueprint v11 repo root." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Blueprint v11 -- claude.ai skills bundle" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Clean output dir
if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$count = 0
Get-ChildItem $SrcDir -Directory | ForEach-Object {
    $skillDir = $_.FullName
    $skillName = $_.Name
    $skillMd = Join-Path $skillDir "SKILL.md"

    if (-not (Test-Path $skillMd)) {
        Write-Host "  [SKIP] $skillName (no SKILL.md)" -ForegroundColor Yellow
        return
    }

    # Validate skill name format
    if ($skillName -notmatch "^[a-z0-9-]+$") {
        Write-Host "  [WARN] $skillName contains non-standard characters; claude.ai may reject it" -ForegroundColor Yellow
    }

    $outZip = Join-Path $OutDir "$skillName.zip"

    # Zip from the parent dir so the folder itself is at the root of the zip
    Push-Location $SrcDir
    try {
        # Remove any pre-existing zip (shouldn't happen since we cleaned OutDir)
        if (Test-Path $outZip) { Remove-Item $outZip -Force }
        Compress-Archive -Path $skillName -DestinationPath $outZip -Force
    } finally {
        Pop-Location
    }

    $sizeKb = [math]::Round((Get-Item $outZip).Length / 1024)
    Write-Host "  [OK] ${skillName}.zip (${sizeKb} KB)" -ForegroundColor Green
    $count++
}

Write-Host ""
Write-Host "Packaged $count skill(s) to: $OutDir" -ForegroundColor Cyan

# Write the README into the bundle
$readme = @'
# Blueprint v11 -- claude.ai skills bundle

This directory contains 16 skill zip files ready to upload to **claude.ai**
(the web app at claude.ai, and the Claude mobile app for iOS and Android).

## What you're getting

**Included:** the 16 skill definitions that make up Blueprint's methodology
layer -- the five-gate build-rules, critical-thinker, freelance billing,
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

If 16 uploads feels like too much, start with these 4 -- they deliver most
of the value:

1. `build-rules.zip` -- the five-gate approval workflow
2. `critical-thinker.zip` -- pressure-tests technical decisions
3. `start.zip` -- session orchestration entry point
4. `global-rules.zip` -- baseline coding rules

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
`.\build-skills-bundle.ps1` (or the bash variant) and re-upload the
zips. claude.ai does not auto-sync.

## Back to full Blueprint

The full desktop install gets you hooks, foundation templates, memory network,
and MCP integration. See the top-level README.md for install.ps1 / install.sh.
'@

$readmePath = Join-Path $OutDir "CLAUDEAI-README.md"
Set-Content -Path $readmePath -Value $readme -NoNewline

Write-Host "Wrote: $readmePath" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open claude.ai -> Settings -> Features -> Skills"
Write-Host "  2. Upload each .zip from $OutDir one at a time"
Write-Host "  3. Read CLAUDEAI-README.md for full instructions"
Write-Host ""
