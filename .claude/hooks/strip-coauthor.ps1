# strip-coauthor.ps1
# Syntaris: Strip Co-Authored-By trailers from git commits
# PowerShell version for Windows

$gitDir = git rev-parse --git-dir 2>$null
if (-not $gitDir) { exit 0 }

$hookPath = Join-Path $gitDir "hooks\commit-msg"
$hookContent = @'
#!/bin/bash
# Syntaris: Strip Co-Authored-By trailers
COMMIT_FILE="$1"
if [ -f "$COMMIT_FILE" ]; then
  grep -v "^Co-Authored-By:" "$COMMIT_FILE" | \
  grep -v "^co-authored-by:" | \
  grep -v "noreply@anthropic.com" > "$COMMIT_FILE.tmp"
  mv "$COMMIT_FILE.tmp" "$COMMIT_FILE"
fi
exit 0
'@

if (-not (Test-Path $hookPath) -or -not (Get-Content $hookPath -Raw).Contains("Co-Authored-By")) {
    Set-Content -Path $hookPath -Value $hookContent -Encoding UTF8
    # Make executable via git
    git config core.hooksPath (Split-Path $hookPath) 2>$null
}

exit 0
