#!/bin/bash
# verify.sh
# Blueprint v11 installation verification
#
# Runs automatically at the end of install.sh, but can also be run standalone:
#   ./verify.sh
#   ./verify.sh --install-root ~/.claude
#   ./verify.sh --verbose
#
# Checks four layers:
#   1. Files present
#   2. Files structurally valid (JSON parses, YAML frontmatter well-formed)
#   3. Hooks executable and dependencies available
#   4. Functional smoke tests (SessionStart JSON, block-dangerous behavior)
#
# Exit codes:
#   0 - all layers passed
#   1 - one or more failures (details printed)

set -u  # treat unset variables as errors

INSTALL_ROOT="${HOME}/.claude"
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root) INSTALL_ROOT="$2"; shift 2 ;;
    --verbose|-v)   VERBOSE=true; shift ;;
    -h|--help)
      cat <<EOF
Blueprint v11 Verification

Usage:
  ./verify.sh                           # verify default install location
  ./verify.sh --install-root DIR        # verify a specific install
  ./verify.sh --verbose                 # show detail for every check

Exit codes:
  0  all checks passed
  1  one or more failures
EOF
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# == Color helpers ===========================================================

if [[ -t 1 ]]; then
  C_CYAN='\033[0;36m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'; C_GRAY='\033[0;90m'; C_RESET='\033[0m'
else
  C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_GRAY=''; C_RESET=''
fi

pass_count=0
fail_count=0
warn_count=0
fail_msgs=()

pass() {
  pass_count=$((pass_count + 1))
  $VERBOSE && printf "  ${C_GREEN}[PASS]${C_RESET} %s\n" "$*"
}
fail() {
  fail_count=$((fail_count + 1))
  fail_msgs+=("$*")
  printf "  ${C_RED}[FAIL]${C_RESET} %s\n" "$*"
}
warn() {
  warn_count=$((warn_count + 1))
  printf "  ${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"
}
section() {
  printf "\n${C_CYAN}%s${C_RESET}\n" "$*"
}

echo ""
printf "${C_CYAN}============================================${C_RESET}\n"
printf "${C_CYAN}  Blueprint v11 - Verification${C_RESET}\n"
printf "${C_CYAN}  Install root: %s${C_RESET}\n" "$INSTALL_ROOT"
printf "${C_CYAN}============================================${C_RESET}\n"

# ===========================================================================
# LAYER 1: Files present
# ===========================================================================

section "Layer 1: Files present"

if [[ ! -d "$INSTALL_ROOT" ]]; then
  fail "Install root does not exist: $INSTALL_ROOT"
  printf "\n${C_RED}CRITICAL: cannot continue without install root. Run install.sh first.${C_RESET}\n"
  exit 1
fi
pass "install root exists"

# settings.json
settings="$INSTALL_ROOT/settings.json"
if [[ -f "$settings" ]]; then
  pass "settings.json present"
else
  fail "settings.json missing: $settings"
fi

# 16 skills
required_skills=(
  start build-rules global-rules critical-thinker
  testing security deployment costs performance
  debug research freelance-billing handoff
  health onboard rollback
)
missing_skills=0
for s in "${required_skills[@]}"; do
  if [[ -f "$INSTALL_ROOT/skills/$s/SKILL.md" ]]; then
    pass "skill: $s"
  else
    fail "skill missing: $s/SKILL.md"
    missing_skills=$((missing_skills + 1))
  fi
done

# 16 hook scripts
required_hooks=(
  hook-wrapper.sh hook-wrapper.ps1
  session-start.sh session-start.ps1
  strip-coauthor.sh strip-coauthor.ps1
  enforce-tests.sh enforce-tests.ps1
  block-dangerous.sh block-dangerous.ps1
  context-check.sh context-check.ps1
  pre-compact.sh pre-compact.ps1
  writethru-episodic.sh writethru-episodic.ps1
)
for h in "${required_hooks[@]}"; do
  if [[ -f "$INSTALL_ROOT/hooks/$h" ]]; then
    pass "hook: $h"
  else
    fail "hook missing: $h"
  fi
done

# 3 agents
for a in spec-reviewer.md test-writer.md security-auditor.md; do
  if [[ -f "$INSTALL_ROOT/agents/$a" ]]; then
    pass "agent: $a"
  else
    fail "agent missing: $a"
  fi
done

# ===========================================================================
# LAYER 2: Structural validity
# ===========================================================================

section "Layer 2: Structural validity"

