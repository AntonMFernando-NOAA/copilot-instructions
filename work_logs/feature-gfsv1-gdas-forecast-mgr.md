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


## 2026-06-01 21:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `de57b4a` Refactor GFSCycledAppConfig to streamline run configuration logic


## 2026-06-02 01:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `66155ae` Restrict OCN and ICE product table checks to 'gfs' run in exglobal_forecast_manager.sh
- `4128cfb` Restrict ocean and ice product managers to run only for the full GFS cycle in config.resources
- `f3ee46e` Restrict ocean and ice history file declarations to 'gfs' run in JGLOBAL_FORECAST_MANAGER and update dependencies in GFSTasks for proper file management


## 2026-06-02 02:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `b612488` Update forecast manager task allocation based on inline post-processing settings
- `aac94bb` Update JGLOBAL_FORECAST_MANAGER to conditionally source job header for efcs configuration


## 2026-06-03 17:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `53a54d4` Refactor variable names in split_table_by_sentinel function for clarity
- `af9af43` Update script paths to use USHglobal for consistency
- `d256c1f` [dev/gfs.v17] Write UFSWM logs to output directories and add UPP foundation T land mask (#4946)
- `92ab644` [dev/gfs.v17] Update package for release versions of expdir/comroot (#4948)
- `314e1a2` (dev/gfs.v17) Introduce the auxiliary verification and archiving workflow (#4950)
- `82b048c` update CICE log sentinels


## 2026-06-03 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `e03ffe1` KEEPDATA- revert this when merging


## 2026-06-18 19:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `9d4c6dd` [dev/gfs.v17] Forecast Manager: Real-Time Product Copy to COM with Adaptive, Component-Aware Segment Management (#4907)
- `1bac467` [dev/gfsv17] ecflow updates  (#4975)
- `62f4977` (dev/gfs.v17) Track changes in /jobs and /scripts via linking (#4977)
- `06889b9` Add Forecast Manager Configs to `parm/config/gfs` (#4980)
- `48ad928` feat(gfs): Add conditional inline post logic to Forecast Manager resource config
- `806abd5` chore(forecast): Update Forecast Manager job script syntax
- `445e428` style(forecast_manager): Fix spacing in conditional statements
- `9a87056` HOTFIX: Update ocean log file location (#4989)
- `b710663` feat(forecast_manager): Enable ice product manager for gdas and enkfgdas cycles
- `73b2551` (dev/gfs.v17) Update the location of the master GRIB2 analysis files (#4958)
- `5d9190c` HOTFIX: (dev/gfs.v17) Update marineanalysis rundirs to include $RUN  (#4990) (#4991)
- `1f6a059` (dev/gfs.v17) Apply fixes needed for ecflow (#4997)
- `0396cb7` (dev/gfsv.17) Add utility script to check for dead links (#4799) (#5001)
- `c1b2607` feat(forecast): Add Forecast Manager tasks to GFS and GDAS cycles
- `fea3a4a` feat(ecf): Add enkfgdas forecast manager file generation to setup script
- `4e9c66b` [dev/gfs.v17] Add marine observation processing to dev/gfs.v17 workflow (#4922)
- `cd5996d` (dev/gfs.v17) Archive MPMD logs in DATA instead of piping back to the parent log (#5020)
- `ab5f38d` [dev/gfs.v17] Module files update 1: non-gdas components to use operational modules on wcoss2 (#5010)
- `dc95693` preupdate to add mom6 sentinels (make sure to update the ufs model before approving)
- `e42f47a` (dev/gfs.v17) Fix 2-meter water vapor moist bias in western US (#5011)
- `82d8e2d` (dev/gfs.v17) Rename GDAS/ENKFGDAS ocean output prefix from `ocn_da` to `ocn` (#5016)
- `74fd8af` Lay groundwork for custom GDAS compiler flags (#5026)
- `05749df` (dev/gfs.v17) Remove NAM dependency from GFSv17 (#5032)
- `7033fc6` [v17] bug fix and code owner update (#5033)
- `2abd302` [dev/gfs.v17] Update bmat ecflow triggers and some other ecflow cleanup (#5035)
- `2b43c9d` Update UFSWM hash -- MOM6 hourly output logs
- `afdae27` Set MOM6_HISTFREQ_N to a fixed value of 1 in parsing_ufs_configure.sh
- `dec1c0e` Update MOM6 output file naming to reflect hourly sentinel writes with MOM6_HISTFREQ_N=1


## 2026-06-18 21:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `60755b1` Refactor MOM6 output handling to set MOM6_HISTFREQ_N based on run type, ensuring correct sentinel suffixes for hourly and 6-hourly outputs.


## 2026-06-18 22:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `219472f` Update COM_BASE path to conditionally include MEMDIR for ensemble runs
- `eb3d0e1` Refactor Stage IC task to enhance clarity and maintainability of initial conditions path variables


## 2026-06-24 18:00 UTC (auto)
**Branch:** `feature/gfsv1-gdas-forecast-mgr`
**New commits:**
- `5eb449a` Update dev/jobs/JGLOBAL_FORECAST_MANAGER
- `9b11c48` (dev/gfs.v17) Update v17 prep jobs in ecflow to operations-like configuration (#5013)
- `e815721` [dev/gfsv17] update to not have stop string in wave output (#5045)
- `ea7161c` [dev/gfs.v17] Add back bmat_init forecast dependencies (#5046)
- `b0aae68` (dev/gfs.v17) Replace or Remove CDATE variable with PDY and cyc throughout codebase (#5039)
- `f977637` [dev/gfs.v17] Add in Ed Givelberg's marine obs report for NCO SDM (#5029)
- `1e3c283` (dev/gfs.v17) Add %manual documentation blocks to 77 ecFlow scripts (#5027)
- `3cbf91e` (dev/v17) Release Notes (#5034)
- `9b898ea` [dev/gfs.v17] Hotfix for analysis ecf triggers (#5057)
- `03c41de` Update submodules to match upstream dev/gfs.v17: gfs_utils.fd, ufs_model.fd
- `dd2a39a` Fire release_<RUN>_fcst_manager event for both gfs and gdas
- `5e13f83` Update dev/scripts/exglobal_forecast.sh
- `4ca2ad9` Add default case to RUN switch (shellcheck SC2249)

