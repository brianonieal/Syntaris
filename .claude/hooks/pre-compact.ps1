# pre-compact.ps1
# Syntaris: Save state before lossy auto-compaction
# Runs as PreCompact hook

$ErrorActionPreference = "SilentlyContinue"

$rawInput = [Console]::In.ReadToEnd()

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $PWD }
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Create backup directory
$backupDir = Join-Path $projectDir ".claude/backups"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Backup session transcript if accessible. Prefer USERPROFILE (always set on
# Windows) and fall back to HOME for macOS / Linux PowerShell.
$userRoot = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { $null }
if (-not $userRoot) { exit 0 }
$sessionDir = Join-Path $userRoot ".claude/sessions"
if (Test-Path $sessionDir) {
    $latestSession = Get-ChildItem "$sessionDir/*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestSession) {
        $backupName = "pre-compact-$(Get-Date -Format 'yyyyMMdd-HHmmss').jsonl"
        Copy-Item $latestSession.FullName (Join-Path $backupDir $backupName) -Force
    }
}

# Append warning to PLANS.md
$plansPath = Join-Path $projectDir "PLANS.md"
if (Test-Path $plansPath) {
    $lastCommit = git log --oneline -1 2>$null
    $entry = @"

## AUTO-COMPACT WARNING: $timestamp
Context auto-compacted. 70-80% of detail was lost.
Session backup saved to: .claude/backups/
Resume with /start option 2 and read this file carefully.
Last git state: $lastCommit
"@
    Add-Content -Path $plansPath -Value $entry
}

[Console]::Error.WriteLine("Syntaris: Pre-compaction backup saved to .claude/backups/")
exit 0
