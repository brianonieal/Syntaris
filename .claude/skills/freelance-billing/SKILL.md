---
name: freelance-billing
description: "This skill automates time tracking and invoice generation for freelance work. Use when tracking billable hours, generating invoices, or when the user types /bill or /invoice."
---

# FREELANCE BILLING SKILL -- Blueprint v11
# Invoke: /bill or /invoice

## IDENTITY (configured per user)

Owner: {{OWNER_NAME}}
Rate: {{HOURLY_RATE}} (sole proprietor)
Payment: {{PAYMENT_METHODS}}
Terms: {{PAYMENT_TERMS}}
Invoice numbering: [CLIENT_CODE]-[NNN]

Configure these values in CONTRACT.md OWNER section.

## AUTO-TRIGGER

At session start on a client project (CONTRACT.md CLIENT_TYPE = CLIENT):
1. Read TIMELOG.md
2. Note unbilled hours since last invoice
3. Remind user if unbilled hours exceed 8

## TIME TRACKING

Every gate close on a client project:
- Update TIMELOG.md with gate hours
- Mark hours as BILLABLE or NON_BILLABLE
- Running total of unbilled billable hours

## INVOICE GENERATION

Command: /invoice [CLIENT_CODE]

1. Read TIMELOG.md -- extract unbilled billable hours
2. Read CONTRACT.md -- extract client name, project description
3. Generate invoice with line items per gate
4. Mark hours as INVOICED in TIMELOG.md

## BILLING MODES

/bill -- show unbilled hours summary
/invoice [CLIENT] -- generate full invoice
/bill history [CLIENT] -- show all prior invoices

## PERSONAL PROJECTS

Projects with CONTRACT.md CLIENT_TYPE = PERSONAL are NOT billable.
Track hours anyway for estimation calibration data.
