# Blueprint Changelog

## v11.4 - April 23, 2026

Phase structure rename + personality change + full-roadmap-at-planning.
No breaking behavioral changes beyond the phase name migration; re-run
install to pick up the updated skills and foundation templates.

### Changed (phase rename)

- **Five phases renamed and redefined.** Old structure:
  `CONFIRMED -> ROADMAP APPROVED -> MOCKUPS APPROVED -> FRONTEND APPROVED -> GO`.
  New structure:
  `SCOPE CONFIRMED -> MOCKUPS APPROVED -> FRONTEND APPROVED -> TESTS APPROVED -> GO`.
  The old CONFIRMED and ROADMAP APPROVED phases are merged into
  SCOPE CONFIRMED, which now covers concept confirmation, build-type
  selection, dump + clarifying questions, and full roadmap generation
  in one checkpoint with one approval word. A new TESTS APPROVED phase
  sits between FRONTEND APPROVED and GO for test plan approval (the
  `testing` skill executes what gets approved there).

- **Full roadmap generated at SCOPE CONFIRMED, not incrementally.** The
  user sees the complete gate ladder from v0.0 through their final
  version at planning time. Near-term gates (first third, typically
  v0.0-v0.3) get single-number hour estimates. Later gates get ranges
  (e.g. "3-10h") with a one-line note on what drives the uncertainty.
  This gives the user destination visibility without false precision
  on far-future gates whose dependencies haven't been chosen yet.

- **Build type asked upfront.** New mandatory question in Phase 1:
  Production / Internal / Exploratory. Each path gets its own final
  version labeled explicitly: `v1.0 Production Live`,
  `v1.0 Internal GA`, or `v0.X Prototype Validated`. Gate count scales
  with build type and complexity; a simple exploratory prototype
  doesn't need staging-hardening gates.

### Changed (personality)

- **Easygoing SME voice across user-facing skills.** Rewrote
  `build-rules`, `start`, `critical-thinker`, `debug`, and
  `foundation/CLAUDE.md` to read as an experienced engineer asking
  good questions rather than a checklist robot. Explicit tone sections
  added to each skill with good and bad example phrasings.

- **Hook output softened.** Removed shouting-caps prefixes like
  `BLUEPRINT v11 HOOK: Recursive force delete blocked.` Replaced with
  direct but conversational language:
  `Blocked: rm -rf is a system-destructive command. If intentional,
  run it manually outside Claude Code.` Same firmness, no theatrical
  urgency. Applied to `block-dangerous.sh/.ps1`,
  `context-check.sh/.ps1`, and `enforce-tests.sh/.ps1`.

### Changed (interrogation flow)

- **Memory-dump question invites file and image uploads.** The
  interrogation now explicitly tells the user to upload screenshots,
  mockups, reference PDFs, or anything else relevant. The dump flows
  through the existing memory system; no new upload-tracking pipeline
  was added (the earlier three-layer design was judged overkill).

- **Clarifying questions use user-impact language, not engineer-speak.**
  Each clarifying question now includes a short consequence
  explanation framed in terms the user cares about (cost, timeline,
  security surface, lock-in), not internal technical concerns. Cap is
  5 questions; beyond that, Claude says plainly "I don't have enough
  yet, take another pass at the dump."

- **Scope changes force SCOPE CONFIRMED re-approval.** Mid-build
  scope creep (adding a feature, dropping a gate, changing build
  type) is handled by going back to SCOPE CONFIRMED rather than
  silently absorbing into the active gate. Stated plainly in the
  skill and enforced by CLAUDE.md's hard rules.

### Changed (calibration)

- **Variance > 30% prints a heads-up, does not silently edit the
  approved roadmap.** The calibration hook was already in v11.3. v11.4
  adds explicit policy: if variance at gate close exceeds 30%, print
  a human-readable note to the user indicating that future estimates
  for later gates were set before this data point and may warrant
  review. The approved roadmap is a commitment; variance informs
  future *new* estimates without rewriting existing commitments.

