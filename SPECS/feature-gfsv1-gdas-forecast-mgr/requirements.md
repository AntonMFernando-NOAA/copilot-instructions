# Requirements — `feature/gfsv1-gdas-forecast-mgr`

## Introduction

Extend the GFS Forecast Manager (real-time product copy to COM with
adaptive, component-aware segment management, originally introduced
in PR #4907) to cover the GDAS and ENKFGDAS cycles, and harden the
manager against real-world failure modes: stale product tables on
rewind, missing history-file sentinels on shared filesystems,
multi-segment coordination, and per-product-rank MPMD synchronization.

## Requirements

### Requirement 1: Forecast Manager task available in GDAS and ENKFGDAS

**User Story:** As a workflow operator, I want a `fcst_manager` task
in the GDAS and ENKFGDAS cycles, so that products are copied to COM
in real time for those cycles the same way they are for GFS.

#### Acceptance Criteria

1. THE workflow SHALL emit a `{run}_fcst_manager` metatask when the
   `fcst_manager` config is present, for `run` in {`gfs`, `gdas`,
   `enkfgdas`}.
2. THE `{run}_fcst_manager` metatask SHALL be serial across segments
   (`is_serial=True`), so segment N+1 starts only after segment N's
   manager finishes.
3. WHERE `run == 'enkfgdas'`, THE J-Job SHALL source the efcs job
   header conditionally in `JGLOBAL_FORECAST_MANAGER`.
4. THE ecFlow tree SHALL include manager scripts at
   `ecf/scripts/gfs/forecast/jgfs_fcst_manager.ecf`,
   `ecf/scripts/gdas/forecast/jgdas_fcst_manager.ecf`, and
   `ecf/scripts/enkfgdas/forecast/jenkfgdas_fcst_manager_master.ecf`.
5. THE workflow setup script SHALL generate the enkfgdas forecast
   manager files.

### Requirement 2: Sentinel-based synchronization

**User Story:** As a workflow operator, I want the manager to key off
sentinels rather than raw history files, so that a rewound segment
cannot re-trigger the manager on a stale product table.

#### Acceptance Criteria

1. THE forecast job SHALL write `fcst_started` in `DATAjob` just
   before model launch and clean it on exit.
2. THE forecast job SHALL write `fcst_table_ready_seg#seg#` in
   `DATAjob` after postdet completes for a segment.
3. THE `{run}_fcst_manager_seg#seg#` task SHALL depend on BOTH the
   product table (`atm_atmf_products_seg#seg#_inst0.txt`) AND
   `fcst_table_ready_seg#seg#` via an `and` condition.
4. Product tables SHALL be written to `DATAjob`
   (`${DATAROOT}/${RUN}_forecast.${PDY}${cyc}`) so the manager and
   forecast jobs share a location.
5. WHEN a forecast rerun starts, THE workflow SHALL delete stale
   COM tables so a rewound segment does not immediately re-trigger
   the manager.

### Requirement 3: OCN/ICE component gating

**User Story:** As a workflow operator, I want OCN/ICE product
managers to run only where they make sense, so that no-op tasks
don't clutter the DAG or waste resources.

#### Acceptance Criteria

1. THE OCN/ICE product managers SHALL run only for the full GFS
   cycle in `config.resources`.
2. WHERE `run == 'enkfgdas'` AND the cycle is the first cycle, THE
   OCN/ICE product tasks SHALL be skipped.
3. WHERE `run == 'gdas'`, THE workflow SHALL NOT declare redundant
   ocean/ice production tasks in `GFSCycledAppConfig`.
4. WHERE `run == 'enkfgdas'`, THE `efcs_manager` datadep and OCN/ICE
   prod tasks SHALL be correct (data-dep points at real sentinels;
   product tasks depend on `efcs_manager`).

### Requirement 4: Missing-sentinel fallback for OCN/ICE

**User Story:** As a workflow operator, I want the manager to make
forward progress even when the shared filesystem does not surface
an OCN or ICE history sentinel promptly, so that a visibility lag
does not stall the pipeline.

#### Acceptance Criteria

1. WHEN the model has written the model-done sentinel BUT the OCN or
   ICE history sentinel has not appeared within the configured
   timeout, THE manager SHALL write a synthetic COM log for the
   affected component.
2. THE synthetic log SHALL use the base file name of the expected
   sentinel for clarity.
3. Sentinel size checks SHALL be performed before declaring an
   ocean product ready, to avoid triggering on partially-copied
   files.

### Requirement 5: ATM barrier for MPMD product ranks

**User Story:** As a workflow operator, I want per-product-rank
synchronization for ATM output, so that parallel product processes
do not race each other or the manager.

#### Acceptance Criteria

1. `ush/forecast_atm_barrier.sh` SHALL track dependency-file
   progress across MPMD product ranks.
2. THE barrier SHALL apply a post-done timeout (120s default,
   reduced from an earlier 1800s) after model completion for
   remaining pending rows.
3. WHEN the final log is written, THE barrier SHALL remove
   intermediate per-rank sentinels.

### Requirement 6: Downstream dependency wiring

**User Story:** As a workflow operator, I want tasks that used to
depend on the `{run}_fcst` metatask to prefer `{run}_fcst_manager`
when the manager is enabled, so that they trigger as products land
in COM rather than at end-of-segment.

#### Acceptance Criteria

1. WHERE `fcst_manager` is configured, THE `postsnd` task SHALL
   depend on `{run}_fcst_manager` instead of `{run}_fcst`.
2. WHERE `fcst_manager` is NOT configured, THE dependency SHALL
   remain on `{run}_fcst` (backward compatible fallback).
3. Wave, archive, and cleanup tasks SHALL follow the same
   configuration-conditional pattern where they previously
   depended on `{run}_fcst`.

### Requirement 7: Naming and script-hygiene consistency

**User Story:** As a maintainer, I want consistent naming across
scripts, jobs, configs, and ecFlow, so that grep is reliable.

#### Acceptance Criteria

1. THE canonical names SHALL be `forecast_manager` and
   `fcst_manager` (not `forecast_mgr` / `fcst_mgr`).
2. IN the `gfsv17` code paths, script variables SHALL be `HOMEgfs`
   / `USHgfs` / `SCRgfs` for CI compatibility; `HOMEglobal` remains
   valid elsewhere.
3. RUN-switch case statements in bash SHALL include a default `*)`
   arm (shellcheck SC2249).

### Requirement 8: Post-determination per-component split

**User Story:** As a maintainer, I want per-component
post-determination logic in separate files, so that changes to one
component (e.g. MOM6) do not entangle with unrelated changes to
another (e.g. CICE or WW3).

#### Acceptance Criteria

1. `ush/forecast_postdet.sh` SHALL be split into per-component
   files (FV3, MOM6, CICE, WW3, CMEPS, GOCART).
2. Each component SHALL use the `use_mgr` pattern to gate the
   manager-specific logic; a non-manager run SHALL fall back to
   the original NLN symlink pattern.
3. NLN symlinks SHALL be created for all runs (enkfgfs, gefs, sfs,
   gcafs) in `MOM6_postdet` to preserve existing behavior for
   cycles that do not enable the manager.

## Work Log

_Appended on demand — ask Kiro to "log the work" and a summary of
recent chat activity will be inserted here. Do not edit prior
entries — add new entries at the bottom._

<!-- WORKLOG:BEGIN -->

### 2026-07-06T19:55Z

- Created spec directory `.kiro/specs/feature-gfsv1-gdas-forecast-mgr/` seeded from git history since branch base `865eed8ec`.
- Built `context.md` covering the Forecast Manager extension to GDAS/ENKFGDAS, sentinel model, ATM barrier, OCN/ICE fallback, and post-determination per-component split.
- Built `requirements.md` with 8 EARS requirements: manager available in GDAS/ENKFGDAS, sentinel synchronization, OCN/ICE gating, missing-sentinel fallback, ATM barrier, downstream dependency wiring, naming hygiene, and postdet split.
- Reconstructed scope from `git log --no-merges dev/gfs.v17..feature/gfsv1-gdas-forecast-mgr` (~800 files touched; core work in `ush/forecast_manager.sh`, `ush/forecast_atm_barrier.sh`, `ush/wait_for_table.sh`, `ush/forecast_postdet.sh`, `dev/jobs/JGLOBAL_FORECAST_MANAGER`, `dev/scripts/exglobal_forecast_manager.sh`, `dev/workflow/rocoto/gfs_tasks.py`, and ecf `jgfs_fcst_manager.ecf` / `jgdas_fcst_manager.ecf` / `jenkfgdas_fcst_manager_master.ecf`).
- Caveat noted: chat history from other Kiro sessions is not accessible to this agent; the summary is git-derived. User confirmed git history was acceptable ("yeah. use history").
- Open follow-ups flagged in context.md: `TODO for gefs/sfs/gcafs` manager coverage; verify no `KEEPDATA revert` markers survive to tip; confirm UFS-WM hash alignment for MOM6 hourly logs.

### 2026-07-06T22:30Z — DATA cleanup race fix: split "history done" vs "job finalized" sentinels

Prompted by user observation that commit `d3338ad` ("Add model-done sentinel handling for forecast manager synchronization") did not fully close the race between `JGLOBAL_FORECAST_MANAGER`'s `rm -rf "${DATAjob}"` and the forecast job's `*_out` restart copies. Root-caused, redesigned, and generalized.

#### Root cause
`fcst_done_seg${FCST_SEGMENT}` was written in `exglobal_forecast.sh` immediately after the `${APRUN_UFS}` model exec returned, *before* `FV3_out` / `MOM6_out` / `CMEPS_out` / `WW3_out` / `CICE_out` / `GOCART_out` copied restart files from `${DATArestart}` / `${DATAoutput}` to COM. `forecast_manager.sh`'s atmf instance-0 finalization row triggered on that sentinel, so the manager could exit and `JGLOBAL_FORECAST_MANAGER`'s cleanup could wipe `${DATAjob}` while the forecast job was still reading files inside it.

#### Fix — two sentinels with distinct semantics
1. **`fcst_history_done_seg${seg}`** (renamed from `fcst_done_seg`) — "UFS model exec returned; every history / period file the model itself writes is on disk." Written where `fcst_done_seg` used to be. Continues to drive:
   - OCN / ICE missing-sentinel fallback in `ush/forecast_manager.sh`.
   - The `fcst_history_done_idle` graceful-exit idle counter in `ush/forecast_manager.sh`.
   - The WARN-drain countdown in `ush/forecast_atm_barrier.sh`.
2. **`fcst_finalized_seg${seg}`** (new) — "forecast J-job has completed every `*_out` restart copy AND its own `DATA` / `DATArestart` cleanup and is exiting." Only used to gate the atmf instance-0 finalization row so the manager rank does not exit (and therefore `JGLOBAL_FORECAST_MANAGER`'s `rm -rf "${DATAjob}"` does not fire) until the forecast job is truly done touching `DATAjob`.

#### Sentinel write moved to the J-job level, via EXIT trap
Iterated on placement:
1. First tried writing `fcst_finalized_seg` at the bottom of `exglobal_forecast.sh` after all `*_out`. User pointed out `JGLOBAL_FORECAST`'s post-work (DBN alerts, `cat pgmout`, `rm -rf "${DATA}"`, optional `rm -rf "${DATArestart}"`) still ran after the ex-script returned, so the race persisted.
2. Moved the write to the very end of `dev/jobs/JGLOBAL_FORECAST`, right before `exit 0`.
3. User requested a failure-path trap so the manager exits promptly instead of waiting `FCST_MGR_TIMEOUT` on `err_exit` / `set_strict` trip / signal.
4. First trap iteration used an in-line bash function `_fcst_finalize_on_exit`. User pushed back — "don't use a function. we just use scripts."
5. Extracted the logic to a plain script `ush/fcst_finalize.sh` (no function definition, top-level commands). J-job installs a one-line trap that invokes the script.
6. User asked to generalize into a reusable utility. Renamed to **`ush/write_status_sentinel.sh`** with signature `<rc> <sentinel_path>`. Idempotent (never overwrites), silent-skip on missing args (safe inside a trap), reads no environment of its own. Writes `finalized at <UTC ts>` when rc=0, `aborted rc=<rc> at <UTC ts>` otherwise. User also had the `label` argument dropped as unnecessary.

Final J-job trap (installed right after `${DATAjob}` is exported, before any real work):
```
# shellcheck disable=SC2064
trap '"${USHglobal}/write_status_sentinel.sh" "$?" "${DATAjob}/fcst_finalized_seg${FCST_SEGMENT:-0}"' EXIT
```

#### Failure propagation into the manager
Added an abort-check block at the top of each poll iteration in `ush/forecast_manager.sh` (fires in every MPMD rank, not just atmf inst-0):
```
if [[ -n "${FCST_FINALIZED_SENTINEL:-}" && -f "${FCST_FINALIZED_SENTINEL}" ]]; then
    _fcst_final_content=$(< "${FCST_FINALIZED_SENTINEL}")
    if [[ "${_fcst_final_content}" == *aborted* ]]; then
        _fcst_rc=1
        if [[ "${_fcst_final_content}" =~ rc=([0-9]+) ]]; then
            _fcst_rc="${BASH_REMATCH[1]}"
            if ((_fcst_rc == 0)); then _fcst_rc=1; fi
        fi
        exit "${_fcst_rc}"
    fi
fi
```
`scripts/exglobal_forecast_manager.sh` (and its hardlink under `dev/scripts/`) now exports `FCST_FINALIZED_SENTINEL="${DATAjob}/fcst_finalized_seg${FCST_SEGMENT}"` alongside the existing `FCST_HISTORY_DONE_SENTINEL`.

#### Rename churn (semantic clarity)
- `fcst_done_seg${seg}`   → `fcst_history_done_seg${seg}` (filename)
- `FCST_DONE_SENTINEL`     → `FCST_HISTORY_DONE_SENTINEL` (env var)
- `_fcst_done_fallback`    → `_fcst_history_done_fallback` (local, `ush/forecast_manager.sh`)
- `fcst_done_idle`         → `fcst_history_done_idle`      (local, `ush/forecast_manager.sh`)
- Comment / log messages in `ush/forecast_manager.sh` and `ush/forecast_atm_barrier.sh` updated accordingly. Data-file-trigger pattern in `forecast_manager.sh` widened to match `fcst_history_done_seg*` **and** `fcst_finalized_seg*` (in addition to the existing `*.nc` case for ice).

#### Documentation correction in JGLOBAL_FORECAST_MANAGER
User asked to verify whether OCN / ICE history is copied for GDAS and ENKFGDAS. Traced code paths: `use_mgr_ice="YES"` in `CICE_postdet` and the OCN / ICE rank launch in `exglobal_forecast_manager.sh` both gate on `${RUN} =~ ^(gfs|gdas|enkfgdas)$`, so OCN / ICE history are managed in real time by the manager (not by the forecast job) for all three RUNs. The header block in `dev/jobs/JGLOBAL_FORECAST_MANAGER` said the opposite — updated the abstract to reflect current behavior: manager handles FV3ATM + WW3 + MOM6 + CICE history; forecast job's `*_out` functions handle restarts only.

#### GDAS half-cycle verification
User asked whether OCN / ICE history are copied specifically for the GDAS half cycle. Confirmed: `gdas_half` is a rocoto cycledef label, not a distinct RUN — the half cycle runs with `RUN=gdas`, so every RUN gate in the code (`gfs | gdas | enkfgdas`) matches. Ocean / ice ranks are launched, and whatever history the (short) half-cycle forecast produces gets copied. If `FHMAX` is shorter than one `FHOUT_OCN` / `FHOUT_ICE` interval the ranks graceful-exit via `fcst_history_done_seg` idle-counter. Flagged (but did not implement) an optional short-circuit in `exglobal_forecast_manager.sh` to skip launching OCN / ICE ranks when the forecast produces no output.

#### Files touched this session
- `ush/write_status_sentinel.sh` — **new**, executable. General-purpose EXIT-trap sentinel writer.
- `dev/jobs/JGLOBAL_FORECAST` — installed EXIT trap, removed the earlier attempt at an inline `_fcst_finalize_on_exit` function, updated the trailing comment.
- `dev/jobs/JGLOBAL_FORECAST_MANAGER` — updated header abstract (OCN / ICE now streamed by manager, not forecast job).
- `scripts/exglobal_forecast.sh` (hardlinked to `dev/scripts/exglobal_forecast.sh`) — write `fcst_history_done_seg` in place of `fcst_done_seg`; removed the finalization write here (moved to J-job trap).
- `scripts/exglobal_forecast_manager.sh` (hardlinked to `dev/scripts/exglobal_forecast_manager.sh`) — export `FCST_HISTORY_DONE_SENTINEL` and new `FCST_FINALIZED_SENTINEL`.
- `ush/forecast_manager.sh` — renamed identifiers; widened data-file-trigger pattern; added abort-propagation block at top of poll loop.
- `ush/forecast_postdet.sh` — atmf inst-0 finalization row now points at `fcst_finalized_seg${seg}` with `${RUN}.t${cyc}z.fcst_finalized` COM sentinel; updated comment.
- `ush/forecast_atm_barrier.sh` — renamed `FCST_DONE_SENTINEL` → `FCST_HISTORY_DONE_SENTINEL`; updated log strings and comments.
- `.kiro/steering/work-context.md` — updated the "sentinel contract" bullets to describe both sentinels.

#### Follow-ups deferred
- Belt-and-suspenders: optionally add the finalization row to every ATM instance's atmf table (not just inst-0) so a crash of inst-0 still leaves a rank waiting. Not implemented — current design relies on `err_exit` in `JGLOBAL_FORECAST_MANAGER` to skip cleanup on manager rank failure, which already prevents the race in that path.
- Optional half-cycle short-circuit for OCN / ICE ranks when `FHMAX < FHOUT_OCN` (or `FHOUT_ICE`). Not implemented — graceful-exit already handles it, just at the cost of a few rank-seconds.

<!-- WORKLOG:END -->
