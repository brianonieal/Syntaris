# block-dangerous.ps1
# Syntaris v0.5.2: Block dangerous commands before execution
# Runs as PreToolUse hook with matcher "Bash"
# Per Anthropic hook spec: input arrives as JSON on stdin, exit 2 blocks.

$ErrorActionPreference = "SilentlyContinue"

# Read JSON input from stdin
$rawInput = [Console]::In.ReadToEnd()

if ([string]::IsNullOrEmpty($rawInput)) {
    exit 0
}

try {
    $data = $rawInput | ConvertFrom-Json
} catch {
    exit 0
}

$toolName = $data.tool_name
$command = $null
if ($data.tool_input) {
    $command = $data.tool_input.command
}

if ($toolName -ne "Bash") {
    exit 0
}

if ([string]::IsNullOrEmpty($command)) {
    exit 0
}

# Block destructive database operations
if ($command -imatch "DROP TABLE|DROP DATABASE|DELETE FROM .* WHERE 1=1|TRUNCATE TABLE") {
    [Console]::Error.WriteLine("Blocked: destructive database command. If intentional, run it manually outside Claude Code.")
    [Console]::Error.WriteLine("Command: $command")
    [Console]::Error.WriteLine("If intentional, run manually outside Claude Code.")
    exit 2
}

# Block recursive force delete of root/current/home/glob
if ($command -match "rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\s+(/|\./|\*|~)") {
    [Console]::Error.WriteLine("Blocked: rm -rf is a system-destructive command. If intentional, run it manually outside Claude Code.")
    [Console]::Error.WriteLine("Command: $command")
    exit 2
}

# Block PowerShell equivalent recursive remove
if ($command -imatch "Remove-Item\s+.*-Recurse.*-Force") {
    [Console]::Error.WriteLine("Blocked: recursive force remove. If intentional, run it manually outside Claude Code.")
    [Console]::Error.WriteLine("Command: $command")
    exit 2
}

# Block force push to main/master
if ($command -match "git\s+push\s+(-[a-zA-Z]*f|--force)\s+.*\b(main|master)\b") {
    [Console]::Error.WriteLine("Blocked: force push to protected branch. If intentional, run it manually outside Claude Code.")
    [Console]::Error.WriteLine("Command: $command")
    exit 2
}

# Block direct psql/pg_dump against production
if ($command -imatch "(psql|pg_dump)\s+.*production") {
    [Console]::Error.WriteLine("Blocked: direct production database access. Use migrations or the app backend instead.")
    [Console]::Error.WriteLine("Use a database MCP server for database operations.")
    exit 2
}

exit 0
