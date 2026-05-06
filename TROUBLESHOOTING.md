# Syntaris Troubleshooting

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
default. Syntaris hooks target PS 5.1 for maximum compatibility. Any
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

**Fix (quickest).** Use the PowerShell versions of the hooks. Syntaris
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

**Prevention.** verify.ps1 added a bash probe that differentiates
"bash is on PATH" from "bash can actually execute a trivial command."
You should not see this as a FAIL anymore; it downgrades to a WARN with
a "bash couldn't read the file" message.

---

## OBSERVED: `.sh` hooks fail bash syntax check with "unexpected end of file"

**Symptom.** On Windows with WSL installed and working, `verify.ps1`'s
layer 2 reports every `.sh` hook as a syntax error. Running with
`-VerboseMode` shows `unexpected end of file` in the error output.
This is different from the "bash couldn't read the file" warning (which
means bash can't find or open the file at all).

**Cause.** `git clone` on Windows with `core.autocrlf=true` (the default)
converts LF line endings to CRLF. Bash cannot parse scripts that have
`\r` at the end of every line. The `\r` is treated as part of the last
command on each line, causing cascading parse failures that surface as
"unexpected end of file."

**Fix.** The v0.3.0 repo now includes a `.gitattributes` file that forces
`*.sh` files to LF on checkout. If you cloned before this fix:

```bash
git rm --cached -r .
git reset HEAD -- .
git checkout -- .
```

Then re-run `install.ps1` (which now converts `.sh` files to LF during
install) and `verify.ps1` (which now creates a LF temp copy before
running `bash -n` on Windows).

**Prevention.** `.gitattributes` forces `*.sh` to `eol=lf`. `install.ps1`
strips `\r` from `.sh` files during copy. `verify.ps1` detects CRLF in
`.sh` files and tests a LF temp copy instead.

---

## OBSERVED: PowerShell scripts blocked by execution policy

**Symptom.** When running `install.ps1` or any other `.ps1` script from
Syntaris:

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

**Cause.** Syntaris' install flow is clobber-by-design. Any user-edited
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
Syntaris-related context. A dry-run test showed 4 false positives
out of 5 adversarial prompts:

- `"my kid has a test at school"` - correctly nomatches (narrow keyword)
- `"debug my thinking"` - falsely triggers `debug` (word appears)
- `"when did napoleon deploy his cavalry"` - falsely triggers `deployment`
- `"baroque architecture"` - falsely triggers `critical-thinker`
- `"when should I start my diet"` - falsely triggers `start`

**Fix (for you, when analyzing data).** Treat telemetry counts for
these skills as an upper bound. The signal is still useful for
identifying dead skills (any skill that has zero invocations over 30
days is genuinely unused), but usage rankings should be calibrated
for the ambiguity. Skills with highly distinctive keywords (`rollback`,
`testing`, `billing`) have near-zero false
positive rates.

**Fix (for a future release if this becomes a real problem).** Tighten keyword
patterns with phrase-context windows (e.g., `debug` requires nearby
words like `error`, `code`, `failing`). Not prioritized for v0.3.0
because the current data is good enough for dead-skill identification,
which is the primary use case.

This entry is predicted because the false-positive rate was measured
in simulation, not observed in real usage. Real-world prompt
distributions may produce different rates.

---

## Plugin install path issues (v0.3.0+)

### Plugin install fails with "manifest not found"

If `/plugin install syn@brianonieal` reports it cannot find the manifest:

1. Confirm the repo's default branch contains `.claude-plugin/plugin.json` at the repo root, not nested deeper.
2. Run `claude --plugin-dir /path/to/local/Syntaris` to test the manifest locally first. This bypasses the marketplace lookup and reads the manifest from disk.
3. Validate the JSON: `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"`. The most common failure is a trailing comma or unescaped quote in the description field.

### Plugin commands not appearing in autocomplete

After install, slash commands from the plugin should appear in the `/` menu under the namespace prefix. If they don't:

1. Run `/reload-plugins` to force Claude Code to re-read the plugin without restarting.
2. Check the init message when Claude Code starts. It lists loaded plugins and their detected slash commands. If your plugin appears but with zero commands, the skill directory was not detected. Verify `.claude-plugin/plugin.json` has the `"skills": "./.claude/skills"` custom path set.
3. Plugin commands use the namespaced format `<plugin-name>:<skill-name>`. Type the full name (e.g., `/syn:start`) at least once before autocomplete recognizes it.

### Both install paths active, behavior differs

If you have both `bash install.sh` and `/plugin install` active, you'll have access to both `/start` (from install.sh) and `/syn:start` (from plugin). They run the same skill content. If you observe behavior differences:

1. Edit one and not the other. The plugin reads `.claude/skills/` from the plugin's install location (cached at `~/.claude/plugins/cache/`); install.sh reads from `~/.claude/skills/`. Local edits to either source don't propagate to the other.
2. The plugin form's hooks (declared in `hooks.json`) and the install.sh form's hooks (declared in `settings.json`) are independent. If you customized one, the other won't see the change.

If the behavior difference is unexpected, compare the actual hook config (`cat ~/.claude/settings.json`) against the plugin's `hooks.json` (in the plugin cache).

---

## Subagent issues (v0.3.0+)

### Subagent invocation hangs or times out

If `/research`, `/debug`, `/health`, or `/critical-thinker` hangs after starting:

1. The subagent may be waiting for a tool that's not in its allowed-tools list. The subagents have explicit `tools:` frontmatter (Read, Grep, Glob, plus WebFetch/WebSearch for `research-agent`). If your project requires a tool not on this list, the subagent will silently fail to call it.
2. Check `~/.claude/state/skill-log.jsonl` for the most recent skill invocation. The telemetry hook logs subagent dispatches. If the skill fired but the subagent never returned, the agent system itself is the failure point, not the parent skill.

### Subagent returns empty or malformed structured output

The subagents are instructed to return output in specific formats (`TARGET:`, `DIAGNOSIS:`, `STRONGEST_OBJECTIONS:`, etc.). If a subagent returns prose instead:

1. The Sonnet model occasionally drifts from rigid output formats. The parent skill is written to handle this: it should re-invoke the subagent with an explicit reminder of the format. If you see the parent fail without retrying, that's a parent-skill bug; please open an issue.
2. If the subagent returns `STATUS: NEEDS_NARROWING`, that's not a malfunction. The subagent is asking the parent to clarify the request. The parent skill should ask you the narrowing questions.

### Subagent did write to memory files

The architectural rule is: subagents return structured output, parent skills write to memory files. If you observe a subagent directly writing to `RESEARCH.md`, `ERRORS.md`, `MEMORY_*`, or `DECISIONS.md`:

1. That's a regression. Subagents in v0.3.0 are read-only with respect to memory files. The parent skill is responsible for the write.
2. Open an issue with the diagnostic bundle. Include the subagent name and the file that was written. This is the kind of bug that erodes the calibration loop's coherence and needs to be fixed quickly.

---

## How to report something not in this list

1. Run `collect-diagnostics.sh` or `collect-diagnostics.ps1` in the
   directory where you installed Syntaris.
2. Review the resulting `bp-diagnostics-<timestamp>.txt` file. Remove
   anything you do not want to share publicly (typically: path segments
   that reveal your username).
3. Open a GitHub issue and paste the diagnostics file as the issue body.
4. Include a one-line description of what you were trying to do and
   what happened instead.

A good issue has three elements: what you ran, what happened, what you
expected. The diagnostics file covers the "what happened" half
automatically.
