# Work Log — feature/gfsv17-forecast_manager
# Branch: feature/gfsv17-forecast_manager
# Repo: https://github.com/AntonMFernando-NOAA/global-workflow
# Loaded automatically via .vscode/settings.json when this workspace is open.
# Reference manually: `#file:~/copilot-instructions/work_logs/feature-gfsv17-forecast_manager.md`
#
# Entry format:
#   ## YYYY-MM-DD
#   **Files changed:** list
#   **What:** short description
#   **Why:** motivation / bug / feature
#   **Status:** done | in-progress | blocked
#   **Notes:** gotchas, follow-ups, decisions made

---

## 2026-05-04

**Files changed:**
- `dev/scripts/exglobal_fsm.sh`
- `parm/archive/ocean_6hravg.yaml.j2`
- `ush/forecast_mgr.sh`

**What:** Fixed MOM6 sentinel dependency. Replaced hardcoded `TARGET_SIZE` file-size
check for OCN output with sentinel log file poll (`gfs.tz.ocn.log.f.txt`), consistent
with how ATM uses `log.f*.txt`. Initialized new `array_element_ocn_log` tracking array.
Added `ocn.log.f*.txt` to the ocean_6hravg archive manifest.

**Why:** The old ACTUAL_SIZE >= TARGET_SIZE heuristic was fragile across
platform/build/output differences. Sentinel-driven readiness is required throughout.

**Status:** done — committed and pushed (b56eff11a)

**Notes:** Archive manifest must include sentinel files alongside NC output files so
archival is complete and downstream verification can check sentinel presence.

---

## 2026-05-04

**Files changed:**
- `dev/scripts/exglobal_forecast_manager.sh`
- `dev/jobs/JGLOBAL_FORECAST`
- `dev/jobs/JGLOBAL_FORECAST_MANAGER`
- `dev/scripts/exglobal_cleanup.sh`

**What:** Renamed `forecast_mgr` → `forecast_manager` (mgr abbreviation not used in
develop branch convention). Simplified `MANAGER_INIT_TIMEOUT` from double-fallback
to single `${FCST_MGR_INIT_TIMEOUT:-7200}`.

**Why:** Naming consistency with develop branch. Double-fallback on the same variable
was a no-op.

**Status:** done — committed and pushed (b56eff11a)

**Notes:** Submodule pointer changes (sorc/*) were present in working tree — unstaged
with `git restore --staged sorc/...` before committing. Never commit submodule pointer
changes unless explicitly requested.

## 2026-05-04 20:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `52ee7b8` [gfs.v17] Eliminate Wave Postprocessing Warnings and Suppress Creation of Empty Output Directories (#4831)
- `91e4b6b` [dev/gfs.v17] Update the production/GFS.v17 UFS WM hash (#4767)
- `1e94a9d` fcst_mgr: port fcst_done graceful-exit sentinel and postdet consolidation from develop branch
- `dcac115` fcst_mgr: replace HOMEglobal/USHglobal/SCRglobal with HOMEgfs/USHgfs/SCRgfs for CI compatibility
- `c630069` ush: use MOM6 outputlog as sentinel in forecast manager
- `dd24ec5` Fix MOM6 sentinel dependencies in FSM, manager, and archive
- `772e93d` Rename forecast_mgr.sh to forecast_manager.sh and update related references in exglobal_forecast_manager.sh
- `8e69023` Rename forecast_mgr to forecast_manager across scripts and configurations for consistency
- `b56eff1` Forecast manager: rename mgr->manager, simplify init timeout
- `41a2aea` Remove changelog and cleanup script updates for MOM6/CICE sentinel logs; refactor forecast manager timeout handling


## 2026-05-07 18:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `c7e26cb` v17 Hot fix: only untar if file exists (#4880)
- `a4a1be1` (dev/gfs.v17) Update verfozn and analdiag scripts to handle missing ozone data (#4883)
- `22c27fe` (dev/gfs.v17) Hotfix for ozone archiving (#4888)
- `b85d10d` (dev/gfs.v17) Reinstate updates from dev/gfs.v17_20260505 following hotfixes (#4887)

