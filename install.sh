#!/bin/bash
# install.sh
# Syntaris Installer for macOS and Linux
#
# Usage:
#   ./install.sh
#   ./install.sh --personal-config ./personal-overlay/owner-config.md
#   ./install.sh --install-root ~/.claude --syntaris-root ~/Syntaris
#   ./install.sh --zip /path/to/syntaris-v0.3.0.zip
#
# Supports two source modes:
#   A) Cloned from GitHub: run from repo root, no zip.
#   B) Packaged zip: extract first, then install.

set -e  # exit on error

# == Defaults ================================================================

ZIP_PATH="./syntaris-v0.3.0.zip"
INSTALL_ROOT="$HOME/.claude"
SYNTARIS_ROOT="$HOME/Syntaris"
PERSONAL_CONFIG=""
ASSUME_YES=false
TARGET=""              # If empty, auto-detect via .claude/lib/detect-runtime.sh

# == Parse args ==============================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --zip)              ZIP_PATH="$2"; shift 2 ;;
    --install-root)     INSTALL_ROOT="$2"; shift 2 ;;
    --syntaris-root)    SYNTARIS_ROOT="$2"; shift 2 ;;
    --blueprint-root)   SYNTARIS_ROOT="$2"; shift 2 ;;  # back-compat alias
    --personal-config)  PERSONAL_CONFIG="$2"; shift 2 ;;
    --target)           TARGET="$2"; shift 2 ;;
    --yes|-y)           ASSUME_YES=true; shift ;;
    -h|--help)
      cat <<EOF
Syntaris Installer (macOS / Linux / WSL)

Options:
  --zip <path>              Path to syntaris-v0.3.0.zip (default: ./syntaris-v0.3.0.zip)
  --install-root <dir>      Claude Code config dir (default: ~/.claude)
  --syntaris-root <dir>     Foundation templates dir (default: ~/Syntaris). Alias: --blueprint-root
  --personal-config <file>  Path to owner-config.md for variable substitution
  --target <name>           Runtime target. One of:
                              claude-code  (Tier 1, full enforcement, default if Claude Code detected)
                              cursor       (Tier 2, partial enforcement)
                              windsurf     (Tier 2, partial enforcement)
                              codex-cli    (Tier 3, advisory only)
                              gemini-cli   (Tier 3, advisory only)
                              aider        (Tier 3, advisory only)
                              kiro         (Tier 3, advisory only)
                              opencode     (Tier 3, advisory only)
                            If omitted, auto-detect via .claude/lib/detect-runtime.sh.
  --yes, -y                 Skip the pre-install confirmation prompt

If you cloned this repo from GitHub, run this script from the repo root.
If you have a distributable zip, point --zip at it.

This installer CLOBBERS any existing Syntaris install at --install-root.
If you have personally edited Syntaris skills or settings.json, back them
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

# == Target detection and tier mapping ======================================

# If TARGET wasn't passed on command line, try to auto-detect from environment.
# detect-runtime.sh lives inside the source dir, so we may need to delay this
# until we know SCRIPT_DIR. For now, do a lightweight inline detection.

if [[ -z "$TARGET" ]]; then
  if [[ -n "${CLAUDE_CODE:-}" ]] || [[ -n "${ANTHROPIC_CLAUDE_CODE:-}" ]]; then
    TARGET="claude-code"
  elif [[ -n "${CURSOR_USER:-}" ]] || [[ -d ".cursor" ]] || [[ -f ".cursorrules" ]]; then
    TARGET="cursor"
  elif [[ -n "${WINDSURF_USER:-}" ]] || [[ -d ".windsurf" ]]; then
    TARGET="windsurf"
  elif [[ -f ".codex/config.toml" ]] || [[ -n "${CODEX_HOME:-}" ]]; then
    TARGET="codex-cli"
  elif [[ -d ".gemini" ]]; then
    TARGET="gemini-cli"
  elif [[ -n "${AIDER_MODEL:-}" ]] || [[ -f ".aider.conf.yml" ]]; then
    TARGET="aider"
  elif [[ -n "${KIRO_HOME:-}" ]] || [[ -d ".kiro" ]]; then
    TARGET="kiro"
  elif [[ -d ".opencode" ]] || [[ -f "opencode.json" ]]; then
    TARGET="opencode"
  else
    TARGET="claude-code"  # default if nothing detected
    AUTO_DETECT_FALLBACK=true
  fi
fi

# Map target to tier for downstream logic
case "$TARGET" in
  claude-code)              TIER=1 ;;
  cursor|windsurf)          TIER=2 ;;
  codex-cli|gemini-cli|aider|kiro|opencode)  TIER=3 ;;
  *) echo "Unknown target: $TARGET. Use --help to see valid targets." >&2; exit 1 ;;
esac

