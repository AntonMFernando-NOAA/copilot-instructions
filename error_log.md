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

---

## 2026-05-15 — forecast_manager.sh shfmt CI violations (3 bot fixup commits)

**Error:** Three consecutive GitHub Actions bot commits were required to fix the same file
(`ush/forecast_manager.sh`) because generated code violated shfmt formatting rules enforced
by the global-workflow CI pipeline.

**Root cause:** Two shfmt rules were not followed in the generated code:
1. `2>/dev/null` written without a space → CI changed to `2> /dev/null`
2. `continue  # comment` written with double space → CI changed to `continue # comment`

**Fix:** Already recorded in `.github/copilot-instructions.md` of the repo. The rules are:
- **Shell redirections**: always write `2> /dev/null` (space after `>`), never `2>/dev/null`
- **Inline comments**: always use exactly one space before `#`, never two: `continue # reason`

**Files:** `ush/forecast_manager.sh`

**Notes:** shfmt is enforced via GitHub Actions on every push. These two violations will
always trigger automated fixup commits. Check all generated shell code for these patterns
before finalising. Use `grep "2>/dev/null\|  #" <file>` to catch violations quickly.

---

## 2026-05-15 — Last ocean output (f120) never copied to COM

**Error:**
```
ERROR - file_utils: Source file '.../gfs.t18z.6hr_avg.f120.nc' does not exist and is required, ABORT!
```
The `oceanice_products` task for the last forecast hour (f120) failed because the file was not in `COMIN_OCEAN_HISTORY`.

**Root cause (two interacting parts):**

1. **MOM6 period-log timing**: MOM6 writes its averaging-period sentinel log at the START of the NEXT period, not the end of the current one. For the LAST averaging period (e.g., 114→120 h), there is no next period, so `DATA/YYYYMMDD.HH0000.mom6.06h` is **never written** by the model.  The manager (`forecast_manager.sh`) polls for this log, the `fcst_done_idle` countdown reaches `FCST_MGR_DONE_IDLE_MAX=3`, and the manager exits with a WARNING—without ever copying `gfs.t18z.6hr_avg.f120.nc` to COM.

2. **Rocoto `or` dependency**: The ocean-products Rocoto task depends on **either** the COM log appearing **or** the `gfs_fcst_manager` metatask completing (`dep_condition='or'`). The manager completes (having skipped the last period), the `gfs_fcst_manager` metatask succeeds, which fires ALL ocean-products tasks—including f120—even though its data file was never placed in COM.

**Fix:** Added a **model-done data-existence fallback** in `forecast_manager.sh`. When:
- `FCST_DONE_SENTINEL` is present (model is done), **and**
- `local_log` (model period log) does not exist, **and**
- `local_log != local_data` (this is a model-log-sentinel entry, not data-as-sentinel), **and**
- `local_data` (the .nc output file) exists

...the manager treats data-file existence as the trigger and writes a **synthetic** `com_log` (`basename completed timestamp`) to signal completion to downstream Rocoto tasks, instead of trying to `cpfs` the non-existent period log.

**Files:** `ush/forecast_manager.sh`

**Notes:** The fallback fires in the first poll cycle after `FCST_DONE_SENTINEL` appears, which is safe because: the model is provably done, the 30-second poll interval has elapsed, and `FCST_DONE_SENTINEL` is only written after `srun` returns (model fully finished). This is similar to the data-as-sentinel path used for CICE, but triggered by model completion rather than by the data file itself acting as the log.

---

## 2026-05-15 — shfmt: multi-line `[[ ]]` condition format (4th bot fixup)

**Error:**
```
ush/forecast_manager.sh:81:-            if [[ "${component}" == "ocn" \
ush/forecast_manager.sh:82:-                  && "${local_log[i]}" == "${local_log[count-1]}" \
ush/forecast_manager.sh:83:-                  && -n "${FCST_DONE_SENTINEL:-}" && -f "${FCST_DONE_SENTINEL}" \
ush/forecast_manager.sh:84:-                  && -f "${local_data[i]}" ]]; then
ush/forecast_manager.sh:81:+            if [[ "${component}" == "ocn" &&
ush/forecast_manager.sh:82:+                "${local_log[count - 1]}" &&
...
```

**Root cause:** Two additional shfmt rules violated when writing multi-line `[[ ]]` conditions:
1. `&&` must go at the **end** of the line, not at the start of the next line with a `\` continuation
2. Arithmetic expressions inside `[[ ]]` (e.g. array indices) require spaces around `-`: `count - 1` not `count-1`
3. Continuation lines indent by 4 spaces relative to the `if`, not aligned to `[[`

**Wrong:**
```bash
if [[ "${component}" == "ocn" \
      && "${local_log[i]}" == "${local_log[count-1]}" \
      && -f "${FCST_DONE_SENTINEL}" ]]; then
```

**Correct (shfmt):**
```bash
if [[ "${component}" == "ocn" &&
    "${local_log[i]}" == "${local_log[count - 1]}" &&
    -f "${FCST_DONE_SENTINEL}" ]]; then
```

**Files:** `ush/forecast_manager.sh`

**Notes:** Always use `&&` at end-of-line for multi-line `[[ ]]`. Use `grep "\\ &&\|\\\\$" <file>` to catch backslash-continuation violations quickly.

---

## 2026-05-21 — shellcheck SC2129: consecutive redirects to the same file

**Error:**
```
[shellcheck] reported by reviewdog 🐶
Consider using { cmd1; cmd2; } >> file instead of individual redirects. SC2129
scripts/exglobal_forecast_manager.sh
```

**Root cause:** Multiple consecutive `echo ... >> "${file}"` lines targeting the same file trigger SC2129. The global-workflow CI runs shellcheck via reviewdog and auto-flags this as a style violation.

**Fix:** Group consecutive redirects with `{ ... } >> "${file}"`:

**Wrong:**
```bash
echo "${USHgfs}/forecast_manager.sh atm_atmf ${ATM_ATMF_TABLE}" >> "${FCST_MANAGER_CMDFILE}"
echo "${USHgfs}/forecast_manager.sh atm_sfcf ${ATM_SFCF_TABLE}" >> "${FCST_MANAGER_CMDFILE}"
echo "${USHgfs}/forecast_manager.sh atm_grib ${ATM_GRIB_TABLE}" >> "${FCST_MANAGER_CMDFILE}"
```

**Correct:**
```bash
{
    echo "${USHgfs}/forecast_manager.sh atm_atmf ${ATM_ATMF_TABLE}"
    echo "${USHgfs}/forecast_manager.sh atm_sfcf ${ATM_SFCF_TABLE}"
    echo "${USHgfs}/forecast_manager.sh atm_grib ${ATM_GRIB_TABLE}"
} >> "${FCST_MANAGER_CMDFILE}"
```

**Files:** `scripts/exglobal_forecast_manager.sh`

**Notes:** A single `echo` inside a loop body is not flagged — only consecutive redirects at the same indentation level trigger SC2129. Always group 2+ consecutive redirects to the same file.
