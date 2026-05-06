# CODING_RULES.md
# Stack-specific coding rules loaded by CLAUDE.md.
# These extend the universal coding rules from foundation/CLAUDE.md.

## LANGUAGE RULES

[Examples for TypeScript:]
- TypeScript strict mode
- No `any` types unless explicitly justified in DECISIONS.md
- Use `unknown` instead of `any` for type narrowing

[Examples for Python:]
- Python 3.11+ type hints on every function
- ruff clean before commit
- mypy strict mode

## FRAMEWORK RULES

[Examples:]
- All database queries via the ORM, no raw SQL with f-string interpolation
- HTTP request validation: Zod schemas (TS) or Pydantic models (Python)
- No environment variable reads at module top level; read inside functions or init code

## TESTING RULES

[Examples:]
- pytest for backend, Vitest + React Testing Library for frontend, Playwright for E2E
- Test files colocated with source: `foo.py` -> `test_foo.py`
- Coverage threshold: 80% for new code, 60% for legacy

## ORGANIZATION RULES

[Examples:]
- Imports sorted alphabetically within their groups (stdlib, third-party, local)
- One component per file
- Hooks in `/hooks`, utilities in `/lib`, components in `/components`
