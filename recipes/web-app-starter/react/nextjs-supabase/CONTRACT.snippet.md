LANGUAGE_PRIMARY:      TypeScript
FRAMEWORK_FRONTEND:    Next.js 14+ (App Router)
FRAMEWORK_BACKEND:     Next.js API routes
DATABASE:              Supabase (Postgres)
ORM:                   Drizzle or Prisma (project's choice)
AUTH:                  Supabase Auth
AI_ORCHESTRATION:      Direct API calls (OpenAI / Anthropic SDKs)

FRONTEND_PLATFORM:     Vercel
BACKEND_PLATFORM:      Vercel (Next.js routes are deployed as serverless functions)
FRONTEND_PORT_LOCAL:   3000
BACKEND_PORT_LOCAL:    N/A (runs in Next.js dev server)
DATABASE_PORT:         5432 (Supabase pooled)

UNIT:                  Vitest
COMPONENT:             React Testing Library
E2E:                   Playwright
