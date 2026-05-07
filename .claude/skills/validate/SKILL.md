---
name: validate
description: "Run the Syntaris harness validation suite plus user-project tests. Use this skill at gate close, before tagging a Syntaris release, before publishing, or whenever you want to confirm the methodology layer (hooks, skills, agents, calibration) plus the user's project tests are all healthy. Trigger phrases: validate, run validation, /validate, harness check, full test sweep."
---

# VALIDATE SKILL - Syntaris v0.6.0+
# Invoke: /validate

The validation suite confirms two things in one pass:

1. **Harness validation.** All hooks parse, install round-trips cleanly,
   no stale references, calibration math is correct, every cross-file
   dependency resolves.
2. **User-project tests.** If the project has a test suite (pytest /
   vitest / jest / go test), it runs. A harness with green calibration
   but failing project tests is not a passing validation.

## When to invoke

Manual:
- Before tagging a new Syntaris version (`syntaris-gate-vX.Y.Z`)
- Before publishing changes that touch hooks, skills, or agents
- After modifying `.claude/hooks/`, `.claude/skills/`, or `.claude/agents/`
- Whenever a regression is suspected

Auto (per `foundation/CLAUDE.md` gate-close protocol):
- At every gate close, before the calibration hook fires
- Failures block the gate. The user cannot type GO if /validate
  reports any failures.

## Platform requirement

Tests are bash. On Windows you need **Git Bash** or **WSL** to run them.
PowerShell-only environments cannot invoke /validate; install Git Bash
or run from inside WSL. Tests still cover both `.sh` and `.ps1` hooks
(syntax check, format consistency) — the runner just needs bash.

## How it works

The skill orchestrates `tests/*.sh` scripts. The runner:
1. Sources `lib.sh` for shared assertion helpers.
2. Iterates `tests/*.sh` in numeric order, sourcing each into the
   shared counter scope.
3. Aggregates totals, prints a summary, lists every failure.
4. Exits non-zero if any test failed (so the gate-close protocol can
   block on it).

Run-all entry point:
```bash
bash .claude/skills/validate/run-all.sh
```

Or invoke through the skill:
```
/validate
```

## What gets tested

| Group | Script | Covers |
|---|---|---|
| Syntax | `01-syntax.sh` | Every `.sh` passes `bash -n`; every `.ps1` tokenizes cleanly |
| Session-start | `02-session-start.sh` | Error count snapshot writes correctly, edge cases |
| Gate-close calibration | `03-gate-close.sh` | ESTIMATION line format, error delta, idempotent re-runs, variance heads-up |
| Stale references | `04-stale-refs.sh` | No ONBOARDING_MODE, no casual-coder, no CLIENT_TYPE in template |
| Cross-file consistency | `05-cross-file.sh` | All agents/skills/hooks present, .gitattributes correct, format parity bash/PS |
| Full-cycle integration | `06-integration.sh` | Session start → work → gate close end-to-end |
| Edge cases | `07-edge-cases.sh` | Unicode, stress 200 errors, garbage input, backwards compat |
| Hook-wrapper | `08-wrapper.sh` | Dispatcher routes correctly, propagates exit 2, fails gracefully |
| Install round-trip | `09-install.sh` | install.sh + uninstall.sh into a fake $HOME, CRLF stripped, hooks functional |
| Project tests | `10-project-tests.sh` | Detect and run pytest, vitest, jest, or go test if the project ships one |

## Output format

The runner prints sections like:

```
=== 02-session-start.sh ===
  [PASS] 1.1 Count 3 ERR- entries
  [PASS] 1.2 Count 0 ERR- entries
  [FAIL] 1.3 No ERRORS.md => count=0: expected='0' actual=''
  ...

=== SUMMARY ===
  Total: 87
  Passed: 86
  Failed: 1

  Failures:
    - 1.3 No ERRORS.md => count=0
```

Exit codes:
- `0` — all tests passed
- `1` — one or more tests failed (gate close should block)
- `2` — runner could not start (missing dependency, bad path, etc.)

## Interpreting results

Most failures fall into three categories:

1. **Stale-reference fail** — A cleanup left a dangling
   `ONBOARDING_MODE` or `casual coder` reference in some doc. Fix the
   referenced file. Re-run.
2. **Hook drift fail** — A hook was edited and broke either syntax
   (caught by `01-syntax.sh`) or behavior (caught by `02`/`03`). Read
   the failure message; the assertion shows expected vs actual.
3. **Cross-file fail** — A skill, hook, or agent referenced in docs
   doesn't exist on disk, or vice versa. Either add the missing file
   or update the reference.

When a project test (`10-project-tests.sh`) fails, that's a real
project-code failure — not a Syntaris bug. Fix the project test
before closing the gate.

## Gate-close integration

The `foundation/CLAUDE.md` gate-close protocol step 1 reads:
> 1. Run /validate - fix failures before presenting

This replaces the older "Run full test suite" since `/validate` covers
both the harness and the project tests in one pass.

## Adding a new test

1. Create `tests/NN-name.sh` (use the next available NN).
2. Inside, call `assert_eq`, `assert_contains`, `assert_file_exists`
   from `lib.sh` — they auto-update PASS/FAIL/TOTAL counters.
3. Use a setup/teardown pattern with `mktemp -d` for isolation.
4. Re-run `/validate` — your new test is picked up automatically by
   the glob in `run-all.sh`.

The runner's iteration order is alphabetical, so prefix new tests
with the right number to control order. Tests that depend on earlier
tests' artifacts should number higher.

## What this skill does NOT cover

- Network-dependent tests (web fetches, API calls)
- Tier-2/3 install paths (Cursor, Windsurf, Codex, Aider, Kiro,
  OpenCode adapters) — these need the target harness installed
- Migration script behavior on a real v0.2.0 project
- PowerShell-only paths run end-to-end (we test PS1 syntax + the
  PS1 calibration hook directly, but full PS1 install round-trip
  needs `verify.ps1` instead)

These are tracked as gaps in `BUILD_NEXT.md` for future expansion.
