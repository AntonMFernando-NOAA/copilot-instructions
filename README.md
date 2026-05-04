# Copilot Instructions System

Persistent context management for GitHub Copilot Chat across HPC sessions on Hera.
Repo: `AntonMFernando-NOAA/copilot-instructions`
Cloned at: `~/copilot-instructions/`

---

## How It Works

VS Code merges two levels of `github.copilot.chat.codeGeneration.instructions`:

| Level | File | Loaded |
|-------|------|--------|
| User (always) | `~/.vscode-server/data/User/settings.json` | Every session, every repo |
| Workspace (per branch) | `<repo>/.vscode/settings.json` | Only when that repo is open |

The user settings always load two files:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": "/home/Anton.Fernando/copilot-instructions/copilot-instructions.md" },
    { "file": "/home/Anton.Fernando/copilot-instructions/error_log.md" }
  ]
}
```

When you switch branches, the workspace settings are rewritten by the `post-checkout` hook to load the matching branch work log.

---

## Files

```
copilot-instructions.md       Always loaded — identity, domain context, code style,
                               architecture patterns, git conventions.

error_log.md                  Always loaded — history of bugs/errors diagnosed this
                               session or prior. Prevents repeat mistakes.

work_log.md                   Full task history. NOT auto-loaded.
                               Reference on demand: #file:~/copilot-instructions/work_log.md

work_logs/
  <branch-slug>.md            One file per git branch. Auto-loaded when that branch is
                               active (via workspace .vscode/settings.json).
                               Auto-appended with new commits every hour via cron.
  .last_<branch-slug>         Watermark file — stores last-logged commit hash so the
                               hourly script only appends new work.

use_branch.sh                 Manually activates per-branch work log for any repo.
                               Called automatically by the post-checkout git hook.

auto_log_work.sh              Hourly cron script. Scans watched repos for new commits
                               and appends them to the matching work log.

push_copilot_instructions.sh  Nightly cron script. Pushes all changes to GitHub.
```

---

## Automation

### Hourly — `auto_log_work.sh`
- Runs at `:00` every hour via cron
- Detects current branch in each watched repo (`REPOS=()` array in the script)
- Appends new commits (hash + subject) since last run to `work_logs/<branch-slug>.md`
- Pushes update to GitHub
- Log: `~/logs/auto_log.log`

### Nightly — `push_copilot_instructions.sh`
- Runs at `23:59` every night
- Stages and pushes all changes in `~/copilot-instructions/`
- Log: `~/logs/copilot_push.log`

### On branch switch — `post-checkout` git hook
- Installed at `<repo>/.git/hooks/post-checkout`
- Fires on every `git checkout` / `git switch` (not on file-level checkouts)
- Calls `use_branch.sh` → creates work log if new, rewrites `.vscode/settings.json`
- Calls `code --reload-window` → VS Code reloads with the new branch context

Crontab entries (view with `crontab -l`):
```
59 23 * * * /home/Anton.Fernando/copilot-instructions/push_copilot_instructions.sh >> ~/logs/copilot_push.log 2>&1
0  *  * * * /home/Anton.Fernando/copilot-instructions/auto_log_work.sh >> ~/logs/auto_log.log 2>&1
```

---

## Setup on a New Repo

```bash
# 1. Activate the branch work log for the current branch
cd /path/to/repo
~/copilot-instructions/use_branch.sh

# 2. Install the post-checkout hook for auto-activation on future branch switches
cat > .git/hooks/post-checkout << 'EOF'
#!/usr/bin/env bash
if [[ "$3" == "1" ]]; then
    "${HOME}/copilot-instructions/use_branch.sh" 2>/dev/null || true
    code --reload-window 2>/dev/null || true
fi
EOF
chmod +x .git/hooks/post-checkout

# 3. Add the repo path to the REPOS=() array in auto_log_work.sh
# 4. Reload VS Code: Ctrl+Shift+P → Developer: Reload Window
```

---

## Work Log Entry Format

Entries are auto-appended as commit summaries. Manual entries use:

```markdown
## YYYY-MM-DD
**Files changed:** list of files
**What:** short description of the change
**Why:** motivation, bug reference, or feature context
**Status:** done | in-progress | blocked
**Notes:** gotchas, decisions, follow-ups
```

Ask Copilot to append a manual entry at any time:
> *"append today's work to the branch log"*

---

## Repos Currently Watched

| Repo | Path | Hook installed |
|------|------|----------------|
| global-workflow | `/scratch3/NCEPDEV/global/Anton.Fernando/global-workflow` | Yes |

---

## Key Paths

| Purpose | Path |
|---------|------|
| VS Code user settings | `~/.vscode-server/data/User/settings.json` |
| Workspace settings (per branch) | `<repo>/.vscode/settings.json` (gitignored via `.git/info/exclude`) |
| Cron log — auto-log | `~/logs/auto_log.log` |
| Cron log — nightly push | `~/logs/copilot_push.log` |
| GitHub repo | `https://github.com/AntonMFernando-NOAA/copilot-instructions` |
