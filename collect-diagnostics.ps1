# collect-diagnostics.ps1
# Syntaris: gather everything needed to report a bug
#
# Produces a single bp-diagnostics-<timestamp>.txt file you can send to
# whoever you're asking for help. No secrets are collected. Review the
# output before sending if you're worried about leakage.

param(
    [string]$InstallRoot = "$env:USERPROFILE\.claude",
    [string]$SyntarisRoot = "$env:USERPROFILE\Syntaris"
)

$ErrorActionPreference = "Continue"

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$out = "bp-diagnostics-${ts}.txt"

$lines = @()

function Add-Line {
    param([string]$text = "")
    $script:lines += $text
}

Add-Line "============================================"
Add-Line "  Syntaris Diagnostics"
Add-Line "  Generated: $(Get-Date -Format o)"
Add-Line "============================================"

Add-Line ""
Add-Line "## ENVIRONMENT"
Add-Line ""
Add-Line "OS: $([System.Environment]::OSVersion.VersionString)"
Add-Line "Windows build: $((Get-CimInstance Win32_OperatingSystem).BuildNumber)"
Add-Line "Architecture: $([System.Environment]::Is64BitOperatingSystem)"
Add-Line "PowerShell version: $($PSVersionTable.PSVersion)"
Add-Line "PowerShell edition: $($PSVersionTable.PSEdition)"
Add-Line "Execution policy: $(Get-ExecutionPolicy)"
try { Add-Line "Git version: $(git --version 2>$null)" } catch { Add-Line "Git: not installed" }
try { Add-Line "Node version: $(node --version 2>$null)" } catch { Add-Line "Node: not installed" }
try { Add-Line "Python version: $(python --version 2>$null)" } catch { Add-Line "Python: not installed" }
if (Get-Command bash -ErrorAction SilentlyContinue) {
    try {
        $bashProbe = & bash -c "echo ok" 2>$null
        if ($LASTEXITCODE -eq 0 -and $bashProbe -match "ok") {
            Add-Line "Bash available: yes (functional)"
        } else {
            Add-Line "Bash available: yes (but not functional - may be WSL launcher without WSL installed)"
        }
    } catch { Add-Line "Bash: on PATH but errored when probed" }
} else {
    Add-Line "Bash: not available"
}
Add-Line "Locale: $([System.Globalization.CultureInfo]::CurrentCulture.Name)"

Add-Line ""
Add-Line "## INSTALL PATHS"
Add-Line ""
Add-Line "InstallRoot: $InstallRoot"
Add-Line "SyntarisRoot: $SyntarisRoot"
Add-Line "InstallRoot exists: $(if (Test-Path $InstallRoot) {'yes'} else {'NO'})"
Add-Line "SyntarisRoot exists: $(if (Test-Path $SyntarisRoot) {'yes'} else {'NO'})"

Add-Line ""
Add-Line "## INSTALL CONTENTS"
Add-Line ""
if (Test-Path $InstallRoot) {
    $skillsDir = Join-Path $InstallRoot "skills"
    $hooksDir = Join-Path $InstallRoot "hooks"
    $agentsDir = Join-Path $InstallRoot "agents"
    $settingsFile = Join-Path $InstallRoot "settings.json"

    $skillCount = if (Test-Path $skillsDir) { (Get-ChildItem $skillsDir -Directory).Count } else { 0 }
    Add-Line "Skills installed: $skillCount"
    if ($skillCount -gt 0) {
        Get-ChildItem $skillsDir -Directory | ForEach-Object { Add-Line "  $($_.Name)" }
    }
    Add-Line ""

    $hookCount = if (Test-Path $hooksDir) { (Get-ChildItem $hooksDir -File).Count } else { 0 }
    Add-Line "Hooks installed: $hookCount"
    if ($hookCount -gt 0) {
        Get-ChildItem $hooksDir -File | ForEach-Object { Add-Line "  $($_.Name)" }
    }
    Add-Line ""

    $agentCount = if (Test-Path $agentsDir) { (Get-ChildItem $agentsDir -File).Count } else { 0 }
    Add-Line "Agents installed: $agentCount"
    if ($agentCount -gt 0) {
        Get-ChildItem $agentsDir -File | ForEach-Object { Add-Line "  $($_.Name)" }
    }
    Add-Line ""

    if (Test-Path $settingsFile) {
        $size = (Get-Item $settingsFile).Length
        Add-Line "settings.json size: $size bytes"
    } else {
        Add-Line "settings.json: MISSING"
    }
} else {
    Add-Line "(install root does not exist - Syntaris not installed at this location)"
}

