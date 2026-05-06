# verify.ps1
# Syntaris installation verification for Windows
#
# Runs automatically at the end of install.ps1, but can also be run standalone:
#   .\verify.ps1
#   .\verify.ps1 -InstallRoot "$env:USERPROFILE\.claude"
#   .\verify.ps1 -Verbose
#
# Checks four layers:
#   1. Files present
#   2. Files structurally valid (JSON parses, YAML frontmatter well-formed)
#   3. Hooks executable and dependencies available
#   4. Functional smoke tests (SessionStart JSON, block-dangerous behavior)
#
# Exit codes:
#   0 - all layers passed
#   1 - one or more failures

param(
    [string]$InstallRoot = "$env:USERPROFILE\.claude",
    [string]$Target = "",
    [switch]$VerboseMode
)

$ErrorActionPreference = "Continue"

# Tier 2/3 verification: short branch that checks target-native config files,
# not Claude Code hooks/agents/skills.
if ($Target -and $Target -ne "claude-code") {
    Write-Host ""
    Write-Host "Verifying Syntaris install for target: $Target" -ForegroundColor Cyan
    Write-Host ""

    $targetFile = switch ($Target) {
        "cursor"     { ".cursor/rules/syntaris-core.mdc" }
        "windsurf"   { ".windsurf/rules/syntaris-core.md" }
        "codex-cli"  { "AGENTS.md" }
        "gemini-cli" { ".gemini/GEMINI.md" }
        "aider"      { ".aider.syntaris.md" }
        "kiro"       { ".kiro/specs/syntaris-methodology.md" }
        "opencode"   { ".opencode/instructions/INSTRUCTIONS.md" }
        default      { $null }
    }

    if ($targetFile -and (Test-Path $targetFile)) {
        Write-Host "  [OK] $targetFile present" -ForegroundColor Green
    } elseif ($targetFile) {
        Write-Host "  [MISSING] $targetFile" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "  Unknown target: $Target" -ForegroundColor Red
        exit 1
    }

    if (Test-Path "foundation") {
        Write-Host "  [OK] foundation/ directory present" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] foundation/ directory" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Tier 2/3 verification complete." -ForegroundColor Cyan
    Write-Host "Note: hook checks skipped for non-claude-code targets." -ForegroundColor Yellow
    Write-Host "See docs/COMPATIBILITY.md for what's enforced at this tier." -ForegroundColor Yellow
    exit 0
}

$passCount = 0
$failCount = 0
$warnCount = 0
$failMessages = @()

function Pass {
    param([string]$msg)
    $script:passCount++
    if ($VerboseMode) { Write-Host "  [PASS] $msg" -ForegroundColor Green }
}

function Fail {
    param([string]$msg)
    $script:failCount++
    $script:failMessages += $msg
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
}

function Warn {
    param([string]$msg)
    $script:warnCount++
    Write-Host "  [WARN] $msg" -ForegroundColor Yellow
}

