#!/bin/bash
# uninstall.sh
# Syntaris v0.5.3: Remove Syntaris-owned files from this machine.
#
# What this REMOVES:
#   - $INSTALL_ROOT/skills/   (all skills)
#   - $INSTALL_ROOT/hooks/    (all hooks)
#   - $INSTALL_ROOT/agents/   (all subagents)
#   - $INSTALL_ROOT/settings.json (restored from .bak if present)
#   - $INSTALL_ROOT/state/skill-log.jsonl (telemetry log)
#
# What this PRESERVES:
#   - $SYNTARIS_ROOT/foundation/ (template files; may have project-side edits)
#   - $SYNTARIS_ROOT/foundation/ (template files)
#   - Any per-project foundation files (CONTRACT.md etc inside real projects)
#   - personal-overlay/owner-config.md (your personal config)
#   - Hook error logs in $TMPDIR (they auto-expire)
#
# Usage:
#   ./uninstall.sh
#   ./uninstall.sh --install-root ~/.claude
#   ./uninstall.sh --yes          # skip confirmation
#   ./uninstall.sh --dry-run      # show what would be removed
#
# Platform note: this removes the Syntaris install on the side of the
# filesystem it's run from. If you installed on both Windows and WSL,
# run the appropriate uninstaller on each side.

set -u

INSTALL_ROOT="${HOME}/.claude"
SYNTARIS_ROOT="${HOME}/Syntaris"
ASSUME_YES=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root) INSTALL_ROOT="$2"; shift 2 ;;
    --syntaris-root) SYNTARIS_ROOT="$2"; shift 2 ;;
    --blueprint-root) SYNTARIS_ROOT="$2"; shift 2 ;;  # back-compat alias
    --yes|-y) ASSUME_YES=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      cat <<EOF
Syntaris Uninstaller

Usage:
  ./uninstall.sh [options]

Options:
  --install-root DIR     Claude Code config dir (default: ~/.claude)
  --syntaris-root DIR    Foundation templates dir (default: ~/Syntaris). Alias: --blueprint-root
  --yes, -y              Skip confirmation prompt
  --dry-run              Show what would be removed without removing it

This removes Syntaris-owned files only. Your personal overlay, foundation
templates, and per-project Syntaris files are preserved. Hook error logs
in \$TMPDIR auto-expire.
EOF
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -t 1 ]]; then
  C_CYAN='\033[0;36m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'; C_RESET='\033[0m'
else
  C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

echo ""
printf "${C_CYAN}============================================${C_RESET}\n"
printf "${C_CYAN}  Syntaris Uninstaller${C_RESET}\n"
printf "${C_CYAN}============================================${C_RESET}\n"

# --- Enumerate what will be removed ---

to_remove=()
to_restore=""

if [[ -d "$INSTALL_ROOT/skills" ]]; then to_remove+=("$INSTALL_ROOT/skills"); fi
if [[ -d "$INSTALL_ROOT/hooks" ]]; then to_remove+=("$INSTALL_ROOT/hooks"); fi
if [[ -d "$INSTALL_ROOT/agents" ]]; then to_remove+=("$INSTALL_ROOT/agents"); fi
if [[ -f "$INSTALL_ROOT/settings.json" ]]; then to_remove+=("$INSTALL_ROOT/settings.json"); fi
if [[ -d "$INSTALL_ROOT/state" ]]; then to_remove+=("$INSTALL_ROOT/state"); fi
if [[ -f "$INSTALL_ROOT/settings.json.bak" ]]; then to_restore="$INSTALL_ROOT/settings.json.bak"; fi

if [[ ${#to_remove[@]} -eq 0 && -z "$to_restore" ]]; then
  printf "${C_YELLOW}Nothing to remove. Syntaris does not appear to be installed at:${C_RESET}\n"
  printf "  $INSTALL_ROOT\n"
  exit 0
fi

echo ""
echo "The following will be REMOVED:"
for path in "${to_remove[@]}"; do
  size=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
  printf "  - %s  (%s)\n" "$path" "${size:-?}"
done

echo ""
echo "The following will be PRESERVED:"
printf "  - $SYNTARIS_ROOT/foundation/   (template files)\n"
printf "  - personal-overlay/owner-config.md (your personal config, if any)\n"
printf "  - Any project-side Syntaris files (CONTRACT.md etc in your projects)\n"

if [[ -n "$to_restore" ]]; then
  echo ""
  printf "${C_GREEN}A settings.json.bak was found and will be restored after removal.${C_RESET}\n"
fi

if $DRY_RUN; then
  echo ""
  printf "${C_CYAN}DRY RUN: nothing removed.${C_RESET}\n"
  exit 0
fi

# --- Confirm ---

if ! $ASSUME_YES; then
  echo ""
  printf "${C_YELLOW}Proceed with uninstall? [y/N]: ${C_RESET}"
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# --- Execute ---

echo ""
for path in "${to_remove[@]}"; do
  rm -rf "$path"
  printf "  ${C_GREEN}removed:${C_RESET} %s\n" "$path"
done

if [[ -n "$to_restore" ]]; then
  mv "$to_restore" "$INSTALL_ROOT/settings.json"
  printf "  ${C_GREEN}restored:${C_RESET} settings.json from .bak\n"
fi

echo ""
printf "${C_GREEN}Syntaris uninstalled from: $INSTALL_ROOT${C_RESET}\n"
echo ""
printf "${C_YELLOW}If you installed Syntaris on both Windows and WSL sides of this${C_RESET}\n"
printf "${C_YELLOW}machine, run the uninstaller on the other side as well.${C_RESET}\n"
echo ""
