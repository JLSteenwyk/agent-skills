---
name: audit
description: Run N parallel Claude Code audits of the codebase and collect results for democratic comparison. Use when the user wants to audit code quality, generators, architecture, or any other aspect of the project.
argument-hint: [audit-focus-description]
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Glob, Grep, Edit, Task
---

# Parallel Codebase Audit Skill

The user wants to run a parallel audit of this codebase. Your job is to:

1. **Understand the codebase** — Quickly explore the project structure, key files, and purpose so you can write a targeted audit prompt.

2. **Determine the audit focus** — The user's requested focus is: `$ARGUMENTS`. If no arguments were provided, ask the user what aspect of the codebase they want audited.

3. **Write a detailed, structured audit prompt** — Craft a thorough audit prompt tailored to this specific codebase and the requested focus. The prompt MUST:
   - Be specific to the project (reference actual directories, files, patterns found in the repo)
   - Cover multiple dimensions relevant to the focus area
   - End with two sections:
     - "THE SINGLE MOST IMPACTFUL NEXT STEP" — forces each audit to commit to one priority
     - "RANKED TOP-5 NEXT STEPS" — provides a ranked list for democratic comparison across runs
   - Request structured markdown output with clear headers

4. **Generate and run the audit shell script** — Create a bash script called `audit.sh` in the project root that:
   - Stores the prompt in a heredoc variable
   - Runs `claude -p "${PROMPT}" --output-format text --max-turns 1` N times with controlled parallelism
   - Saves each result to `audit_results/<timestamp>/audit_XX.md`
   - Prints a summary when done (completed/failed counts, helper grep commands)
   - Uses these defaults (ask the user if they want to change them):
     - Iterations: 20
     - Parallelism: 10

   **Script template:**
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
   echo " Codebase Audit"
   echo "============================================================"
   echo " Focus       : <audit focus>"
   echo " Iterations  : ${ITERATIONS}"
   echo " Parallelism : ${PARALLELISM}"
   echo " Output dir  : ${RUN_DIR}"
   echo "============================================================"
   echo ""

   # ── Progress tracking function ──────────────────────────────────────────
   print_progress() {
       local done=0
       local errs=0
       local in_flight=0
       local files
       files=$(ls "${RUN_DIR}"/audit_*.md 2>/dev/null) || true
       for f in ${files}; do
           [ -f "${f}" ] || continue
           local sz
           sz=$(wc -c < "${f}" 2>/dev/null || echo 0)
           if [ "${sz}" -gt 1000 ]; then
               done=$((done + 1))
           elif [ "${sz}" -gt 0 ]; then
               errs=$((errs + 1))
           else
               in_flight=$((in_flight + 1))
           fi
       done
       printf "\r[$(date +%H:%M:%S)] Progress: %d/%d complete | %d errors | %d in-flight   " \
           "${done}" "${ITERATIONS}" "${errs}" "${in_flight}"
   }

   # ── Launch audits ─────────────────────────────────────────────────────────
   running=0
   for i in $(seq -w 1 "${ITERATIONS}"); do
       outfile="${RUN_DIR}/audit_${i}.md"
       echo "[$(date +%H:%M:%S)] Launching audit ${i}/${ITERATIONS}"
       claude -p "${PROMPT}" --output-format text --max-turns 1 > "${outfile}" 2>&1 &
       running=$((running + 1))
       if [ "${running}" -ge "${PARALLELISM}" ]; then
           wait -n 2>/dev/null || true
           running=$((running - 1))
           print_progress
       fi
   done

   echo ""
   echo "[$(date +%H:%M:%S)] All ${ITERATIONS} audits launched. Waiting for remaining jobs…"

   # ── Poll progress while waiting ───────────────────────────────────────────
   while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
       print_progress
       sleep 5
   done
   wait

   echo ""
   echo "[$(date +%H:%M:%S)] All audits complete."
   echo ""

   # ── Final summary ─────────────────────────────────────────────────────────
   completed=0
   failed=0
   errors=0
   for f in "${RUN_DIR}"/audit_*.md; do
       if [ ! -s "${f}" ]; then
           failed=$((failed + 1))
       elif [ "$(wc -c < "${f}")" -gt 1000 ]; then
           completed=$((completed + 1))
       else
           errors=$((errors + 1))
       fi
   done

   echo "============================================================"
   echo " Results saved to: ${RUN_DIR}/"
   echo "============================================================"
   echo " Completed (>1KB) : ${completed}"
   echo " Errors (<1KB)    : ${errors}"
   echo " Empty            : ${failed}"
   echo ""
   echo " To extract the top recommendation from each audit:"
   echo "   grep -A 5 'SINGLE MOST IMPACTFUL' ${RUN_DIR}/audit_*.md"
   echo ""
   echo " To extract all ranked top-5 lists:"
   echo "   grep -A 20 'RANKED LIST' ${RUN_DIR}/audit_*.md"
   ```

5. **Make the script executable** and ask the user if they want to run it now.

6. **Warn the user about ANTHROPIC_API_KEY** — After generating the script, check whether the `ANTHROPIC_API_KEY` environment variable is set (run `echo $ANTHROPIC_API_KEY`). If it is set, warn the user:
   - When `ANTHROPIC_API_KEY` is set, `claude -p` authenticates against the API and charges API credits instead of using their Max/Pro subscription.
   - This will cause "Credit balance is too low" errors if the API key has no credits, even if the user has an active subscription.
   - To use their subscription instead, they should run `unset ANTHROPIC_API_KEY` before launching the audit, and remove it from their shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to prevent it from coming back.

## Important Guidelines

- The audit prompt must be **identical across all iterations** — this is critical for democratic comparison of results.
- The prompt should be **self-contained** — each `claude -p` invocation starts fresh with no conversation history, so the prompt must provide enough context for Claude to understand what to audit.
- Tailor the prompt to the **actual codebase** — don't use a generic template. Reference real files, directories, and patterns you discovered during exploration.
- The prompt should ask for **concrete, actionable recommendations** with file paths and line numbers, not vague suggestions.
- **CRITICAL: Single-turn output** — The prompt MUST include an explicit instruction telling Claude to write the COMPLETE report in a SINGLE response without using tools, spawning subagents, or referencing "the report above". Use `--max-turns 1` to enforce this. Without this, Claude will use tool calls to explore the codebase and then output a short summary like "the report above covers all sections" — but with `--output-format text`, only the final text is captured, so the actual audit is lost.
