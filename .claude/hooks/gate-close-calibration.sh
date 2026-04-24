#!/bin/bash
# gate-close-calibration.sh
# Blueprint v11.3: Write ESTIMATION entries to MEMORY_CORRECTIONS.md at gate close.
#
# Triggered manually from the gate-close protocol, or from a git hook.
# Reads:
#   - VERSION_ROADMAP.md for the estimated hours of the gate being closed
#   - TIMELOG.md for actual hours (preferred source)
#   - Git commit timestamps as a fallback if TIMELOG.md has no matching entry
# Writes:
#   - One ESTIMATION: line appended to MEMORY_CORRECTIONS.md
#
# Usage:
#   gate-close-calibration.sh <version>
#   gate-close-calibration.sh v0.3.0
#
# Exit codes:
#   0 = entry written
#   1 = could not determine estimated or actual hours; nothing written
#   2 = invalid arguments

set -u

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>" >&2
  echo "  Example: $0 v0.3.0" >&2
  exit 2
fi

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ROADMAP="$PROJ_DIR/VERSION_ROADMAP.md"
TIMELOG="$PROJ_DIR/TIMELOG.md"
CORRECTIONS="$PROJ_DIR/MEMORY_CORRECTIONS.md"

if [[ ! -f "$ROADMAP" ]]; then
  echo "gate-close-calibration: VERSION_ROADMAP.md not found at $ROADMAP" >&2
  exit 1
fi

# --- Extract estimated hours for this gate from VERSION_ROADMAP.md ---
#
# Format assumed (flexible regex):
#   - "v0.3.0 | Oracle Streaming | 3 screens | 80% tests | 2.5h"
#   - "| v0.3.0 | ... | 2.5 hours |"
# We look for the version string on a line, then pull the first decimal-hour
# value from that line.
#
# Handles two estimate formats:
#   Single: "2.5h" or "2.5 hours" - the single value is used
#   Range:  "2-5h" or "2-5 hours" - the midpoint is used (3.5h in this case),
#           because the approved roadmap explicitly acknowledges uncertainty
#           and midpoint is the most defensible single-point collapse.

ROW=$(grep -E "^\s*[|-]?\s*${VERSION}([^0-9]|$)" "$ROADMAP" 2>/dev/null | head -1)

if [[ -z "$ROW" ]]; then
  echo "gate-close-calibration: could not find row for $VERSION in $ROADMAP" >&2
  exit 1
fi

# Try range first: N-Mh or N.N-M.Mh
RANGE_MATCH=$(printf '%s' "$ROW" | grep -oE '[0-9]+\.?[0-9]*-[0-9]+\.?[0-9]*\s*h(ours?)?' | head -1)
if [[ -n "$RANGE_MATCH" ]]; then
  LOW=$(printf '%s' "$RANGE_MATCH"  | grep -oE '^[0-9]+\.?[0-9]*')
  HIGH=$(printf '%s' "$RANGE_MATCH" | sed 's/^[0-9.]*-//' | grep -oE '^[0-9]+\.?[0-9]*')
  ESTIMATED=$(awk -v l="$LOW" -v h="$HIGH" 'BEGIN { printf "%.2f", (l + h) / 2 }')
else
  # Single value fallback
  ESTIMATED=$(printf '%s' "$ROW" \
              | grep -oE '[0-9]+\.?[0-9]*\s*h(ours?)?' \
              | head -1 \
              | grep -oE '[0-9]+\.?[0-9]*' \
              | head -1)
fi

if [[ -z "$ESTIMATED" ]]; then
  echo "gate-close-calibration: could not find estimated hours for $VERSION in $ROADMAP" >&2
  echo "  Expected format: a line containing '$VERSION' and a value like '2.5h' or '2.5 hours'" >&2
  exit 1
fi

# --- Determine actual hours ---
#
# Priority 1: TIMELOG.md rows matching this gate version
# Priority 2: git commit timestamps (last commit minus first commit of this gate)

