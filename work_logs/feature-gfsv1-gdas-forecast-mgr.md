# Work Log — feature/gfsv1-gdas-forecast-mgr
# Repo: https://github.com/AntonMFernando-NOAA/global-workflow
# Auto-created by auto_log_work.sh

---

## 2026-05-22 18:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `2806558` Update resource retrieval in GFSTasks to use efcs_manager for forecast management
- `45906f5` Update cycle definition in GFSTasks to handle specific run cases for gdas
- `b1b9e09` Update ecf/scripts/gfs/forecast/jgfs_fcst_manager.ecf
- `28fe0b8` Refine size reference logic for missing sentinel logs to ensure accurate comparisons based on normalized file names.
- `ca25bc1` HOTFIX Create RESTART directory to prevent FMS from doing it (#4932)
- `40c5081` (dev/gfs.v17)Updates to wave products  (#4915)
- `f926942` (dev/gfs.v17) Add missing dependency on ensemble regrid in ensemble forecast (#4917)
- `44430d6` [dev/gfs.v17] Have executable names resemble sorc directory names (#4923)
- `e9b9e7e` [dev/gfs.v17] Improve eupd/global cycle log output (#4925)
- `0b49568` Remove unnecessary cleanup of MOM6/CICE sentinel log files and add comment for opening netCDF file in OceanIceProducts task


## 2026-05-22 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `1e743cf` Add ocean and ice configuration to oceanice_products_gdas.yaml; update CICE output filename format in forecast_postdet.sh


## 2026-05-26 16:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `7a395ae` Enhance forecast manager to handle data-file triggers and improve sentinel logging for CICE outputs
- `9bdde0d` Add ATM barrier script and update forecast post-processing for per-product ranks
- `6ad71ce` Refactor ATM command additions in forecast manager script for improved readability
- `7a107c9` Refactor configuration scripts for improved clarity and maintainability
- `c4250de` Enhance ATM barrier script to remove intermediate sentinels after final log is written; update CICE post-processing to use first forecast-hour ice output as trigger
- `fb525af` Refactor ATM configuration and scripts to support multiple instance groups; update barrier handling and product table management for improved parallel processing
- `6982b4a` Update ush/forecast_postdet.sh
- `9d17c7d` Enhance ATM barrier script to implement a post-done timeout feature for improved handling of pending rows after model completion
- `d060892` Enhance ATM barrier script to track dependency file progress and improve timeout logic for pending rows
- `45210d4` fix(forecast_manager): replace cpfs with cp and add retry logic for file copy operations
- `3b77a31` fix(forecast_atm_barrier): reduce post-done timeout from 1800 to 120 seconds


## 2026-05-26 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `5082a52` fix(CICE_postdet): create empty ice product table for non-manager runs


## 2026-05-26 20:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `c1debe3` fix: gdas ocean/ice COM log sentinels for Rocoto datadep
- `8c3bd29` fix: gdas ocean/ice products use wrong YAML and wrong ICE filename
- `99769cc` fix: gdas oceanice products config and ICE COM filename consistency
- `e685112` fix: correct ocean subset variable names in oceanice_products_gdas.yaml


## 2026-05-26 21:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `cb48e4f` fix: correct enkfgdas efcs_manager datadep and add ocean/ice prod tasks


## 2026-05-26 22:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `bc3038e` fix: enkfgdas ocean/ice prod should not run on first cycle


## 2026-05-27 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `721902a` fix(forecast_predet): adjust FV3 output frequency calculation to include FHOUT
- `d96c4f1` Revert "fix(forecast_manager): replace cpfs with cp and add retry logic for file copy operations"
- `b30836e` fix(forecast_postdet): update handling of fcst_table_ready_seg to support independent forecast manager restarts
- `6c21b9f` fix(forecast_postdet): update table-ready sentinel handling to support independent forecast manager restarts


## 2026-05-27 21:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `d5380b9` fix(forecast_postdet): remove redundant file copy commands and add error handling for unsupported runs
- `fa55125` fix(forecast_postdet): update oceanice_products configuration and enhance MOM6 history file handling for non-manager runs


## 2026-05-28 17:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `ed27e61` (dev/gfs.v17) Update DA resources and default configuration for realtime parallel (#4944)
- `c61b09b` [dev/gfs.v17] Update gitignore for additional sorc directories  (#4941)
- `40e5f7b` (dev/gfs.v17) Reduce debug output from logit decorator (#4933)
- `e4437f0` (dev/gfs.v17) Rename HOMEgfs to HOMEglobal; inherit HOMEgfs and set HOMEglobal in ecf scripts (#4839)
- `34283eb` Addres Dave's suggestions
- `8bda283` Update polling interval and variable names for clarity in forecast scripts
- `2df9a17` Update fcst_manager command to use HOMEglobal path
- `cdcd65e` Update fcst_manager script to use HOMEglobal path
- `11f6467` Update fcst_manager command to use HOMEglobal path


## 2026-05-28 18:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `35bd763` Refactor MOM6 and CICE post-processing to streamline output handling and enable forecast manager for additional run types


## 2026-05-28 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `3f2fa11` Remove MOM6 history file handling for non-manager runs from forecast_postdet.sh
- `ba667e6` Refactor forecast_postdet.sh to enable forecast manager for gfs and gdas runs, removing support for gefs, sfs, and gcafs.
- `354013f` Refactor CICE post-processing in forecast_postdet.sh to remove unused forecast manager logic and streamline output handling.


## 2026-05-28 21:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `a9e873f` Remove CICE history file handling for non-manager runs
- `08e236f` Update cycledef assignment in gfs_tasks.py


## 2026-06-01 05:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `fb68cb3` Update script paths to use global variables for consistency


## 2026-06-01 17:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `99527d8` Update MOM6_postdet function to include additional run types and clarify log handling


## 2026-06-01 18:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `ed86c5b` Fix path to wait_for_file.sh in exglobal_forecast_manager.sh
- `8c3d836` Update script paths to use correct global variables in JGLOBAL_FORECAST_MANAGER and exglobal_forecast_manager.sh


## 2026-06-01 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `cbcbf72` Fix path to forecast_manager.sh in exglobal_forecast_manager.sh
- `8270dc0` Remove redundant ocean and ice production tasks for 'gdas' run in GFSCycledAppConfig

