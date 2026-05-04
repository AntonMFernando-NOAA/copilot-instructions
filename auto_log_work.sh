#!/usr/bin/env bash
# auto_log_work.sh
# Runs every hour via cron. For each watched repo, checks for new commits on
# the current branch since the last time this script ran, and appends a
# summary to the matching work_logs/<branch-slug>.md file.
#
# Cron entry (runs every hour):
#   0 * * * * /home/Anton.Fernando/copilot-instructions/auto_log_work.sh >> /home/Anton.Fernando/logs/auto_log.log 2>&1
#
# State tracking: last-logged commit hash stored in work_logs/.last_<slug>

set -uo pipefail

WORK_LOGS_DIR="${HOME}/copilot-instructions/work_logs"
TIMESTAMP="$(date -u '+%Y-%m-%d %H:%M UTC')"

# List of repos to monitor — add more as needed
REPOS=(
    "/scratch3/NCEPDEV/global/Anton.Fernando/global-workflow"
)

append_commits() {
    local repo="$1"

    # Skip if repo doesn't exist
    [[ -d "${repo}/.git" ]] || return 0

    local branch
    branch="$(git -C "${repo}" rev-parse --abbrev-ref HEAD 2>/dev/null)" || return 0
    [[ "${branch}" == "HEAD" ]] && return 0   # detached HEAD, skip

    local slug="${branch//\//-}"
    local work_log="${WORK_LOGS_DIR}/${slug}.md"
    local state_file="${WORK_LOGS_DIR}/.last_${slug}"

    # If no work log exists yet, create it (use_branch.sh may not have run)
    if [[ ! -f "${work_log}" ]]; then
        mkdir -p "${WORK_LOGS_DIR}"
        cat > "${work_log}" <<TEMPLATE
# Work Log — ${branch}
# Repo: $(git -C "${repo}" remote get-url origin 2>/dev/null || echo "unknown")
# Auto-created by auto_log_work.sh

---
TEMPLATE
    fi

    # Get the last-logged commit hash, or use the initial commit of the branch
    local since_ref=""
    if [[ -f "${state_file}" ]]; then
        since_ref="$(cat "${state_file}")"
    fi

    # Get new commits since last run (newest first reversed to oldest first)
    local log_args=("--pretty=format:%H|%s" "--no-merges")
    if [[ -n "${since_ref}" ]]; then
        log_args+=("${since_ref}..HEAD")
    else
        log_args+=("-10")   # first run: only pick up last 10 commits
    fi

    local commits
    commits="$(git -C "${repo}" log "${log_args[@]}" 2>/dev/null)"
    [[ -z "${commits}" ]] && return 0   # nothing new

    # Append to work log
    {
        echo ""
        echo "## ${TIMESTAMP} (auto)"
        echo "**Branch:** \`${branch}\`"
        echo "**New commits:**"
        while IFS='|' read -r hash subject; do
            echo "- \`${hash:0:7}\` ${subject}"
        done <<< "$(echo "${commits}" | tac)"
        echo ""
    } >> "${work_log}"

    # Save latest commit hash as new watermark
    git -C "${repo}" rev-parse HEAD > "${state_file}"

    echo "[${TIMESTAMP}] Appended commits for ${branch} in ${repo}"
}

for repo in "${REPOS[@]}"; do
    append_commits "${repo}"
done

# Push any updates to GitHub
cd "${HOME}/copilot-instructions" || exit 1
if ! git diff --quiet work_logs/; then
    git add work_logs/
    git commit -m "auto: hourly work log update ${TIMESTAMP}"
    git push origin main
    echo "[${TIMESTAMP}] Pushed work log updates."
fi