echo ""
info "============================================"
info "  Syntaris Installer (macOS / Linux)"
info "  AI App Building Methodology"
info "============================================"
echo ""
info "  Target:  $TARGET (Tier $TIER)"
case "$TIER" in
  1) info "  Mode:    Full enforcement (hooks, skills, agents, memory)" ;;
  2) info "  Mode:    Partial enforcement (rules + auto-applied context, no hooks)" ;;
  3) info "  Mode:    Advisory only (methodology as text, honor system)" ;;
esac
if [[ "${AUTO_DETECT_FALLBACK:-false}" == "true" ]]; then
  warn "Could not detect harness from environment. Defaulting to claude-code."
  warn "Override with --target if you're using a different runtime."
fi
echo ""

# == Step 1: Locate source (clone or zip) ===================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USED_ZIP=false

if [[ -d "$SCRIPT_DIR/.claude" ]]; then
  SRC_ROOT="$SCRIPT_DIR"
  printf "${C_GREEN}Installing from cloned repo at: %s${C_RESET}\n" "$SRC_ROOT"
elif [[ -f "$ZIP_PATH" ]]; then
  TMP_DIR="$(mktemp -d -t syntaris-install.XXXXXX)"
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
  err "Cannot locate Syntaris source."
  echo "Expected one of:" >&2
  echo "  - A .claude/ directory next to this installer (clone mode)" >&2
  echo "  - A syntaris-v0.3.0.zip at: $ZIP_PATH (zip mode)" >&2
  echo "" >&2
  echo "If you cloned from GitHub, run this installer from the repo root." >&2
  echo "If you have a zip, specify: --zip /path/to/syntaris-v0.3.0.zip" >&2
  exit 1
fi

# == Step 1.5: Tier 2/3 install branch ======================================
# Tier 1 (Claude Code) continues to the full install. Tier 2/3 take a separate
# path that emits target-native config and exits.

if [[ "$TIER" != "1" ]]; then
  TARGET_DIR="$SRC_ROOT/targets/$TARGET"
  if [[ ! -d "$TARGET_DIR" ]]; then
    err "Target directory not found: $TARGET_DIR"
    err "This installer ships v0.3.0 with scaffold READMEs for Tier 2/3 targets."
    err "Per BUILD_NEXT.md, full adapter logic for $TARGET is pending validation."
    exit 1
  fi

  info "Step 1.5: Installing Tier $TIER adapter for $TARGET"
  echo ""

  # All tiers get foundation templates copied to project root
  if [[ -d "$SRC_ROOT/foundation" ]]; then
    cp -r "$SRC_ROOT/foundation" ./
    ok "Copied foundation/ to project root"
  fi

  case "$TARGET" in
    cursor)
      mkdir -p .cursor/rules
      # In v0.3.0, this writes a placeholder. Claude Code on the user's machine
      # populates the full rules translation per BUILD_NEXT.md.
      cat > .cursor/rules/syntaris-core.mdc << 'CURSOR_EOF'
---
description: Syntaris methodology rules
alwaysApply: true
---

# Syntaris (Tier 2 - Cursor)

Foundation files at foundation/ define the project contract, decisions, errors,
and memory. Read them before any non-trivial edit.

The five approval words gate work: CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED,
FRONTEND APPROVED, GO. Do not advance phases without an explicit approval word
in the chat.

