---
name: testing
description: "This skill manages test strategy, test writing, and test enforcement for all app builds. Use when writing tests, checking test coverage, setting up test infrastructure, or at gate close. Covers Pytest, Vitest, React Testing Library, and Playwright."
---

# TESTING SKILL - Syntaris v0.3.0
# Invoke: /testing

## TEST STRATEGY BY GATE

v0.0.0 Foundation:     0 tests (infrastructure only)
v0.1.0 Scaffold:       0 tests (test framework configured)
v0.2.0 Data Layer:     12+ tests (model validation, migration, RLS isolation)
v0.3.0 Auth:           27+ tests (auth flows, protected routes, JWT)
v0.4.0 External APIs:  50+ tests (webhook, sync, error handling)
v0.5.0 Core Features:  89+ tests (agents, streaming, all screens)
v0.6.0 CRUD:           119+ tests (secondary features)
v1.0.0 Launch:         119+ tests (no regression from v0.6.0)

## BACKEND: PYTEST

Framework: pytest + pytest-asyncio + httpx (async client)

File structure:
  apps/api/tests/
    conftest.py          - fixtures: test_client, test_db, test_user
    test_[feature].py    - one file per domain

Test naming: test_[action]_[condition]_[expected_result]

RLS isolation test (mandatory at v0.2.0+):
```python
async def test_user_cannot_see_other_user_data(client, user_a_headers, user_b_id):
    response = await client.get(f"/api/data?user_id={user_b_id}",
                                headers=user_a_headers)
    assert response.status_code in [403, 200]
    if response.status_code == 200:
        assert len(response.json()["data"]) == 0
```

## FRONTEND: VITEST + REACT TESTING LIBRARY

File structure:
  apps/web/src/components/[Component]/[Component].test.tsx

Component test pattern:
```typescript
import { render, screen } from '@testing-library/react'
import { MyComponent } from './MyComponent'

describe('MyComponent', () => {
  it('renders the expected content', () => {
    render(<MyComponent label="Test" value="$42,000" />)
    expect(screen.getByText('$42,000')).toBeInTheDocument()
  })
})
```

## VISUAL VERIFICATION: PLAYWRIGHT

Triggered at gate close when screens were built.
Run via /visual-checks skill (see VISUAL_CHECKS.md).

## GATE CLOSE REQUIREMENTS

Before marking any gate as COMPLETE:
1. All tests pass (zero failures, zero skips without reason)
2. Test count equals or exceeds gate target
3. No test count regression from prior gate
4. Coverage on new code: minimum 80% line coverage

## TESTS.MD FORMAT

| Gate | Backend | Frontend | E2E | Total | Target | Status |
|------|---------|----------|-----|-------|--------|--------|
