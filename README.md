# Codex + Claude Skills

Reusable skills for both Codex and Claude Code, organized so contributors can add, review, and install skills consistently.

## Layout

- `skills/codex/<skill-name>/...`
- `skills/claude/<skill-name>/...`
- `skills/INDEX.md` maps shared concepts (for example `audit`) to runtime-specific implementations.

## Quick Start

1. Create a skill scaffold:
   - `bash scripts/new-skill.sh my-skill codex --scripts --references`
   - `bash scripts/new-skill.sh my-skill claude --scripts --references`
   - `bash scripts/new-skill.sh my-skill both --scripts --references`
2. Validate:
   - `bash scripts/validate-skills.sh`
3. Install locally:
   - `bash scripts/install-skills.sh codex`
   - `bash scripts/install-skills.sh claude`
   - `bash scripts/install-skills.sh all`
4. Use symlink mode during active development:
   - `bash scripts/install-skills.sh codex link`
   - `bash scripts/install-skills.sh claude link`

## Conventions

- Skill folder name must match frontmatter `name`.
- Use lowercase letters, digits, and hyphens only.
- Keep `SKILL.md` focused; put long details in `references/`.
- Keep Codex and Claude skills aligned in intent even when syntax differs.

## Repository Files

- `scripts/new-skill.sh` creates skill scaffolds.
- `scripts/install-skills.sh` installs skills into runtime directories.
- `scripts/validate-skills.sh` validates skill metadata.
- `.github/workflows/validate-skills.yml` runs validation in CI.

## Publish to GitHub

```bash
git add .
git commit -m "Initial skills repo"
git branch -M main
gh repo create <YOUR_REPO_NAME> --private --source=. --remote=origin --push
```

Or manually:

```bash
git remote add origin git@github.com:<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
git push -u origin main
```
