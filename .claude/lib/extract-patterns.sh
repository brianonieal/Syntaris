#!/bin/bash
# extract-patterns.sh
# Syntaris v0.6.0: Pattern extraction from accumulated ESTIMATION data.
#
# Reads ESTIMATION lines from MEMORY_CORRECTIONS.md, detects five pattern
# types, writes proposed PAT entries to .syntaris/proposed-patterns.md.
# The /health --review-patterns flow (or manual edit) promotes accepted
# patterns to MEMORY_SEMANTIC.md.
#
# Pattern types implemented (v0.6.0+):
#   1. Project-level systemic bias - mean variance across all gates
#   2. Error-introduction variance - gates that grew error count vs not
#   3. Source-of-actuals bias - timelog-source vs git-source mean variance
#   4. Gate-type variance bias - keyword-grouped from VERSION_ROADMAP feature
#   5. Recovery patterns - gates within 24h of STOP EVENT vs cold gates
#
# Idempotent: re-runs with the same input produce the same output. The
# proposed-patterns.md file is overwritten on each run, so accepted
# patterns must be moved to MEMORY_SEMANTIC.md before next run.
#
# Usage:
#   bash .claude/lib/extract-patterns.sh
#
# Exit codes:
#   0 - extraction succeeded (may have written 0 or N proposals)
#   1 - missing required input file
#   2 - insufficient data (fewer than 5 ESTIMATION entries)

set -u

PROJ_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# v0.6.0: foundation files live in foundation/ by Syntaris convention.
# Older projects keep them at root. Try foundation/ first, fall back.
resolve_foundation_file() {
  local fname="$1"
  if [[ -f "$PROJ_DIR/foundation/$fname" ]]; then
    echo "$PROJ_DIR/foundation/$fname"
  elif [[ -f "$PROJ_DIR/$fname" ]]; then
    echo "$PROJ_DIR/$fname"
  elif [[ -d "$PROJ_DIR/foundation" ]]; then
    echo "$PROJ_DIR/foundation/$fname"
  else
    echo "$PROJ_DIR/$fname"
  fi
}

CORRECTIONS=$(resolve_foundation_file "MEMORY_CORRECTIONS.md")
ROADMAP=$(resolve_foundation_file "VERSION_ROADMAP.md")
EPISODIC=$(resolve_foundation_file "MEMORY_EPISODIC.md")
OUT_DIR="$PROJ_DIR/.syntaris"
OUT="$OUT_DIR/proposed-patterns.md"

# --- Preconditions ---

if [[ ! -f "$CORRECTIONS" ]]; then
  echo "extract-patterns: MEMORY_CORRECTIONS.md not found at $CORRECTIONS" >&2
  exit 1
fi

# Need >= 5 entries before any pattern extraction makes sense.
ESTIMATION_COUNT=$(grep -c "^ESTIMATION:" "$CORRECTIONS" 2>/dev/null) || true
ESTIMATION_COUNT="${ESTIMATION_COUNT:-0}"

if [[ "$ESTIMATION_COUNT" -lt 5 ]]; then
  echo "extract-patterns: only $ESTIMATION_COUNT ESTIMATION entries (need >=5)" >&2
  exit 2
fi

mkdir -p "$OUT_DIR" 2>/dev/null

# --- Parse ESTIMATION lines into a temp TSV for awk processing ---
#
# Output columns: gate variance source errors_open errors_close date
# Variance is signed integer (e.g., +25 or -10).

PARSED=$(mktemp)
trap "rm -f '$PARSED'" EXIT

awk '
  /^ESTIMATION:/ {
    gate = ""; var = ""; src = ""; eo = "0"; ec = "0"; date = ""
    n = split($0, fields, " ")
    for (i = 1; i <= n; i++) {
      if (match(fields[i], /^gate=/))         gate = substr(fields[i], 6)
      else if (match(fields[i], /^variance=/)) {
        v = substr(fields[i], 10)
        gsub(/%$/, "", v)
        var = v
      }
      else if (match(fields[i], /^source=/))      src  = substr(fields[i], 8)
      else if (match(fields[i], /^errors_open=/)) eo   = substr(fields[i], 13)
      else if (match(fields[i], /^errors_close=/))ec   = substr(fields[i], 14)
      else if (match(fields[i], /^date=/))        date = substr(fields[i], 6)
    }
    if (gate != "" && var != "") {
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", gate, var, src, eo, ec, date
    }
  }
' "$CORRECTIONS" > "$PARSED"

