# gate-close-calibration.ps1
# Syntaris.3: Write ESTIMATION entries to MEMORY_CORRECTIONS.md at gate close.
#
# Reads:
#   - VERSION_ROADMAP.md for estimated hours of the gate being closed
#   - TIMELOG.md for actual hours (preferred source)
#   - Git commit timestamps as fallback if TIMELOG has no match
# Writes:
#   - One ESTIMATION: line appended to MEMORY_CORRECTIONS.md
#
# Usage:
#   gate-close-calibration.ps1 -Version "v0.3.0"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Continue"

$projDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
# v0.6.0: foundation files live in foundation/ by Syntaris convention.
# Older projects keep them at root. Try foundation/ first, fall back.
function Resolve-FoundationFile($projDir, $fname) {
    $foundationDir  = Join-Path $projDir "foundation"
    $foundationPath = Join-Path $foundationDir $fname
    $rootPath = Join-Path $projDir $fname
    if (Test-Path $foundationPath) { return $foundationPath }
    if (Test-Path $rootPath)       { return $rootPath }
    if (Test-Path $foundationDir)  { return $foundationPath }
    return $rootPath  # legacy fallback when neither exists
}

$roadmap     = Resolve-FoundationFile $projDir "VERSION_ROADMAP.md"
$timelog     = Resolve-FoundationFile $projDir "TIMELOG.md"
$corrections = Resolve-FoundationFile $projDir "MEMORY_CORRECTIONS.md"

if (-not (Test-Path $roadmap)) {
    [Console]::Error.WriteLine("gate-close-calibration: VERSION_ROADMAP.md not found at $roadmap")
    exit 1
}

# --- Extract estimated hours ---
$estimated = $null
$roadmapLines = Get-Content $roadmap -ErrorAction SilentlyContinue
foreach ($line in $roadmapLines) {
    $versionEscaped = [regex]::Escape($Version)
    if ($line -match "(?:^|[^0-9])${versionEscaped}(?:[^0-9]|$)") {
        if ($line -match '([0-9]+(?:\.[0-9]+)?)-([0-9]+(?:\.[0-9]+)?)\s*h(?:ours?)?\b') {
            $low = [double]$matches[1]
            $high = [double]$matches[2]
            $estimated = ($low + $high) / 2
            break
        }
        if ($line -match '([0-9]+(?:\.[0-9]+)?)\s*h(?:ours?)?\b') {
            $estimated = [double]$matches[1]
            break
        }
    }
}

if (-not $estimated) {
    [Console]::Error.WriteLine("gate-close-calibration: could not find estimated hours for $Version in $roadmap")
    [Console]::Error.WriteLine("  Expected format: a line containing '$Version' and a value like '2.5h' or '2.5 hours'")
    exit 1
}

# --- Determine actual hours ---
$actual = $null
$actualSource = $null

if (Test-Path $timelog) {
    $totalHours = 0.0
    $matched = 0
    $timelogLines = Get-Content $timelog -ErrorAction SilentlyContinue
    foreach ($line in $timelogLines) {
        if ($line -match '^\|[-: |]+\|$') { continue }
        if ($line -match '^\| Date') { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $parts = $line.Split('|')
        if ($parts.Count -lt 6) { continue }

        $gate = $parts[2].Trim()
        $hoursStr = $parts[4].Trim()

        if ($gate -eq $Version -and $hoursStr -match '^[0-9]+(\.[0-9]+)?$') {
            $totalHours += [double]$hoursStr
            $matched++
        }
    }

    if ($matched -gt 0 -and $totalHours -gt 0) {
        $actual = "{0:F2}" -f $totalHours
        $actualSource = "timelog"
    }
}

if (-not $actual -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $isGitRepo = $false
    try {
        $null = & git -C $projDir rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -eq 0) { $isGitRepo = $true }
    } catch {}

    if ($isGitRepo) {
        $commitTimes = & git -C $projDir log --all --grep=$Version --format="%ct" --reverse 2>$null

        if (-not $commitTimes) {
            $tags = & git -C $projDir tag --list 'syntaris-gate-*' 'blueprint-gate-*' --sort=-version:refname 2>$null
            if ($tags -and $tags.Count -ge 2) {
                $prevTag = $tags[1]
                $commitTimes = & git -C $projDir log "${prevTag}..HEAD" --format="%ct" --reverse 2>$null
            }
        }

        if ($commitTimes) {
            $times = @($commitTimes | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [long]$_ })
            if ($times.Count -gt 1) {
                $totalSec = 0
                for ($i = 1; $i -lt $times.Count; $i++) {
                    $gap = $times[$i] - $times[$i-1]
                    if ($gap -gt 0 -and $gap -le 7200) {
                        $totalSec += $gap
                    }
                }
                if ($totalSec -gt 0) {
                    $actual = "{0:F2}" -f ($totalSec / 3600)
                    $actualSource = "git"
                }
            }
        }
    }
}

if (-not $actual) {
    [Console]::Error.WriteLine("gate-close-calibration: could not determine actual hours for $Version")
    [Console]::Error.WriteLine("  Neither TIMELOG.md (matching Gate=$Version rows) nor git commits")
    [Console]::Error.WriteLine("  (containing '$Version' or since prior gate tag) produced a value.")
    exit 1
}

# --- Diagnostic delta: error count at gate open vs gate close ---
#
# The session-start hook snapshots the ERR- count in ERRORS.md to
# .syntaris/errors-at-gate-open.count. We read that snapshot here
# and count the current ERR- entries to compute the delta.

