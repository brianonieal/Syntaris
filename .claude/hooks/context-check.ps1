# context-check.ps1
# Syntaris v0.5.3: Warn when context approaches dangerous fill level
# Runs as PostToolUse hook. Turn-count proxy stored per session.
# PowerShell counterpart for the cross-platform install.

$ErrorActionPreference = "SilentlyContinue"

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrEmpty($rawInput)) { exit 0 }

try {
    $data = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$sessionId = $data.session_id
if ([string]::IsNullOrEmpty($sessionId)) { $sessionId = "default" }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR }
              elseif ($env:USERPROFILE) { $env:USERPROFILE }
              elseif ($env:HOME) { $env:HOME }
              else { (Get-Location).Path }
$stateDir = Join-Path $projectDir ".claude/state"
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

$counterFile = Join-Path $stateDir "turns-$sessionId.count"

$current = 0
if (Test-Path $counterFile) {
    try { $current = [int](Get-Content $counterFile -Raw).Trim() } catch { $current = 0 }
}
$current++
Set-Content -Path $counterFile -Value $current -NoNewline

# Thresholds (turns, rough proxy for context percentage)
# Precedence: env var > CONTEXT_BUDGET.md > hardcoded default

$fileWarn = $null
$fileHard = $null

$budgetRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { "." }
$budgetFile = Join-Path $budgetRoot "CONTEXT_BUDGET.md"
if (Test-Path $budgetFile) {
    try {
        $budgetContent = Get-Content $budgetFile -ErrorAction Stop
        foreach ($line in $budgetContent) {
            if ($line -match '^WARN_TURNS:\s*(\d+)') {
                $fileWarn = [int]$matches[1]
            } elseif ($line -match '^HARD_TURNS:\s*(\d+)') {
                $fileHard = [int]$matches[1]
            }
        }
    } catch {
        # ignore parse failures, fall through to defaults
    }
}

if ($env:CONTEXT_WARN_TURNS) {
    $warnTurns = [int]$env:CONTEXT_WARN_TURNS
} elseif ($fileWarn) {
    $warnTurns = $fileWarn
} else {
    $warnTurns = 80
}

if ($env:CONTEXT_HARD_TURNS) {
    $hardTurns = [int]$env:CONTEXT_HARD_TURNS
} elseif ($fileHard) {
    $hardTurns = $fileHard
} else {
    $hardTurns = 120
}

# Sanity floor
if ($warnTurns -lt 1) { $warnTurns = 80 }
if ($hardTurns -lt 1) { $hardTurns = 120 }

if ($current -ge $hardTurns) {
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("Heads up: about $current turns this session (approaching context limit)")
    [Console]::Error.WriteLine("Worth saving state and resetting context now.")
    [Console]::Error.WriteLine("  1. Dump current progress to PLANS.md")
    [Console]::Error.WriteLine("  2. Run /clear (not /compact -- /clear is lossless)")
    [Console]::Error.WriteLine("  3. Start fresh session with /start option 2")
    [Console]::Error.WriteLine("")
} elseif ($current -ge $warnTurns) {
    # Anchor the modulo to $warnTurns so the first warning fires at $warnTurns
    # itself, not at the next multiple of 10.
    if ((($current - $warnTurns) % 10) -eq 0) {
        [Console]::Error.WriteLine("")
        [Console]::Error.WriteLine("Note: about $current turns this session")
        [Console]::Error.WriteLine("Good time to save state to PLANS.md. Run Claude Code's /context for exact usage.")
        [Console]::Error.WriteLine("")
    }
}

exit 0