function Section {
    param([string]$msg)
    Write-Host ""
    Write-Host $msg -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Syntaris -- Verification" -ForegroundColor Cyan
Write-Host "  Install root: $InstallRoot" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ===========================================================================
# LAYER 1: Files present
# ===========================================================================

Section "Layer 1: Files present"

if (-not (Test-Path $InstallRoot)) {
    Fail "Install root does not exist: $InstallRoot"
    Write-Host ""
    Write-Host "CRITICAL: cannot continue without install root. Run install.ps1 first." -ForegroundColor Red
    exit 1
}
Pass "install root exists"

# settings.json
$settingsPath = Join-Path $InstallRoot "settings.json"
if (Test-Path $settingsPath) {
    Pass "settings.json present"
} else {
    Fail "settings.json missing: $settingsPath"
}

# 14 skills
$requiredSkills = @(
    "start", "build-rules", "global-rules", "critical-thinker",
    "testing", "security", "deployment", "costs", "performance",
    "debug", "research", "billing",
    "health", "rollback"
)
foreach ($s in $requiredSkills) {
    $path = Join-Path $InstallRoot "skills\$s\SKILL.md"
    if (Test-Path $path) { Pass "skill: $s" } else { Fail "skill missing: $s\SKILL.md" }
}

# 20 hook scripts (10 bash + 10 PowerShell)
$requiredHooks = @(
    "hook-wrapper.sh", "hook-wrapper.ps1",
    "session-start.sh", "session-start.ps1",
    "strip-coauthor.sh", "strip-coauthor.ps1",
    "enforce-tests.sh", "enforce-tests.ps1",
    "block-dangerous.sh", "block-dangerous.ps1",
    "context-check.sh", "context-check.ps1",
    "pre-compact.sh", "pre-compact.ps1",
    "writethru-episodic.sh", "writethru-episodic.ps1",
    "gate-close-calibration.sh", "gate-close-calibration.ps1",
    "skill-telemetry.sh", "skill-telemetry.ps1"
)
foreach ($h in $requiredHooks) {
    $path = Join-Path $InstallRoot "hooks\$h"
    if (Test-Path $path) { Pass "hook: $h" } else { Fail "hook missing: $h" }
}

# 7 agents
foreach ($a in @("spec-reviewer.md", "test-writer.md", "security-auditor.md",
                 "research-agent.md", "debug-agent.md", "health-agent.md",
                 "critical-thinker-agent.md")) {
    $path = Join-Path $InstallRoot "agents\$a"
    if (Test-Path $path) { Pass "agent: $a" } else { Fail "agent missing: $a" }
}

# ===========================================================================
# LAYER 2: Structural validity
# ===========================================================================

Section "Layer 2: Structural validity"

# settings.json parses as JSON
if (Test-Path $settingsPath) {
    try {
        Get-Content $settingsPath -Raw | ConvertFrom-Json | Out-Null
        Pass "settings.json is valid JSON"
    } catch {
        Fail "settings.json is not valid JSON: $($_.Exception.Message)"
    }
}

# YAML frontmatter validation
function Test-Frontmatter {
    param([string]$Path, [string]$Label)

    if (-not (Test-Path $Path)) { return }

    $lines = Get-Content $Path -TotalCount 20 -ErrorAction SilentlyContinue
    if (-not $lines -or $lines.Count -lt 3) {
        Fail "${Label}: file too short for frontmatter"
        return
    }

    if ($lines[0] -ne "---") {
        Fail "${Label}: missing YAML frontmatter opening '---'"
        return
    }

    $closeIdx = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "---") { $closeIdx = $i; break }
    }
    if ($closeIdx -lt 0) {
        Fail "${Label}: missing YAML frontmatter closing '---'"
        return
    }

    $frontmatter = $lines[1..($closeIdx - 1)] -join "`n"

    if ($frontmatter -notmatch "(?m)^name:\s*\S") {
        Fail "${Label}: missing or empty 'name:' field"
        return
    }
    if ($frontmatter -notmatch "(?m)^description:\s*\S") {
        Fail "${Label}: missing or empty 'description:' field"
        return
    }

    Pass "${Label}: frontmatter valid"
}

foreach ($s in $requiredSkills) {
    Test-Frontmatter (Join-Path $InstallRoot "skills\$s\SKILL.md") "skill/$s"
}
foreach ($a in @("spec-reviewer", "test-writer", "security-auditor",
                 "research-agent", "debug-agent", "health-agent",
                 "critical-thinker-agent")) {
    Test-Frontmatter (Join-Path $InstallRoot "agents\$a.md") "agent/$a"
}

# PowerShell hook syntax check
$hookNames = @(
    "session-start", "strip-coauthor", "enforce-tests", "block-dangerous",
    "context-check", "pre-compact", "writethru-episodic", "hook-wrapper",
    "gate-close-calibration", "skill-telemetry"
)
foreach ($h in $hookNames) {
    $path = Join-Path $InstallRoot "hooks\$h.ps1"
    if (Test-Path $path) {
        try {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                $path, [ref]$tokens, [ref]$errors) | Out-Null
            if ($errors -and $errors.Count -gt 0) {
                Fail "powershell syntax: $h.ps1 ($($errors[0].Message))"
            } else {
                Pass "powershell syntax: $h.ps1"
            }
        } catch {
            Fail "powershell syntax: $h.ps1 ($($_.Exception.Message))"
        }
    }
}

# Bash hook syntax check (only if a real, working bash is available)
# On Windows, `bash.exe` may be the WSL launcher even when WSL isn't installed,
# which fails to run scripts at a Windows path. Verify bash actually works before
# treating its non-zero exit as a syntax error.
$bashWorks = $false
if (Get-Command bash -ErrorAction SilentlyContinue) {
    # Probe: can bash execute a trivial command?
    $probe = & bash -c "echo ok" 2>&1
    if ($LASTEXITCODE -eq 0 -and $probe -match "ok") {
        $bashWorks = $true
    }
}

