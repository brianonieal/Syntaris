# Blueprint v11 Troubleshooting

This document contains specific failure modes and their fixes.

Each entry is labeled:

- **OBSERVED** - this failure has actually been seen on a real install
- **PREDICTED** - this failure has not been seen yet but is anticipated
  based on the code path. Treat predicted entries as hypotheses, not
  confirmed issues.

If you hit something not in this list, please file a GitHub issue and
include the output of `collect-diagnostics.sh` or `collect-diagnostics.ps1`.
The list grows as issues surface.

---

## OBSERVED: PowerShell 7-only operators failing on PowerShell 5.1

**Symptom.** When running `install.ps1` or any `.ps1` hook on Windows, you
see a parse error like:

```
Unexpected token '??' in expression or statement.
Missing closing '}' in statement block or type definition.
```

The line number in the error may point somewhere far from the actual
problem because PowerShell's parser gives up at the first unknown token
and reports the next structural mismatch.

**Cause.** Windows 10 and Windows 11 ship with Windows PowerShell 5.1 by
default. Blueprint hooks target PS 5.1 for maximum compatibility. Any
PowerShell 7-only operator in a hook causes the entire script to fail to
parse. The common culprits are:

- `??` (null-coalescing)
- `?.` (null-conditional member access)
- `?[` (null-conditional index)
- `&&` and `||` as pipeline chain operators

**Fix.** Find the offending file with `verify.ps1` (its PowerShell syntax
check runs during layer 2). Then rewrite the PS7 construct as an explicit
`if`/`else`. Example:

```powershell
# PS7 (fails on PS5.1):
$base = $env:CLAUDE_PROJECT_DIR ?? (Get-Location).Path

# PS5.1-compatible:
if ($env:CLAUDE_PROJECT_DIR) {
    $base = $env:CLAUDE_PROJECT_DIR
} else {
    $base = (Get-Location).Path
}
```

**Prevention.** verify.ps1's layer 2 (structural validity) runs the full
PowerShell AST parser on every `.ps1` hook. A stray PS7 operator will
surface there, not at runtime.

---

## OBSERVED: `bash.exe` is the WSL launcher without WSL installed

**Symptom.** On Windows, `verify.sh` (or verify.ps1's layer 2 bash-syntax
sub-check) reports every `.sh` hook as a syntax error. The message is
generic; it does not mention WSL.

**Cause.** Windows 10 and 11 ship a `bash.exe` stub at `C:\Windows\System32\bash.exe`
even when WSL is not installed. The stub's only job is to launch the WSL
distribution. If WSL is not installed, `bash.exe` errors out with a
non-zero exit, and any tool that expected "bash exists, therefore bash
can run .sh files" treats this as a script-level failure.

**Fix (quickest).** Use the PowerShell versions of the hooks. Blueprint
ships `.sh` and `.ps1` for every hook; on native Windows you only need
the `.ps1` versions, and Claude Code invokes the right ones based on
platform.

**Fix (enable WSL properly).** If you want bash support too:

```powershell
wsl --install
```

Restart, then re-run `verify.ps1`. The bash-syntax sub-check will now
probe `bash -c "echo ok"` before trusting `bash -n`, and will work
correctly against Windows paths translated to `/c/Users/...` or
`/mnt/c/Users/...`.

**Prevention.** v11.2's verify.ps1 added a bash probe that differentiates
"bash is on PATH" from "bash can actually execute a trivial command."
You should not see this as a FAIL anymore; it downgrades to a WARN with
a "bash couldn't read the file" message.

---

## OBSERVED: PowerShell scripts blocked by execution policy

**Symptom.** When running `install.ps1` or any other `.ps1` script from
Blueprint:

```
File C:\...\install.ps1 cannot be loaded because running scripts is
disabled on this system. For more information, see about_Execution_Policies
at https:/go.microsoft.com/fwlink/?LinkID=135170.
```

**Cause.** Windows's default execution policy for PowerShell 5.1 is
`Restricted`, which blocks all scripts. This is the most common first-run
problem on a fresh Windows install.

