---
name: testing
description: "This skill manages test strategy, test writing, and test enforcement for all app builds. Use when writing tests, checking test coverage, setting up test infrastructure, or at gate close. Covers Pytest, Vitest, React Testing Library, and Playwright."
---

# TESTING SKILL - Syntaris v0.4.0
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

## SPEC-TO-TEST TRACEABILITY

When a component's spec changes in FRONTEND_SPEC.md, the tests that cover it
need review. This traceability check runs at gate close and when /testing is
invoked.

### How it works

1. COMPONENT_REGISTRY.md has a `Test File` column for every registered component.
2. When the test-writer agent writes tests for a component, it fills in the
   `Test File` column in COMPONENT_REGISTRY.md.
3. At gate close (or when /testing is invoked with the `--trace` flag), this
   skill checks for spec drift:
   - Read FRONTEND_SPEC.md. For each component section, hash the content.
   - Compare to the last known hashes in `.syntaris/spec-hashes.json`.
   - If a component's spec changed, look up its `Test File` in
     COMPONENT_REGISTRY.md.
   - Flag those test files as NEEDS REVIEW and list them.
4. After review, re-run /testing to update the hashes.

### Traceability check protocol

When you detect spec changes that affect existing tests:

```
SPEC DRIFT DETECTED - tests may need updates:

| Component | Spec Change | Test File | Action |
|-----------|-------------|-----------|--------|
| DashboardChart | Props added: `showLegend` | src/.../DashboardChart.test.tsx | REVIEW |
| BudgetCard | Variant removed: `compact` | src/.../BudgetCard.test.tsx | REVIEW |
```

Do NOT auto-rewrite tests. Present the drift table to the user and ask:
- "Should I update these tests to match the new spec?"
- "Should I mark them as reviewed (spec change is cosmetic, tests still valid)?"

### When COMPONENT_REGISTRY has no Test File entry

If a component has no test file registered, flag it:
```
UNTESTED COMPONENT: [ComponentName] at [file path]
  Spec exists in FRONTEND_SPEC.md but no test file registered.
  Run /testing to generate tests, or register manually.
```

## TESTS.MD FORMAT

| Gate | Backend | Frontend | E2E | Total | Target | Status |
|------|---------|----------|-----|-------|--------|--------|
