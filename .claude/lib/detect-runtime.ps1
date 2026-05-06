# detect-runtime.ps1
# Detects which AI coding harness Syntaris is running inside.
# Echoes one of: claude-code | cursor | windsurf | codex-cli | gemini-cli | aider | kiro | opencode | unknown
# Usage: pwsh .claude/lib/detect-runtime.ps1

# Anthropic Claude Code sets CLAUDE_CODE in v2.0+
if ($env:CLAUDE_CODE -or $env:ANTHROPIC_CLAUDE_CODE) {
    Write-Output "claude-code"
    exit 0
}

# Cursor sets CURSOR_USER and ships with .cursor/ project config
if ($env:CURSOR_USER -or (Test-Path ".cursor") -or (Test-Path ".cursorrules")) {
    Write-Output "cursor"
    exit 0
}

# Windsurf (Codeium)
if ($env:WINDSURF_USER -or (Test-Path ".windsurf")) {
    Write-Output "windsurf"
    exit 0
}

# Codex CLI
if ((Test-Path ".codex/config.toml") -or $env:CODEX_HOME) {
    Write-Output "codex-cli"
    exit 0
}

# Gemini CLI
if ((Test-Path ".gemini") -or ($env:GEMINI_API_KEY -and $env:GEMINI_CLI_HOME)) {
    Write-Output "gemini-cli"
    exit 0
}

# Kiro (Amazon)
if ($env:KIRO_HOME -or (Test-Path ".kiro")) {
    Write-Output "kiro"
    exit 0
}

# OpenCode
if ((Test-Path ".opencode") -or (Test-Path "opencode.json")) {
    Write-Output "opencode"
    exit 0
}

# Aider check
if ($env:AIDER_MODEL -or (Test-Path ".aider.conf.yml") -or (Test-Path ".aider.input.history")) {
    Write-Output "aider"
    exit 0
}

# Last fallback: parent process detection (best effort on Windows)
try {
    $parent = (Get-Process -Id (Get-Process -Id $PID).Parent.Id -ErrorAction SilentlyContinue).Name
    switch -Wildcard ($parent) {
        "*claude-code*" { Write-Output "claude-code"; exit 0 }
        "*claude*"      { Write-Output "claude-code"; exit 0 }
        "*cursor*"      { Write-Output "cursor"; exit 0 }
        "*windsurf*"    { Write-Output "windsurf"; exit 0 }
        "*codex*"       { Write-Output "codex-cli"; exit 0 }
        "*gemini*"      { Write-Output "gemini-cli"; exit 0 }
        "*aider*"       { Write-Output "aider"; exit 0 }
        "*opencode*"    { Write-Output "opencode"; exit 0 }
    }
} catch {
    # Parent process detection failed; continue to unknown.
}

Write-Output "unknown"
exit 0