### Changed (foundation templates)

- **CONTRACT.md template** gained `BUILD_TYPE` and `FINAL_VERSION`
  fields in the PROJECT IDENTITY section. Header comment updated to
  "SCOPE CONFIRMED phase."

- **VERSION_ROADMAP.md template** restructured for the full-roadmap
  model. New BUILD TYPE section, explicit CALIBRATION MULTIPLIER
  section, roadmap table with example rows showing both near-term
  single-hour and far-term range formats.

- **CLAUDE.md template** got a new "HOW TO SHOW UP" section at the
  top setting the SME tone for every session, and the gate-close
  protocol now references the calibration hook.

### Fixed (bugs found by full v0.0 -> v1.0 dry-run simulation)

Six distinct bugs surfaced and were fixed by running a complete mock
app build through every phase and gate:

- **Calibration hook couldn't parse range estimates.** Ranges like
  `2-5h` were parsed as `5h`, systematically biasing calibration data
  toward "everything came in under estimate" and corrupting the
  feedback signal the system is designed to build. The hook now
  detects ranges explicitly and uses the midpoint (3.5h for `2-5h`).
  Verified: range 2-5h with actual 5.5h correctly produces +57%
  variance.

- **Variance heads-up was documented but not implemented.** The
  build-rules skill stated the policy "print a heads-up at >30%
  variance" but no code printed anything. Relying on the model to
  notice variance in the ESTIMATION line was unreliable. The hook
  itself now checks |variance| > 30 and writes a heads-up block to
  stderr with the gate version, the variance number, and the policy
  note ("approved ranges have not been edited; your call"). Mechanical
  enforcement matches documented behavior.

- **`[Empty until first gate close]` placeholder never got removed.**
  On every project past the first gate close, a stale placeholder line
  sat in the REFLEXION LOG section of MEMORY_CORRECTIONS.md below all
  the real entries. The hook now detects and removes that placeholder
  on first real insertion.

- **Telemetry match rate was catastrophically bad for natural
  language.** Only `/slash-command` and exact skill-name strings
  matched. "lets roll back" missed rollback. "write tests" missed
  testing. "review this architecture decision" missed critical-thinker.
  The hook now carries a curated natural-language keyword map per
  skill; 19 of 21 realistic test prompts now match the right skill,
  up from 1 of 21 previously. The two remaining non-matches are
  correctly non-matches (genuinely unrelated prompts).

- **VERSION_ROADMAP.md was never updated as gates closed.** After 11
  gate closes in the simulation, every row still said "pending" with
  "-" for actual hours. The gate-close protocol now explicitly
  includes updating VERSION_ROADMAP status to DONE and filling in
  actual hours for the closing gate as step 4, before the memory
  updates and calibration. Both build-rules/SKILL.md and
  foundation/CLAUDE.md reflect the new step.

- **verify.sh smoke test broke when hook output was softened.** The
  v11.4 softening changed `BLUEPRINT v11 HOOK: ...blocked.` to
  `Blocked: ...`. The smoke test's `grep -q "blocked"` was
  case-sensitive and missed the new capitalized message, producing
  83 passes / 2 warnings instead of 84 / 1. Changed to `grep -qi`.
  Baseline restored.

### Fixed (regression audit pass)

Four bugs found by an end-to-end v0.0 -> v1.0 simulation. All LOW
severity, none catastrophic. No version bump; re-run install to pick
up the fixed hooks.

- **`gate-close-calibration.sh` variance rounding mismatch.**
  The display used banker's rounding (`%.0f`) while the
  over-30% threshold check used truncation (`%d`). A variance of
  30.7% would print as `+31%` but fail the `-gt 30` guard, so the
  heads-up silently did not fire. Aligned both to `%.0f`. The PS1
  twin already used `[math]::Round` and was unaffected.

- **`gate-close-calibration` appended duplicate ESTIMATION rows on
  re-run.** The hook had no idempotency check. A realistic trigger
  (user fixes a TIMELOG typo and re-runs) produced a second row with
  a fresh timestamp. Both `.sh` and `.ps1` now drop any prior
  `ESTIMATION: gate=<version>` row inside the REFLEXION LOG section
  before inserting the new one.

