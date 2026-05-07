#!/bin/bash
# 01-syntax.sh - validate every hook script parses cleanly
#
# Bash hooks: bash -n
# PowerShell hooks: tokenize via PSParser if powershell is on PATH.
# If PowerShell is not available (e.g. macOS/Linux without pwsh), .ps1
# files are skipped with a note rather than failing.

HOOKS_DIR="$SYNTARIS_ROOT/.claude/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  assert_dir_exists "01.0 hooks dir present" "$HOOKS_DIR"
  return
fi

# Bash syntax checks
for f in "$HOOKS_DIR"/*.sh; do
  [[ -f "$f" ]] || continue
  name="$(basename "$f")"
  TOTAL=$((TOTAL+1))
  if bash -n "$f" 2>/dev/null; then
    echo "  [PASS] 01.bash $name"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 01.bash $name: bash -n syntax error"
    FAIL=$((FAIL+1))
    FAILURES+=("01.bash $name syntax")
  fi
done

# PowerShell syntax checks (if available)
if command -v powershell.exe >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
  PSCMD="powershell.exe"
  command -v pwsh >/dev/null 2>&1 && PSCMD="pwsh"

  for f in "$HOOKS_DIR"/*.ps1; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    TOTAL=$((TOTAL+1))
    # Tokenize the file - any parse error throws and we catch it
    winpath="$f"
    if command -v cygpath >/dev/null 2>&1; then
      winpath="$(cygpath -w "$f")"
    fi
    if "$PSCMD" -NoProfile -Command "
      try {
        \$null = [System.Management.Automation.PSParser]::Tokenize(
          (Get-Content '$winpath' -Raw), [ref]\$null
        )
        exit 0
      } catch {
        Write-Error \$_
        exit 1
      }
    " >/dev/null 2>&1; then
      echo "  [PASS] 01.ps1 $name"
      PASS=$((PASS+1))
    else
      echo "  [FAIL] 01.ps1 $name: PowerShell tokenize error"
      FAIL=$((FAIL+1))
      FAILURES+=("01.ps1 $name syntax")
    fi
  done
else
  echo "  [SKIP] PowerShell not on PATH; .ps1 syntax not checked"
fi
