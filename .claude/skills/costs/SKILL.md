---
name: costs
description: "This skill tracks build costs and operational costs for app projects. Use when estimating costs, checking spending, or when the user types /costs. Flags cheaper alternatives at every decision point."
---

# COSTS SKILL - Syntaris v0.6.0
# Invoke: /costs or /cost-tracker

## COST ESTIMATES BEFORE BUILDING

Before every gate, estimate:
- Build cost: API tokens consumed during this gate
- Operational cost: monthly cost at 100 / 1000 / 10000 users

Use MEMORY_CORRECTIONS.md calibration data for estimates.

## COST CEILING ENFORCEMENT

Default AI cost ceiling: configurable in CONTRACT.md (e.g. $0.50/user/month).
Hard-code this in every agent's cost_guard middleware.

## SOFT BLOCK THRESHOLDS

Development: warn at $25/month operational
Launch:      warn at $75/month operational
Scale:       warn at $200/month operational

## COSTS.MD FORMAT

### Build Costs
| Gate | API Tokens | Estimated Cost | Hours | Total |
|------|-----------|----------------|-------|-------|

### Operational Costs (monthly estimate)
| Service | Free Tier | At 100 users | At 1000 users |
|---------|-----------|--------------|---------------|
