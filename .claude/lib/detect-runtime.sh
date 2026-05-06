#!/usr/bin/env bash
# detect-runtime.sh
# Detects which AI coding harness Syntaris is running inside.
# Echoes one of: claude-code | cursor | windsurf | codex-cli | gemini-cli | aider | kiro | opencode | unknown
# Usage: bash .claude/lib/detect-runtime.sh

# Strategy: probe environment variables, parent process names, and known config files.
# This is a heuristic. Not all runtimes set identifiable env vars yet.
# When detection is ambiguous, fall through to "unknown" rather than guessing.

# Anthropic Claude Code sets CLAUDE_CODE=1 in v2.0+ sessions.
if [[ -n "${CLAUDE_CODE:-}" ]] || [[ -n "${ANTHROPIC_CLAUDE_CODE:-}" ]]; then
  echo "claude-code"
  exit 0
fi

# Cursor sets CURSOR_USER and ships with .cursor/ project config.
if [[ -n "${CURSOR_USER:-}" ]] || [[ -d ".cursor" ]] || [[ -f ".cursorrules" ]]; then
  echo "cursor"
  exit 0
fi

# Windsurf (Codeium's harness) sets WINDSURF_USER.
if [[ -n "${WINDSURF_USER:-}" ]] || [[ -d ".windsurf" ]]; then
  echo "windsurf"
  exit 0
fi

# Codex CLI ships .codex/config.toml and respects AGENTS.md.
if [[ -f ".codex/config.toml" ]] || [[ -n "${CODEX_HOME:-}" ]]; then
  echo "codex-cli"
  exit 0
fi

# Gemini CLI ships .gemini/ config directory.
if [[ -d ".gemini" ]] || [[ -n "${GEMINI_API_KEY:-}" && -n "${GEMINI_CLI_HOME:-}" ]]; then
  echo "gemini-cli"
  exit 0
fi

# Aider runs as Python; not easy to detect from env. Falls through to unknown.
# Future: detect parent process name = "aider".

# Kiro (Amazon's harness) sets KIRO_HOME.
if [[ -n "${KIRO_HOME:-}" ]] || [[ -d ".kiro" ]]; then
  echo "kiro"
  exit 0
fi

# OpenCode harness ships .opencode/ config.
if [[ -d ".opencode" ]] || [[ -f "opencode.json" ]]; then
  echo "opencode"
  exit 0
fi

# Aider check (after Kiro/OpenCode since they're more deterministic)
if [[ -n "${AIDER_MODEL:-}" ]] || [[ -f ".aider.conf.yml" ]] || [[ -f ".aider.input.history" ]]; then
  echo "aider"
  exit 0
fi

# Last fallback: try to detect from parent process if shell allows.
# This is unreliable across platforms; only attempt if ps is available.
if command -v ps >/dev/null 2>&1; then
  PARENT_PROC=$(ps -o comm= -p $PPID 2>/dev/null || echo "")
  case "$PARENT_PROC" in
    *claude-code*|*claude*) echo "claude-code"; exit 0 ;;
    *cursor*) echo "cursor"; exit 0 ;;
    *windsurf*) echo "windsurf"; exit 0 ;;
    *codex*) echo "codex-cli"; exit 0 ;;
    *gemini*) echo "gemini-cli"; exit 0 ;;
    *aider*) echo "aider"; exit 0 ;;
    *opencode*) echo "opencode"; exit 0 ;;
  esac
fi

echo "unknown"
exit 0
