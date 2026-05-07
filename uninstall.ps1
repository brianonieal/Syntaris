# uninstall.ps1
# Syntaris v0.6.0: Remove Syntaris-owned files from this machine.
#
# Removes: $InstallRoot\skills, hooks, agents, settings.json, state
# Restores: settings.json.bak if present
# Preserves: foundation templates, personal overlay, per-project files
#
# Usage:
#   .\uninstall.ps1
#   .\uninstall.ps1 -InstallRoot "$env:USERPROFILE\.claude"
#   .\uninstall.ps1 -Force           # skip confirmation
#   .\uninstall.ps1 -DryRun          # show what would be removed

param(
    [string]$InstallRoot = "$env:USERPROFILE\.claude",
    [string]$SyntarisRoot = "$env:USERPROFILE\Syntaris",
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Syntaris Uninstaller" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$toRemove = @()
$toRestore = $null

$skillsPath = Join-Path $InstallRoot "skills"
$hooksPath = Join-Path $InstallRoot "hooks"
$agentsPath = Join-Path $InstallRoot "agents"
$settingsPath = Join-Path $InstallRoot "settings.json"
$statePath = Join-Path $InstallRoot "state"
$bakPath = Join-Path $InstallRoot "settings.json.bak"

if (Test-Path $skillsPath) { $toRemove += $skillsPath }
if (Test-Path $hooksPath) { $toRemove += $hooksPath }
if (Test-Path $agentsPath) { $toRemove += $agentsPath }
if (Test-Path $settingsPath) { $toRemove += $settingsPath }
if (Test-Path $statePath) { $toRemove += $statePath }
if (Test-Path $bakPath) { $toRestore = $bakPath }

if ($toRemove.Count -eq 0 -and -not $toRestore) {
    Write-Host "Nothing to remove. Syntaris does not appear to be installed at:" -ForegroundColor Yellow
    Write-Host "  $InstallRoot"
    exit 0
}

Write-Host ""
Write-Host "The following will be REMOVED:"
foreach ($path in $toRemove) {
    if (Test-Path $path -PathType Container) {
        $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeStr = if ($size) { "{0:N0} bytes" -f $size } else { "empty" }
    } else {
        $size = (Get-Item $path -ErrorAction SilentlyContinue).Length
        $sizeStr = "{0:N0} bytes" -f $size
    }
    Write-Host "  - $path  ($sizeStr)"
}

Write-Host ""
Write-Host "The following will be PRESERVED:"
Write-Host "  - $SyntarisRoot\foundation\   (template files)"
Write-Host "  - personal-overlay\owner-config.md (your personal config, if any)"
Write-Host "  - Any project-side Syntaris files (CONTRACT.md etc in your projects)"

if ($toRestore) {
    Write-Host ""
    Write-Host "A settings.json.bak was found and will be restored after removal." -ForegroundColor Green
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN: nothing removed." -ForegroundColor Cyan
    exit 0
}

if (-not $Force) {
    Write-Host ""
    $reply = Read-Host "Proceed with uninstall? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Aborted."
        exit 0
    }
}

Write-Host ""
foreach ($path in $toRemove) {
    try {
        Remove-Item -Recurse -Force $path -ErrorAction Stop
        Write-Host "  removed: $path" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED to remove: $path ($($_.Exception.Message))" -ForegroundColor Red
    }
}

if ($toRestore) {
    try {
        Move-Item -Path $toRestore -Destination $settingsPath -Force
        Write-Host "  restored: settings.json from .bak" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED to restore settings.json.bak ($($_.Exception.Message))" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Syntaris uninstalled from: $InstallRoot" -ForegroundColor Green
Write-Host ""
Write-Host "If you installed Syntaris on both Windows and WSL sides of this" -ForegroundColor Yellow
Write-Host "machine, run the uninstaller on the other side as well." -ForegroundColor Yellow
Write-Host ""
