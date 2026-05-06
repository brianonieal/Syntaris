# session-start.ps1
# Syntaris: Inject Syntaris mode context at session start
# Runs as SessionStart hook
# Stdout from SessionStart becomes additionalContext for Claude

$ErrorActionPreference = "SilentlyContinue"

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrEmpty($rawInput)) { exit 0 }

$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $PWD }
$contractPath = Join-Path $projectDir "CONTRACT.md"

if (-not (Test-Path $contractPath)) { exit 0 }

$contractContent = Get-Content $contractPath -Raw

$projectName = if ($contractContent -match "PROJECT_NAME:\s*(.+)") { $matches[1].Trim() } else { "unknown" }
$currentVersion = if ($contractContent -match "PROJECT_VERSION:\s*(.+)") { $matches[1].Trim() } else { "v0.0.0" }
$clientType = if ($contractContent -match "CLIENT_TYPE:\s*(.+)") { $matches[1].Trim() } else { "PERSONAL" }

$context = "You are operating under Syntaris methodology."
$context += " Project: $projectName at $currentVersion."
$context += " Client type: $clientType."
$context += " Hard rules: never write code before FRONTEND APPROVED,"
$context += " never advance a gate without the exact approval word,"
$context += " never skip the REFLEXION entry at gate close,"
$context += " never let test count decrease between gates."
$context += " Use /start to begin. Check ERRORS.md before diagnosing any error."

# Check for unclosed stop events
$episodicPath = Join-Path $projectDir "MEMORY_EPISODIC.md"
if (Test-Path $episodicPath) {
    $lastStop = Select-String -Path $episodicPath -Pattern "STOP EVENT" | Select-Object -Last 1
    if ($lastStop) {
        $context += " WARNING: Unclosed STOP EVENT found. Read PLANS.md to resume."
    }
}

# Snapshot error count for diagnostic delta at gate close.
# Counts ERR- entries in ERRORS.md and writes to .syntaris/errors-at-gate-open.count.
# The gate-close-calibration hook reads this to compute the delta.
$errorsPath = Join-Path $projectDir "ERRORS.md"
$errCount = 0
if (Test-Path $errorsPath) {
    $errCount = @(Select-String -Path $errorsPath -Pattern "^(###?\s+)?ERR-" -ErrorAction SilentlyContinue).Count
}
$syntarisState = Join-Path $projectDir ".syntaris"
if (-not (Test-Path $syntarisState)) { New-Item -ItemType Directory -Path $syntarisState -Force | Out-Null }
Set-Content -Path (Join-Path $syntarisState "errors-at-gate-open.count") -Value $errCount -NoNewline -ErrorAction SilentlyContinue

# Output as JSON per Anthropic SessionStart hook spec
# Format: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}
$escapedContext = $context -replace '"', '\"'
Write-Output "{`"hookSpecificOutput`":{`"hookEventName`":`"SessionStart`",`"additionalContext`":`"$escapedContext`"}}"

exit 0