$errorsFile = Resolve-FoundationFile $projDir "ERRORS.md"
$gateOpenCountFile = Join-Path (Join-Path $projDir ".syntaris") "errors-at-gate-open.count"

$errorsClose = 0
if (Test-Path $errorsFile) {
    $errorsClose = @(Select-String -Path $errorsFile -Pattern "^(###?\s+)?ERR-" -ErrorAction SilentlyContinue).Count
}

$errorsOpen = 0
if (Test-Path $gateOpenCountFile) {
    $rawCount = (Get-Content $gateOpenCountFile -ErrorAction SilentlyContinue) -replace '[^0-9]', ''
    if ($rawCount -match '^\d+$') { $errorsOpen = [int]$rawCount }
}

$varPct = (([double]$actual - [double]$estimated) / [double]$estimated) * 100
$variance = "{0:+#;-#;0}%" -f [math]::Round($varPct)
$varianceAbs = [math]::Abs([math]::Round($varPct))

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$entry = "ESTIMATION: gate=$Version estimated=${estimated}h actual=${actual}h variance=$variance source=$actualSource errors_open=$errorsOpen errors_close=$errorsClose date=$timestamp"

if (-not (Test-Path $corrections)) {
    $header = @(
        "# MEMORY_CORRECTIONS.md"
        "# Syntaris | Calibration data and reflexion entries"
        ""
        "## REFLEXION LOG"
        ""
        $entry
    ) -join "`n"
    Set-Content -Path $corrections -Value $header
    [Console]::Error.WriteLine("gate-close-calibration: created MEMORY_CORRECTIONS.md with first entry")
    [Console]::Error.WriteLine("  $entry")
} else {
    $lines = @(Get-Content $corrections -ErrorAction SilentlyContinue)
    $headerIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## REFLEXION LOG') {
            $headerIdx = $i
            break
        }
    }

    if ($headerIdx -ge 0) {
        $sectionEnd = $lines.Count
        for ($i = $headerIdx + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^## ' -and $lines[$i] -notmatch '^## REFLEXION LOG') {
                $sectionEnd = $i
                break
            }
        }

        # Strip placeholder lines and any prior ESTIMATION line for this same
        # gate. Dropping the prior row makes re-runs idempotent: if the hook
        # is invoked twice for the same version (e.g., after fixing a TIMELOG
        # typo) we overwrite the old row instead of stacking duplicates.
        $priorPrefix = "ESTIMATION: gate=$Version "
        $kept = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -gt $headerIdx -and $i -lt $sectionEnd) {
                if ($lines[$i] -eq '[Empty until first gate close]') { continue }
                if ($lines[$i].StartsWith($priorPrefix)) { continue }
            }
            $kept += $lines[$i]
        }
        $lines = $kept

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^## REFLEXION LOG') { $headerIdx = $i; break }
        }

        $insertAt = -1
        for ($i = $headerIdx + 1; $i -lt $lines.Count; $i++) {
            if ([string]::IsNullOrWhiteSpace($lines[$i])) {
                $insertAt = $i + 1
                break
            }
        }
        if ($insertAt -lt 0) { $insertAt = $headerIdx + 1 }

        $newLines = @()
        if ($insertAt -gt 0) { $newLines += $lines[0..($insertAt - 1)] }
        $newLines += $entry
        if ($insertAt -lt $lines.Count) {
            $newLines += $lines[$insertAt..($lines.Count - 1)]
        }
        Set-Content -Path $corrections -Value ($newLines -join "`n")
        [Console]::Error.WriteLine("gate-close-calibration: inserted into REFLEXION LOG section of MEMORY_CORRECTIONS.md")
    } else {
        Add-Content -Path $corrections -Value $entry
        [Console]::Error.WriteLine("gate-close-calibration: appended to MEMORY_CORRECTIONS.md (no REFLEXION LOG section found)")
    }
    [Console]::Error.WriteLine("  $entry")
}

if ($varianceAbs -gt 30) {
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("=== Heads up: $Version came in at $variance variance ===")
    [Console]::Error.WriteLine("That is data for future estimates. Approved ranges for later gates were")
    [Console]::Error.WriteLine("set before this data point and may warrant review before starting the next")
    [Console]::Error.WriteLine("gate. The approved roadmap has not been edited; that's your call.")
    [Console]::Error.WriteLine("")
}

# --- Pattern extraction (v0.5.0+) ---
# After every gate close, attempt to extract patterns. The extractor
# is bash-only; we invoke it via Git Bash if available. If not, skip
# silently - the user can run /validate later to surface patterns.

$extractor = $null
$libCandidates = @(
    (Join-Path $env:USERPROFILE ".claude\lib\extract-patterns.sh"),
    (Join-Path $projDir ".claude\lib\extract-patterns.sh")
)
foreach ($c in $libCandidates) {
    if (Test-Path $c) { $extractor = $c; break }
}

if ($extractor -and (Get-Command bash -ErrorAction SilentlyContinue)) {
    try {
        $env:CLAUDE_PROJECT_DIR = $projDir
        $extractorOut = & bash $extractor 2>&1
        $proposalLine = $extractorOut | Select-String -Pattern "wrote [1-9][0-9]* proposals"
        if ($proposalLine) {
            [Console]::Error.WriteLine("")
            [Console]::Error.WriteLine("=== Pattern extraction ===")
            $extractorOut | Select-String -Pattern "wrote [0-9]+ proposals|/health --review-patterns" | ForEach-Object {
                [Console]::Error.WriteLine($_.Line)
            }
            [Console]::Error.WriteLine("")
        }
    } catch {
        # Silently swallow - pattern extraction is opportunistic, not required
    }
}

exit 0
