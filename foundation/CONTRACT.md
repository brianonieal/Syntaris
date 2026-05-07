# CONTRACT.md
# Syntaris v0.6.0 | Project Contract
# Fill this out during BUILD APPROVED phase. Lock all fields before GO.
# Once LOCKED, fields only change via new DECISIONS.md entry, which
# also triggers re-doing BUILD APPROVED.

---

## PROJECT IDENTITY

PROJECT_NAME:          [App name]
PROJECT_VERSION:       v0.0.0
BUILD_TYPE:            PRODUCTION | INTERNAL | EXPLORATORY
FINAL_VERSION:         v1.0 Production Live | v1.0 Internal GA | v0.X Prototype Validated
PROJECT_TYPE:          personal | client
CLIENT_REF:            [If PROJECT_TYPE: client, link to foundation/CLIENTS.md] | N/A
RECIPE:                [Recipe name from /start, e.g. web-app-starter/react/nextjs-supabase]
RUNTIME_TIER:          1 | 2 | 3 (set by /start based on detected harness)
TEAM_MODE:             false | true (activates TEAM.md)
START_DATE:            [date]
TARGET_LAUNCH_DATE:    [date]

---

## TECH STACK (locked after BUILD APPROVED)

# NOTE: The fields below default to Brian's reference stack (Next.js + FastAPI + Supabase + LangGraph).
# When you run /start and pick a recipe, the recipe's CONTRACT.snippet.md will override these defaults.
# For 'bring-your-own' or unrecognized recipes, /build-rules will ask you to fill these in interactively.
# If you see this section unchanged after /start, your recipe didn't apply - manually edit or re-run /start.

FRONTEND:              Next.js 14+ App Router | TypeScript strict
STYLING:               Tailwind CSS + CSS custom properties
CHARTS:                Recharts
STATE_MANAGEMENT:      TanStack Query + Zustand
BACKEND:               FastAPI Python 3.11
DATABASE:              Supabase (Postgres + pgvector)
MIGRATIONS:            Alembic + SQLAlchemy
AUTH:                  Supabase Auth (Google OAuth + magic link)
AI_ORCHESTRATION:      LangGraph | None
AI_ROUTING:            LiteLLM | Direct Anthropic API
AI_PRIMARY_MODEL:      claude-sonnet-4-6
AI_CLASSIFIER_MODEL:   claude-haiku-4-5
EMBEDDINGS:            Voyage AI voyage-finance-2 | voyage-3 | None
OBSERVABILITY:         Sentry (v1.0.0+)
BILLING:               Stripe (v5.0.0+) | None

---

## DEPLOYMENT (locked after BUILD APPROVED)

FRONTEND_PLATFORM:     Vercel
BACKEND_PLATFORM:      Render (free -> Railway at v5.0.0)
FRONTEND_URL:          [vercel-url] | TBD
BACKEND_URL:           [render-url] | TBD
FRONTEND_PORT_LOCAL:   3000
BACKEND_PORT_LOCAL:    8000
DATABASE_PORT:         5432 (direct) | 6543 (pooled - use this)

---

## AGENTS (if AI_ORCHESTRATION = LangGraph)

AGENT_1_NAME:          @[NAME]
AGENT_1_MODEL:         claude-sonnet-4-6
AGENT_1_PURPOSE:       [what it does]
AGENT_1_COST_CEILING:  $[X]/user/month

AGENT_2_NAME:          @[NAME]
AGENT_2_MODEL:         claude-haiku-4-5
AGENT_2_PURPOSE:       [what it does]

---

## CONSTRAINTS (hard limits that never change)

AI_COST_CEILING:       $0.50/user/month
FREE_TIER_QUERIES:     10/month
PRO_PRICE:             $9/month | N/A
WCAG_MINIMUM:          AA (AAA for financial data)
MIN_TEST_COVERAGE:     80% line coverage on new code
CONTEXT_WARN_PERCENT:  40
CONTEXT_HARD_PERCENT:  50

---

## BANNED TECHNOLOGIES

The following are explicitly banned on this project:
(Claude Code must never suggest or use these)

| Technology | Use Instead | Reason |
|-----------|-------------|--------|
| Prisma | SQLAlchemy + Alembic | Python incompatibility, migration issues |
| OpenAI embeddings | Voyage AI | Domain-specific performance |
| Redux | Zustand | Simpler, less boilerplate |
| Pages Router | App Router | Current Next.js standard |
| /compact | /clear | Lossy vs lossless context reset |
| Parallel file writes | Sequential builds | Race conditions, ERR-PARALLEL-001 |

---

## HOOKS STATUS

CO_AUTHOR_HOOK:        INSTALLED | NOT INSTALLED
ENFORCE_TESTS_HOOK:    INSTALLED | NOT INSTALLED
BLOCK_DANGEROUS_HOOK:  INSTALLED | NOT INSTALLED
CONTEXT_CHECK_HOOK:    INSTALLED | NOT INSTALLED
WRITETHRU_HOOK:        INSTALLED | NOT INSTALLED

---

## VISUAL VERIFICATION

VISUAL_CHECKS_ENABLED: true | false
SCREENSHOTS_PATH:      /mockups/screenshots/
DEV_SERVER_URL:        http://localhost:3000

---

## STATUS

Contract status: DRAFT | BUILD APPROVED | LOCKED
Last updated: [date]
Updated by: [project owner]
