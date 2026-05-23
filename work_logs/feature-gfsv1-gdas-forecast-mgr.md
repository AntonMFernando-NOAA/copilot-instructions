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

