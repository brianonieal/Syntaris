# skill-telemetry.ps1
# Blueprint v11.3: Log skill-invocation signals to a jsonl file.
#
# UserPromptSubmit hook. Scans installed skills' SKILL.md descriptions for
# trigger phrases, logs matches to ~/.claude/state/skill-log.jsonl.
#
# Opt out by creating ~/.claude/state/telemetry-off (touch an empty file).

$ErrorActionPreference = "Continue"

$input_data = [Console]::In.ReadToEnd()
if ([string]::IsNullOrEmpty($input_data)) { exit 0 }

$session = "unknown"
$prompt = ""
try {
    $parsed = $input_data | ConvertFrom-Json -ErrorAction Stop
    if ($parsed.session_id) { $session = $parsed.session_id }
    if ($parsed.prompt) { $prompt = $parsed.prompt }
    elseif ($parsed.user_prompt) { $prompt = $parsed.user_prompt }
} catch {
    # Fallback regex if JSON parse fails
    if ($input_data -match '"session_id"\s*:\s*"([^"]+)"') { $session = $matches[1] }
    if ($input_data -match '"prompt"\s*:\s*"([^"]+)"') { $prompt = $matches[1] }
}

if ([string]::IsNullOrEmpty($prompt)) { exit 0 }

# Resolve the user-profile root. On Windows $env:USERPROFILE is always set;
# on macOS / Linux PowerShell 7 it is null, so fall back to $HOME. Keeping
# both lets the hook run wherever PowerShell runs, without changing the
# Windows default.
$userRoot = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($env:HOME) { $env:HOME } else { (Get-Location).Path }
$skillsDir = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $userRoot ".claude/skills" }
$logDir = Join-Path $userRoot ".claude/state"
$logFile = Join-Path $logDir "skill-log.jsonl"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Opt-out marker
if (Test-Path (Join-Path $logDir "telemetry-off")) { exit 0 }

if (-not (Test-Path $skillsDir)) { exit 0 }

$promptLower = $prompt.ToLower()
$promptHint = if ($prompt.Length -gt 120) { $prompt.Substring(0, 120) } else { $prompt }
$promptHint = $promptHint -replace "[`r`n]", " " -replace '\\', '\\\\' -replace '"', '\"'

# IMPORTANT: do not name this variable $matches. $matches is an automatic
# PowerShell variable that every `-match` / `-notmatch` operation writes to
# as a hashtable; using that name here causes `+= $skillName` to throw
# "A hash table can only be added to another hash table." on every prompt.
$matchedSkills = @()

Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $skillName = $_.Name
    $skillMd = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path $skillMd)) { return }

    # Extract frontmatter description
    $content = Get-Content $skillMd -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }

    $description = ""
    if ($content -match '(?s)^---\s*\n(.*?)\n---') {
        $frontmatter = $matches[1]
        if ($frontmatter -match '(?ms)^description:\s*(.+?)(?=^\w+:|\Z)') {
            $description = $matches[1] -replace '\s+', ' '
            $description = $description.Trim().ToLower()
        }
    }
    if ([string]::IsNullOrEmpty($description)) { return }

    $matched = $false

    if ($promptLower.Contains($skillName)) { $matched = $true }
    elseif ($promptLower.Contains("/$skillName")) { $matched = $true }
    else {
        # Curated natural-language keywords per skill. Kept conservative.
        $kw = switch ($skillName) {
            'rollback'         { '(roll back|revert to|undo to|restore (a|the) (earlier|previous) gate)' }
            'testing'          { '(write tests?|add tests?|test coverage|run the tests?|failing tests?|pytest|vitest|playwright)' }
            'debug'            { '(debug|fix (this|the) error|why is this failing|stack trace|error message|not working|broken)' }
            'deployment'       { '(deploy|push to (prod|production|staging)|ship it|release)' }
            'security'         { '(security (audit|check|review|scan)|vulnerabilit|owasp|secrets? (leak|exposed))' }
            'performance'      { '(performance|slow|latency|load test|benchmark|profiling|optimize)' }
            'critical-thinker' { '(architectu|design decision|pressure[ -]?test|second opinion|review (this|the) (stack|decision|approach)|tech stack)' }
            'build-rules'      { '(new (project|app|build)|start (a|the) build|plan (a|the) (app|build|project)|build (a|an) (app|tool)|make (a|an) (app|tool))' }
            'freelance-billing'{ '(invoice|billable hours|hours worked|how many hours|bill (for|the) client|timelog)' }
            'handoff'          { '(hand[ -]?off|deliver to client|client handoff|project complete)' }
            'health'           { '(health check|audit blueprint|blueprint audit)' }
            'research'         { '(competitive (intel|intelligence|analysis)|research (the )?market|look up (the )?competitors?|competitor analysis)' }
            'costs'            { '(how much will (this|it) cost|cost (estimate|projection|forecast)|monthly bill|pricing for)' }
            'onboard'          { '(new client|client (intake|onboarding)|send (the )?proposal|draft (a )?contract)' }
            'start'            { '(resume (the|this) project|pick (this|it) up|continue from|where did we leave)' }
            default            { $null }
        }

        if ($kw -and $promptLower -match $kw) {
            $matched = $true
        }

        # Fallback: any /command triggers mentioned in description
        if (-not $matched) {
            $triggers = [regex]::Matches($description, '/[a-z][a-z0-9-]+') |
                        ForEach-Object { $_.Value } | Select-Object -Unique
            foreach ($trig in $triggers) {
                if ($promptLower.Contains($trig)) {
                    $matched = $true
                    break
                }
            }
        }
    }

    if ($matched) {
        $script:matchedSkills += $skillName
    }
}

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$sessionEsc = $session -replace '\\', '\\\\' -replace '"', '\"'

if ($matchedSkills.Count -eq 0) {
    $line = '{"ts":"' + $ts + '","skill":null,"session":"' + $sessionEsc + '","prompt_hint":"' + $promptHint + '"}'
    Add-Content -Path $logFile -Value $line
} else {
    foreach ($skill in $matchedSkills) {
        $line = '{"ts":"' + $ts + '","skill":"' + $skill + '","session":"' + $sessionEsc + '","prompt_hint":"' + $promptHint + '"}'
        Add-Content -Path $logFile -Value $line
    }
}

exit 0