- **`context-check` WARN throttle anchored to the wrong counter.**
  The throttle was `CURRENT % 10 == 0`, which means a user who set
  `WARN_TURNS=35` would see the first warning at turn 40, not 35.
  At the defaults (80/120) this was invisible because 80 is a
  multiple of 10. Now anchored to `(CURRENT - WARN_TURNS) % 10 == 0`
  so the first warning fires exactly at `WARN_TURNS` regardless.
  Applied to `.sh` and `.ps1`.

- **`build-rules/SKILL.md` step 10 snapshot list omitted
  `TIMELOG.md`.** A rollback that followed the skill literally
  restored `MEMORY_CORRECTIONS.md` correctly but left `TIMELOG.md`
  with stale rows for the rolled-back gates. If the user re-did a
  gate, the next calibration would sum both old and new rows and
  inflate the actual-hours figure. Added `TIMELOG.md` to the `cp`
  list with a brief note on why. Both skill copies updated; drift
  check passes.

### Fixed (PowerShell audit pass)

PowerShell 7.4 became available in the audit environment, which let us
run a second pass focused on the `.ps1` path. Six bugs fixed. One was
a real Windows-runtime crash; five were cross-platform portability
bugs that prevented PS 7 on Linux / macOS from running the scripts.

- **`skill-telemetry.ps1` crashed on every prompt on Windows.** The
  script used `$matches` as a local collection variable name. But
  `$matches` is an automatic PowerShell variable that every `-match`
  operator writes to as a hashtable, and the script performs regex
  matches on each SKILL.md frontmatter before the `+=` on line 111.
  The `+=` then raised "A hash table can only be added to another
  hash table" and the log write failed silently (the hook returns 0
  regardless). Renamed to `$matchedSkills` throughout. HIGH severity
  on Windows; this hook was effectively non-functional on every user
  prompt.

- **`install.ps1`, `verify.ps1`, `collect-diagnostics.ps1` hardcoded
  `powershell.exe`** for auto-run / smoke-test child invocations.
  Works on Windows; fails on macOS / Linux PS 7 where only `pwsh`
  exists. Replaced with `(Get-Process -Id $PID).Path` so the
  currently running PowerShell binary is reused, which works on PS
  5.1 Desktop, PS 7 Core, and all three OSes.

- **`verify.ps1` Layer 3 would FAIL with "powershell.exe not on
  PATH"** on any non-Windows host. Now reports the running
  PowerShell host path (`pwsh` on Linux/macOS, `powershell.exe` or
  `pwsh.exe` on Windows).

- **`verify.ps1` Temp fallback was Windows-only** (`C:\Windows\Temp`
  as default when `$env:TEMP` unset). Replaced with
  `[System.IO.Path]::GetTempPath()` which returns the OS-correct
  temp directory on Windows, macOS, and Linux.

- **`verify.ps1` bash-syntax check used backslash path literals**
  (`Join-Path $InstallRoot "hooks\$h.sh"`). PowerShell normalizes
  those on Windows; Linux PS 7 treats them as literal characters in
  the filename, so every bash-syntax check reported "unrecognized
  path format". Forward-slash literals work everywhere. The
  drive-letter-to-POSIX translation is now Windows-only; non-Windows
  hosts pass the POSIX path to bash directly.

- **`verify.ps1` Layer 4 hook-wrapper smoke tests** hard-depended on
  `cmd.exe` and `powershell.exe` (the wrapper's deliberate PS 5.1
  stdin workaround). Added an explicit Windows guard: on non-Windows
  the Layer 4 tests are skipped with a clear note rather than
  producing false failures. Layer 4 still runs in full on Windows.

- **`$env:USERPROFILE` assumed set** in `skill-telemetry.ps1`,
  `context-check.ps1`, and `pre-compact.ps1`. Always true on Windows;
  null on macOS / Linux PS 7. Added `$env:HOME` fallback. No Windows
  impact (the fallback is never taken when USERPROFILE is present).

