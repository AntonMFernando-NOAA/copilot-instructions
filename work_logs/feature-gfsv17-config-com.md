# Work Log — feature/gfsv17-config-com
# Repo: https://github.com/AntonMFernando-NOAA/global-workflow
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

## 2026-06-24 15:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `05749df` (dev/gfs.v17) Remove NAM dependency from GFSv17 (#5032)
- `7033fc6` [v17] bug fix and code owner update (#5033)
- `2abd302` [dev/gfs.v17] Update bmat ecflow triggers and some other ecflow cleanup (#5035)
- `9b11c48` (dev/gfs.v17) Update v17 prep jobs in ecflow to operations-like configuration (#5013)
- `e815721` [dev/gfsv17] update to not have stop string in wave output (#5045)
- `ea7161c` [dev/gfs.v17] Add back bmat_init forecast dependencies (#5046)
- `b0aae68` (dev/gfs.v17) Replace or Remove CDATE variable with PDY and cyc throughout codebase (#5039)
- `f977637` [dev/gfs.v17] Add in Ed Givelberg's marine obs report for NCO SDM (#5029)
- `1e3c283` (dev/gfs.v17) Add %manual documentation blocks to 77 ecFlow scripts (#5027)
- `3cbf91e` (dev/v17) Release Notes (#5034)


## 2026-06-24 19:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `dd211fc` Refactor COM path templates: replace config.com with com_paths.py for better management and clarity
- `ac0ee5b` Remove nexus.fd submodule from index - not part of config-com feature
- `8e7096a` Remove config.com sourcing - replaced by com_paths.py


## 2026-06-24 20:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `b2e515f` Add session summary for GDAS forecast manager fixes and configuration updates
- `e241ab2` update gdas app
- `7677d07` Remove nexus.fd submodule as it is not part of the config-com feature
- `6e479cf` GDAS remove dangling submodule


## 2026-06-24 21:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `b3c2ec5` Bump sorc/gdas.cd to include orphaned gsibec submodule fix


## 2026-06-25 01:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `d69bf5f` Fix PYTHONPATH order: set local wxflow after module load to ensure precedence on WCOSS2


## 2026-06-25 04:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `f599de3` Add all fixed COM_*_TMPL exports to config.base.j2 for job runtime
- `c2c6276` Revert "Add all fixed COM_*_TMPL exports to config.base.j2 for job runtime"
- `87c302a` Use com_paths.get_com_templates() as base in stage_ic._copy_com_templates()
- `1b9b542` Use com_paths.get_com_templates() as base in archive_vars.add_config_vars()


## 2026-06-25 16:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `5138b5d` Add COM template loading to MarineBMat class for Jinja2 rendering
- `8ab1479` Add COM template loading to SnowAnalysis and SnowEnsAnalysis classes for Jinja2 rendering


## 2026-06-25 18:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `0ace378` Add COM template loading to MarineRecenter class for Jinja2 rendering
- `cc106eb` Add COM_OCEAN_ANALYSIS_TMPL and COM_ICE_ANALYSIS_TMPL to needed templates in MarineRecenter class
- `8d7d805` Update PYTHONPATH setup in gw_setup.sh to ensure proper precedence for wxflow


## 2026-06-25 19:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `1af8433` update gw_setup.sh


## 2026-06-25 20:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `a267daf` Add COM template loading to exglobal_archive_tars.py and exglobal_archive_vrfy.py for Jinja2 rendering
- `cd6830c` Remove unused imports and clean up COM template handling in ArchiveVrfyVars class
- `60da35e` Remove unused import and clean up comments in ArchiveVrfyVars class


## 2026-06-25 21:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `d8a71dd` Refactor scripts to import COM template definitions from com_paths and inject defaults into configurations


## 2026-06-25 23:00 UTC (auto)
**Branch:** `feature/gfsv17-config-com`
**New commits:**
- `f056558` Refactor marine analysis scripts to streamline COM template imports and configuration injectionco
- `61297bc` Add missing sys import in exglobal_marine_analysis_letkf.py
- `bb78931` Refactor scripts to inject COM_*_TMPL templates from com_paths with environment overrides