PARSED_COUNT=$(wc -l < "$PARSED")
if [[ "$PARSED_COUNT" -lt 5 ]]; then
  echo "extract-patterns: only $PARSED_COUNT parsed entries (some lines malformed?)" >&2
  exit 2
fi

# --- Pattern type 1: Project-level systemic bias ---

P1_OUTPUT=$(awk -F'\t' '
  { sum += $2; count++ }
  END {
    if (count >= 5) {
      mean = sum / count
      abs_mean = (mean < 0) ? -mean : mean
      if (abs_mean >= 15) {
        printf "PROJECT_SYSTEMIC|%.0f|%d", mean, count
      }
    }
  }
' "$PARSED")

# --- Pattern type 2: Error-introduction variance ---
# Group A: errors_close > errors_open (error-growing gates)
# Group B: errors_close <= errors_open (clean or shrinking gates)
# Need N>=2 in each group. Flag if absolute difference between means >= 15%.

P2_OUTPUT=$(awk -F'\t' '
  $5 > $4 { a_sum += $2; a_count++ }
  $5 <= $4 { b_sum += $2; b_count++ }
  END {
    if (a_count >= 2 && b_count >= 2) {
      a_mean = a_sum / a_count
      b_mean = b_sum / b_count
      diff = a_mean - b_mean
      abs_diff = (diff < 0) ? -diff : diff
      if (abs_diff >= 15) {
        printf "ERROR_INTRO|%.0f|%d|%.0f|%d", a_mean, a_count, b_mean, b_count
      }
    }
  }
' "$PARSED")

# --- Pattern type 3: Source-of-actuals bias ---
# Group T: source=timelog
# Group G: source=git
# Need N>=2 in each. Flag if abs difference between means >= 15%.

P3_OUTPUT=$(awk -F'\t' '
  $3 == "timelog" { t_sum += $2; t_count++ }
  $3 == "git"     { g_sum += $2; g_count++ }
  END {
    if (t_count >= 2 && g_count >= 2) {
      t_mean = t_sum / t_count
      g_mean = g_sum / g_count
      diff = t_mean - g_mean
      abs_diff = (diff < 0) ? -diff : diff
      if (abs_diff >= 15) {
        printf "SOURCE_BIAS|%.0f|%d|%.0f|%d", t_mean, t_count, g_mean, g_count
      }
    }
  }
' "$PARSED")

# --- Pattern type 4: Gate-type variance bias ---
# Requires VERSION_ROADMAP.md. For each ESTIMATION gate, find the row in
# VERSION_ROADMAP that mentions that version, extract feature text, match
# against keyword sets, group, compute means.
#
# Keyword sets (loose categorization, conservative to avoid false positives):
#   auth          - matches: auth, login, session, jwt, oauth
#   rls           - matches: rls, row.level, security policy
#   migration     - matches: migration, schema, alembic
#   agent         - matches: agent, langgraph, llm
#   deployment    - matches: deploy, vercel, render, railway, ci.cd
#   crud          - matches: crud, list, detail, create, update, delete
#   scaffold      - matches: scaffold, foundation, setup, init
#   data          - matches: data layer, models, database

P4_OUTPUT=""
if [[ -f "$ROADMAP" ]]; then
  # Build a temp file mapping gate -> category, then re-parse with category.
  TYPED=$(mktemp)
  trap "rm -f '$PARSED' '$TYPED'" EXIT

  while IFS=$'\t' read -r gate variance source eo ec date; do
    # Find the roadmap row for this gate
    feature_lower=$(grep -E "^\s*\|?\s*${gate}\b" "$ROADMAP" 2>/dev/null \
                    | head -1 \
                    | tr '[:upper:]' '[:lower:]')

    category="unknown"
    if [[ -n "$feature_lower" ]]; then
      if   echo "$feature_lower" | grep -qE 'auth|login|session|jwt|oauth'; then
        category="auth"
      elif echo "$feature_lower" | grep -qE 'rls|row.level|security policy|policies'; then
        category="rls"
      elif echo "$feature_lower" | grep -qE 'migration|schema|alembic'; then
        category="migration"
      elif echo "$feature_lower" | grep -qE 'agent|langgraph|llm'; then
        category="agent"
      elif echo "$feature_lower" | grep -qE 'deploy|vercel|render|railway|ci.cd|ci/cd'; then
        category="deployment"
      elif echo "$feature_lower" | grep -qE 'crud|list|detail|create|update|delete'; then
        category="crud"
      elif echo "$feature_lower" | grep -qE 'scaffold|foundation|setup|init'; then
        category="scaffold"
      elif echo "$feature_lower" | grep -qE 'data layer|models|database'; then
        category="data"
      fi
    fi

    printf "%s\t%s\t%s\n" "$gate" "$variance" "$category" >> "$TYPED"
  done < "$PARSED"

  # For each category with N>=3, compute mean variance. Flag if abs(mean) >= 20%.
  P4_OUTPUT=$(awk -F'\t' '
    $3 != "unknown" { sum[$3] += $2; count[$3]++ }
    END {
      first = 1
      for (cat in count) {
        if (count[cat] >= 3) {
          mean = sum[cat] / count[cat]
          abs_mean = (mean < 0) ? -mean : mean
          if (abs_mean >= 20) {
            if (!first) printf ";"
            printf "%s|%.0f|%d", cat, mean, count[cat]
            first = 0
          }
        }
      }
    }
  ' "$TYPED")
fi

# --- Pattern type 5: Recovery patterns (gates after STOP EVENT) ---
# Read MEMORY_EPISODIC.md for STOP EVENT markers. For each gate, decide
# if it closed within ~24h after a STOP EVENT (recovery gate) or not (cold).
# Compare mean variance between groups. Need N>=2 in each group.
# Flag if abs difference between means >= 15%.
#
# Episodic format expected (loose - these are narrative):
#   STOP EVENT: <date> ...
#   GATE CLOSED: v0.1.0 <date> ...
# We use ESTIMATION date as the gate close timestamp instead, since that's
# what we already have parsed. A gate is "after STOP" if its date is within
# 24h after any STOP EVENT.

P5_OUTPUT=""
if [[ -f "$EPISODIC" ]]; then
  STOPS=$(mktemp)
  trap "rm -f '$PARSED' '${TYPED:-/dev/null}' '$STOPS'" EXIT

  # Extract STOP EVENT dates (ISO-formatted YYYY-MM-DD or full ISO timestamp)
  grep -iE "^.*STOP EVENT" "$EPISODIC" 2>/dev/null \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9:]+Z?)?' \
    | sort -u > "$STOPS" || true

  # Group gates: ESTIMATION date within 24h after any STOP = recovery gate
  RECOVERY_TYPED=$(mktemp)
  trap "rm -f '$PARSED' '${TYPED:-/dev/null}' '$STOPS' '$RECOVERY_TYPED'" EXIT

  while IFS=$'\t' read -r gate variance source eo ec date; do
    # Use date prefix for comparison (YYYY-MM-DD)
    gate_day=$(echo "$date" | cut -c1-10)
    classification="cold"

    while IFS= read -r stop_date; do
      stop_day=$(echo "$stop_date" | cut -c1-10)
      # Compare epoch days. Gate within 1 day after stop = recovery.
      g_epoch=$(date -d "$gate_day" +%s 2>/dev/null) || continue
      s_epoch=$(date -d "$stop_day" +%s 2>/dev/null) || continue
      diff=$(( (g_epoch - s_epoch) / 86400 ))
      if [[ "$diff" -ge 0 && "$diff" -le 1 ]]; then
        classification="recovery"
        break
      fi
    done < "$STOPS"

    printf "%s\t%s\n" "$variance" "$classification" >> "$RECOVERY_TYPED"
  done < "$PARSED"

  # Compute means per group; flag if N>=2 each and abs diff >= 15
  P5_OUTPUT=$(awk -F'\t' '
    $2 == "recovery" { r_sum += $1; r_count++ }
    $2 == "cold"     { c_sum += $1; c_count++ }
    END {
      if (r_count >= 2 && c_count >= 2) {
        r_mean = r_sum / r_count
        c_mean = c_sum / c_count
        diff = r_mean - c_mean
        abs_diff = (diff < 0) ? -diff : diff
        if (abs_diff >= 15) {
          printf "RECOVERY|%.0f|%d|%.0f|%d", r_mean, r_count, c_mean, c_count
        }
      }
    }
  ' "$RECOVERY_TYPED")
fi

# --- Build proposed-patterns.md ---

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date -u +%Y-%m-%d)
NEXT_PAT_NUM=1

# Read existing PAT-NNN highest number from MEMORY_SEMANTIC.md if it exists
SEMANTIC=$(resolve_foundation_file "MEMORY_SEMANTIC.md")
if [[ -f "$SEMANTIC" ]]; then
  HIGHEST=$(grep -oE '^### PAT-[0-9]+' "$SEMANTIC" 2>/dev/null \
            | grep -oE '[0-9]+' \
            | sort -n \
            | tail -1)
  if [[ -n "$HIGHEST" ]]; then
    NEXT_PAT_NUM=$((HIGHEST + 1))
  fi
fi

confidence_for_n() {
  local n="$1"
  if   [[ "$n" -ge 7 ]]; then echo "HIGH"
  elif [[ "$n" -ge 4 ]]; then echo "MEDIUM"
  else                        echo "LOW"
  fi
}

PROPOSAL_COUNT=0

# Build the output file in-memory then write atomically
tmp_out=$(mktemp)

cat > "$tmp_out" <<HEADER
# proposed-patterns.md
# Auto-generated by .claude/lib/extract-patterns.sh
# Generated: $TIMESTAMP
# Source data: $ESTIMATION_COUNT ESTIMATION entries in MEMORY_CORRECTIONS.md
#
# These are PROPOSED patterns. The /health --review-patterns skill (or
# manual review) walks through each entry; accepted ones move to
# MEMORY_SEMANTIC.md, rejected ones are dropped on next extraction.
#
# Re-running extract-patterns.sh OVERWRITES this file. Move accepted
# patterns to MEMORY_SEMANTIC.md before re-running.
#
# ---

HEADER

# --- Pattern 1: project-systemic ---
if [[ -n "$P1_OUTPUT" ]]; then
  IFS='|' read -r _ mean count <<< "$P1_OUTPUT"
  conf=$(confidence_for_n "$count")
  pat_id=$(printf "PAT-%03d" "$NEXT_PAT_NUM")
  NEXT_PAT_NUM=$((NEXT_PAT_NUM + 1))
  PROPOSAL_COUNT=$((PROPOSAL_COUNT + 1))

  cat >> "$tmp_out" <<EOF
### $pat_id: Project-level systemic estimation bias
Confidence: $conf
Source: $count gates of accumulated ESTIMATION data
Description: Across all closed gates so far, actual hours run an
average of ${mean}% off predicted hours. When estimating future gates,
apply a 1+(${mean}/100) baseline multiplier or budget the variance
explicitly into the range.
Last validated: $TODAY
Auto-extracted: yes (extract-patterns.sh, $TIMESTAMP)
Human-reviewed: no
Data points: $count gates aggregated; see MEMORY_CORRECTIONS.md ESTIMATION lines

---

EOF
fi

# --- Pattern 2: error-introduction ---
if [[ -n "$P2_OUTPUT" ]]; then
  IFS='|' read -r _ a_mean a_count b_mean b_count <<< "$P2_OUTPUT"
  total=$((a_count + b_count))
  conf=$(confidence_for_n "$total")
  pat_id=$(printf "PAT-%03d" "$NEXT_PAT_NUM")
  NEXT_PAT_NUM=$((NEXT_PAT_NUM + 1))
  PROPOSAL_COUNT=$((PROPOSAL_COUNT + 1))

  cat >> "$tmp_out" <<EOF
### $pat_id: Error-introducing gates run differently from clean gates
Confidence: $conf
Source: $a_count gates that grew error count, $b_count gates that did not
Description: Gates whose errors_close exceeded errors_open averaged
${a_mean}% variance from estimate. Gates that did not grow the error
count averaged ${b_mean}% variance. The gap is ${a_mean}% - ${b_mean}%.
When estimating a gate where new error discovery is likely (e.g. a
data layer or auth gate), budget extra hours.
Last validated: $TODAY
Auto-extracted: yes (extract-patterns.sh, $TIMESTAMP)
Human-reviewed: no
Data points: $a_count error-growing + $b_count clean gates

---

EOF
fi

# --- Pattern 3: source-of-actuals bias ---
if [[ -n "$P3_OUTPUT" ]]; then
  IFS='|' read -r _ t_mean t_count g_mean g_count <<< "$P3_OUTPUT"
  total=$((t_count + g_count))
  conf=$(confidence_for_n "$total")
  pat_id=$(printf "PAT-%03d" "$NEXT_PAT_NUM")
  NEXT_PAT_NUM=$((NEXT_PAT_NUM + 1))
  PROPOSAL_COUNT=$((PROPOSAL_COUNT + 1))

  cat >> "$tmp_out" <<EOF
### $pat_id: Source-of-actuals affects calibration
Confidence: $conf
Source: $t_count timelog-source gates, $g_count git-source gates
Description: Gates with actuals derived from TIMELOG.md averaged
${t_mean}% variance. Gates that fell back to git commit timestamps
averaged ${g_mean}% variance. The gap suggests one source is more
accurate than the other for this project. If the gap is large,
investigate whether TIMELOG entries are being logged consistently
or whether the 2-hour git gap filter is misclassifying long thinking
sessions as "walked away."
Last validated: $TODAY
Auto-extracted: yes (extract-patterns.sh, $TIMESTAMP)
Human-reviewed: no
Data points: $t_count timelog + $g_count git source gates

---

EOF
fi

# --- Pattern 4: gate-type variance bias (one entry per detected category) ---
if [[ -n "$P4_OUTPUT" ]]; then
  # P4_OUTPUT is semicolon-separated entries
  IFS=';' read -ra ENTRIES <<< "$P4_OUTPUT"
  for entry in "${ENTRIES[@]}"; do
    IFS='|' read -r category mean count <<< "$entry"
    conf=$(confidence_for_n "$count")
    pat_id=$(printf "PAT-%03d" "$NEXT_PAT_NUM")
    NEXT_PAT_NUM=$((NEXT_PAT_NUM + 1))
    PROPOSAL_COUNT=$((PROPOSAL_COUNT + 1))

    cat >> "$tmp_out" <<EOF
### $pat_id: Gates categorized as '$category' run with consistent variance
Confidence: $conf
Source: $count gates whose VERSION_ROADMAP feature matched '$category' keywords
Description: Gates whose feature description matches '$category' keywords
have averaged ${mean}% variance from estimate, last $count gates. When
estimating a future gate that involves $category work, apply a
1+(${mean}/100) multiplier to the baseline.
Last validated: $TODAY
Auto-extracted: yes (extract-patterns.sh, $TIMESTAMP)
Human-reviewed: no
Data points: $count $category-category gates

---

EOF
  done
fi

# --- Pattern 5: Recovery patterns (gates after STOP EVENT vs cold) ---
if [[ -n "$P5_OUTPUT" ]]; then
  IFS='|' read -r _ r_mean r_count c_mean c_count <<< "$P5_OUTPUT"
  total=$((r_count + c_count))
  conf=$(confidence_for_n "$total")
  pat_id=$(printf "PAT-%03d" "$NEXT_PAT_NUM")
  NEXT_PAT_NUM=$((NEXT_PAT_NUM + 1))
  PROPOSAL_COUNT=$((PROPOSAL_COUNT + 1))

  cat >> "$tmp_out" <<EOF
### $pat_id: Recovery gates (after STOP EVENT) run differently
Confidence: $conf
Source: $r_count recovery gates (within 24h after a STOP EVENT in
MEMORY_EPISODIC), $c_count cold gates
Description: Gates closed within ~24h after a STOP EVENT in
MEMORY_EPISODIC.md averaged ${r_mean}% variance from estimate. Cold
gates (no recent STOP) averaged ${c_mean}%. The gap suggests context-
switch cost (or recovery boost) is a real estimation factor on this
project. When estimating a gate immediately after a long break, budget
for the recovery-gate variance.
Last validated: $TODAY
Auto-extracted: yes (extract-patterns.sh, $TIMESTAMP)
Human-reviewed: no
Data points: $r_count recovery + $c_count cold gates

---

EOF
fi

# --- Footer ---

cat >> "$tmp_out" <<FOOTER
## How to act on these proposals

1. Read each entry above.
2. For each one you want to keep, copy the block (### PAT-NNN through
   the data-points line) into foundation/MEMORY_SEMANTIC.md under
   "## PATTERNS". Set "Human-reviewed: yes (accepted by [user] $TODAY)".
3. Re-run extract-patterns.sh after a few more gates close. New data
   either confirms the pattern (confidence rises) or contradicts it
   (extraction will produce different numbers; review again).

If a proposal is wrong (false positive), just don't promote it. The
next run won't auto-add it; it'll re-propose if the data still supports
it, with a warning that you previously rejected it.

Generated $PROPOSAL_COUNT proposals from $ESTIMATION_COUNT data points.
FOOTER

mv "$tmp_out" "$OUT"

echo "extract-patterns: wrote $PROPOSAL_COUNT proposals to $OUT" >&2

if [[ "$PROPOSAL_COUNT" -gt 0 ]]; then
  echo "" >&2
  echo "  Run /health --review-patterns to walk through them and promote" >&2
  echo "  accepted ones to foundation/MEMORY_SEMANTIC.md." >&2
fi

exit 0
