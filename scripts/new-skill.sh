#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <skill-name> <codex|claude|both> [--scripts] [--references] [--assets]"
  exit 1
fi

skill_name="$1"
runtime="$2"
shift 2

if [[ ! "$skill_name" =~ ^[a-z0-9-]+$ ]]; then
  echo "Skill name must use lowercase letters, digits, and hyphens only"
  exit 1
fi

if [[ "$runtime" != "codex" && "$runtime" != "claude" && "$runtime" != "both" ]]; then
  echo "Runtime must be one of: codex, claude, both"
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

create_scripts=false
create_references=false
create_assets=false

for arg in "$@"; do
  case "$arg" in
    --scripts) create_scripts=true ;;
    --references) create_references=true ;;
    --assets) create_assets=true ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

create_skill() {
  local target_runtime="$1"
  local skill_dir="$repo_root/skills/$target_runtime/$skill_name"

  if [[ -e "$skill_dir" ]]; then
    echo "Skill already exists: $skill_dir"
    exit 1
  fi

  mkdir -p "$skill_dir"

  if [[ "$target_runtime" == "codex" ]]; then
    mkdir -p "$skill_dir/agents"
    cat > "$skill_dir/agents/openai.yaml" <<EOT
display_name: "TODO"
short_description: "TODO"
default_prompt: "TODO"
EOT
  fi

  $create_scripts && mkdir -p "$skill_dir/scripts"
  $create_references && mkdir -p "$skill_dir/references"
  $create_assets && mkdir -p "$skill_dir/assets"

  if [[ "$target_runtime" == "claude" ]]; then
    cat > "$skill_dir/SKILL.md" <<EOT
---
name: $skill_name
description: TODO - Describe what this skill does and exactly when to use it.
argument-hint: [optional-arguments]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Glob, Grep, Edit, Task
---

# $skill_name

## Workflow

1. Define the task and expected output.
2. Use bundled scripts/references/assets as needed.
3. Validate output before returning it.
EOT
  else
    cat > "$skill_dir/SKILL.md" <<EOT
---
name: $skill_name
description: TODO - Describe what this skill does and exactly when to use it.
---

# $skill_name

## Workflow

1. Define the task and expected output.
2. Use bundled scripts/references/assets as needed.
3. Validate output before returning it.
EOT
  fi

  echo "Created $target_runtime skill scaffold at $skill_dir"
}

if [[ "$runtime" == "both" ]]; then
  create_skill codex
  create_skill claude
else
  create_skill "$runtime"
fi
