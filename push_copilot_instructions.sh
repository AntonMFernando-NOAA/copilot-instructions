#!/usr/bin/env bash
# push_copilot_instructions.sh
# Commits any changes in ~/copilot-instructions and pushes to GitHub.
# Intended to run nightly via cron (e.g., 20:00 Hera local time).
# Cron entry (edit with: crontab -e):
#   0 20 * * * /home/Anton.Fernando/copilot-instructions/push_copilot_instructions.sh >> /home/Anton.Fernando/logs/copilot_push.log 2>&1

REPO="${HOME}/copilot-instructions"
TIMESTAMP="$(date -u '+%Y-%m-%d %H:%M UTC')"

cd "${REPO}" || { echo "ERROR: Cannot cd to ${REPO}"; exit 1; }

# Nothing to do if working tree is clean
if git diff --quiet && git diff --cached --quiet; then
    echo "[${TIMESTAMP}] No changes to push."
    exit 0
fi

git add copilot-instructions.md work_log.md error_log.md work_logs/ use_branch.sh
git commit -m "auto: nightly sync ${TIMESTAMP}"
git push origin main

echo "[${TIMESTAMP}] Push complete."
