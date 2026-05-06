# install.ps1
# Syntaris Installer
# Run: PowerShell -ExecutionPolicy Bypass -File "install.ps1"
#
# Options:
#   -ZipPath        Path to syntaris-v0.3.0.zip (default: current directory)
#   -InstallRoot    Claude Code config directory (default: ~/.claude)
#   -SyntarisRoot  Foundation templates location (default: ~/Syntaris)
#   -PersonalConfig Path to owner-config.md for variable substitution (optional)

param(
    [string]$ZipPath = ".\syntaris-v0.3.0.zip",
    [string]$InstallRoot = "$env:USERPROFILE\.claude",
    [string]$SyntarisRoot = "$env:USERPROFILE\Syntaris",
    [string]$PersonalConfig = "",
    [string]$Target = "",   # Empty = auto-detect. Valid: claude-code, cursor, windsurf, codex-cli, gemini-cli, aider, kiro, opencode
    [switch]$Force
)

# == Target detection ========================================================
# If -Target wasn't passed, auto-detect via env vars and config files.

if ([string]::IsNullOrEmpty($Target)) {
    if ($env:CLAUDE_CODE -or $env:ANTHROPIC_CLAUDE_CODE) {
        $Target = "claude-code"
    } elseif ($env:CURSOR_USER -or (Test-Path ".cursor") -or (Test-Path ".cursorrules")) {
        $Target = "cursor"
    } elseif ($env:WINDSURF_USER -or (Test-Path ".windsurf")) {
        $Target = "windsurf"
    } elseif ((Test-Path ".codex/config.toml") -or $env:CODEX_HOME) {
        $Target = "codex-cli"
    } elseif ((Test-Path ".gemini") -or ($env:GEMINI_API_KEY -and $env:GEMINI_CLI_HOME)) {
        $Target = "gemini-cli"
    } elseif ($env:KIRO_HOME -or (Test-Path ".kiro")) {
        $Target = "kiro"
    } elseif ((Test-Path ".opencode") -or (Test-Path "opencode.json")) {
        $Target = "opencode"
    } elseif ($env:AIDER_MODEL -or (Test-Path ".aider.conf.yml")) {
        $Target = "aider"
    } else {
        $Target = "claude-code"
    }
}