**Fix (one-time, this command only).** Prefix invocations with `-ExecutionPolicy Bypass`:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\install.ps1
```

This applies only to the single PowerShell invocation; it does not change
your system policy.

**Fix (permanent, current user only).**

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

`RemoteSigned` allows local scripts to run and requires signatures only
on scripts downloaded from the internet. Scoping to `CurrentUser` means
this does not require admin and only affects your account.

**Fix (not recommended, machine-wide).** `Set-ExecutionPolicy -Scope LocalMachine Unrestricted`.
Avoid this unless you fully understand the security implications.

**Prevention.** The README documents the `-ExecutionPolicy Bypass` pattern
in the install instructions.

---

## PREDICTED: Install completes but skills do not load in Claude Code

**Symptom.** `verify.sh` or `verify.ps1` reports all 84 checks passed.
But when you open Claude Code and type a prompt that should trigger a
skill (e.g. "/start"), nothing skill-specific happens.

**Cause (hypothetical).** Claude Code caches the skill index. After a
clobber-reinstall, the cache may reference paths or skills that no
longer exist.

**Fix.** Close every Claude Code session and reopen it. The session
pulls a fresh skill index on startup. If the problem persists, check
that `~/.claude/settings.json` is well-formed JSON and that the hooks
it references exist.

This entry is predicted because I have not observed it in this repo.
If you hit it, please open an issue with the output of
`collect-diagnostics` so it can be promoted to OBSERVED.

---

## PREDICTED: Clobber-reinstall removes a skill that had local edits

**Symptom.** You customized a skill (for example, edited
`~/.claude/skills/start/SKILL.md` to add a personal preference). You then
re-ran `install.sh` and accepted the clobber prompt. Your customization
is gone.

**Cause.** Blueprint's install flow is clobber-by-design. Any user-edited
file in `~/.claude/skills/`, `~/.claude/hooks/`, or `~/.claude/agents/`
is overwritten without warning on a re-install.

**Fix.** Before re-running `install.sh` or `install.ps1`, diff your
customized files against the new version and re-apply your edits. If
you have many customizations, track them in `personal-overlay/` where
they are preserved across re-installs, and use the `--personal-config`
flag to apply them.

**Prevention.** This is documented in `MIGRATION.md`. The install flow
prints a pre-clobber warning listing exactly what will be overwritten.

---

## PREDICTED: Skill telemetry over-counts common English words

**Symptom.** Analyzing `~/.claude/state/skill-log.jsonl` shows higher
invocation counts for skills like `debug`, `deployment`, `start`, and
`critical-thinker` than you'd expect from actual usage.

**Cause.** The telemetry hook uses a curated natural-language keyword
map per skill to improve match rate on conversational prompts. Some
of those keywords are common English words that appear outside any
Blueprint-related context. A dry-run test showed 5 false positives
out of 6 adversarial prompts:

- `"my kid has a test at school"` - correctly nomatches (narrow keyword)
- `"debug my thinking"` - falsely triggers `debug` (word appears)
- `"when did napoleon deploy his cavalry"` - falsely triggers `deployment`
- `"baroque architecture"` - falsely triggers `critical-thinker`
- `"when should I start my diet"` - falsely triggers `start`
- `"new work assignment from my boss"` - falsely triggers `coursework`

**Fix (for you, when analyzing data).** Treat telemetry counts for
these skills as an upper bound. The signal is still useful for
identifying dead skills (any skill that has zero invocations over 30
days is genuinely unused), but usage rankings should be calibrated
for the ambiguity. Skills with highly distinctive keywords (`rollback`,
`testing`, `freelance-billing`, `handoff`) have near-zero false
positive rates.

**Fix (for v11.5, if this becomes a real problem).** Tighten keyword
patterns with phrase-context windows (e.g., `debug` requires nearby
words like `error`, `code`, `failing`). Not prioritized for v11.4
because the current data is good enough for dead-skill identification,
which is the primary use case.

This entry is predicted because the false-positive rate was measured
in simulation, not observed in real usage. Real-world prompt
distributions may produce different rates.

---

## How to report something not in this list

1. Run `collect-diagnostics.sh` or `collect-diagnostics.ps1` in the
   directory where you installed Blueprint.
2. Review the resulting `bp-diagnostics-<timestamp>.txt` file. Remove
   anything you do not want to share publicly (typically: path segments
   that reveal your username).
3. Open a GitHub issue and paste the diagnostics file as the issue body.
4. Include a one-line description of what you were trying to do and
   what happened instead.

A good issue has three elements: what you ran, what happened, what you
expected. The diagnostics file covers the "what happened" half
automatically.