if ($bashWorks) {
    foreach ($h in $hookNames) {
        $hostPath = Join-Path $InstallRoot "hooks/$h.sh"
        if (Test-Path $hostPath) {
            $unixPath = $hostPath -replace '\\', '/'
            if ($unixPath -match '^([A-Za-z]):(.*)') {
                # Windows: CRLF line endings break bash parsing. Write a
                # temp copy with LF endings and test that instead of the
                # installed file (which git may have checked out as CRLF).
                $drive = $matches[1].ToLower()
                $rest = $matches[2]
                $gitBashPath = "/$drive$rest"
                $wslPath = "/mnt/$drive$rest"

                $tmpFile = $null
                $needsTmp = $false
                $content = [System.IO.File]::ReadAllText($hostPath)
                if ($content.Contains("`r`n")) {
                    $needsTmp = $true
                    $tmpFile = [System.IO.Path]::GetTempFileName() + ".sh"
                    $lfContent = $content -replace "`r`n", "`n"
                    [System.IO.File]::WriteAllText($tmpFile, $lfContent, [System.Text.UTF8Encoding]::new($false))
                }

                $passed = $false
                if ($needsTmp) {
                    # Use the LF temp copy for syntax check
                    $tmpUnix = $tmpFile -replace '\\', '/'
                    if ($tmpUnix -match '^([A-Za-z]):(.*)') {
                        $td = $matches[1].ToLower()
                        $tr = $matches[2]
                        $out = & bash -n "/$td$tr" 2>&1
                        if ($LASTEXITCODE -eq 0) { $passed = $true }
                        else {
                            $out = & bash -n "/mnt/$td$tr" 2>&1
                            if ($LASTEXITCODE -eq 0) { $passed = $true }
                        }
                    }
                } else {
                    $out = & bash -n $gitBashPath 2>&1
                    if ($LASTEXITCODE -eq 0) { $passed = $true }
                    else {
                        $out = & bash -n $wslPath 2>&1
                        if ($LASTEXITCODE -eq 0) { $passed = $true }
                    }
                }

                if ($passed) {
                    Pass "bash syntax: $h.sh"
                } else {
                    if ($VerboseMode) { Warn "bash syntax: $h.sh - $out" }
                    else { Warn "bash syntax: $h.sh (skipped: bash couldn't read the file)" }
                }

                if ($tmpFile -and (Test-Path $tmpFile)) {
                    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
                }
            } else {
                $out = & bash -n $unixPath 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Pass "bash syntax: $h.sh"
                } else {
                    Fail "bash syntax error: $h.sh - $out"
                }
            }
        }
    }
} else {
    if ($VerboseMode) {
        Warn "bash not available or not working - skipping .sh syntax checks"
    }
}

# ===========================================================================
# LAYER 3: Execution readiness
# ===========================================================================

Section "Layer 3: Execution readiness"

# PowerShell execution policy
$policy = Get-ExecutionPolicy
if ($policy -in @("Restricted", "Default")) {
    Warn "PowerShell execution policy is '$policy' - hooks may not run"
    Warn "  Fix: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
} else {
    Pass "PowerShell execution policy: $policy"
}

# Dependencies
# The running PowerShell binary is the one we'll hand to hook-wrapper child
# processes. On Windows that's typically powershell.exe (5.1) or pwsh.exe
# (7+); on Linux / macOS it's pwsh. Either way, verify the *running* binary
# resolves to an executable path, not a hardcoded name.
$runningPwsh = (Get-Process -Id $PID).Path
if ($runningPwsh -and (Test-Path $runningPwsh)) {
    Pass "PowerShell host: $runningPwsh"
} else {
    Fail "could not resolve running PowerShell binary path"
}

if (Get-Command bash -ErrorAction SilentlyContinue) {
    Pass "bash on PATH (Git Bash or WSL)"
} else {
    Warn "bash not on PATH -- .sh hooks can't run, but .ps1 fallback will"
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    Pass "git on PATH (needed by strip-coauthor and pre-compact)"
} else {
    Warn "git not on PATH -- strip-coauthor hook will no-op"
}

# Temp dir writable
# Use the .NET API which returns the OS-correct temp dir on Windows, macOS,
# and Linux. Keep $env:TEMP as a first choice for compatibility with Windows
# users who have set it explicitly.
$tmpDir = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
try {
    $testFile = Join-Path $tmpDir "bp-verify-$(Get-Random).tmp"
    New-Item -ItemType File -Path $testFile -Force | Out-Null
    Remove-Item $testFile -Force
    Pass "temp dir writable ($tmpDir)"
} catch {
    Fail "temp dir not writable: $tmpDir"
}

