#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIMES=(codex claude)

errors=0

validate_skill_file() {
  local runtime="$1"
  local skill="$2"
  local name file declared_name

  name="$(basename "$skill")"
  file="$skill/SKILL.md"

  if [[ ! -f "$file" ]]; then
    echo "ERROR: $runtime/$name is missing SKILL.md"
    errors=1
    return
  fi

  if ! grep -q '^---$' "$file"; then
    echo "ERROR: $runtime/$name SKILL.md missing YAML frontmatter delimiters"
    errors=1
  fi

  if ! grep -Eq '^name:[[:space:]]*[a-z0-9-]+$' "$file"; then
    echo "ERROR: $runtime/$name SKILL.md missing valid name field"
    errors=1
  fi

  if ! grep -Eq '^description:[[:space:]]*.+$' "$file"; then
    echo "ERROR: $runtime/$name SKILL.md missing description field"
    errors=1
  fi

  declared_name="$(grep -E '^name:' "$file" | head -n1 | sed -E 's/^name:[[:space:]]*//')"
  if [[ "$declared_name" != "$name" ]]; then
    echo "ERROR: $runtime/$name folder does not match name: $declared_name"
    errors=1
  fi

  if [[ "$runtime" == "codex" && ! -f "$skill/agents/openai.yaml" ]]; then
    echo "WARN: $runtime/$name missing agents/openai.yaml"
  fi
}

for runtime in "${RUNTIMES[@]}"; do
  runtime_dir="$REPO_ROOT/skills/$runtime"

  if [[ ! -d "$runtime_dir" ]]; then
    echo "WARN: missing runtime directory $runtime_dir"
    continue
  fi

  for skill in "$runtime_dir"/*; do
    [[ -d "$skill" ]] || continue
    validate_skill_file "$runtime" "$skill"
  done
done

if [[ $errors -ne 0 ]]; then
  echo "Validation failed"
  exit 1
fi

echo "All skills validated"