- **Install summary and README hook-count text** said `14 hooks + 2
  wrappers`. True count after v11.3 added `gate-close-calibration`
  and `skill-telemetry` is `9 hooks + 1 wrapper` (bash + PowerShell
  pair), = 20 scripts. Updated both installers and verified against
  the README's corresponding phrasing.

### Known gaps

- **Windows PowerShell 5.1 path remains unexercised in v11.4.** The
  PS 7.4 audit exercised every `.ps1` file through the parser and
  ran the hooks directly, which catches nearly all real issues. But
  PS 5.1 has a few behavioral differences (`ConvertFrom-Json` edge
  cases, stricter automatic-variable handling, execution policy
  defaults) that a PS 7 run cannot fully simulate. If install fails
  on Windows PS 5.1 specifically, please file an issue with your
  `verify.ps1 -VerboseMode` output attached.
- **PS 5.1 stdin workaround in `hook-wrapper.ps1`** uses
  `cmd.exe /c powershell.exe < stdin > stdout 2> err`. That is
  intentional — PS 5.1's pipeline-to-stdin is unreliable — but it
  means the wrapper's child process always runs under
  `powershell.exe` (5.1) even if the caller is `pwsh.exe` (7+). All
  hooks are written to be PS 5.1 compatible (no ternary, no
  null-coalescing, no pipeline chains; confirmed by scan).

### Not addressed in this release (deferred)

- **lsp-safe-edit skill.** Still deferred.
- **Telemetry analyzer.** Still deferred until 30+ days of real data.
- **External replication.** Still sole-user testing.
- **Unified /start + /build-rules entry point.** Explicitly rejected;
  keeping them separate is the right call.

---

## v11.3 - April 23, 2026

Closes several operational loops left open in v11.2. No breaking changes.

### Added

- **`gate-close-calibration.sh` and `.ps1`** - writes ESTIMATION entries
  to MEMORY_CORRECTIONS.md at gate close. Reads estimated hours from
  VERSION_ROADMAP.md and actual hours from TIMELOG.md (priority 1) or
  git commit timestamps with a 2-hour gap filter (priority 2). This
  closes the open loop in v11.2's estimation calibration protocol:
  the reader existed, but nothing wrote data. Invoked from gate-close
  step 9 in build-rules.

- **`skill-telemetry.sh` and `.ps1`** - UserPromptSubmit hook that logs
  skill-invocation signals to `~/.claude/state/skill-log.jsonl`. Matches
  trigger phrases from each installed skill's SKILL.md frontmatter
  description against the user prompt. Logs both matches and non-matches
  so match rate is computable. Opt out by touching
  `~/.claude/state/telemetry-off`. No analyzer shipped; raw JSONL only.

- **`uninstall.sh` and `uninstall.ps1`** - removes Blueprint-owned files
  (skills, hooks, agents, settings.json, state directory) and restores
  `settings.json.bak` if present. Preserves foundation templates,
  personal overlay, per-project Blueprint files, and rollback snapshots.
  Flags: `--dry-run`, `--yes` / `-Force`, `--install-root`,
  `--blueprint-root`.

- **`TROUBLESHOOTING.md`** - three confirmed failure modes with fixes
  (PS7 operators on PS5.1, bash.exe as WSL launcher without WSL,
  execution policy blocked scripts) plus two predicted failure modes
  labeled as such. Grows as new issues surface.

- **`MIGRATION.md`** - documents the clobber-on-reinstall behavior,
  what is preserved vs destroyed, side-specific installs for Windows +
  WSL, and version-to-version notes.

### Changed

- **`install.sh` / `install.ps1` now clobber on re-install with a
  warning.** Previously a second install would copy files on top of
  existing ones, leaving stale skills and hooks from prior versions.
  Now the installer detects an existing install, lists what will be
  overwritten, and requires confirmation (or `--yes` / `-Force` to
  skip). The clobber removes entire `skills/`, `hooks/`, and `agents/`
  directories so stale v11.x files cannot linger.