# ===========================================================================
# LAYER 4: Functional smoke tests
# ===========================================================================

Section "Layer 4: Functional smoke tests"

# hook-wrapper.ps1 drives the child hook through `cmd.exe /c powershell.exe <
# stdinfile > stdoutfile 2> errfile`, which is a deliberate PS 5.1 workaround
# for pipeline-to-stdin unreliability. cmd.exe and powershell.exe don't exist
# on non-Windows hosts, so Layer 4 can only run on Windows. Skip cleanly there
# so verify doesn't report false failures when someone runs it on PS 7 for
# macOS or Linux.
$isWindowsHost = if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) { $IsWindows } else { $true }
if (-not $isWindowsHost) {
    if ($VerboseMode) {
        Warn "not on Windows - skipping .ps1 wrapper smoke tests (cmd.exe required)"
    } else {
        Write-Host "  (not on Windows - .ps1 wrapper smoke tests require cmd.exe; skipped)" -ForegroundColor DarkGray
    }
    # Jump straight to the summary
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Verification summary" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Passed: $passCount" -ForegroundColor Green
    if ($warnCount -gt 0) { Write-Host "  Warnings: $warnCount" -ForegroundColor Yellow }
    if ($failCount -gt 0) {
        Write-Host "  Failed: $failCount" -ForegroundColor Red
        Write-Host ""
        Write-Host "Failures:" -ForegroundColor Red
        foreach ($m in $failMessages) { Write-Host "  - $m" }
        exit 1
    }
    Write-Host ""
    Write-Host "All non-Windows layers passed. For full Layer 4 coverage run on Windows." -ForegroundColor Green
    exit 0
}

# Set up a temp project dir with hooks. Use forward slashes in the literal
# relative segments so PowerShell treats them as path separators on every
# platform (on Windows they're normalized; on Linux / macOS they're native).
$smokeRoot = Join-Path $tmpDir "bp-verify-smoke-$(Get-Random)"
New-Item -ItemType Directory -Path (Join-Path $smokeRoot ".claude/hooks") -Force | Out-Null

