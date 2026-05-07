#!/bin/bash
# lib.sh - shared assertion helpers for /validate test scripts
#
# Each assertion auto-updates the parent scope counters PASS, FAIL, TOTAL,
# and appends to FAILURES on failure. The runner (run-all.sh) initializes
# these and prints the final summary.
#
# All scripts under tests/ are sourced by run-all.sh, so they share scope.

assert_eq() {
  TOTAL=$((TOTAL+1))
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc: expected='$expected' actual='$actual'"
    FAIL=$((FAIL+1))
    FAILURES+=("$desc")
  fi
}

assert_contains() {
  TOTAL=$((TOTAL+1))
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc: '$needle' not found"
    FAIL=$((FAIL+1))
    FAILURES+=("$desc")
  fi
}

assert_file_exists() {
  TOTAL=$((TOTAL+1))
  local desc="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc: not found at '$path'"
    FAIL=$((FAIL+1))
    FAILURES+=("$desc")
  fi
}

assert_file_not_exists() {
  TOTAL=$((TOTAL+1))
  local desc="$1" path="$2"
  if [[ ! -f "$path" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc: file should not exist at '$path'"
    FAIL=$((FAIL+1))
    FAILURES+=("$desc")
  fi
}

assert_dir_exists() {
  TOTAL=$((TOTAL+1))
  local desc="$1" path="$2"
  if [[ -d "$path" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc: directory not found at '$path'"
    FAIL=$((FAIL+1))
    FAILURES+=("$desc")
  fi
}

assert_exit_code() {
  TOTAL=$((TOTAL+1))
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  [PASS] $desc"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $desc: expected exit=$expected actual exit=$actual"
    FAIL=$((FAIL+1))
    FAILURES+=("$desc")
  fi
}

# Helper: set up a minimal Syntaris project in a temp dir for testing.
# Echoes the path; caller is responsible for rm -rf.
setup_test_project() {
  local dir
  dir=$(mktemp -d)
  cat > "$dir/CONTRACT.md" <<'CONTRACT_EOF'
PROJECT_NAME: ValidateTest
PROJECT_VERSION: v0.1.0
CLIENT_TYPE: PERSONAL
CONTRACT_EOF
  echo "$dir"
}