Skills documented in .claude/skills/*/SKILL.md describe phase-specific behavior.
This Cursor adapter loads the canonical SKILL.md contents as advisory rules.
Full rules translation is pending per BUILD_NEXT.md.
CURSOR_EOF
      ok "Wrote .cursor/rules/syntaris-core.mdc placeholder"
      warn "Full rules translation pending. See BUILD_NEXT.md task: 'Populate Cursor rules'"
      ;;
    windsurf)
      mkdir -p .windsurf/rules
      echo "# Syntaris (Tier 2 - Windsurf) - placeholder, see BUILD_NEXT.md" > .windsurf/rules/syntaris-core.md
      ok "Wrote .windsurf/rules/syntaris-core.md placeholder"
      warn "Full rules translation pending"
      ;;
    codex-cli)
      cat > AGENTS.md << 'AGENTS_EOF'
# Syntaris Methodology (Tier 3 advisory, Codex CLI)

This project uses the Syntaris methodology. Foundation files in foundation/
contain the project contract, decisions log, errors log, and memory.

Read foundation/CONTRACT.md before any non-trivial edit. Respect the five
approval words: CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED, FRONTEND APPROVED,
GO. These gate phase advancement.

Full Syntaris methodology is documented at github.com/brianonieal/Syntaris.
This file is an advisory summary; for the full skill set, see .claude/skills/.
AGENTS_EOF
      ok "Wrote AGENTS.md for Codex CLI"
      ;;
    gemini-cli)
      mkdir -p .gemini
      echo "# Syntaris (Tier 3 advisory, Gemini CLI) - see foundation/ and .claude/skills/" > .gemini/GEMINI.md
      ok "Wrote .gemini/GEMINI.md"
      ;;
    aider)
      cat > .aider.syntaris.md << 'AIDER_EOF'
# Syntaris Methodology (Tier 3 advisory, Aider)

Foundation files at foundation/ define project contract and memory.
Read foundation/CONTRACT.md before non-trivial edits.
Respect the five approval words: CONFIRMED, ROADMAP APPROVED, MOCKUPS APPROVED,
FRONTEND APPROVED, GO.
AIDER_EOF
      ok "Wrote .aider.syntaris.md"
      warn "Add 'read: .aider.syntaris.md' to your .aider.conf.yml manually"
      ;;
    kiro)
      mkdir -p .kiro/specs
      echo "# Syntaris Methodology (Tier 3 advisory, Kiro) - see foundation/" > .kiro/specs/syntaris-methodology.md
      ok "Wrote .kiro/specs/syntaris-methodology.md"
      ;;
    opencode)
      mkdir -p .opencode/instructions
      echo "# Syntaris Methodology (Tier 3 advisory, OpenCode) - see foundation/" > .opencode/instructions/INSTRUCTIONS.md
      ok "Wrote .opencode/instructions/INSTRUCTIONS.md"
      ;;
  esac

  echo ""
  info "Tier $TIER install complete for $TARGET."
  info "See docs/COMPATIBILITY.md for what's enforced vs advisory."
  info "Full adapter logic for Tier 2/3 targets is pending validation per BUILD_NEXT.md."
  exit 0
fi

# Below this line: Tier 1 (Claude Code) full install

# == Step 2: Detect existing install and confirm clobber ====================

existing_detected=false
if [[ -d "$INSTALL_ROOT/skills" ]] || [[ -d "$INSTALL_ROOT/hooks" ]] \
   || [[ -d "$INSTALL_ROOT/agents" ]] || [[ -f "$INSTALL_ROOT/settings.json" ]]; then
  existing_detected=true
fi

if $existing_detected; then
  echo ""
  warn "Existing Syntaris install detected at: $INSTALL_ROOT"
  warn "Continuing will CLOBBER:"
  [[ -d "$INSTALL_ROOT/skills" ]] && warn "  - all files under $INSTALL_ROOT/skills/"
  [[ -d "$INSTALL_ROOT/hooks" ]]  && warn "  - all files under $INSTALL_ROOT/hooks/"
  [[ -d "$INSTALL_ROOT/agents" ]] && warn "  - all files under $INSTALL_ROOT/agents/"
  [[ -f "$INSTALL_ROOT/settings.json" ]] && warn "  - settings.json (backed up to .bak first)"
  warn "Any files you've personally edited will be overwritten."
  echo ""
  warn "Preserved: foundation templates at $SYNTARIS_ROOT, per-project files,"
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

  # Clobber cleanly so stale files from prior versions don't linger
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
info "Installing foundation templates to: $SYNTARIS_ROOT"
mkdir -p "$SYNTARIS_ROOT/foundation"

for md_file in "$SRC_ROOT/foundation/"*.md; do
  [[ -f "$md_file" ]] || continue
  name="$(basename "$md_file")"
  cp -f "$md_file" "$SYNTARIS_ROOT/foundation/$name"
  ok "foundation/$name"
done

# Copy meta files
cp -f "$0" "$SYNTARIS_ROOT/install.sh" 2>/dev/null || true
[[ -f "$SRC_ROOT/README.md" ]] && cp -f "$SRC_ROOT/README.md" "$SYNTARIS_ROOT/"
[[ -f "$SRC_ROOT/LICENSE" ]] && cp -f "$SRC_ROOT/LICENSE" "$SYNTARIS_ROOT/"
[[ -f "$SRC_ROOT/CHANGELOG.md" ]] && cp -f "$SRC_ROOT/CHANGELOG.md" "$SYNTARIS_ROOT/"

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
      "$SYNTARIS_ROOT/foundation"
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
  if [[ -d "$SYNTARIS_ROOT/foundation" ]]; then
    ph_count=$(find "$SYNTARIS_ROOT/foundation" -type f -name "*.md" \
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
  "debug" "research" "billing"
  "health" "rollback"
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

# == Step 7: Clean up =======================================================

if $USED_ZIP && [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
  rm -rf "$TMP_DIR"
fi

# == Step 8: Summary ========================================================

echo ""
info "============================================"

if $all_ok; then
  printf "${C_GREEN}  Syntaris installed successfully!${C_RESET}\n"
  echo ""
  echo "  Skills:     $INSTALL_ROOT/skills/ (14 skills)"
  echo "  Hooks:      $INSTALL_ROOT/hooks/ (10 hooks + 1 wrapper, bash + PowerShell)"
  echo "  Agents:     $INSTALL_ROOT/agents/ (7 subagents)"
  echo "  Settings:   $INSTALL_ROOT/settings.json"
  echo "  Foundation: $SYNTARIS_ROOT/foundation/ (22 templates)"
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