ACTUAL=""
ACTUAL_SOURCE=""

# Priority 1: TIMELOG.md
# Expected row format:
#   | Date | Gate | Task | Hours | Billable | Notes |
# We sum the Hours column where Gate matches $VERSION.
if [[ -f "$TIMELOG" ]]; then
  ACTUAL=$(awk -v ver="$VERSION" '
    BEGIN { FS="|"; sum=0; matched=0 }
    # Skip header, separator, and empty rows
    /^\|[-: |]+\|$/ { next }
    /^\| Date/ { next }
    /^\s*$/ { next }
    # Columns: "" | Date | Gate | Task | Hours | Billable | Notes | ""
    NF >= 6 {
      gate = $3
      hours = $5
      gsub(/^[ \t]+|[ \t]+$/, "", gate)
      gsub(/^[ \t]+|[ \t]+$/, "", hours)
      if (gate == ver && hours ~ /^[0-9]+(\.[0-9]+)?$/) {
        sum += hours
        matched++
      }
    }
    END { if (matched > 0) printf "%.2f", sum }
  ' "$TIMELOG" 2>/dev/null)

  if [[ -n "$ACTUAL" && "$ACTUAL" != "0.00" ]]; then
    ACTUAL_SOURCE="timelog"
  else
    ACTUAL=""
  fi
fi

# Priority 2: git commit timestamps
# Find commits between the previous gate tag (if any) and HEAD, or since a
# conventional "gate start" marker. We use the simplest reliable approach:
# commits whose message contains this version string.
if [[ -z "$ACTUAL" ]] && command -v git >/dev/null 2>&1 \
   && git -C "$PROJ_DIR" rev-parse --git-dir >/dev/null 2>&1; then

  # Get commits mentioning this version, sorted oldest first
  COMMIT_TIMES=$(git -C "$PROJ_DIR" log --all --grep="$VERSION" \
                 --format="%ct" --reverse 2>/dev/null)

  if [[ -z "$COMMIT_TIMES" ]]; then
    # Fall back to "commits since the previous gate tag"
    PREV_TAG=$(git -C "$PROJ_DIR" tag --list 'blueprint-gate-*' \
               --sort=-version:refname 2>/dev/null | head -2 | tail -1)
    if [[ -n "$PREV_TAG" ]]; then
      COMMIT_TIMES=$(git -C "$PROJ_DIR" log "${PREV_TAG}..HEAD" \
                     --format="%ct" --reverse 2>/dev/null)
    fi
  fi

  if [[ -n "$COMMIT_TIMES" ]]; then
    # Sum intervals between commits, skipping gaps > 2 hours (= 7200s).
    # This discards overnight/lunch/context-switch time as "walked away".
    ACTUAL_SECONDS=$(echo "$COMMIT_TIMES" | awk '
      BEGIN { total = 0; prev = 0 }
      {
        if (prev == 0) {
          prev = $1
          next
        }
        gap = $1 - prev
        if (gap > 0 && gap <= 7200) { total += gap }
        prev = $1
      }
      END { print total }
    ')

    if [[ -n "$ACTUAL_SECONDS" && "$ACTUAL_SECONDS" -gt 0 ]]; then
      # Convert to hours with 2 decimals using awk (more portable than bc)
      ACTUAL=$(awk -v s="$ACTUAL_SECONDS" 'BEGIN { printf "%.2f", s/3600 }')
      ACTUAL_SOURCE="git"
    fi
  fi
fi

if [[ -z "$ACTUAL" ]]; then
  echo "gate-close-calibration: could not determine actual hours for $VERSION" >&2
  echo "  Neither TIMELOG.md (matching Gate=$VERSION rows) nor git commits" >&2
  echo "  (containing '$VERSION' or since prior gate tag) produced a value." >&2
  exit 1
fi

# --- Compute variance and write entry ---

VARIANCE=$(awk -v est="$ESTIMATED" -v act="$ACTUAL" '
  BEGIN { printf "%+.0f%%", ((act - est) / est) * 100 }
')

# Numeric absolute variance for threshold check.
# NOTE: use %.0f here (not %d) so the rounding matches the display above.
# If we truncated instead, a variance of 30.7% would display as +31% but
# the heads-up would silently NOT fire (30 is not > 30).
VARIANCE_ABS=$(awk -v est="$ESTIMATED" -v act="$ACTUAL" '
  BEGIN {
    v = ((act - est) / est) * 100
    if (v < 0) v = -v
    printf "%.0f", v
  }
')

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

ENTRY="ESTIMATION: gate=${VERSION} estimated=${ESTIMATED}h actual=${ACTUAL}h variance=${VARIANCE} source=${ACTUAL_SOURCE} date=${TIMESTAMP}"

if [[ ! -f "$CORRECTIONS" ]]; then
  # File doesn't exist; create it with standard header
  {
    echo "# MEMORY_CORRECTIONS.md"
    echo "# Blueprint v11 | Calibration data and reflexion entries"
    echo ""
    echo "## REFLEXION LOG"
    echo ""
    echo "$ENTRY"
  } > "$CORRECTIONS"
  echo "gate-close-calibration: created MEMORY_CORRECTIONS.md with first entry" >&2
else
  # File exists. Insert ESTIMATION line after the "## REFLEXION LOG" header
  # (or any equivalent section marker) so entries stay grouped. If no such
  # header exists, fall back to appending at EOF.
  #
  # On first real entry we also remove any placeholder line like
  # "[Empty until first gate close]" that sits in the REFLEXION section
  # from the template.
  if grep -q "^## REFLEXION LOG" "$CORRECTIONS"; then
    # The prior-entry filter makes re-runs idempotent: if this hook is invoked
    # twice for the same <version> (e.g., after fixing a TIMELOG typo), the
    # older row for that gate is dropped before the new one is inserted.
    awk -v entry="$ENTRY" -v ver="$VERSION" '
      BEGIN {
        inserted = 0; in_section = 0
        prefix = "ESTIMATION: gate=" ver " "
      }
      /^## REFLEXION LOG/ { in_section = 1; print; next }
      # Exit section when the next ## header starts
      in_section && /^## / && !/^## REFLEXION LOG/ { in_section = 0 }
      # Drop the placeholder line; never keep it once we have real data
      in_section && /^\[Empty until first gate close\]$/ { next }
      # Drop any prior ESTIMATION line for the same gate
      in_section && index($0, prefix) == 1 { next }
      in_section && !inserted && /^$/ {
        print
        print entry
        inserted = 1
        next
      }
      { print }
      END { if (!inserted) print entry }
    ' "$CORRECTIONS" > "$CORRECTIONS.tmp" && mv "$CORRECTIONS.tmp" "$CORRECTIONS"
    echo "gate-close-calibration: inserted into REFLEXION LOG section of MEMORY_CORRECTIONS.md" >&2
  else
    # No section header; append at EOF
    echo "$ENTRY" >> "$CORRECTIONS"
    echo "gate-close-calibration: appended to MEMORY_CORRECTIONS.md (no REFLEXION LOG section found)" >&2
  fi
fi
echo "  $ENTRY" >&2

# Heads-up when variance exceeds 30%. This is intentionally mechanical:
# the skill documents the policy, the hook enforces it. Approved roadmap
# values are NOT silently edited; the user is told so they can choose to
# re-open SCOPE CONFIRMED if the pattern continues.
if [ "$VARIANCE_ABS" -gt 30 ]; then
  echo "" >&2
  echo "=== Heads up: ${VERSION} came in at ${VARIANCE} variance ===" >&2
  echo "That is data for future estimates. Approved ranges for later gates were" >&2
  echo "set before this data point and may warrant review before starting the next" >&2
  echo "gate. The approved roadmap has not been edited; that's your call." >&2
  echo "" >&2
fi

exit 0
