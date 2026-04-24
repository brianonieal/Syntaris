# install.ps1
# Blueprint v11 Installer
# Run: PowerShell -ExecutionPolicy Bypass -File "install.ps1"
#
# Options:
#   -ZipPath        Path to blueprint-v11.zip (default: current directory)
#   -InstallRoot    Claude Code config directory (default: ~/.claude)
#   -BlueprintRoot  Foundation templates location (default: ~/Blueprint-v11)
#   -PersonalConfig Path to owner-config.md for variable substitution (optional)

param(
    [string]$ZipPath = ".\blueprint-v11.zip",
    [string]$InstallRoot = "$env:USERPROFILE\.claude",
    [string]$BlueprintRoot = "$env:USERPROFILE\Blueprint-v11",
    [string]$PersonalConfig = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Blueprint v11 Installer" -ForegroundColor Cyan
Write-Host "  AI App Building Methodology" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# == Step 1: Locate source tree (zip OR direct clone) ========================
#
# This installer supports two usage patterns:
#   A) Cloned from GitHub: run directly from the repo root, no zip involved.
#   B) Packaged zip: extract a blueprint-v11.zip first, then install.
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
    $TempDir = "$env:TEMP\blueprint-v11-install"
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
    Write-Host "ERROR: Cannot locate Blueprint source." -ForegroundColor Red
    Write-Host "Expected one of:" -ForegroundColor Yellow
    Write-Host "  - A .claude/ directory next to this installer (clone mode), or" -ForegroundColor Yellow
    Write-Host "  - A blueprint-v11.zip at: $ZipPath (zip mode)" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "If you cloned from GitHub, run this installer from the repo root." -ForegroundColor Yellow
    Write-Host "If you have a zip, specify: -ZipPath 'C:\path\to\blueprint-v11.zip'" -ForegroundColor Yellow
    exit 1
}

# == Step 2: Detect existing install and confirm clobber =====================

$existingDetected = $false
foreach ($p in @("$InstallRoot\skills", "$InstallRoot\hooks", "$InstallRoot\agents", "$InstallRoot\settings.json")) {
    if (Test-Path $p) { $existingDetected = $true; break }
}

if ($existingDetected) {
    Write-Host ""
    Write-Host "Existing Blueprint install detected at: $InstallRoot" -ForegroundColor Yellow
    Write-Host "Continuing will CLOBBER:" -ForegroundColor Yellow
    if (Test-Path "$InstallRoot\skills") { Write-Host "  - all files under $InstallRoot\skills\" -ForegroundColor Yellow }
    if (Test-Path "$InstallRoot\hooks") { Write-Host "  - all files under $InstallRoot\hooks\" -ForegroundColor Yellow }
    if (Test-Path "$InstallRoot\agents") { Write-Host "  - all files under $InstallRoot\agents\" -ForegroundColor Yellow }
    if (Test-Path "$InstallRoot\settings.json") { Write-Host "  - settings.json (backed up to .bak first)" -ForegroundColor Yellow }
    Write-Host "Any files you have personally edited will be overwritten." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Preserved: foundation templates at $BlueprintRoot, per-project files," -ForegroundColor Yellow
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

# Hook scripts
$hookFiles = Get-ChildItem (Join-Path $ExtractedRoot ".claude\hooks\*")
foreach ($file in $hookFiles) {
    Copy-Item $file.FullName (Join-Path $InstallRoot "hooks\$($file.Name)") -Force
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
Write-Host "Installing foundation templates to: $BlueprintRoot" -ForegroundColor Cyan

@("$BlueprintRoot\foundation", "$BlueprintRoot\claude-skills") | ForEach-Object {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
}

# Foundation files
Get-ChildItem (Join-Path $ExtractedRoot "foundation\*.md") | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $BlueprintRoot "foundation\$($_.Name)") -Force
    Write-Host "  [OK] foundation\$($_.Name)" -ForegroundColor Green
}

# Claude-skills (for claude.ai upload)
$csPath = Join-Path $ExtractedRoot "claude-skills"
if (Test-Path $csPath) {
    Get-ChildItem $csPath -Directory | ForEach-Object {
        $destDir = Join-Path $BlueprintRoot "claude-skills\$($_.Name)"
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Copy-Item "$($_.FullName)\*" $destDir -Recurse -Force
        Write-Host "  [OK] claude-skills\$($_.Name)" -ForegroundColor Green
    }
}

# Copy install script and meta files
Copy-Item $PSCommandPath (Join-Path $BlueprintRoot "install.ps1") -Force
$readme = Join-Path $ExtractedRoot "README.md"
if (Test-Path $readme) { Copy-Item $readme $BlueprintRoot -Force }
$license = Join-Path $ExtractedRoot "LICENSE"
if (Test-Path $license) { Copy-Item $license $BlueprintRoot -Force }

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
            "$BlueprintRoot\foundation",
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
    if (Test-Path "$BlueprintRoot\foundation") {
        $placeholderCount = (Get-ChildItem "$BlueprintRoot\foundation\*.md" | Select-String -Pattern "{{[A-Z_]+}}" | Measure-Object).Count
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
    "debug", "research", "freelance-billing", "handoff",
    "health", "onboard", "rollback"
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

# Check hook wrappers (new in v11.1)
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

# Check that source zip's .claude/skills and claude-skills directories are in sync
# (they should be exact copies - drift indicates a packaging bug)
$zipSkillsA = Join-Path $ExtractedRoot ".claude\skills"
$zipSkillsB = Join-Path $ExtractedRoot "claude-skills"
if ((Test-Path $zipSkillsA) -and (Test-Path $zipSkillsB)) {
    $driftCount = 0
    Get-ChildItem $zipSkillsA -Directory | ForEach-Object {
        $skillA = Join-Path $_.FullName "SKILL.md"
        $skillB = Join-Path $zipSkillsB "$($_.Name)\SKILL.md"
        if ((Test-Path $skillA) -and (Test-Path $skillB)) {
            $hashA = (Get-FileHash $skillA).Hash
            $hashB = (Get-FileHash $skillB).Hash
            if ($hashA -ne $hashB) {
                Write-Host "  [DRIFT] skill '$($_.Name)' differs between .claude/skills and claude-skills" -ForegroundColor Yellow
                $driftCount++
            }
        }
    }
    if ($driftCount -eq 0) {
        Write-Host "  [OK] skill directories in sync" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $driftCount skill(s) drifted - package integrity issue" -ForegroundColor Yellow
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
    Write-Host "  Blueprint v11 installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Skills:     $InstallRoot\skills\ (16 skills)" -ForegroundColor White
    Write-Host "  Hooks:      $InstallRoot\hooks\ (9 hooks + 1 wrapper, bash + PowerShell)" -ForegroundColor White
    Write-Host "  Agents:     $InstallRoot\agents\ (3 subagents)" -ForegroundColor White
    Write-Host "  Settings:   $InstallRoot\settings.json" -ForegroundColor White
    Write-Host "  Foundation: $BlueprintRoot\foundation\ (22 templates)" -ForegroundColor White
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
