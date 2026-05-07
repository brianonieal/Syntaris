#!/bin/bash
# 10-project-tests.sh - run user-project tests if the project ships a suite
#
# Auto-detects pytest / vitest / jest / go test / cargo test in the
# project at $PROJECT_ROOT. Skips cleanly if none are configured.
#
# Skipped if SKIP_PROJECT is set.

P="$PROJECT_ROOT"

# 10.0 - At least announce what we found
echo "  Project root: $P"

# Detect what test runners are configured
HAS_PYTEST=0
HAS_VITEST=0
HAS_JEST=0
HAS_GO=0
HAS_CARGO=0

[[ -f "$P/pyproject.toml" ]] && grep -qE "(pytest|\\[tool\\.pytest)" "$P/pyproject.toml" 2>/dev/null && HAS_PYTEST=1
[[ -f "$P/setup.cfg"      ]] && grep -q  "pytest" "$P/setup.cfg" 2>/dev/null && HAS_PYTEST=1
[[ -f "$P/pytest.ini"     ]] && HAS_PYTEST=1

[[ -f "$P/package.json" ]] && {
  grep -q '"vitest"' "$P/package.json" 2>/dev/null && HAS_VITEST=1
  grep -q '"jest"'   "$P/package.json" 2>/dev/null && HAS_JEST=1
}

[[ -f "$P/go.mod"        ]] && HAS_GO=1
[[ -f "$P/Cargo.toml"    ]] && HAS_CARGO=1

if [[ $HAS_PYTEST -eq 0 && $HAS_VITEST -eq 0 && $HAS_JEST -eq 0 && $HAS_GO -eq 0 && $HAS_CARGO -eq 0 ]]; then
  echo "  [SKIP] No project test runner detected (pytest/vitest/jest/go/cargo)"
  echo "         (This is expected when validating Syntaris itself, which has no project tests)"
  return
fi

# Run pytest
if [[ $HAS_PYTEST -eq 1 ]] && command -v pytest >/dev/null 2>&1; then
  echo "  Running pytest..."
  TOTAL=$((TOTAL+1))
  if (cd "$P" && pytest -q --tb=line 2>&1 | tail -20); then
    echo "  [PASS] 10.1 pytest suite passes"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 10.1 pytest suite has failures"
    FAIL=$((FAIL+1))
    FAILURES+=("10.1 pytest")
  fi
elif [[ $HAS_PYTEST -eq 1 ]]; then
  echo "  [SKIP] pytest configured but not installed in this env"
fi

# Run vitest
if [[ $HAS_VITEST -eq 1 ]] && [[ -f "$P/package.json" ]]; then
  echo "  Running vitest..."
  TOTAL=$((TOTAL+1))
  if (cd "$P" && npx --no-install vitest run --reporter=basic 2>&1 | tail -20); then
    echo "  [PASS] 10.2 vitest suite passes"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 10.2 vitest suite has failures"
    FAIL=$((FAIL+1))
    FAILURES+=("10.2 vitest")
  fi
fi

# Run jest
if [[ $HAS_JEST -eq 1 ]] && [[ -f "$P/package.json" ]]; then
  echo "  Running jest..."
  TOTAL=$((TOTAL+1))
  if (cd "$P" && npx --no-install jest --silent 2>&1 | tail -20); then
    echo "  [PASS] 10.3 jest suite passes"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 10.3 jest suite has failures"
    FAIL=$((FAIL+1))
    FAILURES+=("10.3 jest")
  fi
fi

# Run go test
if [[ $HAS_GO -eq 1 ]] && command -v go >/dev/null 2>&1; then
  echo "  Running go test..."
  TOTAL=$((TOTAL+1))
  if (cd "$P" && go test ./... 2>&1 | tail -20); then
    echo "  [PASS] 10.4 go test passes"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 10.4 go test has failures"
    FAIL=$((FAIL+1))
    FAILURES+=("10.4 go test")
  fi
fi

# Run cargo test
if [[ $HAS_CARGO -eq 1 ]] && command -v cargo >/dev/null 2>&1; then
  echo "  Running cargo test..."
  TOTAL=$((TOTAL+1))
  if (cd "$P" && cargo test --quiet 2>&1 | tail -20); then
    echo "  [PASS] 10.5 cargo test passes"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 10.5 cargo test has failures"
    FAIL=$((FAIL+1))
    FAILURES+=("10.5 cargo test")
  fi
fi
