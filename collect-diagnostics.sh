#!/bin/bash
# collect-diagnostics.sh
# Syntaris: gather everything needed to report a bug
#
# Produces a single bp-diagnostics-<timestamp>.txt file you can send to
# whoever you're asking for help. No secrets are collected. Review the
# output before sending if you're worried about leakage.

set -u

INSTALL_ROOT="${HOME}/.claude"
SYNTARIS_ROOT="${HOME}/Syntaris"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root) INSTALL_ROOT="$2"; shift 2 ;;
    --syntaris-root) SYNTARIS_ROOT="$2"; shift 2 ;;
    --blueprint-root) SYNTARIS_ROOT="$2"; shift 2 ;;  # back-compat alias
    -h|--help)
      cat <<EOF
Syntaris diagnostic collector

Usage:
  ./collect-diagnostics.sh
  ./collect-diagnostics.sh --install-root DIR --syntaris-root DIR

Produces a text file named bp-diagnostics-<timestamp>.txt in the current
directory. Send that file when asking for help.
EOF
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

TS=$(date -u +%Y%m%d-%H%M%S)
OUT="bp-diagnostics-${TS}.txt"

{
  echo "============================================"
  echo "  Syntaris Diagnostics"
  echo "  Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "============================================"

  echo ""
  echo "## ENVIRONMENT"
  echo ""
  echo "uname -a: $(uname -a 2>/dev/null || echo 'n/a')"
  echo "Shell: $SHELL"
  echo "Bash version: $(bash --version 2>/dev/null | head -1 || echo 'n/a')"
  echo "Git version: $(git --version 2>/dev/null || echo 'not installed')"
  echo "jq version: $(jq --version 2>/dev/null || echo 'not installed')"
  echo "Python version: $(python3 --version 2>/dev/null || echo 'not installed')"
  echo "Node version: $(node --version 2>/dev/null || echo 'not installed')"
  echo "Terminal: ${TERM:-unknown}"
  echo "Locale: $(locale 2>/dev/null | head -3 | tr '\n' ' ')"

  echo ""
  echo "## INSTALL PATHS"
  echo ""
  echo "INSTALL_ROOT: $INSTALL_ROOT"
  echo "SYNTARIS_ROOT: $SYNTARIS_ROOT"
  echo "Install root exists: $([ -d "$INSTALL_ROOT" ] && echo yes || echo NO)"
  echo "Syntaris root exists: $([ -d "$SYNTARIS_ROOT" ] && echo yes || echo NO)"

  echo ""
  echo "## INSTALL CONTENTS"
  echo ""
  if [ -d "$INSTALL_ROOT" ]; then
    echo "Skills installed: $(ls "$INSTALL_ROOT/skills" 2>/dev/null | wc -l | tr -d ' ')"
    ls "$INSTALL_ROOT/skills" 2>/dev/null | sed 's/^/  /'
    echo ""
    echo "Hooks installed: $(ls "$INSTALL_ROOT/hooks" 2>/dev/null | wc -l | tr -d ' ')"
    ls "$INSTALL_ROOT/hooks" 2>/dev/null | sed 's/^/  /'
    echo ""
    echo "Agents installed: $(ls "$INSTALL_ROOT/agents" 2>/dev/null | wc -l | tr -d ' ')"
    ls "$INSTALL_ROOT/agents" 2>/dev/null | sed 's/^/  /'
    echo ""
    echo "settings.json size: $([ -f "$INSTALL_ROOT/settings.json" ] && wc -c < "$INSTALL_ROOT/settings.json" | tr -d ' ' || echo MISSING) bytes"
  else
    echo "(install root does not exist - Syntaris not installed at this location)"
  fi

  echo ""
  echo "## FOUNDATION FILES"
  echo ""
  if [ -d "$SYNTARIS_ROOT/foundation" ]; then
    echo "Foundation files: $(ls "$SYNTARIS_ROOT/foundation" 2>/dev/null | wc -l | tr -d ' ')"
    ls "$SYNTARIS_ROOT/foundation" 2>/dev/null | sed 's/^/  /'
  else
    echo "(foundation directory not found at $SYNTARIS_ROOT/foundation)"
  fi

  echo ""
  echo "## SETTINGS.JSON VALIDITY"
  echo ""
  if [ -f "$INSTALL_ROOT/settings.json" ]; then
    if command -v python3 >/dev/null 2>&1; then
      if python3 -c "import json; json.load(open('$INSTALL_ROOT/settings.json'))" 2>/dev/null; then
        echo "Valid JSON"
      else
        echo "INVALID JSON. First 20 lines:"
        head -20 "$INSTALL_ROOT/settings.json" | sed 's/^/  /'
      fi
    elif command -v jq >/dev/null 2>&1; then
      if jq empty "$INSTALL_ROOT/settings.json" 2>/dev/null; then
        echo "Valid JSON (via jq)"
      else
        echo "INVALID JSON. jq says:"
        jq empty "$INSTALL_ROOT/settings.json" 2>&1 | sed 's/^/  /'
      fi
    else
      echo "Cannot validate (neither python3 nor jq available)"
    fi
  else
    echo "settings.json not present"
  fi

  echo ""
  echo "## HOOK EXECUTABILITY"
  echo ""
  if [ -d "$INSTALL_ROOT/hooks" ]; then
    for h in "$INSTALL_ROOT/hooks"/*.sh; do
      [ -f "$h" ] || continue
      name=$(basename "$h")
      if [ -x "$h" ]; then
        echo "  executable: $name"
      else
        echo "  NOT EXECUTABLE: $name"
      fi
    done
  fi

  echo ""
  echo "## RECENT HOOK ERROR LOGS"
  echo ""
  tmpdir="${TMPDIR:-/tmp}"
  log_files=$(find "$tmpdir" -maxdepth 1 -name "bp-hook-err-*.log" -mtime -7 2>/dev/null)
  if [ -n "$log_files" ]; then
    echo "Found hook error logs in $tmpdir (last 7 days):"
    echo "$log_files" | while read -r logf; do
      echo ""
      echo "--- $logf ---"
      if [ -s "$logf" ]; then
        head -50 "$logf" | sed 's/^/  /'
        lines=$(wc -l < "$logf" | tr -d ' ')
        if [ "$lines" -gt 50 ]; then
          echo "  (truncated; full log is $lines lines)"
        fi
      else
        echo "  (empty)"
      fi
    done
  else
    echo "No recent hook error logs found in $tmpdir"
  fi

  echo ""
  echo "## VERIFY OUTPUT"
  echo ""
  # Run verify.sh if it's next to this script, else look for it in the install
  verify_script=""
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/verify.sh" ]; then
    verify_script="$script_dir/verify.sh"
  fi

  if [ -n "$verify_script" ]; then
    echo "Running: $verify_script --install-root $INSTALL_ROOT"
    echo ""
    bash "$verify_script" --install-root "$INSTALL_ROOT" 2>&1 | sed 's/^/  /'
  else
    echo "verify.sh not found next to this diagnostic script."
    echo "Run it manually and paste the output when reporting."
  fi

  echo ""
  echo "============================================"
  echo "  End of diagnostics"
  echo "  File: $OUT"
  echo "============================================"
} > "$OUT" 2>&1

echo ""
echo "Diagnostics written to: $OUT"
echo ""
echo "Before sending, you may want to skim it for anything you don't want to"
echo "share (e.g., custom paths that reveal your username). The script does"
echo "not collect file contents beyond settings.json, but paths and skill"
echo "names will be present."
echo ""
echo "Send this file to whoever is helping you debug."
