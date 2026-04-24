#!/bin/bash
# install.sh
# Blueprint v11 Installer for macOS and Linux
#
# Usage:
#   ./install.sh
#   ./install.sh --personal-config ./personal-overlay/owner-config.md
#   ./install.sh --install-root ~/.claude --blueprint-root ~/Blueprint-v11
#   ./install.sh --zip /path/to/blueprint-v11.zip
#
# Supports two source modes:
#   A) Cloned from GitHub: run from repo root, no zip.
#   B) Packaged zip: extract first, then install.

set -e  # exit on error

# == Defaults ================================================================

ZIP_PATH="./blueprint-v11.zip"
INSTALL_ROOT="$HOME/.claude"
BLUEPRINT_ROOT="$HOME/Blueprint-v11"
PERSONAL_CONFIG=""
ASSUME_YES=false

# == Parse args ==============================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --zip)              ZIP_PATH="$2"; shift 2 ;;
    --install-root)     INSTALL_ROOT="$2"; shift 2 ;;
    --blueprint-root)   BLUEPRINT_ROOT="$2"; shift 2 ;;
    --personal-config)  PERSONAL_CONFIG="$2"; shift 2 ;;
    --yes|-y)           ASSUME_YES=true; shift ;;
    -h|--help)
      cat <<EOF
Blueprint v11 Installer (macOS / Linux / WSL)

Options:
  --zip <path>              Path to blueprint-v11.zip (default: ./blueprint-v11.zip)
  --install-root <dir>      Claude Code config dir (default: ~/.claude)
  --blueprint-root <dir>    Foundation templates dir (default: ~/Blueprint-v11)
  --personal-config <file>  Path to owner-config.md for variable substitution
  --yes, -y                 Skip the pre-install confirmation prompt

If you cloned this repo from GitHub, run this script from the repo root.
If you have a distributable zip, point --zip at it.

This installer CLOBBERS any existing Blueprint install at --install-root.
If you have personally edited Blueprint skills or settings.json, back them
up before running.
EOF
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# == Colored output helpers =================================================

if [[ -t 1 ]]; then
  C_CYAN='\033[0;36m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'; C_GRAY='\033[0;90m'; C_RESET='\033[0m'
else
  C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_GRAY=''; C_RESET=''
fi

info()  { printf "${C_CYAN}%s${C_RESET}\n" "$*"; }
ok()    { printf "  ${C_GREEN}[OK]${C_RESET} %s\n" "$*"; }
warn()  { printf "  ${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"; }
err()   { printf "  ${C_RED}[ERROR]${C_RESET} %s\n" "$*"; }
miss()  { printf "  ${C_RED}[MISSING]${C_RESET} %s\n" "$*"; }

echo ""
info "============================================"
info "  Blueprint v11 Installer (macOS / Linux)"
info "  AI App Building Methodology"
info "============================================"
echo ""

# == Step 1: Locate source (clone or zip) ===================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USED_ZIP=false

if [[ -d "$SCRIPT_DIR/.claude" ]]; then
  SRC_ROOT="$SCRIPT_DIR"
  printf "${C_GREEN}Installing from cloned repo at: %s${C_RESET}\n" "$SRC_ROOT"
elif [[ -f "$ZIP_PATH" ]]; then
  TMP_DIR="$(mktemp -d -t blueprint-v11-install.XXXXXX)"
  printf "${C_GRAY}Extracting: %s${C_RESET}\n" "$ZIP_PATH"
  unzip -q "$ZIP_PATH" -d "$TMP_DIR"

  # The zip typically contains a single top-level directory
  INNER="$(find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)"
  if [[ -n "$INNER" && -d "$INNER/.claude" ]]; then
    SRC_ROOT="$INNER"
  else
    SRC_ROOT="$TMP_DIR"
  fi
  printf "${C_GREEN}Extracted to: %s${C_RESET}\n" "$SRC_ROOT"
  USED_ZIP=true
else
  err "Cannot locate Blueprint source."
  echo "Expected one of:" >&2
  echo "  - A .claude/ directory next to this installer (clone mode)" >&2
  echo "  - A blueprint-v11.zip at: $ZIP_PATH (zip mode)" >&2
  echo "" >&2
  echo "If you cloned from GitHub, run this installer from the repo root." >&2
  echo "If you have a zip, specify: --zip /path/to/blueprint-v11.zip" >&2
  exit 1
fi

# == Step 2: Detect existing install and confirm clobber ====================

