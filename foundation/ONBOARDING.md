# ONBOARDING.md
# Syntaris v0.6.0 | First-Time User Guide
# For: researchers, collaborators, or anyone new to Syntaris

---

## WHAT IS SYNTARIS?

Syntaris is an AI app building methodology for Claude Code.
It is not a library. It is not a plugin. It is a set of files that tell
Claude Code how to behave when building software.

It solves one problem: AI coding tools are fast but inconsistent.
They forget decisions between sessions, skip tests, ignore architectural rules,
and produce work that regresses without warning.

Syntaris fixes this with:
- Memory that persists across sessions and projects
- Gate-by-gate structure that prevents regressions
- Enforced quality checks (tests, security, visual verification)
- Mechanical hooks that block bad behavior at the shell level

The result: consistent, production-quality software with near-zero manual friction.

---

## PREREQUISITES

Before installing Syntaris:

- [ ] Claude Code subscription (Pro or Max plan at claude.ai)
- [ ] GitHub account
- [ ] Node.js 20+ and pnpm installed
- [ ] Python 3.11+ installed
- [ ] Git installed and configured
- [ ] PowerShell 7+ (Windows) or bash (Mac/Linux)

For the default stack you will also need accounts at:
- Supabase (supabase.com) - free tier sufficient for development
- Vercel (vercel.com) - free Hobby tier sufficient
- Render (render.com) - free tier sufficient
- Anthropic (console.anthropic.com) - API key for AI features

---

## INSTALLATION (5 minutes)

### Option A: PowerShell (Windows)

```powershell
# Download and run installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/.../install-syntaris.ps1" -OutFile "install-syntaris.ps1"
powershell.exe -ExecutionPolicy Bypass -File "install-syntaris.ps1"
```

### Option B: Manual

1. Clone the repo or download `syntaris-v0.3.0.zip`
2. Extract to a temporary folder
3. Run `bash install.sh` (Mac/Linux) or `./install.ps1` (Windows)
4. The installer copies `.claude/skills/`, `.claude/hooks/`, and `.claude/agents/` to `~/.claude/`, and copies the foundation templates to `~/Syntaris/foundation/`

Verify installation:
```bash
ls ~/.claude/skills/
# Should show 16 directories: start, build-rules, global-rules, critical-thinker, etc.

ls ~/.claude/hooks/
# Should show 20 files: hook-wrapper.sh, hook-wrapper.ps1, strip-coauthor.sh, ...

bash ~/.claude/skills/../verify.sh   # or run verify.sh from the repo root
```

---

## YOUR FIRST PROJECT (30-45 minutes)

### Step 1: Open Claude Code

```bash
claude
```

### Step 2: Start a new project

```
/start --new
```

Claude Code will read the memory files (empty at first), then ask you to describe your app.

### Step 3: Answer the interrogation questions

Syntaris asks 3-20 questions depending on what it already knows.
For your first project: expect about 15-20 questions covering your app idea,
tech stack, users, monetization, and AI requirements.

Answer honestly. Vague answers produce vague specs.

### Step 4: Review and approve the roadmap

Claude Code generates a VERSION_ROADMAP.md showing every build gate
from v0.0.0 through v1.0.0 with time estimates.

Review it. If something looks wrong: say so now.
Type: BUILD APPROVED

### Step 5: Review and approve the mockups

Claude Code generates MOCKUPS.md with text component trees for every screen.
This is your last chance to change what gets built before code is written.

Type: MOCKUPS APPROVED

### Step 6: Review and approve the frontend spec

Claude Code generates FRONTEND_SPEC.md with full component specifications.
Review the key screens. Verify the design system colors and fonts are correct.

Type: FRONTEND APPROVED

### Step 7: Build

Type: GO

Claude Code begins building. You review gate close checklists and type GO at each gate.
Everything else is autonomous.

---

## THE APPROVAL WORDS

Syntaris uses five specific words as approval gates:

| Word | Meaning |
|------|---------|
| BUILD APPROVED | App description, build type, and full roadmap through final version approved |
| MOCKUPS APPROVED | Screen mockups approved |
| FRONTEND APPROVED | Component specs and design system approved |
| GO | Build this gate |

These exact words trigger gate advancement. Nothing else does.
If you type "ok" or "looks good" - Claude Code waits for the real approval word.

---

## COMMON FIRST-SESSION MISTAKES

**Mistake: Skipping approval words**
Claude Code asks "Does this look right?" and you say "yes, go ahead."
Claude Code waits. It needs the exact word: GO.

**Mistake: Interrupting mid-gate**
If Claude Code is building and you start asking questions, it loses context.
Wait for the gate close checklist before asking questions.

**Mistake: Not installing the Co-Authored-By hook**
Every commit from Claude Code adds a "Co-Authored-By: Anthropic" trailer.
This blocks Vercel deployments on the free Hobby plan.
The hook fixes this automatically - but it needs to be installed first.
Run: bash ~/.claude/hooks/strip-coauthor.sh in your project directory.

**Mistake: Using /compact instead of /clear**
/compact summarizes the context (lossy - loses 70% of details).
/clear wipes the context (lossless - save to PLANS.md first).
Always use /clear for context resets.

**Mistake: Ignoring the 40% context warning**
When context-check warns you, save state immediately.
Don't try to finish the task first. The quality drop is real and immediate.

---

## READING THE MEMORY FILES

After your first project, Syntaris has learned from your build.
Check what it learned:

```bash
cat MEMORY_CORRECTIONS.md
# Shows REFLEXION entries: what was estimated vs actual hours

cat MEMORY_SEMANTIC.md
# Shows patterns: what Syntaris knows about your stack and preferences

cat MEMORY_EPISODIC.md
# Shows the session log: what was built, when, what gate outcomes were
```

By project 3-4, Syntaris pre-fills most interrogation questions automatically.
The methodology gets faster with each project.

---

## GETTING HELP

ERRORS.md - check this first for any error you encounter
WHY.md - explains the reasoning behind every major decision
EXAMPLES.md - real code patterns for the default stack
DEPLOYMENT_CONFIG.md - external service configuration checklists

For issues not covered by the foundation files:
The Claude Code community at github.com/anthropics/claude-code/issues
is the best resource for Claude Code-specific behavior.
