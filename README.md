# Persistent AI Instructions System

Persistent context management for Kiro (and legacy VS Code Copilot Chat) across HPC sessions.
Repo: `AntonMFernando-NOAA/copilot-instructions`
Cloned at: `~/copilot-instructions/`

---

## How It Works (Kiro)

Kiro merges two layers of steering files into every chat session:

| Level | Path | Loaded |
|-------|------|--------|
| User (always) | `~/.kiro/steering/*.md` | Every session, every workspace |
| Workspace (per branch) | `<repo>/.kiro/steering/*.md` | Only when that workspace is open |

The **user** layer holds two thin steering files that re-export the always-on content
via Kiro's file-include syntax (`#[[file:...]]`):

```
~/.kiro/steering/persistent-instructions.md  →  #[[file:~/copilot-instructions/copilot-instructions.md]]
~/.kiro/steering/error-log.md                →  #[[file:~/copilot-instructions/error_log.md]]
```

The **workspace** layer is rewritten by the `post-checkout` git hook on every branch
switch to re-export the matching branch work log:

```
<repo>/.kiro/steering/work-log.md  →  #[[file:~/copilot-instructions/work_logs/<branch-slug>.md]]
```

Because Kiro resolves file includes at prompt time, edits to the source files (including
the hourly cron commit appends) are picked up live — no reload needed.

> Legacy VS Code Copilot integration still works for machines that need it; see
> `copilot-instructions.md` → "Editor Integration".

---

## Files

```
copilot-instructions.md       Always loaded — identity, domain context, code style,
                               architecture patterns, git conventions.

error_log.md                  Always loaded — history of bugs/errors diagnosed this
                               session or prior. Prevents repeat mistakes.

work_log.md                   Full task history. NOT auto-loaded.
                               Reference on demand by name in chat.

work_logs/
  <branch-slug>.md            One file per git branch. Auto-loaded when that branch is
                               active (via workspace .kiro/steering/work-log.md).
                               Auto-appended with new commits every hour via cron.
  .last_<branch-slug>         Watermark file — stores last-logged commit hash so the
                               hourly script only appends new work.

setup_user_steering.sh        One-time bootstrap. Writes the two user-level steering
                               files under ~/.kiro/steering/.

use_branch.sh                 Activates per-branch work-log steering for any repo.
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
- Calls `use_branch.sh` → creates work log if new, rewrites `.kiro/steering/work-log.md`
- Kiro picks up the new steering on the next prompt automatically (no IDE reload).

Crontab entries (view with `crontab -l`):
```
59 23 * * * /home/Anton.Fernando/copilot-instructions/push_copilot_instructions.sh >> ~/logs/copilot_push.log 2>&1
0  *  * * * /home/Anton.Fernando/copilot-instructions/auto_log_work.sh >> ~/logs/auto_log.log 2>&1
```

---

## Setup

### One-time per machine

```bash
~/copilot-instructions/setup_user_steering.sh
```

This writes `~/.kiro/steering/persistent-instructions.md` and `~/.kiro/steering/error-log.md`.

### Per repo

```bash
# 1. Activate the branch work log for the current branch (writes .kiro/steering/work-log.md)
cd /path/to/repo
~/copilot-instructions/use_branch.sh

# 2. Install the post-checkout hook for auto-activation on future branch switches
cat > .git/hooks/post-checkout << 'EOF'
#!/usr/bin/env bash
if [[ "$3" == "1" ]]; then
    "${HOME}/copilot-instructions/use_branch.sh" 2>/dev/null || true
fi
EOF
chmod +x .git/hooks/post-checkout

# 3. Add the repo path to the REPOS=() array in auto_log_work.sh
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

Ask Kiro to append a manual entry at any time:
> *"append today's work to the branch log"*

---

## Repos Currently Watched

| Repo | Path | Hook installed |
|------|------|----------------|
| global-workflow | `/scratch3/NCEPDEV/global/Anton.Fernando/global-workflow` | Yes |
| global-workflow_gfsv17 | `/scratch3/NCEPDEV/global/Anton.Fernando/global-workflow_gfsv17` | Yes |

---

## Key Paths

| Purpose | Path |
|---------|------|
| Kiro user steering | `~/.kiro/steering/` |
| Kiro workspace steering (per branch) | `<repo>/.kiro/steering/work-log.md` (locally git-excluded) |
| VS Code user settings (legacy) | `~/.vscode-server/data/User/settings.json` |
| Cron log — auto-log | `~/logs/auto_log.log` |
| Cron log — nightly push | `~/logs/copilot_push.log` |
| GitHub repo | `https://github.com/AntonMFernando-NOAA/copilot-instructions` |
