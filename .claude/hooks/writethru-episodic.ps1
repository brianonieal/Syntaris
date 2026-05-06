# writethru-episodic.ps1
# Syntaris: Write-through to MEMORY_EPISODIC.md on session stop
# Runs as Stop hook

$ErrorActionPreference = "SilentlyContinue"

$rawInput = [Console]::In.ReadToEnd()

# Prevent infinite loop: check stop_hook_active
if (-not [string]::IsNullOrEmpty($rawInput)) {
    try {
        $data = $rawInput | ConvertFrom-Json
        if ($data.stop_hook_active -eq $true) {
            exit 0
        }
    } catch {}
}

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $PWD }
$memoryFile = Join-Path $projectDir "MEMORY_EPISODIC.md"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

if (-not (Test-Path $memoryFile)) { exit 0 }

$activeGate = (Select-String -Path (Join-Path $projectDir "SPEC.md") -Pattern "Active gate:|Current gate:" -ErrorAction SilentlyContinue | Select-Object -First 1).Line
$lastCommit = git log --oneline -1 2>$null

$entry = @"

## STOP EVENT: $timestamp
Session ended (crash or manual stop).
Gate in progress: $activeGate
Last git commit: $lastCommit
Resume: /start option 2
"@

Add-Content -Path $memoryFile -Value $entry
exit 0