- **`verify.sh` / `verify.ps1` now clean up their own artifacts.** The
  smoke tests use `CLAUDE_SESSION_ID=verify` to create deterministically
  named state files; cleanup logic now removes `turns-verify.count`
  from both the smoke root and the install root, the verify-session
  hook error log, and any `"session":"verify"` rows that may have
  landed in `skill-log.jsonl` during layer 4 probes.

- **Gate close protocol (build-rules step 8 / 9).** Step 8 now prunes
  rollback snapshots to the 10 most recent by mtime to prevent
  unbounded growth over many gates. Step 9 now invokes
  `gate-close-calibration` to append an ESTIMATION entry. Both
  additions are defensive: step 8 bounds disk usage, step 9 keeps the
  calibration data loop closed.

### Fixed (bugs found by dry-run simulation)

- **Gate-close step ordering.** In v11.3 pre-release, snapshot ran BEFORE
  calibration. The snapshot captured MEMORY_CORRECTIONS.md at its
  pre-calibration state, so a later rollback to that gate would silently
  wipe the gate's ESTIMATION entry. Reordered so calibration precedes
  snapshot. A dry-run simulation building a toy project from v0.0 to
  v0.1 and rolling back to v0.0 confirmed the fix preserves ESTIMATION
  data across rollback.

- **ESTIMATION entry placement.** The calibration hook previously
  appended to EOF of MEMORY_CORRECTIONS.md, which on the default template
  landed below the `## PRE-FILL ACCURACY LOG` section placeholder,
  fragmenting the file structure over many gates. The hook now inserts
  under `## REFLEXION LOG` (creating the header if absent) so entries
  stay in the correct section. Falls back to EOF append only if no
  section header exists.

### Not addressed in this release (deferred)

- **`lsp-safe-edit` skill.** Still deferred pending LSP-MCP ecosystem
  stability. Same rationale as v11.2.
- **Telemetry analyzer.** Intentionally cut. Shipping the logger first
  without an analyzer avoids baking assumptions about what the data
  should answer before data exists. After 30+ days of logged data, an
  analyzer will be written with actual usage patterns in view.
- **External replication.** Sole-user testing only, per user decision.
  The "sample size of one" limitation in RESEARCH_AGENDA.md still
  applies.

---

## v11.2 - April 23, 2026

Follow-up release to v11.1-public. Focused on credibility repair, research rigor,
and two small new capabilities. No breaking changes; re-run install.ps1 or
install.sh to pick up the updated skills and hooks.

### Changed (credibility repair)

- **RESEARCH_AGENDA.md RELATED WORK section rewritten.** Every citation was
  audited against its primary source (arxiv or equivalent). Three attribution
  errors fixed: the Jaroslawicz et al. paper title corrected to "How Many
  Instructions Can LLMs Follow at Once?" (arxiv 2507.11538, IFScale benchmark),
  the 83.8% Claude Code merge-rate figure re-attributed to Watanabe et al.
  arxiv 2509.14745 (previously conflated with arxiv 2601.13597 which is a
  separate longitudinal study by different authors), and the "60-70%
  compliance" claim re-sourced to GitHub issue anecdote rather than the
  HumanLayer blog post which does not contain that specific figure. Missing
  author names and arxiv IDs added to all entries. A new "sample size of one"
  limitation paragraph added at the end.

- **Hypothesis 2c (visual drift) operationalized.** Previously defined as
  "drift count per screen", now concretely defined as a Playwright
  `pixelmatch` comparison at fixed viewports (1280x720 desktop, 375x812
  mobile) with threshold 0.1 and a 0.5% total-pixel-mismatch ceiling for
  flagging DRIFT. Includes a specific log format and a falsification
  criterion ("non-Claude mean exceeds Claude mean by more than 1.0").

### Added (new capabilities)

