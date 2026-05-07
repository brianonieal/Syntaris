#!/usr/bin/env bash
# migrate-reflexion-to-estimation.sh
# Syntaris v0.6.0+: backfill structured ESTIMATION: lines from existing
# narrative REFLEXION blocks in MEMORY_CORRECTIONS.md.
#
# Why: pre-v0.6.0 projects (or projects where the calibration hook didn't
# fire at gate close) accumulated REFLEXION entries in the narrative
# template format. Pattern extraction only reads the structured
# ESTIMATION: line format. This script parses narrative entries and
# appends matching ESTIMATION: lines so extract-patterns.sh can read the
# accumulated history.
#
# Idempotent: skips REFLEXION blocks that already have a matching
# ESTIMATION: line for the same gate.
#
# Usage:
#   bash scripts/migrate-reflexion-to-estimation.sh           # in project root
#   CLAUDE_PROJECT_DIR=/path/to/proj bash .../migrate.sh      # explicit
#
# Exit codes:
#   0 - migration succeeded (entries added or already-current)
#   1 - MEMORY_CORRECTIONS.md not found

set -u

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

resolve_foundation_file() {
  local fname="$1"
  if [[ -f "$PROJ_DIR/foundation/$fname" ]]; then
    echo "$PROJ_DIR/foundation/$fname"
  elif [[ -f "$PROJ_DIR/$fname" ]]; then
    echo "$PROJ_DIR/$fname"
  else
    echo ""
  fi
}

CORRECTIONS=$(resolve_foundation_file "MEMORY_CORRECTIONS.md")

if [[ -z "$CORRECTIONS" ]]; then
  echo "migrate-reflexion: MEMORY_CORRECTIONS.md not found" >&2
  echo "  Searched: $PROJ_DIR/foundation/, $PROJ_DIR/" >&2
  exit 1
fi

echo "migrate-reflexion: parsing $CORRECTIONS" >&2

# Backup
BACKUP="$CORRECTIONS.pre-migration.bak"
if [[ ! -f "$BACKUP" ]]; then
  cp "$CORRECTIONS" "$BACKUP"
  echo "  [OK] Backed up to $BACKUP" >&2
fi

# Parse REFLEXION blocks. Each block has shape (regex-loose):
#   ### REFLEXION: v[X.Y.Z] [- and optional name]
#   Date: <date>
#   Project: <name>
#
#   ESTIMATE
#     Predicted: <N> hours
#     Actual:    <M> hours        (or "~M hours")
#     Variance:  <+/-Z>%
#
# We extract gate, predicted, actual, variance, date for each block.
# Fields not in narrative: source, errors_open, errors_close. Defaulted.

EXTRACTED=$(mktemp)
trap "rm -f '$EXTRACTED'" EXIT

awk '
  BEGIN { gate=""; predicted=""; actual=""; variance=""; date=""; in_block=0 }
  /^###[[:space:]]+REFLEXION:[[:space:]]+v/ {
    # Flush prior block if complete
    if (gate != "" && predicted != "" && actual != "") {
      printf "%s|%s|%s|%s|%s\n", gate, predicted, actual, variance, date
    }
    gate=""; predicted=""; actual=""; variance=""; date=""
    # Extract version
    match($0, /v[0-9]+\.[0-9]+\.[0-9]+/)
    if (RSTART > 0) {
      gate = substr($0, RSTART, RLENGTH)
    }
    in_block=1
    next
  }
  in_block && /^Date:/ {
    sub(/^Date:[[:space:]]*/, "")
    date = $0
    next
  }
  in_block && /Predicted:/ {
    # Match "Predicted: 4 hours" or "Predicted: 4h" - extract number
    if (match($0, /[0-9]+(\.[0-9]+)?/)) {
      predicted = substr($0, RSTART, RLENGTH)
    }
    next
  }
  in_block && /Actual:/ {
    # Match "Actual:    ~2 hours" - extract number, ignore tildes
    s = $0
    gsub(/~/, "", s)
    if (match(s, /[0-9]+(\.[0-9]+)?/)) {
      actual = substr(s, RSTART, RLENGTH)
    }
    next
  }
  in_block && /Variance:/ {
    # Match "Variance: -50% (-2 hours)" or "Variance: +25%" - extract signed int
    if (match($0, /[+-]?[0-9]+/)) {
      variance = substr($0, RSTART, RLENGTH)
    }
    next
  }
  END {
    if (gate != "" && predicted != "" && actual != "") {
      printf "%s|%s|%s|%s|%s\n", gate, predicted, actual, variance, date
    }
  }
' "$CORRECTIONS" > "$EXTRACTED"

PARSED=$(wc -l < "$EXTRACTED")
echo "  [OK] Parsed $PARSED REFLEXION block(s)" >&2

if [[ "$PARSED" -eq 0 ]]; then
  echo "migrate-reflexion: nothing to migrate" >&2
  exit 0
fi

# For each parsed entry, check if an ESTIMATION line already exists for
# that gate. If not, append it. This makes the migration idempotent.
ADDED=0
SKIPPED=0

while IFS='|' read -r gate predicted actual variance date; do
  [[ -z "$gate" ]] && continue

  # Check if an ESTIMATION line exists for this gate already
  if grep -q "^ESTIMATION: gate=$gate " "$CORRECTIONS"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Default fields not in the narrative
  : "${variance:=0}"
  : "${date:=$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
  source_field="manual"

  # Format the ESTIMATION line
  ENTRY="ESTIMATION: gate=${gate} estimated=${predicted}h actual=${actual}h variance=${variance}% source=${source_field} errors_open=0 errors_close=0 date=${date}"

  # Append after the line "## REFLEXION LOG" if it exists, else at EOF.
  # We need to keep entries grouped under the REFLEXION LOG header.
  if grep -q "^## REFLEXION LOG" "$CORRECTIONS"; then
    # Insert immediately after the header (before any narrative blocks)
    awk -v entry="$ENTRY" '
      /^## REFLEXION LOG/ && !inserted {
        print
        print ""
        print entry
        inserted=1
        next
      }
      { print }
      END { if (!inserted) print entry }
    ' "$CORRECTIONS" > "$CORRECTIONS.tmp"
    mv "$CORRECTIONS.tmp" "$CORRECTIONS"
  else
    # No section header; append at EOF
    echo "" >> "$CORRECTIONS"
    echo "$ENTRY" >> "$CORRECTIONS"
  fi

  echo "  [ADD] $ENTRY" >&2
  ADDED=$((ADDED + 1))
done < "$EXTRACTED"

echo "" >&2
echo "migrate-reflexion: complete - $ADDED added, $SKIPPED already current" >&2
echo "" >&2

if [[ "$ADDED" -gt 0 ]]; then
  echo "Run extract-patterns.sh next:" >&2
  echo "  bash \$HOME/.claude/lib/extract-patterns.sh" >&2
fi

exit 0
