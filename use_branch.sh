#!/usr/bin/env bash
# use_branch.sh — Activate per-branch Copilot work log for the current workspace.
#
# Usage:
#   cd /path/to/repo
#   ~/copilot-instructions/use_branch.sh
#
# What it does:
#   1. Detects the current git branch.
#   2. Creates ~/copilot-instructions/work_logs/<branch-slug>.md if it doesn't exist.
#   3. Writes .vscode/settings.json in the repo to load that work log automatically.
#      (.vscode/settings.json should be gitignored in the repo.)
#
# Run this once each time you start working on a new or switched-to branch.

set -euo pipefail

WORK_LOGS_DIR="${HOME}/copilot-instructions/work_logs"
INSTRUCTIONS="${HOME}/copilot-instructions/copilot-instructions.md"
ERROR_LOG="${HOME}/copilot-instructions/error_log.md"

# Detect repo root and branch
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "ERROR: Not inside a git repository." >&2
    exit 1
}
BRANCH="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)"
SLUG="${BRANCH//\//-}"   # replace / with - for filename safety
WORK_LOG="${WORK_LOGS_DIR}/${SLUG}.md"

echo "Branch : ${BRANCH}"
echo "Work log: ${WORK_LOG}"

# Create work log for this branch if it doesn't exist
if [[ ! -f "${WORK_LOG}" ]]; then
    mkdir -p "${WORK_LOGS_DIR}"
    cat > "${WORK_LOG}" <<TEMPLATE
# Work Log — ${BRANCH}
# Repo: $(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || echo "unknown")
# Loaded automatically via .vscode/settings.json when this workspace is open.
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

# Write .vscode/settings.json in the repo
VSCODE_DIR="${REPO_ROOT}/.vscode"
VSCODE_SETTINGS="${VSCODE_DIR}/settings.json"
mkdir -p "${VSCODE_DIR}"

cat > "${VSCODE_SETTINGS}" <<JSON
{
    "github.copilot.chat.codeGeneration.instructions": [
        { "file": "${WORK_LOG}" }
    ]
}
JSON

echo "Updated: ${VSCODE_SETTINGS}"

# Ensure .vscode/settings.json is gitignored
GITIGNORE="${REPO_ROOT}/.gitignore"
if ! grep -qF '.vscode/settings.json' "${GITIGNORE}" 2>/dev/null; then
    echo '.vscode/settings.json' >> "${GITIGNORE}"
    echo "Added .vscode/settings.json to .gitignore"
fi

echo "Done. Reload VS Code window to apply (Ctrl+Shift+P → 'Developer: Reload Window')."
