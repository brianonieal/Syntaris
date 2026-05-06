# WHY.md
# Syntaris v0.3.0 | The Reasoning Behind Every Major Decision
# Read this before questioning the methodology
# Stack-specific: Next.js + FastAPI + Supabase + LangGraph + Plaid
#
# STACK-SPECIFIC FILE
# Some sections below justify decisions that are specific to the v0.3.0 reference stack
# (Voyage AI embeddings for finance, Plaid as the data integration, asyncpg
# connection strategy). The methodological reasoning - why gates, why memory,
# why Reflexion, why /clear over /compact - is universal. The stack-specific
# justifications are not. If you adapt Syntaris to a different stack, replace
# the stack-specific WHY entries with your own.

---

## WHY SYNTARIS EXISTS

In early 2025, a complex desktop app called Forge Genesis was built using an early
version of this methodology. Over 30 iterations, the same failures kept recurring:
storage key drift, invented API model IDs, disappearing required headers.

Each rebuild started fresh. Each rebuild re-made the same mistakes.
The root cause: no memory, no spec, no gate structure. Just prompting.

Syntaris was built to solve this. Not to make Claude Code faster - to make it
accurate across multiple sessions and multiple projects.

---

## WHY GATE STRUCTURE (sequential, no skipping)

The temptation is to skip gates. "v0.5.0 is complex, let me just start."
But every gate skipped creates debt that compounds.

Evidence from real builds:
- Projects without gate structure have 3x more regressions
- Projects with gates show nearly zero regressions between versions
- Claude Code that jumps ahead (as it did to v5.0.0 in one session) produces
  work that contradicts earlier decisions and requires throwaway rebuilds

The gate structure is not bureaucracy. It is the anti-regression protocol.

---

## WHY SPEC BEFORE CODE (SCOPE CONFIRMED -> FRONTEND APPROVED before GO)

In AI-assisted development, implementation time approaches zero.
The bottleneck is decision quality, not coding speed.

A wrong decision made at v0.0.0 costs 1 hour to fix.
The same wrong decision made at v1.0.0 costs 10 hours.
The same decision made at v3.0.0 costs 50 hours and may require a rebuild.

FRONTEND_SPEC.md forces every screen to be designed before it's built.
MOCKUPS.md forces every component to be approved before it's coded.
DECISIONS.md records every architectural choice before it propagates.

The spec phase feels slow. The implementation phase feels fast.
This is by design. Specification is the work. Implementation is execution.

---

## WHY FASTAPI AND NOT NEXT.JS API ROUTES

Next.js API routes would eliminate the backend deployment entirely.
Simpler architecture, one deployment, one repository.

But: AI agent workflows (LangGraph, SSE streaming, long-running tasks)
do not work reliably in serverless Next.js functions.

Serverless functions have execution time limits (typically 10-60 seconds).
LangGraph agent pipelines routinely exceed these limits.
SSE streaming requires persistent connections - serverless can't do this.

FastAPI with Uvicorn on Render gives:
- Unlimited execution time
- Persistent connections for SSE streaming
- Async support throughout
- Full Python ecosystem (LangGraph, SQLAlchemy, Alembic, pytest)

The cost: one more deployment. The benefit: agents actually work.

---

## WHY SUPABASE AND NOT PLAIN POSTGRES

Supabase is Postgres with:
- Authentication (Google OAuth, magic link) - eliminates 3+ days of auth work
- Row Level Security - user data isolation is handled at database level
- pgvector extension - semantic search without a separate vector database
- Real-time subscriptions - if needed for live updates
- Dashboard for direct DB access during development

The alternative (plain Postgres on Render) requires building auth from scratch,
implementing data isolation in application code (error-prone), and adding a
separate vector database for embeddings.

Supabase free tier handles most MVP-scale projects.
The database is still Postgres - migrations, SQLAlchemy, and Alembic work normally.

---

## WHY LANGGRAPH AND NOT DIRECT API CALLS

For simple single-turn AI features, direct Anthropic API calls are correct.
LangGraph adds complexity that simple features don't need.