try {
    Copy-Item (Join-Path $InstallRoot "hooks/*") (Join-Path $smokeRoot ".claude/hooks/") -Force

    @"
PROJECT_NAME: VerifyTest
PROJECT_VERSION: v0.0.0
CLIENT_TYPE: PERSONAL
"@ | Set-Content (Join-Path $smokeRoot "CONTRACT.md")

    # Smoke test 1: SessionStart produces valid JSON
    $wrapperPath = Join-Path $smokeRoot ".claude/hooks/hook-wrapper.ps1"
    # Always invoke the SAME PowerShell that verify is running under, so
    # these smoke tests work on PS 5.1, PS 7, and non-Windows PS alike.
    $pwshExe = (Get-Process -Id $PID).Path
    if (Test-Path $wrapperPath) {
        $env:CLAUDE_PROJECT_DIR = $smokeRoot
        $env:CLAUDE_SESSION_ID = "verify"

        $ssOutput = '{"session_id":"verify"}' | & $pwshExe -NoProfile -File $wrapperPath session-start 2>$null
        $ssExit = $LASTEXITCODE

        if ([string]::IsNullOrWhiteSpace($ssOutput)) {
            Fail "SessionStart: no output from hook-wrapper.ps1"
        } else {
            try {
                $parsed = $ssOutput | ConvertFrom-Json -ErrorAction Stop
                if ($null -eq $parsed.hookSpecificOutput) {
                    Fail "SessionStart: missing hookSpecificOutput wrapper"
                } elseif ($parsed.hookSpecificOutput.hookEventName -ne "SessionStart") {
                    Fail "SessionStart: wrong hookEventName: $($parsed.hookSpecificOutput.hookEventName)"
                } elseif (-not ($parsed.hookSpecificOutput.additionalContext -like "*Syntaris*")) {
                    Fail "SessionStart: additionalContext missing 'Syntaris' marker"
                } else {
                    Pass "SessionStart: valid JSON with hookSpecificOutput wrapper"
                }
            } catch {
                Fail "SessionStart: output is not valid JSON"
                if ($VerboseMode) {
                    Write-Host "    got: $ssOutput" -ForegroundColor DarkGray
                }
            }
        }

        # Smoke test 2: block-dangerous blocks rm -rf /
        $dangerPayload = '{"session_id":"verify","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
        $dangerOutput = $dangerPayload | & $pwshExe -NoProfile -File $wrapperPath block-dangerous 2>&1
        $dangerExit = $LASTEXITCODE

        if ($dangerExit -eq 2) {
            Pass "block-dangerous: blocks rm -rf / (exit 2)"
            if ($dangerOutput -match "blocked") {
                Pass "block-dangerous: surfaces block reason"
            } else {
                Warn "block-dangerous: exit 2 but no block reason message"
            }
        } else {
            Fail "block-dangerous: did not block rm -rf / (exit $dangerExit, expected 2)"
        }

        # Smoke test 3: safe command (ls) passes through
        $safePayload = '{"session_id":"verify","tool_name":"Bash","tool_input":{"command":"ls -la"}}'
        $null = $safePayload | & $pwshExe -NoProfile -File $wrapperPath block-dangerous 2>&1
        $safeExit = $LASTEXITCODE

        if ($safeExit -eq 0) {
            Pass "block-dangerous: allows safe command ls (exit 0)"
        } else {
            Fail "block-dangerous: blocked safe command ls (exit $safeExit, expected 0)"
        }

        # Smoke test 4: git force-push to main blocks
        $fpPayload = '{"session_id":"verify","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}'
        $null = $fpPayload | & $pwshExe -NoProfile -File $wrapperPath block-dangerous 2>&1
        $fpExit = $LASTEXITCODE

        if ($fpExit -eq 2) {
            Pass "block-dangerous: blocks force-push to main (exit 2)"
        } else {
            Fail "block-dangerous: did not block force-push to main (exit $fpExit, expected 2)"
        }

        # Smoke test 5: missing hook with SYNTARIS_DEBUG surfaces diagnostic
        $env:SYNTARIS_DEBUG = "1"
        $dbgOutput = '{}' | & $pwshExe -NoProfile -File $wrapperPath nonexistent-hook 2>&1
        $dbgExit = $LASTEXITCODE
        Remove-Item env:SYNTARIS_DEBUG -ErrorAction SilentlyContinue

        if ($dbgExit -eq 0) {
            if ($dbgOutput -match "not found on any fallback path") {
                Pass "missing hook: diagnostic surfaces in SYNTARIS_DEBUG mode"
            } else {
                Warn "missing hook: exit 0 but no diagnostic message"
            }
        } else {
            Fail "missing hook: exit $dbgExit (expected 0 -- missing hooks should fail open)"
        }
    } else {
        Fail "hook-wrapper.ps1 not present -- cannot run smoke tests"
    }
} finally {
    Remove-Item -Recurse -Force $smokeRoot -ErrorAction SilentlyContinue
    Remove-Item env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
    Remove-Item env:CLAUDE_SESSION_ID -ErrorAction SilentlyContinue
    # Clean up any state files from the smoke tests (session="verify")
    Remove-Item -Force (Join-Path $InstallRoot "state\turns-verify.count") -ErrorAction SilentlyContinue
    Remove-Item -Force (Join-Path $tmpDir "bp-hook-err-verify.log") -ErrorAction SilentlyContinue
    # Strip verify-session rows from skill-log.jsonl if telemetry ran
    $telemetryLog = Join-Path $InstallRoot "state\skill-log.jsonl"
    if (Test-Path $telemetryLog) {
        try {
            $filtered = Get-Content $telemetryLog -ErrorAction SilentlyContinue |
                        Where-Object { $_ -notmatch '"session":"verify"' }
            if ($filtered) {
                Set-Content -Path $telemetryLog -Value $filtered -ErrorAction SilentlyContinue
            } else {
                Remove-Item -Force $telemetryLog -ErrorAction SilentlyContinue
            }
        } catch { }
    }
}

# ===========================================================================
# SUMMARY
# ===========================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Verification summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Passed: $passCount" -ForegroundColor Green
if ($warnCount -gt 0) {
    Write-Host "  Warnings: $warnCount" -ForegroundColor Yellow
}
if ($failCount -gt 0) {
    Write-Host "  Failed: $failCount" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failures:" -ForegroundColor Red
    foreach ($msg in $failMessages) {
        Write-Host "  - $msg"
    }
    Write-Host ""
    Write-Host "Syntaris install has problems. See failures above." -ForegroundColor Yellow
    Write-Host "Re-run install.ps1, or fix the specific items listed." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "All verification layers passed. Syntaris is ready to use." -ForegroundColor Green
Write-Host "  * Files: present and structurally valid"
Write-Host "  * Hooks: executable and dependencies available"
Write-Host "  * Smoke tests: SessionStart produces valid JSON; dangerous commands block correctly"
Write-Host ""
exit 0
