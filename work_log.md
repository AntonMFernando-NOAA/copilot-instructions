# Work Log — Anton Fernando
# Full history; use `#file:/home/Anton.Fernando/utils/work_log.md` to reference in Copilot.
# Keep Recent Work section in copilot-instructions.md in sync (last 5 entries only).
#
# Entry format:
#   ## YYYY-MM-DD — <branch or project>
#   **Files changed:** list
#   **What:** short description
#   **Why:** motivation / bug / feature
#   **Status:** done | in-progress | blocked
#   **Notes:** anything useful for future prompts (gotchas, follow-ups, decisions made)

---

## 2026-05-04 — feature/gfsv17-forecast_manager

**Files changed:**
- `dev/scripts/exglobal_fsm.sh`
- `parm/archive/ocean_6hravg.yaml.j2`
- `ush/forecast_mgr.sh`

**What:** Fixed MOM6 sentinel dependency. Replaced hardcoded `TARGET_SIZE` file-size
check for OCN output with sentinel log file poll (`gfs.tz.ocn.log.f.txt`), consistent
with how ATM uses `log.f*.txt`. Initialized new `array_element_ocn_log` tracking array.
Added `ocn.log.f*.txt` to the ocean_6hravg archive manifest.

**Why:** The old ACTUAL_SIZE >= TARGET_SIZE heuristic was fragile across
platform/build/output differences. This branch's design requires sentinel-driven
readiness throughout.

**Status:** done — committed and pushed (b56eff11a)

**Notes:** Archive manifest must include sentinel files alongside NC output files so
archival is complete and downstream verification can check sentinel presence.

---

## 2026-05-04 — feature/gfsv17-forecast_manager

**Files changed:**
- `dev/scripts/exglobal_forecast_manager.sh`
- `dev/jobs/JGLOBAL_FORECAST`
- `dev/jobs/JGLOBAL_FORECAST_MANAGER`
- `dev/scripts/exglobal_cleanup.sh`

**What:** Renamed `forecast_mgr` → `forecast_manager` (mgr abbreviation not used in
develop branch convention). Simplified `MANAGER_INIT_TIMEOUT` assignment from
double-fallback to single `${FCST_MGR_INIT_TIMEOUT:-7200}`.

**Why:** Naming consistency with develop branch. Double-fallback on the same variable
was a no-op.

**Status:** done — committed and pushed (b56eff11a)

**Notes:** Submodule pointer changes (sorc/*) were present in working tree — unstaged
with `git restore --staged sorc/...` before committing.

---

## 2026-05-04 — utils (personal)

**Files changed:**
- `/home/Anton.Fernando/utils/copilot-instructions.md` (created)
- `/home/Anton.Fernando/.vscode-server/data/User/settings.json` (created)
- `/home/Anton.Fernando/utils/work_log.md` (created)

**What:** Set up persistent Copilot instructions loaded automatically into every VS Code
Copilot Chat session via `github.copilot.chat.codeGeneration.instructions` user setting.
Created this work log for full history; abbreviated Recent Work section kept in
copilot-instructions.md.

**Why:** Context is lost between Copilot sessions. Persistent instructions file solves
this without manual copy-paste each session.

**Status:** done

**Notes:** To reference full work history in a prompt: `#file:/home/Anton.Fernando/utils/work_log.md`
To reference instructions: `#file:/home/Anton.Fernando/utils/copilot-instructions.md`
Settings file location: `~/.vscode-server/data/User/settings.json`