# Tier mapping
switch ($Target) {
    "claude-code"  { $Tier = 1 }
    "cursor"       { $Tier = 2 }
    "windsurf"     { $Tier = 2 }
    "codex-cli"    { $Tier = 3 }
    "gemini-cli"   { $Tier = 3 }
    "aider"        { $Tier = 3 }
    "kiro"         { $Tier = 3 }
    "opencode"     { $Tier = 3 }
    default {
        Write-Host "Unknown target: $Target. Valid: claude-code, cursor, windsurf, codex-cli, gemini-cli, aider, kiro, opencode" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  Target:  $Target (Tier $Tier)" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Syntaris Installer" -ForegroundColor Cyan
Write-Host "  AI App Building Methodology" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# == Step 1: Locate source tree (zip OR direct clone) ========================
#
# This installer supports two usage patterns:
#   A) Cloned from GitHub: run directly from the repo root, no zip involved.
#   B) Packaged zip: extract a syntaris-v0.3.0.zip first, then install.
# We detect which mode we're in by checking whether .claude/ exists next to us.

$ScriptDir = Split-Path -Parent $PSCommandPath
$DirectClaude = Join-Path $ScriptDir ".claude"

if (Test-Path $DirectClaude) {
    # Mode A: running from cloned repo. Use $ScriptDir as the source.
    $ExtractedRoot = $ScriptDir
    Write-Host "Installing from cloned repo at: $ExtractedRoot" -ForegroundColor Green
    $UsedZip = $false
} elseif (Test-Path $ZipPath) {
    # Mode B: extract zip into TEMP and use that as source.
    $TempDir = "$env:TEMP\syntaris-install"
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $TempDir | Out-Null
    Write-Host "Extracting: $ZipPath" -ForegroundColor Gray
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    $ExtractedRoot = Get-ChildItem $TempDir -Directory | Select-Object -First 1
    if (-not $ExtractedRoot) { $ExtractedRoot = Get-Item $TempDir }
    else { $ExtractedRoot = $ExtractedRoot.FullName }
    Write-Host "Extracted to: $ExtractedRoot" -ForegroundColor Green
    $UsedZip = $true
} else {
    Write-Host "ERROR: Cannot locate Syntaris source." -ForegroundColor Red
    Write-Host "Expected one of:" -ForegroundColor Yellow
    Write-Host "  - A .claude/ directory next to this installer (clone mode), or" -ForegroundColor Yellow
    Write-Host "  - A syntaris-v0.3.0.zip at: $ZipPath (zip mode)" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "If you cloned from GitHub, run this installer from the repo root." -ForegroundColor Yellow
    Write-Host "If you have a zip, specify: -ZipPath 'C:\path\to\syntaris-v0.3.0.zip'" -ForegroundColor Yellow
    exit 1
}

# == Step 1.5: Tier 2/3 install branch ======================================
# Tier 1 (Claude Code) continues to the full install.
# Tier 2/3 take a separate path that emits target-native config and exits.

if ($Tier -ne 1) {
    Write-Host ""
    Write-Host "Step 1.5: Installing Tier $Tier adapter for $Target" -ForegroundColor Cyan

    # All tiers get foundation templates copied to project root
    $foundationSrc = Join-Path $SrcRoot "foundation"
    if (Test-Path $foundationSrc) {
        Copy-Item -Path $foundationSrc -Destination "." -Recurse -Force
        Write-Host "  Copied foundation/ to project root" -ForegroundColor Green
    }

    switch ($Target) {
        "cursor" {
            New-Item -ItemType Directory -Force -Path ".cursor\rules" | Out-Null
            $cursorRules = @"
---
description: Syntaris methodology rules
alwaysApply: true
---

# Syntaris (Tier 2 - Cursor)

Foundation files at foundation/ define the project contract, decisions, errors, and memory.
Read them before any non-trivial edit.

The five approval words gate work: CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED, GO.
Do not advance phases without an explicit approval word in the chat.

Skills documented in .claude/skills/*/SKILL.md describe phase-specific behavior.
Full rules translation pending per BUILD_NEXT.md.
"@
            $cursorRules | Out-File -FilePath ".cursor\rules\syntaris-core.mdc" -Encoding utf8
            Write-Host "  Wrote .cursor/rules/syntaris-core.mdc" -ForegroundColor Green
            Write-Host "  Full rules translation pending - see BUILD_NEXT.md" -ForegroundColor Yellow
        }
        "windsurf" {
            New-Item -ItemType Directory -Force -Path ".windsurf\rules" | Out-Null
            "# Syntaris (Tier 2 - Windsurf) - placeholder, see BUILD_NEXT.md" | Out-File -FilePath ".windsurf\rules\syntaris-core.md" -Encoding utf8
            Write-Host "  Wrote .windsurf/rules/syntaris-core.md placeholder" -ForegroundColor Green
        }
        "codex-cli" {
            $agentsBody = @"
# Syntaris Methodology (Tier 3 advisory, Codex CLI)

This project uses the Syntaris methodology. Foundation files in foundation/
contain the project contract, decisions log, errors log, and memory.

Read foundation/CONTRACT.md before any non-trivial edit. Respect the five
approval words: CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED,
GO. These gate phase advancement.

Full Syntaris methodology is documented at github.com/brianonieal/Syntaris.
"@
            $agentsBody | Out-File -FilePath "AGENTS.md" -Encoding utf8
            Write-Host "  Wrote AGENTS.md for Codex CLI" -ForegroundColor Green
        }
        "gemini-cli" {
            New-Item -ItemType Directory -Force -Path ".gemini" | Out-Null
            "# Syntaris (Tier 3 advisory, Gemini CLI) - see foundation/ and .claude/skills/" | Out-File -FilePath ".gemini\GEMINI.md" -Encoding utf8
            Write-Host "  Wrote .gemini/GEMINI.md" -ForegroundColor Green
        }
        "aider" {
            $aiderBody = @"
# Syntaris Methodology (Tier 3 advisory, Aider)

Foundation files at foundation/ define project contract and memory.
Read foundation/CONTRACT.md before non-trivial edits.
Respect the five approval words: CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED, GO.
"@
            $aiderBody | Out-File -FilePath ".aider.syntaris.md" -Encoding utf8
            Write-Host "  Wrote .aider.syntaris.md" -ForegroundColor Green
            Write-Host "  Add 'read: .aider.syntaris.md' to your .aider.conf.yml manually" -ForegroundColor Yellow
        }
        "kiro" {
            New-Item -ItemType Directory -Force -Path ".kiro\specs" | Out-Null
            "# Syntaris Methodology (Tier 3 advisory, Kiro) - see foundation/ and .claude/skills/" | Out-File -FilePath ".kiro\specs\syntaris-methodology.md" -Encoding utf8
            Write-Host "  Wrote .kiro/specs/syntaris-methodology.md" -ForegroundColor Green
        }
        "opencode" {
            New-Item -ItemType Directory -Force -Path ".opencode\instructions" | Out-Null
            "# Syntaris (Tier 3 advisory, OpenCode) - see foundation/ and .claude/skills/" | Out-File -FilePath ".opencode\instructions\INSTRUCTIONS.md" -Encoding utf8
            Write-Host "  Wrote .opencode/instructions/INSTRUCTIONS.md" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "Tier $Tier install complete for $Target." -ForegroundColor Cyan
    Write-Host "Foundation templates copied to ./foundation/" -ForegroundColor Cyan
    Write-Host "See docs/COMPATIBILITY.md for what's enforced at this tier." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# == Step 2: Detect existing install and confirm clobber =====================

$existingDetected = $false
foreach ($p in @("$InstallRoot\skills", "$InstallRoot\hooks", "$InstallRoot\agents", "$InstallRoot\settings.json")) {
    if (Test-Path $p) { $existingDetected = $true; break }
}

if ($existingDetected) {
    Write-Host ""
    Write-Host "Existing Syntaris install detected at: $InstallRoot" -ForegroundColor Yellow
    Write-Host "Continuing will CLOBBER:" -ForegroundColor Yellow
    if (Test-Path "$InstallRoot\skills") { Write-Host "  - all files under $InstallRoot\skills\" -ForegroundColor Yellow }
    if (Test-Path "$InstallRoot\hooks") { Write-Host "  - all files under $InstallRoot\hooks\" -ForegroundColor Yellow }
    if (Test-Path "$InstallRoot\agents") { Write-Host "  - all files under $InstallRoot\agents\" -ForegroundColor Yellow }
    if (Test-Path "$InstallRoot\settings.json") { Write-Host "  - settings.json (backed up to .bak first)" -ForegroundColor Yellow }
    Write-Host "Any files you have personally edited will be overwritten." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Preserved: foundation templates at $SyntarisRoot, per-project files," -ForegroundColor Yellow
    Write-Host "  personal-overlay\owner-config.md, hook error logs in `$env:TEMP." -ForegroundColor Yellow

    if (-not $Force) {
        Write-Host ""
        $reply = Read-Host "Proceed with clobber-and-reinstall? [y/N]"
        if ($reply -notmatch '^(y|yes)$') {
            Write-Host "Aborted."
            exit 0
        }
    }

    foreach ($p in @("$InstallRoot\skills", "$InstallRoot\hooks", "$InstallRoot\agents")) {
        if (Test-Path $p) {
            Remove-Item -Recurse -Force $p
        }
    }
}

# == Step 3: Install to ~/.claude =============================================

Write-Host ""
Write-Host "Installing to: $InstallRoot" -ForegroundColor Cyan

# Create target directories
@("$InstallRoot\skills", "$InstallRoot\hooks", "$InstallRoot\agents") | ForEach-Object {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
}

# Settings.json (backup existing)
$settingsSrc = Join-Path $ExtractedRoot ".claude\settings.json"
$settingsDst = Join-Path $InstallRoot "settings.json"
if (Test-Path $settingsDst) {
    Write-Host "  settings.json exists -- backing up to settings.json.bak" -ForegroundColor Yellow
    Copy-Item $settingsDst "$settingsDst.bak" -Force
}
Copy-Item $settingsSrc $settingsDst -Force
Write-Host "  [OK] settings.json" -ForegroundColor Green

# Skill directories
$skillDirs = Get-ChildItem (Join-Path $ExtractedRoot ".claude\skills") -Directory
foreach ($skillDir in $skillDirs) {
    $destDir = Join-Path $InstallRoot "skills\$($skillDir.Name)"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item "$($skillDir.FullName)\*" $destDir -Recurse -Force
    Write-Host "  [OK] skills\$($skillDir.Name)" -ForegroundColor Green
}

# Hook scripts (convert .sh files to LF endings for bash compatibility)
$hookFiles = Get-ChildItem (Join-Path $ExtractedRoot ".claude\hooks\*")
foreach ($file in $hookFiles) {
    $dest = Join-Path $InstallRoot "hooks\$($file.Name)"
    if ($file.Extension -eq ".sh") {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        $lfText = $text -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($dest, $lfText, [System.Text.UTF8Encoding]::new($false))
    } else {
        Copy-Item $file.FullName $dest -Force
    }
    Write-Host "  [OK] hooks\$($file.Name)" -ForegroundColor Green
}

# Agent files
$agentPath = Join-Path $ExtractedRoot ".claude\agents"
if (Test-Path $agentPath) {
    $agentFiles = Get-ChildItem "$agentPath\*"
    foreach ($file in $agentFiles) {
        Copy-Item $file.FullName (Join-Path $InstallRoot "agents\$($file.Name)") -Force
        Write-Host "  [OK] agents\$($file.Name)" -ForegroundColor Green
    }
}

# == Step 4: Install foundation templates =====================================

Write-Host ""
Write-Host "Installing foundation templates to: $SyntarisRoot" -ForegroundColor Cyan

New-Item -ItemType Directory -Path "$SyntarisRoot\foundation" -Force | Out-Null

# Foundation files
Get-ChildItem (Join-Path $ExtractedRoot "foundation\*.md") | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $SyntarisRoot "foundation\$($_.Name)") -Force
    Write-Host "  [OK] foundation\$($_.Name)" -ForegroundColor Green
}

# Copy install script and meta files
Copy-Item $PSCommandPath (Join-Path $SyntarisRoot "install.ps1") -Force
$readme = Join-Path $ExtractedRoot "README.md"
if (Test-Path $readme) { Copy-Item $readme $SyntarisRoot -Force }
$license = Join-Path $ExtractedRoot "LICENSE"
if (Test-Path $license) { Copy-Item $license $SyntarisRoot -Force }

# == Step 5: Apply personal configuration (if provided) =======================

if ($PersonalConfig -and (Test-Path $PersonalConfig)) {
    Write-Host ""
    Write-Host "Applying personal configuration from: $PersonalConfig" -ForegroundColor Cyan

    # Parse owner-config.md into a hashtable
    $configVars = @{}
    Get-Content $PersonalConfig | ForEach-Object {
        if ($_ -match "^(\w+):\s*(.+)$") {
            $configVars[$matches[1]] = $matches[2].Trim()
        }
    }

    if ($configVars.Count -gt 0) {
        # Replace {{VARIABLE}} placeholders in all installed .md files
        $targetDirs = @(
            "$SyntarisRoot\foundation",
            "$InstallRoot\skills"
        )
        foreach ($dir in $targetDirs) {
            if (Test-Path $dir) {
                Get-ChildItem $dir -Recurse -Filter "*.md" | ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    $changed = $false
                    foreach ($key in $configVars.Keys) {
                        $placeholder = "{{$key}}"
                        if ($content -match [regex]::Escape($placeholder)) {
                            $content = $content -replace [regex]::Escape($placeholder), $configVars[$key]
                            $changed = $true
                        }
                    }
                    if ($changed) {
                        Set-Content $_.FullName $content -NoNewline
                        Write-Host "  [OK] Substituted variables in: $($_.Name)" -ForegroundColor Green
                    }
                }
            }
        }

        # Count remaining unreplaced placeholders
        $remaining = 0
        foreach ($dir in $targetDirs) {
            if (Test-Path $dir) {
                $remaining += (Get-ChildItem $dir -Recurse -Filter "*.md" | Select-String -Pattern "{{[A-Z_]+}}" | Measure-Object).Count
            }
        }
        if ($remaining -gt 0) {
            Write-Host "  [WARN] $remaining {{VARIABLE}} placeholders still unreplaced." -ForegroundColor Yellow
            Write-Host "  Add missing keys to your owner-config.md and re-run." -ForegroundColor Yellow
        } else {
            Write-Host "  [OK] All placeholders replaced." -ForegroundColor Green
        }
    }
} else {
    # Check if placeholders exist and warn
    $placeholderCount = 0
    if (Test-Path "$SyntarisRoot\foundation") {
        $placeholderCount = (Get-ChildItem "$SyntarisRoot\foundation\*.md" | Select-String -Pattern "{{[A-Z_]+}}" | Measure-Object).Count
    }
    if ($placeholderCount -gt 0) {
        Write-Host ""
        Write-Host "NOTE: $placeholderCount {{VARIABLE}} placeholders found in foundation files." -ForegroundColor Yellow
        Write-Host "  To personalize, create an owner-config.md and re-run:" -ForegroundColor Yellow
        Write-Host "  .\install.ps1 -PersonalConfig '.\personal-overlay\owner-config.md'" -ForegroundColor Yellow
    }
}

# == Step 6: Set hook permissions via WSL =====================================

Write-Host ""
$wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslAvailable) {
    Write-Host "Setting hook permissions via WSL..." -ForegroundColor Cyan
    Get-ChildItem "$InstallRoot\hooks\*.sh" | ForEach-Object {
        $wslPath = $_.FullName -replace "\\", "/" -replace "C:", "/mnt/c"
        wsl chmod +x $wslPath 2>$null
    }
    Write-Host "  [OK] Hook scripts marked executable" -ForegroundColor Green
} else {
    Write-Host "WSL not available -- bash hooks need manual chmod +x" -ForegroundColor Yellow
    Write-Host "  Run from WSL: chmod +x ~/.claude/hooks/*.sh" -ForegroundColor Yellow
}

# == Step 7: Verify installation ==============================================

Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Cyan

$allOk = $true

# Check skills
$requiredSkills = @(
    "start", "build-rules", "global-rules", "critical-thinker",
    "testing", "security", "deployment", "costs", "performance",
    "debug", "research", "billing",
    "health", "rollback"
)
foreach ($skill in $requiredSkills) {
    $path = Join-Path $InstallRoot "skills\$skill\SKILL.md"
    if (Test-Path $path) {
        Write-Host "  [OK] skills\$skill" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] skills\$skill" -ForegroundColor Red
        $allOk = $false
    }
}

# Check hooks
$requiredHooks = @(
    "session-start.sh", "session-start.ps1",
    "strip-coauthor.sh", "strip-coauthor.ps1",
    "enforce-tests.sh", "enforce-tests.ps1",
    "block-dangerous.sh", "block-dangerous.ps1",
    "context-check.sh", "context-check.ps1",
    "pre-compact.sh", "pre-compact.ps1",
    "writethru-episodic.sh", "writethru-episodic.ps1"
)
foreach ($hook in $requiredHooks) {
    $path = Join-Path $InstallRoot "hooks\$hook"
    if (Test-Path $path) {
        Write-Host "  [OK] hooks\$hook" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] hooks\$hook" -ForegroundColor Red
        $allOk = $false
    }
}

# Check agents
@("spec-reviewer.md", "test-writer.md", "security-auditor.md") | ForEach-Object {
    $path = Join-Path $InstallRoot "agents\$_"
    if (Test-Path $path) {
        Write-Host "  [OK] agents\$_" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] agents\$_" -ForegroundColor Red
        $allOk = $false
    }
}

# Check hook wrappers
$requiredWrappers = @("hook-wrapper.sh", "hook-wrapper.ps1")
foreach ($wrapper in $requiredWrappers) {
    $path = Join-Path $InstallRoot "hooks\$wrapper"
    if (Test-Path $path) {
        Write-Host "  [OK] hooks\$wrapper" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] hooks\$wrapper" -ForegroundColor Red
        $allOk = $false
    }
}

# == Step 8: Clean up ========================================================

# Only remove TempDir if we actually extracted a zip (zip mode).
# In clone mode, $TempDir is never set and $ExtractedRoot points at the repo root.
if ($UsedZip -and $TempDir -and (Test-Path $TempDir)) {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# == Step 9: Summary =========================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

if ($allOk) {
    Write-Host "  Syntaris installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Skills:     $InstallRoot\skills\ (14 skills)" -ForegroundColor White
    Write-Host "  Hooks:      $InstallRoot\hooks\ (10 hooks + 1 wrapper, bash + PowerShell)" -ForegroundColor White
    Write-Host "  Agents:     $InstallRoot\agents\ (7 subagents)" -ForegroundColor White
    Write-Host "  Settings:   $InstallRoot\settings.json" -ForegroundColor White
    Write-Host "  Foundation: $SyntarisRoot\foundation\ (22 templates)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Configure git identity for your project" -ForegroundColor White
    Write-Host "  2. Open Claude Code in your project directory" -ForegroundColor White
    Write-Host "  3. Type: /start" -ForegroundColor White
    Write-Host ""
    Write-Host "  Read foundation\ONBOARDING.md for a full walkthrough." -ForegroundColor White
} else {
    Write-Host "  Installation completed with missing files." -ForegroundColor Yellow
    Write-Host "  Check the MISSING items above and re-run." -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# == Step 10: Auto-run verification ==========================================

if ($allOk) {
    $verifyScript = Join-Path $ScriptDir "verify.ps1"
    if (Test-Path $verifyScript) {
        Write-Host ""
        Write-Host "Running verification (structural + execution + smoke tests)..." -ForegroundColor Cyan
        # Use the current PowerShell binary so this works on Windows PS 5.1,
        # Windows PS 7, macOS PS 7, and Linux PS 7 without hardcoding a name.
        $pwshExe = (Get-Process -Id $PID).Path
        & $pwshExe -NoProfile -ExecutionPolicy Bypass -File $verifyScript -InstallRoot $InstallRoot
        $verifyExit = $LASTEXITCODE
        if ($verifyExit -eq 0) {
            exit 0
        } else {
            Write-Host ""
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host "  Install completed, but verification found issues." -ForegroundColor Yellow
            Write-Host "  Re-run verify.ps1 after fixing:" -ForegroundColor Yellow
            Write-Host "    .\verify.ps1 -InstallRoot '$InstallRoot'" -ForegroundColor Yellow
            Write-Host "============================================" -ForegroundColor Yellow
            Write-Host ""
            exit 2
        }
    }
}
