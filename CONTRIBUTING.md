# Contributing

## Workflow

1. Create or update a skill under `skills/codex` and/or `skills/claude`.
2. Keep skill naming and frontmatter consistent.
3. Run local validation:
   - `bash scripts/validate-skills.sh`
4. Open a pull request with a concise summary.

## Skill Requirements

- Folder name must match `name` in `SKILL.md`.
- `description` in frontmatter must clearly state trigger conditions.
- Keep procedural instructions in `SKILL.md`; move bulky details to `references/`.

## Review Checklist

- Does the change preserve or improve skill clarity?
- Is the same conceptual skill represented correctly across runtimes?
- Do scripts and paths referenced in the skill actually exist?
