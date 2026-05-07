#!/bin/bash
# run-all.sh - /validate entry point
#
# Sources lib.sh for assertion helpers, then sources every tests/*.sh
# in alphabetical order. Each test contributes to the shared counters.
# Prints a summary and exits non-zero if any test failed.
#
# Usage:
#   bash .claude/skills/validate/run-all.sh
#
# Env vars:
#   SYNTARIS_ROOT  - override repo root (default: walks up from this script)
#   PROJECT_ROOT   - user project to validate (default: $PWD)
#   SKIP_INSTALL   - if set, skips 09-install.sh (saves ~30s on quick runs)
#   SKIP_PROJECT   - if set, skips 10-project-tests.sh

set -u

# Resolve script and Syntaris repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNTARIS_ROOT="${SYNTARIS_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"

export SYNTARIS_ROOT PROJECT_ROOT

# Shared counters
PASS=0
FAIL=0
TOTAL=0
FAILURES=()

# Source helpers
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

echo "============================================"
echo "  Syntaris /validate"
echo "  Repo:    $SYNTARIS_ROOT"
echo "  Project: $PROJECT_ROOT"
echo "============================================"
echo ""

# Iterate test scripts in numeric/alphabetical order
for script in "$SCRIPT_DIR"/tests/*.sh; do
  [[ -f "$script" ]] || continue

  name="$(basename "$script")"

  # Honor skip flags
  case "$name" in
    09-install.sh)
      [[ -n "${SKIP_INSTALL:-}" ]] && { echo "=== $name (SKIPPED) ==="; echo ""; continue; }
      ;;
    10-project-tests.sh)
      [[ -n "${SKIP_PROJECT:-}" ]] && { echo "=== $name (SKIPPED) ==="; echo ""; continue; }
      ;;
  esac

  echo "=== $name ==="
  # shellcheck disable=SC1090
  source "$script"
  echo ""
done

echo "============================================"
echo "  SUMMARY"
echo "============================================"
echo "  Total:  $TOTAL"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "  Failures:"
  for f in "${FAILURES[@]}"; do
    echo "    - $f"
  done
  echo ""
  echo "  /validate FAILED"
  exit 1
fi

echo "  /validate PASSED"
exit 0
