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


## 2026-05-07 19:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `9aff812` Enhance ocean product release logic to check file size before proceeding


## 2026-05-07 20:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `085912a` Fix datajob path in fcst_manager to include '_forecast' suffix for clarity


## 2026-05-08 22:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `889f166` Update MOM6 post-determination file naming to include '_00' suffix for consistency
- `ff78b23` Fix MOM6 post-determination log time calculation to use forecast hour variable
- `0a1170f` Fix MOM6 f120 sentinel: revert incorrect fhr fix and add FHMAX fallback


## 2026-05-09 01:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `4fd224d` Fix forecast_manager.sh: write synthetic text for data-as-sentinel fallback


## 2026-05-11 20:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `33d041f` Update gfs_tasks.py: modify product history file templates and dependency conditions for ocean and ice components
- `4531e7e` Update gfs_tasks.py: change dependency condition for ocean component from 'and' to 'or'
- `db1c9e2` Update exglobal_cleanup.sh and gfs_tasks.py: enhance cleanup process for ocean and ice logs; adjust dependency conditions for ocean products
- `95a2777` Enhance forecast_manager.sh: add comments to clarify xtrace suppression for improved performance
- `d05a009` Remove unnecessary ocean log file requirement from ocean_6hravg.yaml.j2


## 2026-05-11 21:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `af5389f` Make COMOUT directories in regrid J-Job
- `399e5bc` (dev/gfs.v17) Add WDQMS processing into GFSv17 (#4796)
- `313512b` (dev/gfs.v17) NCO SPA requested ecflow updates (#4875)
- `5dfbc02` (dev/gfs.v17) Wave prep -> wave init and wave clean up (#4878)
- `865eed8` Do not trap exits within err_exit (#4896)
- `efa4a48` Refactor forecast manager scripts: streamline segment handling and improve logging conditions
- `f7f9375` update forecast_manager.sh
- `7327443` Update ush/forecast_manager.sh
- `482dd2b` Remove unnecessary comments and formatting from forecast_postdet.sh
- `c916ca5` Fix reviewdog 403 error: switch reporter from github-pr-review to github-check


## 2026-05-14 15:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `5bfa589` Add ecflow scripts and triggers for forecast manager job


## 2026-05-21 20:26 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `7fc84fe` Refactor JGLOBAL_FORECAST_MANAGER and forecast_postdet.sh scripts to improve clarity and remove redundant code
- `a962bcc` Remove redundant warm start handling code and fix source file naming in MOM6 post-processing
- `59a117c` Enhance MOM6 post-processing by adding logging for source and destination files
- `bdf5c55` remove decode coding
- `0391081` update dev/jobs/JGLOBAL_FORECAST_MANAGER
- `50ad388` Enhance forecast manager configuration and stability checks; update resource definitions and logging for oceanice products
- `4465271` Update ush/forecast_manager.sh
- `713bb14` Update ush/forecast_manager.sh
- `19272b2` Update ush/forecast_manager.sh
- `50dbef2` Enhance forecast manager to handle model-done fallback for last segment entry; write synthetic COM log if necessary
- `d939b2c` Enhance forecast manager to implement model-done fallback for ocean component; adjust log handling logic
- `1a25032` Refactor conditional checks for ocean component in forecast manager
- `9cc7b3c` Remove segment completion sentinel cleanup from forecast manager script
- `5f7c0de` Update forecast manager and related scripts to use table-ready sentinel for segment management
- `bf4b9bd` Update forecast manager to check for absence of FCST_TABLE_READY_SENTINEL before waiting
- `338e9f8` Refactor forecast manager for improved task handling and logging
- `43c4055` Enhance synthetic sentinel logging in forecast manager for better clarity
- `135c717` Refactor CICE post-processing to streamline file registration and logging
- `bb0580f` Enhance CICE output handling by adding initial condition snapshot management and directory creation
- `84da728` Update CICE post-processing to manage initial condition snapshots for manager runs
- `0f7aefa` Clarify comments in CICE output function regarding initial condition snapshots for manager runs
- `b468c54` Refactor CICE post-processing to improve initial condition snapshot handling and clarify comments
- `e6d9cc1` Fix indentation in CICE post-processing output handling for better readability
- `fa77a75` Add informative error messages to all err_exit calls (#4895)
- `2365ebf` Removed soca gridgen from the v17 workflow (#4784)
- `b157f61` Update exglobal_prep_sfc (#4879)
- `5c9695a` Introduce master scron job (#4891)
- `f15a038` Parallel reproducibility comparison utility (#4906)
- `d465c19` (dev/gfs.v17) Fix multiple copying issue in regrid code. (#4898)
- `0122e8b` Package level change for COM paths issue (#4911)
- `a70dbbb` Enhance forecast manager script to handle ocean and ice model log visibility issues and defer processing for missing data files
- `8f768c4` Update configuration scripts for improved resource management and clarity
- `1c525ae` update gfs_tasks.py
- `76aa3e3` HOTFIX Create RESTART directory to prevent MOM6 from doing it
- `36819cf` Correct TODO
- `2e81888` Enhance forecast manager to handle missing sentinel logs for ocean and ice models, including size checks for copied outputs.
- `2aa6b4b` Refactor forecast manager script for improved clarity and maintainability
- `e5db0ec` Improve synthetic sentinel logging by using base names for clarity
- `b1b9e09` Update ecf/scripts/gfs/forecast/jgfs_fcst_manager.ecf
- `28fe0b8` Refine size reference logic for missing sentinel logs to ensure accurate comparisons based on normalized file names.
- `ca25bc1` HOTFIX Create RESTART directory to prevent FMS from doing it (#4932)
- `40c5081` (dev/gfs.v17)Updates to wave products  (#4915)
- `f926942` (dev/gfs.v17) Add missing dependency on ensemble regrid in ensemble forecast (#4917)
- `44430d6` [dev/gfs.v17] Have executable names resemble sorc directory names (#4923)
- `e9b9e7e` [dev/gfs.v17] Improve eupd/global cycle log output (#4925)
- `0b49568` Remove unnecessary cleanup of MOM6/CICE sentinel log files and add comment for opening netCDF file in OceanIceProducts task
- `7a395ae` Enhance forecast manager to handle data-file triggers and improve sentinel logging for CICE outputs
- `9bdde0d` Add ATM barrier script and update forecast post-processing for per-product ranks
- `6ad71ce` Refactor ATM command additions in forecast manager script for improved readability


## 2026-05-21 23:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `7a107c9` Refactor configuration scripts for improved clarity and maintainability


## 2026-05-22 15:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `c4250de` Enhance ATM barrier script to remove intermediate sentinels after final log is written; update CICE post-processing to use first forecast-hour ice output as trigger


## 2026-05-22 17:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `fb525af` Refactor ATM configuration and scripts to support multiple instance groups; update barrier handling and product table management for improved parallel processing
- `6982b4a` Update ush/forecast_postdet.sh


## 2026-05-23 00:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `9d17c7d` Enhance ATM barrier script to implement a post-done timeout feature for improved handling of pending rows after model completion


## 2026-05-23 03:00 UTC (auto)
**Branch:** `feature/gfsv17-forecast_manager`
**New commits:**
- `d060892` Enhance ATM barrier script to track dependency file progress and improve timeout logic for pending rows

