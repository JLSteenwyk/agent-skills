#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="${1:-all}"
MODE="${2:-copy}"

usage() {
  echo "Usage: $0 <codex|claude|all> [copy|link]"
}

if [[ "$RUNTIME" != "codex" && "$RUNTIME" != "claude" && "$RUNTIME" != "all" ]]; then
  usage
  exit 1
fi

if [[ "$MODE" != "copy" && "$MODE" != "link" ]]; then
  usage
  exit 1
fi

install_runtime() {
  local runtime="$1"
  local source_dir="$REPO_ROOT/skills/$runtime"
  local target_dir

  if [[ "$runtime" == "codex" ]]; then
    target_dir="${CODEX_HOME:-$HOME/.codex}/skills"
  else
    target_dir="${CLAUDE_HOME:-$HOME/.claude}/skills"
  fi

  if [[ ! -d "$source_dir" ]]; then
    echo "skip $runtime (missing $source_dir)"
    return
  fi

  mkdir -p "$target_dir"

  for skill_dir in "$source_dir"/*; do
    [[ -d "$skill_dir" ]] || continue

    local name
    local dst
    name="$(basename "$skill_dir")"

    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
      echo "skip $runtime/$name (missing SKILL.md)"
      continue
    fi

    dst="$target_dir/$name"
    rm -rf "$dst"

    if [[ "$MODE" == "link" ]]; then
      ln -s "$skill_dir" "$dst"
      echo "linked $runtime/$name -> $dst"
    else
      cp -R "$skill_dir" "$dst"
      echo "copied $runtime/$name -> $dst"
    fi
  done

  echo "Installed $runtime skills to $target_dir"
}

if [[ "$RUNTIME" == "all" ]]; then
  install_runtime codex
  install_runtime claude
else
  install_runtime "$RUNTIME"
fi
