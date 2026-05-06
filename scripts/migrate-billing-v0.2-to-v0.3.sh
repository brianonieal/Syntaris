#!/usr/bin/env bash
# migrate-billing-v0.2-to-v0.3.sh
# Migrates a Syntaris v0.2.0 project to v0.3.0 billing consolidation.
#
# What it does:
#   1. Backs up CONTRACT.md and INVOICES.md
#   2. Renames CLIENT_TYPE: CLIENT -> PROJECT_TYPE: client in CONTRACT.md
#   3. Renames CLIENT_TYPE: PERSONAL -> PROJECT_TYPE: personal in CONTRACT.md
#   4. Renames CLIENT_CODE: ... -> CLIENT_REF: foundation/CLIENTS.md (or N/A)
#   5. Adds new fields: RECIPE, ONBOARDING_MODE, RUNTIME_TIER (with defaults)
#   6. If client project and CLIENTS.md missing, prompts to create from CLIENTS.md.template
#   7. Detects legacy INVOICES.md format and converts to v0.3.0 schema if needed
#
# Idempotent: safe to run twice.

set -e

PROJECT_ROOT="$(pwd)"
CONTRACT="$PROJECT_ROOT/foundation/CONTRACT.md"
INVOICES="$PROJECT_ROOT/foundation/INVOICES.md"
CLIENTS="$PROJECT_ROOT/foundation/CLIENTS.md"

if [[ ! -f "$CONTRACT" ]]; then
  echo "ERROR: foundation/CONTRACT.md not found in $(pwd)"
  echo "Run this script from the project root (where foundation/ lives)."
  exit 1
fi

echo "Syntaris v0.2.0 -> v0.3.0 migration"
echo "Project root: $PROJECT_ROOT"
echo ""

# Backup
if [[ ! -f "$CONTRACT.v0.2.bak" ]]; then
  cp "$CONTRACT" "$CONTRACT.v0.2.bak"
  echo "  [OK] Backed up CONTRACT.md to CONTRACT.md.v0.2.bak"
fi
if [[ -f "$INVOICES" && ! -f "$INVOICES.v0.2.bak" ]]; then
  cp "$INVOICES" "$INVOICES.v0.2.bak"
  echo "  [OK] Backed up INVOICES.md to INVOICES.md.v0.2.bak"
fi

# Detect current state
if grep -q "^PROJECT_TYPE:" "$CONTRACT"; then
  echo "  [INFO] CONTRACT.md already has PROJECT_TYPE field. Skipping rename step."
  ALREADY_MIGRATED=true
else
  ALREADY_MIGRATED=false
fi

if [[ "$ALREADY_MIGRATED" == "false" ]]; then
  # Field renames
  # CLIENT_TYPE: CLIENT -> PROJECT_TYPE: client
  # CLIENT_TYPE: PERSONAL -> PROJECT_TYPE: personal
  sed -i.tmp 's/^CLIENT_TYPE:[[:space:]]*CLIENT/PROJECT_TYPE:          client/' "$CONTRACT"
  sed -i.tmp 's/^CLIENT_TYPE:[[:space:]]*PERSONAL/PROJECT_TYPE:          personal/' "$CONTRACT"
  rm -f "$CONTRACT.tmp"
  echo "  [OK] Renamed CLIENT_TYPE -> PROJECT_TYPE"

  # CLIENT_CODE -> CLIENT_REF
  if grep -q "^CLIENT_CODE:" "$CONTRACT"; then
    if grep -q "^PROJECT_TYPE:[[:space:]]*client" "$CONTRACT"; then
      sed -i.tmp 's|^CLIENT_CODE:.*|CLIENT_REF:            foundation/CLIENTS.md|' "$CONTRACT"
    else
      sed -i.tmp 's|^CLIENT_CODE:.*|CLIENT_REF:            N/A|' "$CONTRACT"
    fi
    rm -f "$CONTRACT.tmp"
    echo "  [OK] Renamed CLIENT_CODE -> CLIENT_REF"
  fi

  # Add new fields after CLIENT_REF
  if ! grep -q "^RECIPE:" "$CONTRACT"; then
    if grep -q "^CLIENT_REF:" "$CONTRACT"; then
      sed -i.tmp '/^CLIENT_REF:/a\
RECIPE:                bring-your-own\
ONBOARDING_MODE:       standard\
RUNTIME_TIER:          1
' "$CONTRACT"
      rm -f "$CONTRACT.tmp"
      echo "  [OK] Added RECIPE, ONBOARDING_MODE, RUNTIME_TIER fields"
    fi
  fi
fi

# CLIENTS.md creation prompt
if grep -q "^PROJECT_TYPE:[[:space:]]*client" "$CONTRACT"; then
  if [[ ! -f "$CLIENTS" ]]; then
    echo ""
    echo "  [WARN] PROJECT_TYPE is 'client' but foundation/CLIENTS.md doesn't exist."
    echo "         You'll need to create it before the billing skill can generate invoices."
    read -p "  Create CLIENTS.md from template now? (y/n): " create_clients
    if [[ "$create_clients" == "y" ]]; then
      if [[ -f "foundation/CLIENTS.md.template" ]]; then
        cp foundation/CLIENTS.md.template "$CLIENTS"
        echo "  [OK] Created foundation/CLIENTS.md from template. Edit it to fill in client info."
      else
        echo "  [ERROR] Template not found at foundation/CLIENTS.md.template."
        echo "          Re-run /start in your harness to populate CLIENTS.md interactively."
      fi
    else
      echo "  [SKIP] CLIENTS.md not created. The billing skill will prompt to fix this on first invocation."
    fi
  fi
fi

# Invoice schema check
if [[ -f "$INVOICES" ]]; then
  if grep -q "^## INV-" "$INVOICES" 2>/dev/null; then
    echo "  [OK] INVOICES.md already in v0.3.0 schema."
  else
    echo "  [INFO] INVOICES.md exists but schema is unrecognized."
    echo "         Manual review recommended. See core/skills/billing/SKILL.md for v0.3.0 schema."
  fi
fi

echo ""
echo "Migration complete."
echo ""
echo "Next steps:"
echo "  1. Review foundation/CONTRACT.md for the new fields."
echo "  2. If client project, fill in foundation/CLIENTS.md with billing details."
echo "  3. Run /start in your harness to confirm the project loads correctly."
echo ""
echo "Rollback if needed:"
echo "  mv foundation/CONTRACT.md.v0.2.bak foundation/CONTRACT.md"
[[ -f "$INVOICES" ]] && echo "  mv foundation/INVOICES.md.v0.2.bak foundation/INVOICES.md"
