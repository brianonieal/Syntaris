# Syntaris

Syntaris is a setup that helps Claude Code build software in clean, ordered steps. It breaks projects into phases, blocks the work from advancing until each phase is finished and approved, keeps notes between sessions so it learns from past mistakes, and includes ready-made templates for common tech stacks.

---

## What this builds on

Syntaris combines existing patterns from the Claude Code ecosystem and the agent literature:

- Reflexion (Shinn et al., NeurIPS 2023) for the verbal-reflection-into-episodic-memory pattern in `MEMORY_CORRECTIONS.md`.
- Anthropic's documented `PreToolUse` exit-code-2 hook behavior for gate enforcement.
- GitHub Spec-Kit for spec-as-source-of-truth in `SPEC.md` and `SPEC_GATES.md`.
- GSD, Superpowers, BMAD, and Anthropic's built-in auto-memory for skills, subagents, and cross-session memory patterns.

---

## How it works

### Gate model

```
CONFIRMED  →  ROADMAP APPROVED  →  MOCKUPS APPROVED  →  FRONTEND APPROVED  →  GO
    ↓               ↓                      ↓                    ↓               ↓
 CONTRACT.md   VERSION_ROADMAP.md    FRONTEND_SPEC.md      Working UI       Ship
 SPEC.md       COSTS.md              DESIGN_SYSTEM.md      Screenshots      Tests pass
 DECISIONS.md  DEPLOYMENT locked     Components locked     Tests > 0        Deploy
```

Each arrow is a `PreToolUse` shell hook that exits 2 if the previous gate's exit artifacts are missing or if the human approval token has not been entered. Each transition writes a reflexion entry.

### Memory

- `MEMORY_SEMANTIC.md`: validated patterns across projects.
- `MEMORY_EPISODIC.md`: session events and gate outcomes.
- `MEMORY_CORRECTIONS.md`: predicted-vs-actual reflexion entries.

### Recipes

| Recipe | Stack |
| --- | --- |
| `nextjs-fastapi-supabase` | Next.js 14+, FastAPI, Supabase, LangGraph |
| `python-cli` | Python CLI tools |
| `bring-your-own` | Empty template |

---

## Quick start

```bash
git clone https://github.com/[your-username]/syntaris.git
cd syntaris

bash install.sh           # macOS, Linux
./install.ps1             # Windows
bash syntaris-doctor.sh

# In a project directory with Claude Code:
/start
```

---

## Skills

12 slash-command skills covering session orchestration, build rules, critical thinking, research, costs, testing, security, performance, deployment, debug, health, and strategy. Three subagents: `spec-reviewer`, `test-writer`, `security-auditor`. See `.claude/skills/` for details.

Two extension packs in separate repos: `syntaris-freelance` and `syntaris-academic`.

---

## Project structure

```
syntaris/
  .claude/
    skills/                 12 skills
    hooks/                  14 shell hooks
    agents/                 3 subagents
    settings.json
  core/                     Stack-neutral foundation files
  recipes/                  Stack-specific configs
  extensions/               Optional skill packs
  syntaris-bench/           Task-suite skeleton
  docs/
```

---

## License

MIT. See [LICENSE](LICENSE).
