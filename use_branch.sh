#!/usr/bin/env bash
# use_branch.sh — Activate per-branch Kiro work-log steering for the current workspace.
#
# Usage:
#   cd /path/to/repo
#   ~/copilot-instructions/use_branch.sh
#
# What it does:
#   1. Detects the current git branch.
#   2. Creates ~/copilot-instructions/work_logs/<branch-slug>.md if it doesn't exist.
#   3. Drops a Kiro workspace steering file at <repo>/.kiro/steering/work-log.md
#      that points at that work log so Kiro auto-loads it every session.
#      (.kiro/steering/work-log.md is excluded locally via .git/info/exclude.)
#
# Run this once each time you start working on a new or switched-to branch.
# Called automatically by the post-checkout git hook.

set -euo pipefail

WORK_LOGS_DIR="${HOME}/copilot-instructions/work_logs"

# Detect repo root and branch
REPO_ROOT="$(git rev-parse --show-toplevel 2> /dev/null)" || {
  echo "ERROR: Not inside a git repository." >&2
  exit 1
}
BRANCH="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)"
SLUG="${BRANCH//\//-}" # replace / with - for filename safety
WORK_LOG="${WORK_LOGS_DIR}/${SLUG}.md"

echo "Branch  : ${BRANCH}"
echo "Work log: ${WORK_LOG}"

# Create work log for this branch if it doesn't exist
if [[ ! -f "${WORK_LOG}" ]]; then
  mkdir -p "${WORK_LOGS_DIR}"
  cat > "${WORK_LOG}" << TEMPLATE
# Work Log — ${BRANCH}
# Repo: $(git -C "${REPO_ROOT}" remote get-url origin 2> /dev/null || echo "unknown")
# Loaded automatically by Kiro via .kiro/steering/work-log.md when this workspace is open.
#
# Entry format:
#   ## YYYY-MM-DD
#   **Files changed:** list
#   **What:** short description
#   **Why:** motivation / bug / feature
#   **Status:** done | in-progress | blocked
#   **Notes:** gotchas, follow-ups, decisions made

---
TEMPLATE
  echo "Created new work log: ${WORK_LOG}"
fi

# Write Kiro workspace steering file pointing at this branch's work log.
# Kiro merges all .md files under .kiro/steering/ into every session by default.
KIRO_STEERING_DIR="${REPO_ROOT}/.kiro/steering"
KIRO_WORK_LOG_STEERING="${KIRO_STEERING_DIR}/work-log.md"
mkdir -p "${KIRO_STEERING_DIR}"

cat > "${KIRO_WORK_LOG_STEERING}" << STEERING
---
inclusion: always
---
# Active Branch Work Log

Repo branch: \`${BRANCH}\`
Source: ${WORK_LOG}

The full per-branch work log is included below (referenced via Kiro file include
so the latest cron-appended commits are always picked up).

#[[file:${WORK_LOG}]]
STEERING

echo "Wrote: ${KIRO_WORK_LOG_STEERING}"

# Exclude the workspace steering file locally without touching the repo's .gitignore.
# .git/info/exclude is the per-clone local equivalent of .gitignore — never committed.
EXCLUDE="${REPO_ROOT}/.git/info/exclude"
for pattern in '.kiro/steering/work-log.md' '.kiro/'; do
  if ! grep -qF "${pattern}" "${EXCLUDE}" 2> /dev/null; then
    echo "${pattern}" >> "${EXCLUDE}"
    echo "Added ${pattern} to .git/info/exclude (local only)"
  fi
done

echo "Done. Kiro picks up steering changes on the next prompt — no reload needed."
