---
name: onboard
description: "This skill handles client onboarding from initial inquiry to signed agreement. Use when a new client reaches out, when scoping a project, or when the user types /onboard. Generates proposal, contract, cost estimate, and email draft."
---

# ONBOARD SKILL - Syntaris v0.3.0
# Invoke: /onboard

## STEP 1: INTAKE QUESTIONS

Gather from user:
1. Client name and contact
2. What they want built (even if vague)
3. Rough timeline expectation
4. Budget range (if known)
5. Equity, cash, or hybrid?

If equity: flag immediately. Require written equity agreement before any work.

## STEP 2: SCOPE DEFINITION

Generate: what IS included, what is NOT, what requires separate contract, assumptions.

## STEP 3: GATE-BY-GATE ESTIMATE

Use MEMORY_CORRECTIONS.md calibration. Add 20% buffer for client communication.
Present as ranges, not fixed prices.

## STEP 4: PROPOSAL DOCUMENT

Executive summary, proposed solution, technical approach, timeline, investment,
about the developer, next steps.

## STEP 5: CONTRACT

Scope, payment terms, IP (client owns code, developer retains methodology),
revision policy, termination clause, equity clause if applicable.

## STEP 6: EMAIL DRAFT

Short, professional email with proposal summary and next steps.

## CLIENTS.MD UPDATE

| Code | Name | Project | Status | Last Invoice | Total Billed |
|------|------|---------|--------|-------------|-------------|
