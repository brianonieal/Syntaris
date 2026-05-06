# Sub-recipe: react/nextjs-fastapi-supabase

Brian's reference stack. Next.js 14+ frontend, FastAPI backend, Supabase for database and auth, LangGraph for AI orchestration when needed.

## When to use

- AI-heavy apps with multi-agent orchestration
- Apps requiring Python ML libraries server-side
- Apps where backend logic is genuinely complex enough to justify a separate service

## When NOT to use

- Simple CRUD apps (use `nextjs-supabase`)
- One-developer projects with tight time pressure (the dual-runtime overhead costs ~10-20% velocity)

## Verified on

This is the stack of Forge Finance (12-gate calibration data in MEMORY_CORRECTIONS.md), EOM-AI, and Feast-AI.
