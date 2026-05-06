# CODING_RULES.md - Next.js + FastAPI + Supabase

## LANGUAGE
- TypeScript strict mode (frontend)
- Python 3.11+ with type hints on every function (backend)
- ruff clean (E, F, I, N, W) and mypy strict (backend)

## FRONTEND (Next.js)
- App Router only
- Server Components by default
- All API calls to FastAPI backend via fetch with typed schemas (Zod)

## BACKEND (FastAPI)
- All endpoints have Pydantic models for request/response
- All DB queries through SQLAlchemy ORM, no raw SQL with f-strings
- Async everywhere (no sync DB calls)
- LangGraph state schemas defined upfront, locked before gate close

## SUPABASE
- RLS on every user-data table
- Service role key never exposed to frontend
- pgvector for embeddings if AI/RAG features

## TESTING
- Vitest + React Testing Library + Playwright (frontend)
- pytest with async fixtures (backend)
- Coverage target: 80% on business logic