existing_detected=false
if [[ -d "$INSTALL_ROOT/skills" ]] || [[ -d "$INSTALL_ROOT/hooks" ]] \
   || [[ -d "$INSTALL_ROOT/agents" ]] || [[ -f "$INSTALL_ROOT/settings.json" ]]; then
  existing_detected=true
fi

if $existing_detected; then
  echo ""
  warn "Existing Blueprint install detected at: $INSTALL_ROOT"
  warn "Continuing will CLOBBER:"
  [[ -d "$INSTALL_ROOT/skills" ]] && warn "  - all files under $INSTALL_ROOT/skills/"
  [[ -d "$INSTALL_ROOT/hooks" ]]  && warn "  - all files under $INSTALL_ROOT/hooks/"
  [[ -d "$INSTALL_ROOT/agents" ]] && warn "  - all files under $INSTALL_ROOT/agents/"
  [[ -f "$INSTALL_ROOT/settings.json" ]] && warn "  - settings.json (backed up to .bak first)"
  warn "Any files you've personally edited will be overwritten."
  echo ""
  warn "Preserved: foundation templates at $BLUEPRINT_ROOT, per-project files,"
  warn "  personal-overlay/owner-config.md, hook error logs in \$TMPDIR."

  if ! $ASSUME_YES; then
    echo ""
    printf "${C_YELLOW}Proceed with clobber-and-reinstall? [y/N]: ${C_RESET}"
    read -r reply
    case "$reply" in
      y|Y|yes|YES) ;;
      *) echo "Aborted."; exit 0 ;;
    esac
  fi

  # Clobber cleanly so stale v11.x files don't linger
  rm -rf "$INSTALL_ROOT/skills" "$INSTALL_ROOT/hooks" "$INSTALL_ROOT/agents"
fi

# == Step 3: Install skills, hooks, agents, settings =========================

echo ""
info "Installing to: $INSTALL_ROOT"

mkdir -p "$INSTALL_ROOT/skills" "$INSTALL_ROOT/hooks" "$INSTALL_ROOT/agents"

# settings.json (backup existing)
if [[ -f "$INSTALL_ROOT/settings.json" ]]; then
  warn "settings.json exists - backing up to settings.json.bak"
  cp -f "$INSTALL_ROOT/settings.json" "$INSTALL_ROOT/settings.json.bak"
fi
cp -f "$SRC_ROOT/.claude/settings.json" "$INSTALL_ROOT/settings.json"
ok "settings.json"

# Skills
for skill_dir in "$SRC_ROOT/.claude/skills/"*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  dest="$INSTALL_ROOT/skills/$name"
  mkdir -p "$dest"
  cp -Rf "$skill_dir"* "$dest/"
  ok "skills/$name"
done

# Hooks
for hook_file in "$SRC_ROOT/.claude/hooks/"*; do
  [[ -f "$hook_file" ]] || continue
  name="$(basename "$hook_file")"
  cp -f "$hook_file" "$INSTALL_ROOT/hooks/$name"
  ok "hooks/$name"
done

# Agents
if [[ -d "$SRC_ROOT/.claude/agents" ]]; then
  for agent_file in "$SRC_ROOT/.claude/agents/"*; do
    [[ -f "$agent_file" ]] || continue
    name="$(basename "$agent_file")"
    cp -f "$agent_file" "$INSTALL_ROOT/agents/$name"
    ok "agents/$name"
  done
fi

# == Step 3: Install foundation templates ===================================

echo ""
info "Installing foundation templates to: $BLUEPRINT_ROOT"
mkdir -p "$BLUEPRINT_ROOT/foundation" "$BLUEPRINT_ROOT/claude-skills"

for md_file in "$SRC_ROOT/foundation/"*.md; do
  [[ -f "$md_file" ]] || continue
  name="$(basename "$md_file")"
  cp -f "$md_file" "$BLUEPRINT_ROOT/foundation/$name"
  ok "foundation/$name"
done

# claude-skills (source copies used by bundle builder)
if [[ -d "$SRC_ROOT/claude-skills" ]]; then
  for skill_dir in "$SRC_ROOT/claude-skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"
    dest="$BLUEPRINT_ROOT/claude-skills/$name"
    mkdir -p "$dest"
    cp -Rf "$skill_dir"* "$dest/"
    ok "claude-skills/$name"
  done
fi

