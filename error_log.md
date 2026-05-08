# Error Log — Anton Fernando
# Updated every time a debug session is run with Copilot.
# Reference in prompts: `#file:/home/Anton.Fernando/copilot-instructions/error_log.md`
#
# Entry format:
#   ## YYYY-MM-DD — <script or component>
#   **Error:** exact message or symptom
#   **Root cause:** what actually caused it
#   **Fix:** what was changed
#   **Files:** list of files involved
#   **Notes:** patterns to watch for, related gotchas

---

## 2026-05-08 — ush/forecast_postdet.sh — MOM6 output filename suffix + sentinel time

**Error 1:** `cp: cannot stat '.../ocn_2021_03_23_21.nc': No such file or directory`
— OCN rank of `gfs_fcst_manager_seg0` MPMD process aborted at first 6h average period.

**Root cause 1:** `forecast_postdet.sh` built the MOM6 source filename as
`ocn_YYYY_MM_DD_HH.nc` but MOM6 actually appends a `_MM` (minutes) field and
always writes `ocn_YYYY_MM_DD_HH_00.nc`. The `_00` suffix was missing from both
the `ocn_lead1_` branch and the standard branch of the product-table generation loop.

**Fix 1:** Added `_00` before `.nc` in the `source_file` assignments for both
branches (lines 805 and 808 of `ush/forecast_postdet.sh`).

**Error 2:** `FileNotFoundError: Source file '.../gfs.t12z.6hr_avg.f006.nc' does not exist`
— `gfs_ocean_prod_f006` DEAD; the f006 ocean history file was never copied to COM.

**Root cause 2:** `ocn_log_time` (the sentinel timestamp that `forecast_manager.sh`
polls for) was computed using `${last_fhr}` (period start) instead of `${fhr}`
(period end). For the very first output period (f006, `last_fhr=0`) this produced
a sentinel timestamp of `20210323.120000.mom6.06h` — exactly the cycle start time —
which MOM6 never writes. MOM6 writes sentinels at the *end* of each averaging period.
All later periods (f012–f084) used the sentinel from the *previous* period, which
happened to already exist by the time the manager checked, so they all succeeded.
Only f006 had an unreachable trigger.

**Fix 2:** Changed `${last_fhr}` → `${fhr}` in the `ocn_log_time` date calculation
(line 819 of `ush/forecast_postdet.sh`).

**Manual recovery (current run):**
- Copied `ocn_2021_03_23_15_00.nc` → `gfs.t12z.6hr_avg.f006.nc` in COM ocean history.
- Wrote `gfs.t12z.ocn.log.f006.txt` sentinel manually (same content as f012 sentinel;
  both describe the same MOM6 output file for the first 6h average period).
- Rewound and re-submitted `gfs_ocean_prod_f006`.

**Files:** `ush/forecast_postdet.sh` (lines 805, 808, 819)

**Notes:**
- MOM6 always appends `_HH_MM` (hours + minutes) to its NetCDF output filenames;
  the minutes field is always `_00` for hourly-aligned averaging periods.
- MOM6 sentinel logs are written at the *end* of each averaging period, not the start.
  Product-table sentinel times must use the period-end forecast hour (`fhr`), not the
  period-start (`last_fhr`).
- The off-by-one sentinel bug only manifests on the *first* output period of a run
  because every subsequent period's sentinel already exists from the previous period.

---

## 2026-05-04 — monitor_expdirs.sh (line 233)

**Error:** `/home/Anton.Fernando/utils/monitor_expdirs.sh: line 233: built: unbound variable`

**Root cause:** Variable `built` is declared and populated only inside the
`if [[ -f "${rich_info}" ]]` branch (line 176). For experiments that only have the
legacy `git_info.log` path, `built` is never initialised. The check at line 233
(`if [[ -n "${built}" ]]`) then hits an unbound variable under any strict-mode or
nounset-equivalent behaviour.

**Fix:** Initialise `built`, `build_current`, and `build_time` before the `if/elif`
block that reads metadata (not inside it), so they are always defined.

**Files:** `/home/Anton.Fernando/utils/monitor_expdirs.sh`

**Notes:** Classic shell trap — local variable declarations inside a conditional branch
are invisible to code that runs after the branch exits. Always initialise defensive
variables at function/script scope before any conditional reads them.