# settings.json parses as JSON
if [[ -f "$settings" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$settings" 2>/dev/null; then
      pass "settings.json is valid JSON"
    else
      fail "settings.json is not valid JSON"
    fi
  elif command -v jq >/dev/null 2>&1; then
    if jq empty "$settings" 2>/dev/null; then
      pass "settings.json is valid JSON (via jq)"
    else
      fail "settings.json is not valid JSON (via jq)"
    fi
  else
    warn "no python3 or jq available; cannot validate settings.json"
  fi
fi

# Each SKILL.md has YAML frontmatter with name and description
validate_frontmatter() {
  local file="$1"
  local label="$2"
  [[ -f "$file" ]] || return 1

  # Read first 20 lines; must start with ---, must contain name: and description:
  local head_content
  head_content=$(head -20 "$file")

  # Check starts with --- on line 1
  if ! head -1 "$file" | grep -q "^---$"; then
    fail "$label: missing YAML frontmatter opening '---'"
    return 1
  fi

  # Check has closing ---
  if ! echo "$head_content" | tail -n +2 | grep -q "^---$"; then
    fail "$label: missing YAML frontmatter closing '---'"
    return 1
  fi

  # Check has name: field (must not be empty)
  if ! echo "$head_content" | grep -qE "^name:[[:space:]]+[^[:space:]]"; then
    fail "$label: missing or empty 'name:' field"
    return 1
  fi

  # Check has description: field (must not be empty)
  if ! echo "$head_content" | grep -qE "^description:[[:space:]]+.+"; then
    fail "$label: missing or empty 'description:' field"
    return 1
  fi

  pass "$label: frontmatter valid"
  return 0
}

for s in "${required_skills[@]}"; do
  validate_frontmatter "$INSTALL_ROOT/skills/$s/SKILL.md" "skill/$s"
done

for a in spec-reviewer test-writer security-auditor; do
  validate_frontmatter "$INSTALL_ROOT/agents/${a}.md" "agent/$a"
done

# Bash hooks pass syntax check
for h in session-start strip-coauthor enforce-tests block-dangerous \
         context-check pre-compact writethru-episodic hook-wrapper; do
  path="$INSTALL_ROOT/hooks/$h.sh"
  if [[ -f "$path" ]]; then
    if bash -n "$path" 2>/dev/null; then
      pass "bash syntax: $h.sh"
    else
      fail "bash syntax error: $h.sh"
    fi
  fi
done

# PowerShell hooks parse (if pwsh is available - rare on Mac/Linux)
if command -v pwsh >/dev/null 2>&1; then
  for h in session-start strip-coauthor enforce-tests block-dangerous \
           context-check pre-compact writethru-episodic hook-wrapper; do
    path="$INSTALL_ROOT/hooks/$h.ps1"
    if [[ -f "$path" ]]; then
      if pwsh -NoProfile -Command "
        try {
          \$null = [System.Management.Automation.Language.Parser]::ParseFile('$path', [ref]\$null, [ref]\$null)
          exit 0
        } catch { exit 1 }
      " 2>/dev/null; then
        pass "powershell syntax: $h.ps1"
      else
        fail "powershell syntax error: $h.ps1"
      fi
    fi
  done
else
  $VERBOSE && warn "pwsh not installed - skipping PowerShell syntax checks"
fi

# ===========================================================================
# LAYER 3: Execution readiness
# ===========================================================================

section "Layer 3: Execution readiness"

# Hook scripts executable
for h in session-start strip-coauthor enforce-tests block-dangerous \
         context-check pre-compact writethru-episodic hook-wrapper; do
  path="$INSTALL_ROOT/hooks/$h.sh"
  if [[ -f "$path" ]]; then
    if [[ -x "$path" ]]; then
      pass "executable: $h.sh"
    else
      fail "not executable: $h.sh (run: chmod +x $path)"
    fi
  fi
done

# Dependencies on PATH
if command -v bash >/dev/null 2>&1; then
  pass "bash on PATH ($(bash --version | head -1))"
else
  fail "bash not on PATH - hooks cannot run"
fi

if command -v jq >/dev/null 2>&1; then
  pass "jq on PATH (preferred JSON parser)"
else
  warn "jq not on PATH - hooks will fall back to grep (works but less robust)"
fi

if command -v git >/dev/null 2>&1; then
  pass "git on PATH (needed by strip-coauthor and pre-compact hooks)"
else
  warn "git not on PATH - strip-coauthor hook will no-op"
fi

# On WSL / Git Bash: powershell.exe reachable?
if command -v powershell.exe >/dev/null 2>&1; then
  pass "powershell.exe reachable (Windows fallback available)"
elif [[ "$(uname -s)" == "Darwin" || "$(uname -s)" == "Linux" ]]; then
  $VERBOSE && pass "not on Windows - powershell.exe not required"
else
  warn "powershell.exe not reachable - Windows fallback unavailable"
fi

# /tmp writable (hook-wrapper uses this for error logs)
if [[ -w /tmp ]]; then
  pass "/tmp writable (hook error logs)"
elif [[ -n "${TMPDIR:-}" && -w "$TMPDIR" ]]; then
  pass "TMPDIR writable ($TMPDIR)"
else
  fail "no writable temp dir - hook-wrapper cannot capture errors"
fi

# ===========================================================================
# LAYER 4: Functional smoke tests
# ===========================================================================

section "Layer 4: Functional smoke tests"

# Set up a temporary project dir with hooks accessible at the project-local path
smoke_root="$(mktemp -d -t bp-verify-XXXXXX)"
mkdir -p "$smoke_root/.claude/hooks"

# Copy all the installed hooks into the test project's hooks dir
cp "$INSTALL_ROOT/hooks/"*.sh "$smoke_root/.claude/hooks/" 2>/dev/null || true
chmod +x "$smoke_root/.claude/hooks/"*.sh 2>/dev/null || true

# Create minimal CONTRACT.md so session-start has something to read
cat > "$smoke_root/CONTRACT.md" <<'EOF'
PROJECT_NAME: VerifyTest
PROJECT_VERSION: v0.0.0
CLIENT_TYPE: PERSONAL
EOF

cleanup_smoke() {
  rm -rf "$smoke_root" 2>/dev/null || true
  # Clean up any state files the smoke tests caused to be written.
  # The hooks invoked here use CLAUDE_SESSION_ID=verify so the counters
  # have deterministic names.
  rm -f "$smoke_root/.claude/state/turns-verify.count" 2>/dev/null || true
  rm -f "$INSTALL_ROOT/state/turns-verify.count" 2>/dev/null || true
  # Hook error logs in the system tmp dir for the verify session
  rm -f "${TMPDIR:-/tmp}/bp-hook-err-verify.log" 2>/dev/null || true
  # Telemetry entries produced by verify probes (session "verify" marker)
  local log="$INSTALL_ROOT/state/skill-log.jsonl"
  if [[ -f "$log" ]]; then
    grep -v '"session":"verify"' "$log" > "$log.tmp" 2>/dev/null && mv "$log.tmp" "$log" 2>/dev/null || true
  fi
}
trap cleanup_smoke EXIT

# Smoke test 1: SessionStart produces valid JSON with correct wrapper
if [[ -x "$smoke_root/.claude/hooks/hook-wrapper.sh" ]]; then
  ss_output=$(echo '{"session_id":"verify"}' | \
    CLAUDE_PROJECT_DIR="$smoke_root" \
    CLAUDE_SESSION_ID=verify \
    bash "$smoke_root/.claude/hooks/hook-wrapper.sh" session-start 2>/dev/null || echo "")

  if [[ -z "$ss_output" ]]; then
    fail "SessionStart: no output from hook-wrapper"
  elif command -v python3 >/dev/null 2>&1; then
    if python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    assert 'hookSpecificOutput' in d, 'missing hookSpecificOutput'
    hso = d['hookSpecificOutput']
    assert hso.get('hookEventName') == 'SessionStart', f'wrong hookEventName: {hso.get(\"hookEventName\")}'
    assert 'additionalContext' in hso, 'missing additionalContext'
    assert 'Blueprint v11' in hso['additionalContext'], 'context does not mention Blueprint v11'
except Exception as e:
    print(f'Validation failed: {e}', file=sys.stderr)
    sys.exit(1)
" "$ss_output" 2>/dev/null; then
      pass "SessionStart: valid JSON with hookSpecificOutput wrapper"
    else
      fail "SessionStart: output is not valid Blueprint JSON"
      $VERBOSE && printf "${C_GRAY}    got: %s${C_RESET}\n" "$ss_output"
    fi
  else
    # Without python3, do a best-effort string check
    if echo "$ss_output" | grep -q '"hookSpecificOutput"' && \
       echo "$ss_output" | grep -q '"hookEventName":"SessionStart"'; then
      pass "SessionStart: output contains expected fields (best-effort)"
    else
      fail "SessionStart: output missing hookSpecificOutput or hookEventName"
    fi
  fi
else
  fail "SessionStart: hook-wrapper.sh not executable - cannot test"
fi

# Smoke test 2: block-dangerous blocks rm -rf /
if [[ -x "$smoke_root/.claude/hooks/hook-wrapper.sh" ]]; then
  danger_output=$(echo '{"session_id":"verify","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | \
    CLAUDE_PROJECT_DIR="$smoke_root" \
    bash "$smoke_root/.claude/hooks/hook-wrapper.sh" block-dangerous 2>&1)
  danger_exit=$?

  if [[ $danger_exit -eq 2 ]]; then
    pass "block-dangerous: blocks rm -rf / (exit 2)"
    if echo "$danger_output" | grep -qi "blocked"; then
      pass "block-dangerous: surfaces block reason to stderr"
    else
      warn "block-dangerous: exit 2 but no block reason in stderr"
    fi
  else
    fail "block-dangerous: did not block rm -rf / (exit $danger_exit, expected 2)"
  fi
else
  fail "block-dangerous: hook-wrapper.sh not executable - cannot test"
fi

# Smoke test 3: block-dangerous allows ls
if [[ -x "$smoke_root/.claude/hooks/hook-wrapper.sh" ]]; then
  safe_output=$(echo '{"session_id":"verify","tool_name":"Bash","tool_input":{"command":"ls -la"}}' | \
    CLAUDE_PROJECT_DIR="$smoke_root" \
    bash "$smoke_root/.claude/hooks/hook-wrapper.sh" block-dangerous 2>&1)
  safe_exit=$?

  if [[ $safe_exit -eq 0 ]]; then
    pass "block-dangerous: allows safe command ls (exit 0)"
  else
    fail "block-dangerous: blocked safe command ls (exit $safe_exit, expected 0)"
  fi
fi

# Smoke test 4: block-dangerous blocks git force-push to main
if [[ -x "$smoke_root/.claude/hooks/hook-wrapper.sh" ]]; then
  fp_output=$(echo '{"session_id":"verify","tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' | \
    CLAUDE_PROJECT_DIR="$smoke_root" \
    bash "$smoke_root/.claude/hooks/hook-wrapper.sh" block-dangerous 2>&1)
  fp_exit=$?

  if [[ $fp_exit -eq 2 ]]; then
    pass "block-dangerous: blocks force-push to main (exit 2)"
  else
    fail "block-dangerous: did not block force-push to main (exit $fp_exit, expected 2)"
  fi
fi

# Smoke test 5: missing hook in BLUEPRINT_DEBUG mode surfaces diagnostic
if [[ -x "$smoke_root/.claude/hooks/hook-wrapper.sh" ]]; then
  dbg_output=$(echo '{}' | \
    BLUEPRINT_DEBUG=1 \
    CLAUDE_PROJECT_DIR="$smoke_root" \
    bash "$smoke_root/.claude/hooks/hook-wrapper.sh" nonexistent-hook 2>&1)
  dbg_exit=$?

  if [[ $dbg_exit -eq 0 ]]; then
    if echo "$dbg_output" | grep -q "not found on any fallback path"; then
      pass "missing hook: diagnostic surfaces in BLUEPRINT_DEBUG mode"
    else
      warn "missing hook: exit 0 but no diagnostic message"
    fi
  else
    fail "missing hook: exit $dbg_exit (expected 0 - missing hooks should fail open)"
  fi
fi

# ===========================================================================
# SUMMARY
# ===========================================================================

echo ""
printf "${C_CYAN}============================================${C_RESET}\n"
printf "${C_CYAN}  Verification summary${C_RESET}\n"
printf "${C_CYAN}============================================${C_RESET}\n"
printf "  ${C_GREEN}Passed:${C_RESET} %d\n" "$pass_count"
if [[ $warn_count -gt 0 ]]; then
  printf "  ${C_YELLOW}Warnings:${C_RESET} %d\n" "$warn_count"
fi
if [[ $fail_count -gt 0 ]]; then
  printf "  ${C_RED}Failed:${C_RESET} %d\n" "$fail_count"
  echo ""
  printf "${C_RED}Failures:${C_RESET}\n"
  for msg in "${fail_msgs[@]}"; do
    printf "  - %s\n" "$msg"
  done
  echo ""
  printf "${C_YELLOW}Blueprint v11 install has problems. See failures above.${C_RESET}\n"
  printf "${C_YELLOW}Re-run install.sh, or fix the specific items listed.${C_RESET}\n"
  echo ""
  exit 1
fi

echo ""
printf "${C_GREEN}All verification layers passed. Blueprint v11 is ready to use.${C_RESET}\n"
printf "  * Files: present and structurally valid\n"
printf "  * Hooks: executable and dependencies available\n"
printf "  * Smoke tests: SessionStart produces valid JSON; dangerous commands block correctly\n"
echo ""
exit 0