Add-Line ""
Add-Line "## FOUNDATION FILES"
Add-Line ""
$foundationDir = Join-Path $SyntarisRoot "foundation"
if (Test-Path $foundationDir) {
    $foundationFiles = Get-ChildItem $foundationDir -File
    Add-Line "Foundation files: $($foundationFiles.Count)"
    $foundationFiles | ForEach-Object { Add-Line "  $($_.Name)" }
} else {
    Add-Line "(foundation directory not found at $foundationDir)"
}

Add-Line ""
Add-Line "## SETTINGS.JSON VALIDITY"
Add-Line ""
$settingsFile = Join-Path $InstallRoot "settings.json"
if (Test-Path $settingsFile) {
    try {
        $null = Get-Content $settingsFile -Raw | ConvertFrom-Json
        Add-Line "Valid JSON"
    } catch {
        Add-Line "INVALID JSON. Error: $($_.Exception.Message)"
        Add-Line "First 20 lines:"
        Get-Content $settingsFile -TotalCount 20 | ForEach-Object { Add-Line "  $_" }
    }
} else {
    Add-Line "settings.json not present"
}

Add-Line ""
Add-Line "## POWERSHELL HOOK SYNTAX"
Add-Line ""
$hooksDir = Join-Path $InstallRoot "hooks"
if (Test-Path $hooksDir) {
    $ps1Hooks = Get-ChildItem $hooksDir -Filter "*.ps1"
    foreach ($hook in $ps1Hooks) {
        try {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                $hook.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            if ($errors -and $errors.Count -gt 0) {
                Add-Line "  PARSE ERROR: $($hook.Name) - $($errors[0].Message)"
            } else {
                Add-Line "  ok: $($hook.Name)"
            }
        } catch {
            Add-Line "  EXCEPTION: $($hook.Name) - $($_.Exception.Message)"
        }
    }
}

Add-Line ""
Add-Line "## RECENT HOOK ERROR LOGS"
Add-Line ""
$tmpDir = if ($env:TEMP) { $env:TEMP } else { "C:\Windows\Temp" }
$cutoff = (Get-Date).AddDays(-7)
$hookLogs = Get-ChildItem -Path $tmpDir -Filter "bp-hook-err-*.log" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt $cutoff }

if ($hookLogs) {
    Add-Line "Found hook error logs in $tmpDir (last 7 days):"
    foreach ($log in $hookLogs) {
        Add-Line ""
        Add-Line "--- $($log.FullName) ---"
        if ($log.Length -gt 0) {
            $content = Get-Content $log.FullName -TotalCount 50
            foreach ($line in $content) { Add-Line "  $line" }
            $total = (Get-Content $log.FullName | Measure-Object -Line).Lines
            if ($total -gt 50) {
                Add-Line "  (truncated; full log is $total lines)"
            }
        } else {
            Add-Line "  (empty)"
        }
    }
} else {
    Add-Line "No recent hook error logs found in $tmpDir"
}

Add-Line ""
Add-Line "## VERIFY OUTPUT"
Add-Line ""

$scriptDir = Split-Path -Parent $PSCommandPath
$verifyScript = Join-Path $scriptDir "verify.ps1"
if (Test-Path $verifyScript) {
    Add-Line "Running: verify.ps1 -InstallRoot $InstallRoot"
    Add-Line ""
    try {
        # Use the running PowerShell binary (not hardcoded powershell.exe) so
        # this works on PS 5.1, PS 7, and non-Windows PS alike.
        $pwshExe = (Get-Process -Id $PID).Path
        $verifyOut = & $pwshExe -NoProfile -ExecutionPolicy Bypass -File $verifyScript -InstallRoot $InstallRoot 2>&1
        foreach ($line in $verifyOut) {
            Add-Line "  $line"
        }
    } catch {
        Add-Line "  verify.ps1 threw: $($_.Exception.Message)"
    }
} else {
    Add-Line "verify.ps1 not found next to this diagnostic script."
    Add-Line "Run it manually and paste the output when reporting."
}

Add-Line ""
Add-Line "============================================"
Add-Line "  End of diagnostics"
Add-Line "  File: $out"
Add-Line "============================================"

Set-Content -Path $out -Value ($lines -join "`n") -Encoding UTF8

Write-Host ""
Write-Host "Diagnostics written to: $out" -ForegroundColor Green
Write-Host ""
Write-Host "Before sending, you may want to skim it for anything you don't want to"
Write-Host "share (e.g., custom paths that reveal your username). The script does"
Write-Host "not collect file contents beyond settings.json, but paths and skill"
Write-Host "names will be present."
Write-Host ""
Write-Host "Send this file to whoever is helping you debug."
