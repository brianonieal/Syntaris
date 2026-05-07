# OUTCOMES.md
# Syntaris v0.5.0 | Task-Level Success Criteria
#
# Within a gate, define success criteria for individual tasks. The
# spec-reviewer subagent grades each task at gate close; failed
# outcomes block gate close.
#
# This is sub-gate granularity. Gate-level approval is still binary
# (CONFIRMED, MOCKUPS APPROVED, etc.). Outcomes adds checkpointed
# task-level grading WITHIN a gate.
#
# Format per outcome:
#   ## OUT-[NNN]: [task title]
#   Gate: v[X.Y.Z]
#   Status: PENDING | PASSED | FAILED | RETRY-1 | RETRY-2
#   Success criteria:
#     - [criterion 1]
#     - [criterion 2]
#     ...
#   Grader: spec-reviewer | manual | <subagent name>
#   Retries: <N> max  (manual retry in v0.5.0; auto-retry deferred to v0.6.0)
#   Failure note: [filled in if FAILED, blank otherwise]

## OUTCOMES

[Empty until first gate that uses Outcomes-style sub-gate criteria]

# Example (filled-in entry, kept here for format reference; delete or
# replace once real entries land):
#
# ## OUT-001: Implement /api/budgets endpoint
# Gate: v0.4.0
# Status: PASSED
# Success criteria:
#   - Returns 200 for authed user with valid input
#   - Returns 401 for unauthenticated request
#   - Returns 403 for cross-user RLS violation
#   - Returns 422 for invalid input
#   - Latency p50 < 100ms on local test data
# Grader: spec-reviewer
# Retries: 2 max (used 0)
# Failure note: -

## NOTES

- v0.5.0 ships the template + manual grading. The user reads each
  OUT-NNN at gate close, runs spec-reviewer manually, marks each
  PASSED or FAILED.
- v0.6.0 will add the automated retry loop: if grader returns FAILED,
  the agent gets one structured retry attempt (or two), then escalates
  to /debug. Until then, the operator handles retries by hand.
- Outcomes is OPTIONAL per gate. A simple gate with no sub-tasks can
  use only the gate-level approval words and skip OUTCOMES.md entirely.
- Pre-v0.5.0 projects can adopt Outcomes by creating this file and
  filling in OUT-NNN entries from the gate they want to start using
  the pattern.