LangGraph is justified when:
- Multiple agents need to coordinate (router -> classifier -> responder)
- State needs to persist across agent steps (conversation history, cost tracking)
- Branching logic exists (Haiku classifies, Sonnet reasons only when needed)
- SSE streaming needs to flow through the agent graph

The cost ceiling middleware, query classification, and streaming pipeline
all require state management that LangGraph provides cleanly.
Without LangGraph, this state lives in application code and becomes harder to reason about.

---

## WHY VOYAGE AI AND NOT OPENAI EMBEDDINGS

Voyage AI's voyage-finance-2 model is trained specifically on financial text.
It produces more semantically accurate embeddings for transaction descriptions,
merchant names, and financial categories than general-purpose models.

OpenAI embeddings are general-purpose. They work, but they miss domain nuance.
"Uber" and "Lyft" are semantically similar for general text.
For a personal finance app, they're the same category - transportation.
Voyage Finance gets this right. General models often don't.

Cost is comparable. Quality for financial semantic search is meaningfully better.

---

## WHY 200-LINE SKILL FILES

Research from HumanLayer and community developers confirms:
Claude Code's reliable instruction-following limit is approximately 150-200 instructions.
Claude Code's system prompt already uses ~50 slots.
That leaves 100-150 slots for CLAUDE.md content.

Past the 200-line threshold, compliance degrades uniformly - every rule added
dilutes every other rule proportionally. A 683-line BUILD_RULES.md has the same
compliance probability per rule as a 50-line file, but 13x the dilution.

Critical rules in a 683-line file compete with boilerplate for attention.
Critical rules in a 200-line file get the full attention budget.

This is why skill files are capped at 200 lines and examples moved to EXAMPLES.md.

---

## WHY HOOKS INSTEAD OF CLAUDE.MD RULES

CLAUDE.md is delivered as a user message, not as system configuration.
Claude Code reads it and applies judgment about which rules are relevant to the current task.
Compliance is approximately 70%.

Hooks are shell commands. They run regardless of Claude Code's judgment.
A hook that strips Co-Authored-By from git commits runs every time, on every commit.
A CLAUDE.md rule that says "never add Co-Authored-By" follows about 70% of the time.

For mechanical rules (strip a trailer, block a dangerous command, check context):
hooks are the right mechanism.

For behavioral guidance (code style, communication tone, architectural preferences):
CLAUDE.md is the right mechanism.

The distinction: hooks enforce. CLAUDE.md educates.

---

## WHY POSTGRESQL+ASYNCPG:// AND NOT POSTGRES://

SQLAlchemy's async engine requires a driver that supports async IO.
asyncpg is the async driver for PostgreSQL.

SQLAlchemy's sync engine uses psycopg2, which has the postgres:// prefix.
SQLAlchemy's async engine uses asyncpg, which requires postgresql+asyncpg://.

Supabase provides the postgres:// connection string by default.
If you copy it without changing the prefix, SQLAlchemy's async session throws a
confusing error about an incompatible driver, not about the URL format.

Port 5432 is the direct connection. Port 6543 is the PgBouncer pooler.
For MVP-scale apps, port 5432 (direct) is simpler and works without extra config.

CAUTION: Port 6543 uses PgBouncer in transaction mode, which breaks asyncpg's
default prepared statements. If you use port 6543, you MUST disable prepared
statements: pass statement_cache_size=0 to create_async_engine's connect_args
AND append ?pgbouncer=true to the URL. Without these, you get a
DuplicatePreparedStatementError at engine initialization before any query runs.

Recommended for MVP: postgresql+asyncpg://[host]:5432/[db]
Recommended for scale: postgresql+asyncpg://[host]:6543/[db]?pgbouncer=true
  with connect_args={"statement_cache_size": 0}

---

## WHY NET 15 PAYMENT TERMS

Net 30 is standard for large corporations. For a solo freelancer working with
small-to-medium clients, Net 30 creates cash flow problems.

Net 15 is acceptable to most clients and protects cash flow.
Milestone billing (invoice at gate close, not at project end) further protects
against the risk of late payment on long projects.

The client gets a working, tested feature at every gate. The invoice is justified.
