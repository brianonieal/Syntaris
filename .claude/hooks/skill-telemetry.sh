#!/bin/bash
# skill-telemetry.sh
# Syntaris.3: Log skill-invocation signals to a jsonl file for later analysis.
#
# Triggered as a UserPromptSubmit hook. Reads the user's prompt, scans each
# installed skill's SKILL.md description for trigger phrases, and logs any
# matches to ~/.claude/state/skill-log.jsonl.
#
# This is approximate by design. Skills that Claude auto-loads without a
# matching trigger phrase in the user's prompt will NOT be logged. We accept
# that in exchange for cheapness and zero runtime overhead on the model side.
#
# Output format (one line per matched skill per prompt):
#   {"ts":"2026-04-23T19:12:00Z","skill":"build-rules","session":"abc123","prompt_hint":"start a new app"}
#
# If no skills match, the hook logs a single "nomatch" entry so we can
# distinguish "no skill was relevant" from "the hook didn't run."

set -u

INPUT=$(cat)
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract session_id and prompt from the JSON stdin payload
if command -v jq >/dev/null 2>&1; then
  SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // .user_prompt // ""' 2>/dev/null)
else
  # Fallback: regex. Handles the common case where prompt is a single-line
  # string without embedded quotes. Multi-line / quoted prompts get truncated.
  SESSION=$(printf '%s' "$INPUT" \
    | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  [[ -z "$SESSION" ]] && SESSION="unknown"
  PROMPT=$(printf '%s' "$INPUT" \
    | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

# Can't match without a prompt; exit silently
if [[ -z "$PROMPT" ]]; then
  exit 0
fi

# Normalize prompt for matching: lowercase, truncate to 120 chars for logging
PROMPT_LOWER=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')
PROMPT_HINT=$(printf '%s' "$PROMPT" | head -c 120 \
              | tr '\n' ' ' | tr '\r' ' ' \
              | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

# Where to look for skills and where to write the log
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LOG_DIR="${HOME}/.claude/state"
LOG_FILE="$LOG_DIR/skill-log.jsonl"

mkdir -p "$LOG_DIR" 2>/dev/null

# Opt-out: if $HOME/.claude/state/telemetry-off exists, do nothing.
if [[ -f "$LOG_DIR/telemetry-off" ]]; then
  exit 0
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  exit 0
fi

# Collect matches into a bash array
matches=()

for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name=$(basename "$skill_dir")
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || continue

  # Extract frontmatter description (between --- ... ---)
  # Use awk to grab the description field from YAML frontmatter
  description=$(awk '
    BEGIN { in_front = 0; desc_cont = 0 }
    /^---$/ { in_front = !in_front; next }
    in_front && /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      print
      desc_cont = 1
      next
    }
    in_front && desc_cont && /^[[:space:]]+/ {
      gsub(/^[[:space:]]+/, " ")
      printf "%s", $0
    }
    in_front && /^[a-zA-Z_]+:/ { desc_cont = 0 }
  ' "$skill_md" 2>/dev/null | tr '[:upper:]' '[:lower:]')

  [[ -z "$description" ]] && continue

  # Trigger check in three layers:
  #   1. Exact skill-name string in prompt (e.g., "rollback", "testing")
  #   2. Slash-command form (e.g., "/rollback", "/debug")
  #   3. Curated natural-language keywords per skill (e.g., "roll back"
  #      triggers rollback; "review this architecture" triggers
  #      critical-thinker). Kept small and conservative to minimize
  #      false-positive matches.
  matched=false

  if printf '%s' "$PROMPT_LOWER" | grep -qF -- "$skill_name"; then
    matched=true
  elif printf '%s' "$PROMPT_LOWER" | grep -qF -- "/${skill_name}"; then
    matched=true
  else
    # Curated natural-language keywords per skill. Patterns are grep -E
    # alternations, lowercase, word-boundaried where relevant.
    case "$skill_name" in
      rollback)
        kw='(roll back|revert to|undo to|restore (a|the) (earlier|previous) gate)'
        ;;
      testing)
        kw='(write tests?|add tests?|test coverage|run the tests?|failing tests?|pytest|vitest|playwright)'
        ;;
      debug)
        kw='(debug|fix (this|the) error|why is this failing|stack trace|error message|not working|broken)'
        ;;
      deployment|deploy)
        kw='(deploy|push to (prod|production|staging)|ship it|release)'
        ;;
      security)
        kw='(security (audit|check|review|scan)|vulnerabilit|owasp|secrets? (leak|exposed))'
        ;;
      performance)
        kw='(performance|slow|latency|load test|benchmark|profiling|optimize)'
        ;;
      'critical-thinker')
        kw='(architectu|design decision|pressure[ -]?test|second opinion|review (this|the) (stack|decision|approach)|tech stack)'
        ;;
      'build-rules')
        kw='(new (project|app|build)|start (a|the) build|plan (a|the) (app|build|project)|build (a|an) (app|tool)|make (a|an) (app|tool))'
        ;;
      billing)
        kw='(invoice|billable hours|hours worked|how many hours|bill (for|the) client|timelog|hand[ -]?off|deliver to client|client handoff|project complete|new client|client (intake|onboarding)|send (the )?proposal|draft (a )?contract)'
        ;;
      health)
        kw='(health check|audit blueprint|blueprint audit|audit syntaris|syntaris audit)'
        ;;
      validate)
        kw='(run validation|harness check|full test sweep|validate (the )?(harness|install|skills|hooks))'
        ;;
      research)
        kw='(competitive (intel|intelligence|analysis)|research (the )?market|look up (the )?competitors?|competitor analysis)'
        ;;
      costs|cost)
        kw='(how much will (this|it) cost|cost (estimate|projection|forecast)|monthly bill|pricing for)'
        ;;
      start)
        kw='(resume (the|this) project|pick (this|it) up|continue from|where did we leave)'
        ;;
      'global-rules')
        kw='^never-match-anything$'   # no natural-language triggers, skill is always active
        ;;
      *)
        kw=''
        ;;
    esac

    if [ -n "$kw" ]; then
      if printf '%s' "$PROMPT_LOWER" | grep -qE -- "$kw"; then
        matched=true
      fi
    fi

    # Also still check for any /command triggers mentioned in the description
    if ! $matched; then
      triggers=$(printf '%s' "$description" \
                 | grep -oE '/[a-z][a-z0-9-]+' | sort -u)
      while IFS= read -r trig; do
        [[ -z "$trig" ]] && continue
        if printf '%s' "$PROMPT_LOWER" | grep -qF -- "$trig"; then
          matched=true
          break
        fi
      done <<< "$triggers"
    fi
  fi

  if $matched; then
    matches+=("$skill_name")
  fi
done

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Escape session for JSON
SESSION_ESC=$(printf '%s' "$SESSION" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

if [[ ${#matches[@]} -eq 0 ]]; then
  # Record non-matches too so we can compute match rate
  printf '{"ts":"%s","skill":null,"session":"%s","prompt_hint":"%s"}\n' \
    "$TS" "$SESSION_ESC" "$PROMPT_HINT" >> "$LOG_FILE"
else
  for skill in "${matches[@]}"; do
    printf '{"ts":"%s","skill":"%s","session":"%s","prompt_hint":"%s"}\n' \
      "$TS" "$skill" "$SESSION_ESC" "$PROMPT_HINT" >> "$LOG_FILE"
  done
fi

exit 0
