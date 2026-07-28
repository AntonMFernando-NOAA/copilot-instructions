# Branch Context: `feature/gfsv17-fcst-atmos`

**Repo:** `global-workflow_gfsv17`
**Branch slug:** `feature-gfsv17-fcst-atmos`
**Base / parent work:** extends `feature/gfsv1-gdas-forecast-mgr` (the
Forecast Manager subsystem — real-time product copy to COM, sentinel
synchronization, ATM barrier, per-component postdet split).
**Tracking issue:** [NOAA-EMC/global-workflow#5130](https://github.com/NOAA-EMC/global-workflow/issues/5130)
— "(dev/gfs.v17) Retain ATM product logs" (labels: `ee2`, `GFS v17 - GW Team`).

## Issue summary (#5130)

The forecast manager produces per-product log files for the ATM products,
copies the products to COM, then **deletes** those log files. The logs
should instead be **retained** in COM so downstream jobs and models can
confirm the products were copied correctly.

### Acceptance criteria
1. Product log files are retained in COM.
2. Restart capabilities are retained.
3. Ideally, on restart, the forecast manager knows which products have
   already been copied and does not copy them again.

## Where the logs are produced and destroyed (grounded in code)

- `ush/forecast_postdet.sh` (FV3_postdet, `use_mgr == YES`, ~lines 382–411):
  builds the per-product manager tables and the ATM **barrier** table.
  Per-product COM logs:
  - `${COMOUT_ATMOS_HISTORY}/${RUN}.t${cyc}z.log.atm.atmf.f${FH3}.txt`
  - `${COMOUT_ATMOS_HISTORY}/${RUN}.t${cyc}z.log.atm.sfcf.f${FH3}.txt`
  - `${COMOUT_ATMOS_MASTER}/${RUN}.t${cyc}z.log.atm.grib.f${FH3}.txt` (WRITE_DOPOST)
  - `${COMOUT_ATMOS_MASTER}/${RUN}.t${cyc}z.log.atm.flux.f${FH3}.txt` (WRITE_DOPOST)
  Each per-product log is a copy of the model write-component sentinel
  `log.atm.f${FH3}`. Barrier row =
  `final_com_log (${RUN}.t${cyc}z.log.f${FH3}.txt)  <deps...>`.

- `ush/forecast_manager.sh`: per-product MPMD ranks copy data first, then the
  per-product log last. RERUN safety already present: `if [[ -f "${this_cl}" ]]`
  marks all rows for that sentinel done → skips re-copy.

- `ush/forecast_atm_barrier.sh`: once all deps for a forecast hour are present,
  writes `final_com_log` then **`rm -f "${deps[@]}"`** (normal path) and
  **`rm -f "${warn_deps[@]}"`** (WARN-drain path). These two removals are the
  deletion the issue wants stopped.

## Proposed approach

Stop the barrier from deleting the per-product logs (remove the two `rm -f`
calls, update the surrounding comments). This alone satisfies all three
acceptance criteria:
- (1) logs stay in COM;
- (2) the combined `log.f${FH3}.txt` downstream sentinel is still written, so
  the restart/sentinel contract is unchanged;
- (3) the manager's existing `if [[ -f "${this_cl}" ]]` RERUN guard now fires
  because the per-product log survives, so already-copied products are not
  re-copied; the barrier's own `if [[ -f "${final_log}" ]]` guard handles
  completed hours.

## EE2 / compliance notes

- Issue carries the `ee2` label: retained logs become permanent COM
  deliverables. Existing per-product names already satisfy the EE2 file-naming
  convention (`model.tCCz.type.fHHH.ext`, lowercase, no embedded date; date is
  in the parent COM directory).
- KB (mcp-rag) is indexed on the `develop` tenant and has **no** branch-specific
  forecast-manager content; it corroborates naming standards only, not this
  branch's code. All code findings above come from reading the working tree.

## Open questions / follow-ups

- Confirm whether downstream consumers (post/products/archive) should read the
  per-product logs or continue keying only off the combined `log.f${FH3}.txt`.
- Confirm the retained per-product logs' content is sufficient (currently a
  copy of `log.atm.f${FH3}`); may want an explicit "copied OK" marker.
- The WARN-drain path currently writes a WARN final sentinel and removes deps;
  decide whether retained deps in that degraded path help post-mortem.

## Session log

### 2026-07-28 — Spec kickoff
- Read prior branch context (`feature-gfsv1-gdas-forecast-mgr`) and issue #5130.
- Traced the log lifecycle across `forecast_postdet.sh`, `forecast_manager.sh`,
  `forecast_atm_barrier.sh`. Identified the two `rm -f` calls in the barrier as
  the deletion point.
- Confirmed manager RERUN safety already covers criterion 3 once logs are kept.
- Seeded this spec (context + requirements). No code changed yet.

### 2026-07-28 (cont.) — Spec scaffolding committed to disk

- Created the branch spec directory `.kiro/specs/feature-gfsv17-fcst-atmos/`
  with:
  - `context.md` (this file) — issue summary, grounded log-lifecycle trace,
    proposed approach, EE2 notes.
  - `requirements.md` — 4 EARS requirements: (1) retain per-product ATM logs in
    COM, (2) preserve restart + combined-sentinel contract, (3) skip re-copy on
    restart via existing manager RERUN guard, (4) EE2 file-naming compliance.
    Added Glossary + Introduction; fixed spec-format diagnostics (heading
    `# Requirements Document`, `### Requirement N: Title`, `**User Story:**`).
    Now diagnostics-clean.
  - `.config.kiro` — specType=feature, workflow=requirements-first, issue link,
    `extends: feature-gfsv1-gdas-forecast-mgr`.
- Confirmed `.kiro/` is in `.git/info/exclude` (line 7) — spec tree stays out of
  the workflow repo.
- **No workflow code changed** this turn (barrier edit not yet applied).

**Open questions raised to user (awaiting answers before design/impl):**
1. WARN-drain path in `forecast_atm_barrier.sh`: retain deps there too?
   (drafted req as yes — helps post-mortem.)
2. Retained per-product log content: keep as copy of `log.atm.f${FH3}`, or add
   an explicit per-product "copied OK" marker line?
3. Proceed to design.md + tasks.md, or go straight to the (small) barrier edit?