# Copy meta files
cp -f "$0" "$BLUEPRINT_ROOT/install.sh" 2>/dev/null || true
[[ -f "$SRC_ROOT/README.md" ]] && cp -f "$SRC_ROOT/README.md" "$BLUEPRINT_ROOT/"
[[ -f "$SRC_ROOT/LICENSE" ]] && cp -f "$SRC_ROOT/LICENSE" "$BLUEPRINT_ROOT/"
[[ -f "$SRC_ROOT/CHANGELOG.md" ]] && cp -f "$SRC_ROOT/CHANGELOG.md" "$BLUEPRINT_ROOT/"

# == Step 4: Apply personal configuration (if provided) =====================

if [[ -n "$PERSONAL_CONFIG" && -f "$PERSONAL_CONFIG" ]]; then
  echo ""
  info "Applying personal configuration from: $PERSONAL_CONFIG"

  # Parse KEY: value lines into parallel arrays
  keys=(); values=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*):[[:space:]]*(.+)$ ]]; then
      keys+=("${BASH_REMATCH[1]}")
      # Strip trailing whitespace from the value
      val="${BASH_REMATCH[2]}"
      val="${val%"${val##*[![:space:]]}"}"
      values+=("$val")
    fi
  done < "$PERSONAL_CONFIG"

  if [[ ${#keys[@]} -eq 0 ]]; then
    warn "No KEY: value pairs parsed from $PERSONAL_CONFIG"
  else
    # Walk target dirs and substitute each {{KEY}}
    target_dirs=(
      "$BLUEPRINT_ROOT/foundation"
      "$INSTALL_ROOT/skills"
    )
    for dir in "${target_dirs[@]}"; do
      [[ -d "$dir" ]] || continue
      while IFS= read -r -d '' md_file; do
        changed=false
        for i in "${!keys[@]}"; do
          key="${keys[i]}"
          value="${values[i]}"
          placeholder="{{${key}}}"
          if grep -qF -- "$placeholder" "$md_file" 2>/dev/null; then
            # Escape value for sed (handle /, \, &)
            esc_value=$(printf '%s' "$value" | sed -e 's/[\/&]/\\&/g')
            sed -i.bak "s/{{${key}}}/${esc_value}/g" "$md_file"
            rm -f "${md_file}.bak"
            changed=true
          fi
        done
        if $changed; then
          ok "Substituted variables in: $(basename "$md_file")"
        fi
      done < <(find "$dir" -type f -name "*.md" -print0)
    done

    # Count remaining placeholders
    remaining=0
    for dir in "${target_dirs[@]}"; do
      [[ -d "$dir" ]] || continue
      count=$(find "$dir" -type f -name "*.md" -exec grep -lE '\{\{[A-Z_]+\}\}' {} \; 2>/dev/null | wc -l | tr -d ' ')
      remaining=$((remaining + count))
    done
    if [[ $remaining -gt 0 ]]; then
      warn "$remaining file(s) still contain {{VARIABLE}} placeholders."
      warn "Add missing keys to your owner-config.md and re-run."
    else
      ok "All placeholders replaced."
    fi
  fi
else
  # Check for unsubstituted placeholders and print help
  if [[ -d "$BLUEPRINT_ROOT/foundation" ]]; then
    ph_count=$(find "$BLUEPRINT_ROOT/foundation" -type f -name "*.md" \
               -exec grep -lE '\{\{[A-Z_]+\}\}' {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [[ $ph_count -gt 0 ]]; then
      echo ""
      printf "${C_YELLOW}NOTE: %s file(s) in foundation/ contain {{VARIABLE}} placeholders.${C_RESET}\n" "$ph_count"
      printf "${C_YELLOW}  To personalize, create an owner-config.md and re-run:${C_RESET}\n"
      printf "${C_YELLOW}  ./install.sh --personal-config ./personal-overlay/owner-config.md${C_RESET}\n"
    fi
  fi
fi

# == Step 5: Mark hook scripts executable ==================================

chmod +x "$INSTALL_ROOT/hooks/"*.sh 2>/dev/null || true
ok "Hook scripts marked executable"

# == Step 6: Verify installation ============================================

echo ""
info "Verifying installation..."

all_ok=true

# Skills
required_skills=(
  "start" "build-rules" "global-rules" "critical-thinker"
  "testing" "security" "deployment" "costs" "performance"
  "debug" "research" "freelance-billing" "handoff"
  "health" "onboard" "coursework" "rollback"
)
for skill in "${required_skills[@]}"; do
  if [[ -f "$INSTALL_ROOT/skills/$skill/SKILL.md" ]]; then
    ok "skills/$skill"
  else
    miss "skills/$skill"
    all_ok=false
  fi
done

# Hooks + wrappers
required_hooks=(
  "session-start.sh" "session-start.ps1"
  "strip-coauthor.sh" "strip-coauthor.ps1"
  "enforce-tests.sh" "enforce-tests.ps1"
  "block-dangerous.sh" "block-dangerous.ps1"
  "context-check.sh" "context-check.ps1"
  "pre-compact.sh" "pre-compact.ps1"
  "writethru-episodic.sh" "writethru-episodic.ps1"
  "hook-wrapper.sh" "hook-wrapper.ps1"
)
for hook in "${required_hooks[@]}"; do
  if [[ -f "$INSTALL_ROOT/hooks/$hook" ]]; then
    ok "hooks/$hook"
  else
    miss "hooks/$hook"
    all_ok=false
  fi
done

# Agents
for agent in spec-reviewer.md test-writer.md security-auditor.md; do
  if [[ -f "$INSTALL_ROOT/agents/$agent" ]]; then
    ok "agents/$agent"
  else
    miss "agents/$agent"
    all_ok=false
  fi
done

# Packaging integrity: .claude/skills vs claude-skills drift check
zip_a="$SRC_ROOT/.claude/skills"
zip_b="$SRC_ROOT/claude-skills"
if [[ -d "$zip_a" && -d "$zip_b" ]]; then
  drift=0
  for sd in "$zip_a/"*/; do
    [[ -d "$sd" ]] || continue
    sn="$(basename "$sd")"
    sa="$zip_a/$sn/SKILL.md"
    sb="$zip_b/$sn/SKILL.md"
    if [[ -f "$sa" && -f "$sb" ]]; then
      if ! cmp -s "$sa" "$sb"; then
        warn "skill '$sn' differs between .claude/skills and claude-skills"
        drift=$((drift + 1))
      fi
    fi
  done
  if [[ $drift -eq 0 ]]; then
    ok "skill directories in sync"
  else
    warn "$drift skill(s) drifted - packaging integrity issue"
  fi
fi

# == Step 7: Clean up =======================================================

if $USED_ZIP && [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
  rm -rf "$TMP_DIR"
fi

# == Step 8: Summary ========================================================

echo ""
info "============================================"

if $all_ok; then
  printf "${C_GREEN}  Blueprint v11 installed successfully!${C_RESET}\n"
  echo ""
  echo "  Skills:     $INSTALL_ROOT/skills/ (17 skills)"
  echo "  Hooks:      $INSTALL_ROOT/hooks/ (9 hooks + 1 wrapper, bash + PowerShell)"
  echo "  Agents:     $INSTALL_ROOT/agents/ (3 subagents)"
  echo "  Settings:   $INSTALL_ROOT/settings.json"
  echo "  Foundation: $BLUEPRINT_ROOT/foundation/ (23 templates)"
  echo ""
  info "  Next steps:"
  echo "  1. Configure git identity for your project"
  echo "  2. Open Claude Code in your project directory"
  echo "  3. Type: /start"
  echo ""
  echo "  Read foundation/ONBOARDING.md for a full walkthrough."
else
  printf "${C_YELLOW}  Installation completed with missing files.${C_RESET}\n"
  printf "${C_YELLOW}  Check the MISSING items above and re-run.${C_RESET}\n"
fi

info "============================================"
echo ""

# == Step 9: Auto-run verification ==========================================

if $all_ok; then
  verify_script="$SCRIPT_DIR/verify.sh"
  if [[ -f "$verify_script" ]]; then
    echo ""
    info "Running verification (structural + execution + smoke tests)..."
    if bash "$verify_script" --install-root "$INSTALL_ROOT"; then
      exit 0
    else
      echo ""
      printf "${C_YELLOW}============================================${C_RESET}\n"
      printf "${C_YELLOW}  Install completed, but verification found issues.${C_RESET}\n"
      printf "${C_YELLOW}  Re-run verify.sh after fixing:${C_RESET}\n"
      printf "${C_YELLOW}    %s --install-root %s${C_RESET}\n" "$verify_script" "$INSTALL_ROOT"
      printf "${C_YELLOW}============================================${C_RESET}\n"
      echo ""
      exit 2
    fi
  fi
fi