- **`collect-diagnostics.sh` and `collect-diagnostics.ps1`.** Produces a
  single `bp-diagnostics-<timestamp>.txt` file bundling environment info
  (OS, shell/PowerShell version, execution policy, installed tooling),
  install state (which skills/hooks/agents are present, settings.json
  validity), recent hook error logs from the per-session tmp files, and
  full verify output. Intended for users to generate before reporting a
  bug so the person helping has everything needed in one file. Collects
  no file contents beyond settings.json, but does include paths (which
  may reveal the user's username) and the skill list; the script warns
  the user to skim before sending.

- **`rollback` skill.** Reverts a Blueprint project to the last closed gate,
  restoring both code (via `git reset --hard blueprint-gate-<version>`) and
  the foundation memory files (from `.blueprint/snapshots/<version>/`).
  Includes a dry-run preview step, explicit confirmation gate, automatic
  stash of uncommitted changes, and a ROLLBACK entry appended to
  MEMORY_EPISODIC.md so the rollback event itself is not lost. Documents
  limitations honestly: cannot recover remote-pushed commits that teammates
  have already pulled, cannot reach outside the repo (secrets, databases,
  infrastructure), and cannot work if the target gate was closed without
  the snapshot hook active. Total skills: 16 -> 17.

- **Gate-close snapshot protocol** added to build-rules/SKILL.md. At every
  gate close, the protocol now copies foundation files to
  `.blueprint/snapshots/<version>/` and creates a `blueprint-gate-<version>`
  git tag before pushing. Without these, `rollback` has no data to restore.

- **Estimation calibration protocol** added to build-rules/SKILL.md. Reads
  ESTIMATION entries from MEMORY_CORRECTIONS.md, computes a running median
  multiplier across the most recent 10 entries, applies it to raw gate
  estimates before writing VERSION_ROADMAP.md, and defaults to 2.0 for
  projects with fewer than 3 historical entries (grounded in general
  underestimation literature). Multiplier is recorded in the roadmap header
  so the assumption is visible.

### Changed (tech debt)

- **`context-check` hook now reads CONTEXT_BUDGET.md.** Previously the
  WARN_TURNS and HARD_TURNS thresholds were hardcoded at 80 and 120, with
  env-var overrides. Both `.sh` and `.ps1` versions now parse
  `WARN_TURNS: <n>` and `HARD_TURNS: <n>` lines from
  `$CLAUDE_PROJECT_DIR/CONTEXT_BUDGET.md` when present. Precedence is
  env var > CONTEXT_BUDGET.md > hardcoded default. CONTEXT_BUDGET.md has
  a new machine-readable threshold block at the end.

- **All .md files normalized to ASCII punctuation.** Removed 87 Unicode
  characters (em dashes, en dashes, smart quotes, right arrows, bullets,
  ellipses) across 10 files per Blueprint's style rule. All scripts were
  already ASCII-clean from v11.1-public; this sweep extended that rule
  consistently to the documentation.

### Not addressed in this release (deferred)

- `lsp-safe-edit` skill. After triage, this was deferred to v11.3 pending
  maturity of the LSP-MCP ecosystem. Shipping a skill that depends on a
  pre-1.0 MCP server and stops working silently when that server changes
  would be worse than not shipping it.
- `pattern-library` skill. Cut entirely; EXAMPLES.md already serves this
  purpose, and a separate pattern library would duplicate it with worse
  curation discipline.
- `cost-forecast` hook. Cut. Solves a theoretical problem rather than an
  observed one; the `costs` skill at gate close is sufficient for now.
- External replication data. Getting one independent user to install
  Blueprint on a real project and report what breaks is the highest-leverage
  non-engineering item, and it's in progress as a parallel track.

---

## v11.1-public - April 23, 2026

First public release on GitHub. Same engineering content as v11.1, plus:

### Added

- **`verify.sh` and `verify.ps1`** - four-layer post-install verification:
  (1) files present, (2) structural validity of JSON and YAML frontmatter,
  (3) execution readiness (permissions, `bash`/`jq`/`git`/`powershell.exe`
  on PATH, temp dir writable), (4) functional smoke tests that actually
  pipe fake hook inputs through `hook-wrapper` and confirm SessionStart
  emits the correct `hookSpecificOutput` wrapper, `rm -rf /` exits 2,
  `git push --force origin main` exits 2, safe commands pass with exit 0,
  and missing hooks with `BLUEPRINT_DEBUG=1` surface a diagnostic. Both
  installers auto-run verification at the end; exit code 2 on install-ok
  but verify-fail. Both scripts can be re-run standalone at any time to
  diagnose a broken install.
- **`install.sh`** - macOS and Linux bash installer, mirroring the Windows
  PowerShell installer feature-for-feature (personal-config substitution,
  drift detection, verification pass).
- **`build-skills-bundle.sh` and `.ps1`** - package each of the 17 skills
  as an individual zip for upload to claude.ai via Settings -> Features ->
  Skills. Outputs to `dist/claude-ai-bundle/` along with `CLAUDEAI-README.md`
  detailing what does and does not transfer to the claude.ai surface.
- **`.gitignore`** - prevents accidental commits of `owner-config.md`
  (personal info), build output under `dist/`, hook logs, and editor artifacts.
- Top-level README rewritten to route users to the appropriate install path
  (Option A: desktop Claude Code, Option B: claude.ai skills bundle,
  Option C: zero-install Remote Control from phone).

### Changed

- Installers now support **both clone mode and zip mode**. Running from a
  GitHub clone requires no zip; running against a packaged `blueprint-v11.zip`
  still works. The installer detects mode automatically.
- `install.ps1` default `BlueprintRoot` is now `$env:USERPROFILE\Blueprint-v11`
  (was a hardcoded `D:\Blueprint-v11` specific to the original author).
- `install-blueprint-v11.ps1` renamed to `install.ps1` for clarity and
  filename symmetry with `install.sh`.
- `personal-overlay/owner-config.md` removed (contained the original author's
  name, email, rate, and academic details); replaced with
  `owner-config.template.md` containing sanitized dummy values and clear
  copy-this-first instructions in `personal-overlay/README.md`.

### Removed

- `audit/` directory (private audit reports with identifying information)
  is not included in the public release.

---

## v11.1 - April 23, 2026

This release addresses all findings from a two-pass independent audit that
evaluated v11.0 against 10 primary sources (Anthropic docs, LangGraph, Supabase,
community research) and found four critical issues plus a set of secondary
improvements. Audit reports are kept in the original author's private working
copy and are not included in the public release.

### Fixed - critical

- **C1: SessionStart hook JSON format.** Both `session-start.sh` and
  `session-start.ps1` now emit the correct
  `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}`
  wrapper format per Claude Code's current hooks spec. Previously the
  `hookSpecificOutput` wrapper was missing and the injected Blueprint-mode
  context was silently dropped. End-to-end verified: SessionStart now
  correctly injects Blueprint project identity and hard rules every session.

- **C2: LangGraph `AsyncPostgresSaver` pattern in EXAMPLES.md.** The module-
  level `checkpointer = AsyncPostgresSaver.from_conn_string(...)` assignment
  has been replaced with the correct `async with` pattern. The FastAPI
  lifespan integration example now correctly holds the context manager open
  across the app's lifetime, preventing the "connection is closed" failure
  mode. The previous `create_oracle()` function that returned a graph from
  outside its `async with` block has been removed.

- **C3: `{{VARIABLE}}` substitution.** `install-blueprint-v11.ps1` now
  accepts a `-PersonalConfig` parameter and performs regex-safe substitution
  of all `{{KEY}}` placeholders from `owner-config.md` into the installed
  foundation files and skills. Unreplaced placeholders are counted and
  surfaced as warnings. Previously the install script's claim to perform
  this substitution was unimplemented.

- **C4: Hook fallback silent-failure chain.** The six near-duplicate
  fallback command strings in `settings.json` have been replaced with
  invocations of two new wrapper scripts: `hook-wrapper.sh` and
  `hook-wrapper.ps1`. These wrappers:
  - Preserve `exit 2` (blocking) signals from the first successful hook
    execution instead of swallowing them.
  - Capture hook stderr to a per-session log file at
    `$TMPDIR/bp-hook-err-$CLAUDE_SESSION_ID.log` (platform-aware path).
  - Surface captured errors to Claude's stderr when hooks block or when
    `BLUEPRINT_DEBUG=1` is set.
  - Report clearly when a hook is missing on all fallback paths.

### Fixed - documentation and correctness

- `EXAMPLES.md` now uses `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` instead of
  the dated `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
- `EXAMPLES.md` `createServerClient(...)` now has a complete `cookies`
  block with `getAll`/`setAll` handlers matching current Supabase SSR docs.
  Previously the cookies block was elided with `...`.
- `README.md` competitive table: "Mechanical hook enforcement" row was
  renamed to "Layered enforcement (mechanical hooks + advisory CLAUDE.md)"
  with a footnote explicitly identifying which hooks mechanically block,
  which inject context, and citing the HumanLayer community-consensus
  ~60-70% CLAUDE.md compliance figure.
- `claude-skills/health/SKILL.md`: foundation file audit now accurately
  accounts for all 23 foundation files, grouped by load cadence (ALWAYS
  LOAD, MEMORY NETWORK, ON DEMAND, REFERENCE, RESEARCH+TEAM).

### Research agenda - academic-readiness improvements

- Added `RELATED WORK` section to `RESEARCH_AGENDA.md` with citations to:
  - Rosa et al. (2026) CURRANTE / SANER 2026 (arxiv 2601.03878)
  - Jaroslawicz et al. (2025) - instruction-following limits
  - AgentIF benchmark (2025)
  - Packer et al. (2023) MemGPT (arxiv 2310.08560)
  - "AI-Generated Code Is Not Reproducible (Yet)" (arxiv 2512.22387)
  - Watanabe et al. (2025) / "AI IDEs or Autonomous Agents?" (arxiv 2601.13597)
  - "AI Agentic Programming Survey" (arxiv 2508.11126)
  - Thoughtworks (2025) on spec-driven development
- Rewrote Research Question 2's single unfalsifiable composite hypothesis
  ("within 15% quality") as three separately falsifiable hypotheses
  (H2a test pass rate, H2b security findings, H2c visual drift), each
  with explicit measurement protocols and falsification thresholds.
- Added power-analysis note acknowledging the 15-data-point sample size
  is underpowered for statistical hypothesis testing and should be framed
  as an exploratory case study.

### Improved - packaging

- `install-blueprint-v11.ps1` verification step now checks for hook
  wrappers (`hook-wrapper.sh` and `.ps1`) in addition to the 14 hooks.
- Installation verification now detects drift between `.claude/skills/`
  and `claude-skills/` using file hash comparison. Warns if skill files
  differ between the two shipped locations (packaging integrity check).
- Installation summary now accurately reports "14 hooks + 2 wrappers"
  under the hooks directory.

### Known issues / deferred work

- Research Question 1's pre-fill accuracy study requires 26+ gate events
  across 2+ projects for baseline measurement. The data-collection vehicle
  is every real project built on Blueprint - early adopters can contribute
  anonymized pre-fill logs back via GitHub issues.
- No `SessionEnd` hook yet (introduced in Claude Code 1.0.85 per issue
  #6306). Could replace the current `Stop` + `writethru-episodic.sh`
  pattern for cleaner semantics. Deferred to v11.2.
- `hook-wrapper.sh` assumes `/tmp` or `$TMPDIR` is writable. This is true
  on Git Bash, WSL, MSYS2, and native Unix. Minimal busybox-on-Windows
  configurations may need a `BLUEPRINT_TMP` override. Deferred - no user
  reports of this failure mode yet.

## v11.0 - April 10, 2026

Initial stress-tested release. Private audit reports informed the subsequent
v11.1 fixes; those reports are held in the original author's working copy
and not included in the public release.
