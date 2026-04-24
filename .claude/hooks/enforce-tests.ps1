# enforce-tests.ps1
# Blueprint v11 (IMPROVED): Block new implementation writes when tests are failing
# Runs as PreToolUse hook with matcher "Write|Edit|MultiEdit"
# Per Anthropic hook spec: input arrives as JSON on stdin, exit 2 blocks.

$ErrorActionPreference = "SilentlyContinue"

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrEmpty($rawInput)) { exit 0 }

try {
    $data = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$toolName = $data.tool_name
if ($toolName -notin @("Write", "Edit", "MultiEdit")) { exit 0 }

$filePath = $null
if ($data.tool_input) {
    if ($data.tool_input.file_path) { $filePath = $data.tool_input.file_path }
    elseif ($data.tool_input.path) { $filePath = $data.tool_input.path }
}
if ([string]::IsNullOrEmpty($filePath)) { exit 0 }

# Skip test files and non-source files
if ($filePath -imatch "test|spec|__tests__|\.md$|\.json$|\.ya?ml$|\.toml$|\.txt$|\.lock$|\.env") {
    exit 0
}

# Detect test suite presence
$hasPytest = (Test-Path "pytest.ini") -or (Test-Path "pyproject.toml") -or (Test-Path "apps/api/pyproject.toml")
$hasVitest = (Test-Path "vitest.config.ts") -or (Test-Path "vitest.config.js") -or (Test-Path "apps/web/vitest.config.ts")

if (-not $hasPytest -and -not $hasVitest) { exit 0 }

# Marker-based throttling: skip re-running if tests passed recently
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $PWD }
$markerDir = Join-Path $projectDir ".claude/state"
$markerFile = Join-Path $markerDir "tests-passing-marker"
New-Item -ItemType Directory -Path $markerDir -Force | Out-Null

if (Test-Path $markerFile) {
    $markerAge = (Get-Date) - (Get-Item $markerFile).LastWriteTime
    if ($markerAge.TotalSeconds -lt 60) { exit 0 }
}

$backendStatus = "unknown"
$frontendStatus = "unknown"

if ($hasPytest) {
    Push-Location "apps/api" -ErrorAction SilentlyContinue
    $pytestResult = python -m pytest --tb=no -q --timeout=30 2>&1
    $backendStatus = if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }
    Pop-Location -ErrorAction SilentlyContinue
}

if ($hasVitest) {
    Push-Location "apps/web" -ErrorAction SilentlyContinue
    $vitestResult = pnpm test --run 2>&1
    $frontendStatus = if ($LASTEXITCODE -eq 0) { "pass" } else { "fail" }
    Pop-Location -ErrorAction SilentlyContinue
}

if ($backendStatus -eq "fail" -or $frontendStatus -eq "fail") {
    [Console]::Error.WriteLine("Heads up: tests are currently failing. Fix them before writing new implementation files - that's the test-before-code rule.")
    [Console]::Error.WriteLine("Backend: $backendStatus | Frontend: $frontendStatus")
    [Console]::Error.WriteLine("You may write or edit test files. Non-test source writes are blocked until tests pass.")
    exit 2
}

# Tests pass: touch marker
New-Item -Path $markerFile -ItemType File -Force | Out-Null
exit 0
