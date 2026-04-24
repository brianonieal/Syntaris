# hook-wrapper.ps1
# Blueprint v11: Unified hook invocation for native Windows PowerShell.
# Mirrors hook-wrapper.sh behavior:
#   1. Try $env:CLAUDE_PROJECT_DIR\.claude\hooks\<hook>.ps1
#   2. Fall back to $env:USERPROFILE\.claude\hooks\<hook>.ps1
#   3. Preserve exit 2 (blocking) from the first successful run.
#   4. Surface stderr when BLUEPRINT_DEBUG=1 or when all paths fail.
#
# Usage:
#   powershell.exe -File hook-wrapper.ps1 <hook-name>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$HookName
)

$ErrorActionPreference = "Continue"

# Error log path - per-session when CLAUDE_SESSION_ID is set
$sessionKey = if ($env:CLAUDE_SESSION_ID) { $env:CLAUDE_SESSION_ID } else { "default" }
$tmpDir = if ($env:TEMP) { $env:TEMP } else { "C:\Windows\Temp" }
$errLog = Join-Path $tmpDir "bp-hook-err-$sessionKey.log"

# Ensure log dir exists and truncate log for this invocation
New-Item -ItemType Directory -Path $tmpDir -Force -ErrorAction SilentlyContinue | Out-Null
Set-Content -Path $errLog -Value "" -ErrorAction SilentlyContinue

# Read stdin once
$stdinPayload = [Console]::In.ReadToEnd()

function Invoke-HookScript {
    param([string]$ScriptPath)

    if (-not (Test-Path $ScriptPath)) { return 127 }

    # Write stdin payload to a temp file so the child process gets it reliably.
    # PowerShell 5.1's pipeline-to-stdin conversion is unreliable for subprocesses;
    # using cmd.exe < redirection bypasses that entirely.
    # Use .NET API directly to avoid UTF-8 BOM that Set-Content -Encoding utf8
    # would add in PS5.1 (hooks parse JSON from stdin and a BOM can break parsing).
    $stdinFile = Join-Path $tmpDir "bp-stdin-$sessionKey-$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).tmp"
    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($stdinFile, $stdinPayload, $utf8NoBom)
    } catch {
        Add-Content -Path $errLog -Value "Wrapper stdin setup failed: $_"
        return 1
    }

    # Capture stdout by piping through cmd.exe with redirection.
    # cmd.exe < inFile runs the child with stdin redirected from file, and
    # its stdout comes back to us via PowerShell's pipeline normally.
    $stdoutFile = Join-Path $tmpDir "bp-stdout-$sessionKey-$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).tmp"
    try {
        # Build the cmd line. Quote the script path in case of spaces.
        $quotedScript = '"' + $ScriptPath + '"'
        $quotedStdin = '"' + $stdinFile + '"'
        $quotedStdout = '"' + $stdoutFile + '"'
        $quotedErr = '"' + $errLog + '"'
        $cmdArgs = "/c powershell.exe -NoProfile -File $quotedScript < $quotedStdin > $quotedStdout 2> $quotedErr"

        $proc = Start-Process -FilePath "cmd.exe" `
                              -ArgumentList $cmdArgs `
                              -NoNewWindow `
                              -Wait `
                              -PassThru `
                              -ErrorAction Stop

        $childExit = $proc.ExitCode

        # Emit child's stdout to our stdout so the outer pipeline sees it.
        if (Test-Path $stdoutFile) {
            $childOutput = Get-Content -Path $stdoutFile -Raw -ErrorAction SilentlyContinue
            if ($childOutput) {
                # Write-Host would skip the pipeline; Write-Output sends it through.
                # Using [Console]::Out.Write avoids appending a newline we don't want.
                [Console]::Out.Write($childOutput)
            }
        }

        return $childExit
    } catch {
        Add-Content -Path $errLog -Value "Wrapper exception: $_"
        return 1
    } finally {
        Remove-Item -Path $stdinFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $stdoutFile -Force -ErrorAction SilentlyContinue
    }
}

$result = 127

# Try 1: project-local
# NOTE: $env:CLAUDE_PROJECT_DIR might be unset, so fall back to current location.
# We avoid the ?? null-coalescing operator (PowerShell 7+) for compatibility with
# Windows PowerShell 5.1, which ships by default on Windows 10/11.
if ($env:CLAUDE_PROJECT_DIR) {
    $projBase = $env:CLAUDE_PROJECT_DIR
} else {
    $projBase = (Get-Location).Path
}
$projHook = Join-Path $projBase ".claude\hooks\$HookName.ps1"
if (Test-Path $projHook) {
    $result = Invoke-HookScript $projHook
}

# Try 2: user-global
if ($result -ne 0 -and $result -ne 2) {
    $userHook = Join-Path $env:USERPROFILE ".claude\hooks\$HookName.ps1"
    if (Test-Path $userHook) {
        $result = Invoke-HookScript $userHook
    }
}

# Surface errors
if ($result -eq 2) {
    if (Test-Path $errLog) {
        $errContent = Get-Content $errLog -Raw -ErrorAction SilentlyContinue
        if ($errContent) { [Console]::Error.Write($errContent) }
    }
    exit 2
}

if ($env:BLUEPRINT_DEBUG -eq "1" -or $result -eq 127) {
    if ($result -eq 127) {
        [Console]::Error.WriteLine("BLUEPRINT v11: hook '$HookName' not found on any fallback path")
        [Console]::Error.WriteLine("  Tried: `$CLAUDE_PROJECT_DIR\.claude\hooks\$HookName.ps1")
        [Console]::Error.WriteLine("         `$USERPROFILE\.claude\hooks\$HookName.ps1")
    }
    if (Test-Path $errLog) {
        $errContent = Get-Content $errLog -Raw -ErrorAction SilentlyContinue
        if ($errContent) { [Console]::Error.Write($errContent) }
    }
}

exit 0
