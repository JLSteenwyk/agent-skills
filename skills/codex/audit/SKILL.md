---
name: audit
description: Run N parallel Codex audits of the current repository and compare results democratically. Use when the user wants a codebase audit (quality, architecture, generators, testing, security, performance, maintainability).
---

# Parallel Codebase Audit (Codex)

Use this skill when the user wants many independent audits of the same codebase and prompt.

## Workflow

1. Understand the codebase quickly.
- Inspect structure and key files so the audit prompt is project-specific.
- Reference real paths, patterns, and technologies in the prompt.

2. Determine audit focus.
- Use the user-provided focus.
- If the focus is unclear, ask one short clarification question before generating the script.

3. Build one fixed audit prompt.
- The exact prompt must be reused across all runs.
- Ask for concrete findings with file references.
- Require this ending structure in each result:
  - `THE SINGLE MOST IMPACTFUL NEXT STEP`
  - `RANKED TOP-5 NEXT STEPS`

4. Create `audit.sh` in repo root.
- Use Codex non-interactive runs with controlled parallelism.
- Defaults (confirm with user before changing):
  - `ITERATIONS=20`
  - `PARALLELISM=10`
- Save outputs to `audit_results/<timestamp>/audit_XX.md`.

Use this script template:

```bash
#!/usr/bin/env bash
set -euo pipefail

PARALLELISM="${AUDIT_PARALLELISM:-10}"
ITERATIONS="${AUDIT_ITERATIONS:-20}"
RESULTS_DIR="audit_results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="${RESULTS_DIR}/${TIMESTAMP}"

mkdir -p "${RUN_DIR}"

read -r -d '' PROMPT << 'AUDIT_PROMPT_EOF' || true
<THE AUDIT PROMPT GOES HERE>
AUDIT_PROMPT_EOF

echo "============================================================"
echo " Codebase Audit (Codex)"
echo "============================================================"
echo " Focus       : <audit focus>"
echo " Iterations  : ${ITERATIONS}"
echo " Parallelism : ${PARALLELISM}"
echo " Output dir  : ${RUN_DIR}"
echo "============================================================"
echo ""

running=0
for i in $(seq -w 1 "${ITERATIONS}"); do
    outfile="${RUN_DIR}/audit_${i}.md"
    echo "[$(date +%H:%M:%S)] Launching audit ${i}/${ITERATIONS} -> ${outfile}"
    codex exec \
      --skip-git-repo-check \
      --sandbox workspace-write \
      -C "$(pwd)" \
      "$PROMPT" > "${outfile}" 2>&1 &

    running=$((running + 1))
    if [ "${running}" -ge "${PARALLELISM}" ]; then
        wait -n 2>/dev/null || true
        running=$((running - 1))
    fi
done

echo ""
echo "[$(date +%H:%M:%S)] All ${ITERATIONS} audits launched. Waiting for completion..."
wait
echo "[$(date +%H:%M:%S)] All audits complete."
echo ""

completed=0
failed=0
for f in "${RUN_DIR}"/audit_*.md; do
    if [ -s "${f}" ]; then
        completed=$((completed + 1))
    else
        failed=$((failed + 1))
    fi
done

echo "============================================================"
echo " Results saved to: ${RUN_DIR}/"
echo "============================================================"
echo " Completed : ${completed}"
echo " Failed    : ${failed}"
echo ""
echo "Extract single top recommendations:"
echo "  grep -A 6 'THE SINGLE MOST IMPACTFUL NEXT STEP' ${RUN_DIR}/audit_*.md"
echo ""
echo "Extract ranked top-5 sections:"
echo "  grep -A 20 'RANKED TOP-5 NEXT STEPS' ${RUN_DIR}/audit_*.md"
```

5. Finalize.
- `chmod +x audit.sh`
- Ask the user whether to run it now.

## Guardrails

- Keep the prompt identical across all iterations.
- Keep the prompt self-contained; each run starts fresh.
- Do not produce vague advice; request actionable recommendations with file paths and severity.
