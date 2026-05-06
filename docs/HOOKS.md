# Syntaris Hooks Reference

Syntaris ships 10 shell hooks (each as a bash + PowerShell pair, plus one cross-platform wrapper). They run automatically on Claude Code events. This document describes what each one does, when it fires, and what state it touches.

For a quick at-a-glance table, see the README. This file goes deeper.

---

## How invocation works

`settings.json` points every hook event at `hook-wrapper.sh` (with PowerShell fallback). The wrapper:

1. Reads stdin once and captures the event payload.
2. Tries the project-local hook at `$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh`.
3. Falls back to the user-global hook at `$HOME/.claude/hooks/<name>.sh`.
4. Falls back to PowerShell at `$USERPROFILE\.claude\hooks\<name>.ps1` on Windows.
5. Surfaces any errors when a hook intentionally blocks (exit 2) or when no hook was found.

This means every hook is reachable from every supported platform without forcing the user to maintain two parallel `settings.json` configurations.

`SYNTARIS_DEBUG=1` makes the wrapper surface stderr from every successful hook run, not only blocking ones.

---

## Hook catalog

### `hook-wrapper`

**Fires on:** every other hook event (it's the dispatcher).
**Job:** locate the right per-event hook script across project-local, user-global, and PowerShell paths. Read stdin once and pipe it to the chosen child.
**Can block:** propagates exit 2 from the child.
**State touched:** writes per-session error logs to `$TMPDIR/syntaris-hook-err-<session_id>.log` for diagnostics.

---

### `session-start`

**Fires on:** Claude Code `SessionStart` event (start of a new chat or after `/clear`).
**Job:** reset the per-session turn counter, ensure the state directory exists, prep the session record. Lightweight bookkeeping.
**Can block:** no. Always exits 0.
**State touched:** writes to `~/.claude/state/turns-<session_id>.count` and similar bookkeeping files.

---

### `strip-coauthor`

**Fires on:** `PreToolUse` with matcher `Bash` (every Bash command).
**Job:** install a git `commit-msg` hook in the current repo's `.git/hooks/` directory that strips `Co-Authored-By: Claude` trailers from commits before they're written. This prevents Vercel and other Hobby-tier services from rejecting the deploy because the commit's claimed co-author can't be resolved to a verified GitHub user.
**Can block:** no. Idempotent: only installs the git hook once per repo, then no-ops on subsequent calls.
**State touched:** creates `<repo>/.git/hooks/commit-msg` if not present.

---

### `enforce-tests`

**Fires on:** `PreToolUse` with matcher `Write|Edit|MultiEdit`.
**Job:** if the most recent `pytest`/`vitest` run produced failures, block writes to source files. Allows writes to test files, markdown, JSON, YAML, lockfiles. The intent is to make Claude Code fix failing tests before piling on more changes that depend on broken state.
**Can block:** yes (exit 2). When blocked, prints the failing test names to stderr.
**State touched:** reads `.syntaris/last-test-run.json` written by the testing skill.

---

### `block-dangerous`

**Fires on:** `PreToolUse` with matcher `Bash`.
**Job:** scan the bash command being submitted for destructive patterns. Blocks:
- `rm -rf /`, `rm -rf ~`, `rm -rf .`, `rm -rf *` and `-fr` variants
- Force pushes to `main` or `master` (`git push --force`, `git push -f`)
- Destructive SQL (`DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`, `DELETE ... WHERE 1=1`)
- Direct production database access via `psql` or `pg_dump` against a host name containing "production"

**Can block:** yes (exit 2). Prints a one-line explanation to stderr.
**State touched:** none.

`settings.json` `permissions.deny` provides a coarser first-line block; this hook is the catch-all that handles variants.

---

### `context-check`

**Fires on:** `PostToolUse` after every Write/Edit/MultiEdit.
**Job:** track turn count per session. Warns at 80 turns ("save important context to PLANS.md, consider /clear soon"). Hard-stops at 120 turns ("context is too long, save to PLANS.md and /clear before continuing").
**Can block:** no, but the hard-stop warning is loud enough that Claude Code typically stops.
**State touched:** increments `~/.claude/state/turns-<session_id>.count`.

---

### `pre-compact`

**Fires on:** Claude Code `PreCompact` event (before `/compact`).
**Job:** Syntaris discourages `/compact` in favor of `/clear`. This hook writes the current TODO list, in-progress task, and active gate context to `PLANS.md` so they survive the compact. If the user later regrets the compact, the foundation file has a snapshot.
**Can block:** no.
**State touched:** appends to project-local `foundation/PLANS.md`.

---

### `writethru-episodic`

**Fires on:** Claude Code `Stop` event (session end).
**Job:** write the session's gate outcomes, stop events, and unfinished tasks to `MEMORY_EPISODIC.md`. This is the write-through that keeps the episodic memory continuous across sessions.
**Can block:** no.
**State touched:** appends to project-local `foundation/MEMORY_EPISODIC.md`.

---

### `gate-close-calibration`

**Fires on:** triggered by the build-rules skill at every gate close (not by Claude Code event).
**Job:** read the predicted hours from `VERSION_ROADMAP.md` and the actual hours from `TIMELOG.md`. Compute variance. Append an `ESTIMATION` entry to `MEMORY_CORRECTIONS.md`. If variance exceeds 30%, print a heads-up so Claude knows to write a deeper REFLEXION explaining the gap.
**Can block:** no.
**State touched:** appends to project-local `foundation/MEMORY_CORRECTIONS.md`.

This is the calibration loop. Across enough gates, the variance entries become training data for the build-rules skill's estimation prompts.

---

### `skill-telemetry`

**Fires on:** every skill invocation (logged from inside the skills themselves).
**Job:** record which skill ran, what gate, what project, and how long it took. Used by the `health` skill to surface "this skill hasn't fired in 30 days" or "this skill fired 50 times this week, is it being mis-triggered?"
**Can block:** no.
**State touched:** appends to `~/.claude/state/skill-log.jsonl`.

---

## Which hooks can block tool calls?

Only two: `enforce-tests` and `block-dangerous`. Everything else exits 0 and only logs or warns. This is by design: blocking hooks are a sharp instrument and should only fire when the intent is genuinely "stop this from happening."

---

## Hook ordering on `Bash` events

When the user runs a bash command, three hooks fire in this order:

1. `strip-coauthor` (PreToolUse, matcher `Bash`) - installs the git commit-msg hook if needed
2. `block-dangerous` (PreToolUse, matcher `Bash`) - checks the command for destructive patterns
3. The bash command itself runs (or is blocked)

`strip-coauthor` does not block; it just side-effects the repo's `.git/hooks/`. `block-dangerous` is the only one that can stop execution.

---

## Disabling a hook for one project

Two options:

1. **Project-local override.** Place a stub script at `<project>/.claude/hooks/<name>.sh` that just `exit 0`s. The wrapper picks it up before falling back to the user-global one.
2. **`settings.json` override.** Edit the project-local `.claude/settings.json` to remove the matcher that fires the hook. This is invasive and survives across users; only do it when the hook is genuinely wrong for the project.

Disabling hooks system-wide is not supported. The intent is that hooks are part of the methodology; turning them off changes what Syntaris is.

---

## Diagnosing a misbehaving hook

```bash
# Surface stderr from every hook run
SYNTARIS_DEBUG=1 claude

# Or read the per-session error log directly
cat $TMPDIR/syntaris-hook-err-*.log
```

If a hook is failing silently, set `SYNTARIS_DEBUG=1` first. If it's failing with a parse error, check the PowerShell version (Windows ships 5.1 by default; PS7 operators don't parse). See `TROUBLESHOOTING.md`.
