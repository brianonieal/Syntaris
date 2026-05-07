# DECISIONS.md
# Syntaris v0.5.3 | Architectural Decision Log
# Every significant technical decision is recorded here before being implemented.
# LOCKED decisions cannot be changed without a new entry that supersedes them.

---

## HOW TO USE

When Claude Code or the user proposes a significant decision:
1. /critical-thinker challenges it
2. The user approves or modifies
3. Entry is written here with status LOCKED
4. Implementation proceeds

"Significant" means: affects 3+ future gates, or is hard to reverse.
Small decisions (variable names, file structure within a component) don't need entries.

---

## DECISION TEMPLATE

## DEC-[NNN] - [Short title]
Date: [date]
Gate: v[X.X.X]
Owner: {{OWNER_NAME}} | [Other developer if TEAM_MODE=true]
Proposed by: {{OWNER_NAME}} | Claude Code
Approved by: {{OWNER_NAME}} [+ other developer if TEAM_MODE]
Decision: [What was decided, in one sentence]
Reason: [Why this over the alternative, in one sentence]
Alternatives considered: [What was rejected and why]
Supersedes: DEC-[NNN] | None
Status: LOCKED

---

## DECISIONS LOG

[Entries added here during build, newest at top]

---

## STANDARD LOCKED DECISIONS (pre-seeded for default stack)

## DEC-001 - FastAPI over Next.js API Routes
Date: [project start]
Gate: v0.0.0
Owner: {{OWNER_NAME}}
Decision: Use FastAPI for backend, not Next.js API Routes
Reason: LangGraph agents and SSE streaming exceed serverless function time limits
Alternatives considered: Next.js API routes (simpler but incompatible with agents)
Status: LOCKED

## DEC-002 - SQLAlchemy async with Alembic migrations
Date: [project start]
Gate: v0.0.0
Owner: {{OWNER_NAME}}
Decision: Use SQLAlchemy async + Alembic for all database operations
Reason: Type-safe ORM prevents SQL injection; named versioned migrations prevent drift
Alternatives considered: Prisma (Python incompatibility), raw SQL (injection risk)
Status: LOCKED

## DEC-003 - postgresql+asyncpg:// prefix, connection strategy
Date: [project start]
Gate: v0.0.0
Owner: {{OWNER_NAME}}
Decision: DATABASE_URL uses postgresql+asyncpg:// prefix. For MVP, use port 5432 (direct
connection). If pooling is needed at scale, use port 6543 with statement_cache_size=0 in
the SQLAlchemy engine AND append ?pgbouncer=true to the DATABASE_URL.
Reason: SQLAlchemy async requires asyncpg driver. Supabase port 6543 uses PgBouncer in
transaction mode, which breaks asyncpg's default prepared statements
(DuplicatePreparedStatementError at engine init). Port 5432 direct connection works
out of the box. The pooler requires disabling prepared statement caching explicitly.
Alternatives considered: postgres:// prefix (incompatible with asyncpg driver), port 6543
with default asyncpg settings (crashes on startup)
Status: LOCKED

## DEC-004 - RLS on all user-specific tables from day one
Date: [project start]
Gate: v0.2.0
Owner: {{OWNER_NAME}}
Decision: Enable RLS on every table containing user data at migration time
Reason: Data isolation must be at database level, not application level
Alternatives considered: Application-level filtering (error-prone, bypassed by bugs)
Status: LOCKED

## DEC-005 - Voyage AI over OpenAI embeddings (STACK-SPECIFIC: fintech)
Date: [project start]
Gate: v0.4.0+ (when embeddings needed)
Owner: {{OWNER_NAME}}
Scope: This decision is specific to projects on the Syntaris v0.5.3 fintech stack. Non-fintech projects should evaluate embeddings providers against their own domain. Remove or replace this entry if your project is not fintech.
Decision: Use Voyage AI voyage-finance-2 for financial text, voyage-3 for general
Reason: Finance-specific model produces more accurate semantic search for transactions
Alternatives considered: OpenAI text-embedding-3-small (general purpose, less accurate)
Status: LOCKED

## DEC-006 - /clear over /compact for context resets
Date: [project start]
Gate: All
Owner: {{OWNER_NAME}}
Decision: Always use /clear for context resets, never /compact
Reason: /clear is lossless (save to PLANS.md first); /compact is lossy (retains 20-30%)
Alternatives considered: /compact (convenient but destroys architectural context)
Status: LOCKED

## DEC-007 - Local development port configuration
Date: [project start]
Gate: v0.0.0
Owner: {{OWNER_NAME}}
Decision: Configure BACKEND_PORT_LOCAL in CONTRACT.md so the port can be changed per-developer without code edits
Reason: Some Windows installations reserve common ports (8000, 8080) at the OS level for HTTP services or other software, causing the dev server to fail to bind. Putting the port in CONTRACT.md lets each developer set a port that works on their machine without forking the codebase.
Alternatives considered: Hardcode a single port in source (breaks when that port is reserved); netsh port unblocking on Windows (not persistent across reboots)
Status: LOCKED
