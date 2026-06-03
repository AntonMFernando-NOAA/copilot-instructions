#!/usr/bin/env bash
# setup_user_steering.sh — One-time bootstrap to make Kiro auto-load the persistent
# instructions and error log from ~/copilot-instructions in every workspace.
#
# Kiro reads two layers of steering:
#   - User-level:      ~/.kiro/steering/*.md   (loaded in every workspace)
#   - Workspace-level: <repo>/.kiro/steering/*.md
#
# This script writes two thin user-level steering files that Kiro-include the
# always-on instructions and the error log via the #[[file:...]] mechanism, so
# updates to the source files are picked up automatically.

set -euo pipefail

USER_STEERING="${HOME}/.kiro/steering"
INSTRUCTIONS_SRC="${HOME}/copilot-instructions/copilot-instructions.md"
ERROR_LOG_SRC="${HOME}/copilot-instructions/error_log.md"

mkdir -p "${USER_STEERING}"

cat > "${USER_STEERING}/persistent-instructions.md" << STEERING
---
inclusion: always
---
# Persistent Personal Instructions

Always-loaded identity, domain context, code style and git conventions.
Source of truth: ${INSTRUCTIONS_SRC}

#[[file:${INSTRUCTIONS_SRC}]]
STEERING
echo "Wrote: ${USER_STEERING}/persistent-instructions.md"

cat > "${USER_STEERING}/error-log.md" << STEERING
---
inclusion: always
---
# Recurring Error Log

History of bugs/errors diagnosed in prior sessions. Reference before suggesting
fixes to avoid repeating known mistakes.
Source: ${ERROR_LOG_SRC}

#[[file:${ERROR_LOG_SRC}]]
STEERING
echo "Wrote: ${USER_STEERING}/error-log.md"

echo "Done. Open any workspace in Kiro — these load automatically."
