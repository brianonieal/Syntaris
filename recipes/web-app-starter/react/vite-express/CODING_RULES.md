# CODING_RULES.md - Vite + Express + Postgres

## LANGUAGE
- TypeScript strict mode on frontend AND backend
- Shared types lib for request/response shapes

## FRONTEND (Vite + React)
- React Query (TanStack Query) for server state
- React Router for navigation
- Zod for runtime validation of API responses

## BACKEND (Express)
- Zod for request validation
- Prisma or Drizzle for DB access (no raw SQL)
- Helmet middleware for security headers
- Rate limiting on all auth endpoints

## TESTING
- Vitest unit tests
- Supertest for API integration tests
- Playwright E2E
