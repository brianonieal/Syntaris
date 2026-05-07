---
name: billing
description: "Client work billing automation. Activates conditionally when CONTRACT.md has PROJECT_TYPE: client. Generates invoices at gate close based on hours from MEMORY_CORRECTIONS.md, prompts for invoice generation per gate, produces handoff deliverables at v1.0.0 final gate. Never activates for personal projects."
---

# BILLING SKILL - Syntaris v0.5.1
# Conditional activation based on CONTRACT.md PROJECT_TYPE field

## ACTIVATION RULES

This skill **never invokes itself**. It is read by other skills and activates conditionally.

Activation check: read `foundation/CONTRACT.md`. If `PROJECT_TYPE: client`, activate. If `PROJECT_TYPE: personal` or field missing, do nothing - return silently.

When active, this skill performs three jobs at three trigger points:

1. **At gate close** (triggered by `/build-rules` after gate close protocol completes): prompt user to generate invoice for the gate.
2. **At project mid-points** (when invoked manually via `/billing` or when monthly cadence is configured): generate consolidated invoices.
3. **At v1.0.0 final gate** (triggered by the gate close protocol when version reaches v1.0.0): produce client handoff artifacts.

## DATA SOURCES

The skill reads from:

- `foundation/CONTRACT.md`: PROJECT_TYPE, client name, project code
- `foundation/CLIENTS.md`: full client record (rate, payment terms, invoice cadence, contact info)
- `foundation/MEMORY_CORRECTIONS.md`: actual hours per gate (the calibration loop's output)
- `foundation/VERSION_ROADMAP.md`: gate names and numbers
- `foundation/INVOICES.md`: existing invoice records (to avoid duplicates)
- `foundation/CHANGELOG.md`: gate close summaries (used in handoff documents)

The skill writes to:

- `foundation/INVOICES.md` (append-only ledger)
- `foundation/HANDOFF/` directory (only at v1.0.0)

## TRIGGER 1: GATE CLOSE INVOICE PROMPT

After every gate close (CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED, GO and every subsequent version gate), the `/build-rules` skill calls into this skill. This skill:

1. Reads the actual hours for the just-closed gate from MEMORY_CORRECTIONS.md (the most recent reflexion entry).
2. Reads the client's hourly rate from CLIENTS.md.
3. Computes invoice line-item: hours × rate, plus any fixed-fee adjustments.
4. Asks the user:

   > "Gate `[GATE_NAME]` closed. Hours logged: `[ACTUAL_HOURS]`. At `$[RATE]/hr` that's `$[AMOUNT]`. Generate invoice now? (y/n/defer)"

5. If `y`: append entry to INVOICES.md and confirm.
6. If `defer`: log to INVOICES.md as `STATUS: pending` so it can be batched later.
7. If `n`: do nothing.

**Invoice cadence override.** If CLIENTS.md specifies `INVOICE_CADENCE: monthly` or `INVOICE_CADENCE: project-end`, skip the gate-by-gate prompt and only generate consolidated invoices at the configured cadence. The user can still manually invoke `/billing now` to override.

## TRIGGER 2: MANUAL INVOICE GENERATION

When the user invokes `/billing` directly:

1. List recent gate closes from MEMORY_CORRECTIONS.md.
2. List pending entries in INVOICES.md.
3. Ask: "Generate invoice for which scope? Options: pending entries only, last gate, last month, custom date range."
4. Build the invoice document from selection.
5. Output as both an INVOICES.md ledger entry and a printable invoice PDF (using the `pdf` skill if available, otherwise plaintext).
6. Display path to generated invoice file.

## TRIGGER 3: V1.0.0 HANDOFF

When VERSION_ROADMAP.md shows the current gate is v1.0.0 and it has just closed, this skill triggers handoff generation.

The handoff produces three documents in `foundation/HANDOFF/`:

1. **`HANDOFF_SUMMARY.md`** - non-technical client summary. What was built, what was tested, deployment URL, support handoff. Reads from CHANGELOG.md and DEPLOYMENT.md.
2. **`HANDOFF_TECHNICAL.md`** - technical handoff for the client's future developers. Stack, repo structure, env vars, deployment process, known issues, where to find the test suite. Reads from CONTRACT.md, DEPLOYMENT_CONFIG.md, TESTS.md, ERRORS.md.
3. **`FINAL_INVOICE.md`** - total project invoice. All hours from MEMORY_CORRECTIONS.md, less any already-paid line items from INVOICES.md.

These are draft documents. The user reviews and edits before sending to the client. The skill prints:

> "Handoff drafts generated in `foundation/HANDOFF/`. Review and edit before sending. The skill cannot send these - sending is the user's call."

## CLIENTS.md SCHEMA

The skill expects CLIENTS.md to follow this format. If a project does not have CLIENTS.md or the file is malformed, the skill displays the missing fields and asks the user to fill them.

```markdown
# CLIENTS.md

## Client Record

CLIENT_NAME:        <legal entity or individual name>
PRIMARY_CONTACT:    <person name>
CONTACT_EMAIL:      <email>
CONTACT_PHONE:      <phone, optional>
ADDRESS:            <billing address, optional>
TAX_ID:             <EIN, VAT, etc., optional>

PROJECT_CODE:       <internal short code, e.g. ACME-001>
HOURLY_RATE:        <number in USD>
PAYMENT_TERMS:      <Net-15 | Net-30 | Net-45 | Due-on-receipt | Custom: ...>
INVOICE_CADENCE:    <per-gate | monthly | project-end | custom>

CONTRACT_DATE:      <when project started>
CONTRACT_DOCUMENT:  <path to signed contract, optional>

NOTES:              <free text>
```

## INVOICES.md SCHEMA

```markdown
# INVOICES.md

## INV-NNN

Date:           <YYYY-MM-DD>
Status:         <draft | pending | sent | paid>
Period:         <covered date range or gate>
Hours:          <number>
Rate:           <USD/hr>
Subtotal:       <hours × rate>
Adjustments:    <list, with reasons>
Total:          <USD>
Payment due:    <date based on PAYMENT_TERMS>

Line items:
- Gate <NAME>, <hours>h, $<amount>
- (additional items as needed)

Notes:          <free text>
```

## RULES

- **Never auto-send invoices.** All invoice and handoff documents are drafts. The user sends them. The skill prints filepath and stops.
- **Never modify CONTRACT.md or CLIENTS.md.** Only the `/start` skill writes those at project setup. The billing skill reads them.
- **Always check PROJECT_TYPE before doing anything.** If a project is personal, this skill must remain silent. The user must explicitly change PROJECT_TYPE in CONTRACT.md to activate billing on a previously-personal project.
- **Use MEMORY_CORRECTIONS.md actual hours, not estimates.** Invoices reflect what was actually worked, not what was predicted. The calibration loop's output drives client billing.
- **Handle the migration case.** If a v0.2.0 project upgrades to v0.3.0 and previously used the old `freelance-billing` skill, INVOICES.md may exist in a legacy format. On first read, detect legacy format and prompt the user to migrate. Migration script lives in `scripts/migrate-billing-v0.2-to-v0.3.sh`.

## INTEGRATION WITH OTHER SKILLS

The skill is invoked by:

- `/build-rules` at every gate close (trigger 1)
- `/start` at v1.0.0 detection (trigger 3)
- The user directly via `/billing` (trigger 2)

The skill does NOT invoke other skills. It reads, computes, prompts, writes ledger entries, prints filepaths. Discretion is the user's, not the skill's.

## FAILURE MODES

If CLIENTS.md is missing on a `PROJECT_TYPE: client` project, this skill prompts:

> "PROJECT_TYPE is set to client but CLIENTS.md is missing. Run `/start` again to collect client info, or create CLIENTS.md manually using the schema in `core/skills/billing/SKILL.md`."

If MEMORY_CORRECTIONS.md doesn't have an entry for the gate that just closed (calibration data missing), this skill prompts:

> "No reflexion entry found for gate `[GATE_NAME]`. Cannot compute hours-based invoice. Generate invoice manually with hours estimate, or skip?"

If the hourly rate in CLIENTS.md is not a valid number, this skill refuses to generate invoices and prompts the user to fix the rate.
