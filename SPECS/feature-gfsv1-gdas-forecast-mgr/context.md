# Branch Context: `feature/gfsv1-gdas-forecast-mgr`

**Repo:** `global-workflow_gfsv17`
**Branch slug:** `feature-gfsv1-gdas-forecast-mgr`
**Base:** `dev/gfs.v17` (merge-base `5343000ca`)
**Tip:** `779545ffd`

## Summary

Extend the GFS Forecast Manager subsystem (originally introduced in
PR #4907) to cover the **GDAS** and **ENKFGDAS** cycles, together
with a substantial hardening of the manager machinery: real-time
product copy to COM with per-component segment handling, sentinel-
based synchronization between the model and downstream jobs, an ATM
barrier script for per-product-rank coordination, and per-component
split of the forecast post-determination logic.

## Scope

Reconstructed from git history (`git log --no-merges
dev/gfs.v17..feature/gfsv1-gdas-forecast-mgr`). Author-owned work
touches roughly 800+ files vs the base; the substantive design work
concentrates in the forecast-manager subsystem below.

## Core Additions

### New scripts
- `ush/forecast_manager.sh` — per-segment product copy loop, sentinel
  polling, model-done fallback, synthetic sentinel writer for
  ocean/ice when history files land without matching sentinels.
- `ush/forecast_atm_barrier.sh` — ATM barrier: tracks dependency-file
  progress across MPMD product ranks, applies a post-done timeout
  after model completion, removes intermediate sentinels once the
  final log is written.
- `ush/wait_for_table.sh` — poll-until-ready helper for the segment
  product tables written by the model to `DATAjob`.
- `ush/write_status_sentinel.sh` — writer for `fcst_started`,
  `fcst_table_ready_seg#`, and model-done sentinels.
- `dev/jobs/JGLOBAL_FORECAST_MANAGER` — J-Job (conditionally sources
  the efcs job header for ENKFGDAS).
- `dev/scripts/exglobal_forecast_manager.sh` — ex-script with MPMD
  component handling and per-component gating for OCN/ICE.

### New ecFlow scripts
- `ecf/scripts/gfs/forecast/jgfs_fcst_manager.ecf`
- `ecf/scripts/gdas/forecast/jgdas_fcst_manager.ecf`
- `ecf/scripts/enkfgdas/forecast/jenkfgdas_fcst_manager_master.ecf`

### New configs
- `dev/parm/config/gfs/config.fcst_manager`
- `dev/parm/config/sfs/config.fcst_manager`
- `parm/config/gfs/config.fcst_manager`

### Rocoto integration
- `dev/workflow/rocoto/gfs_tasks.py` — adds `fcst_manager` metatask
  (`is_serial=True`, one segment per iteration). Depends on both the
  atmos product table (`atm_atmf_products_seg#seg#_inst0.txt`) AND
  the `fcst_table_ready_seg#seg#` sentinel to guard against stale
  tables surviving a rewind. Product tables written to `DATAjob` so
  fcst and fcst_manager share a location. `postsnd`, wave, and
  archive tasks conditionally depend on `{run}_fcst_manager` when
  the manager is enabled, falling back to `{run}_fcst`.

### Forecast post-determination refactor
- `ush/forecast_postdet.sh` — split into per-component files
  (FV3, MOM6, CICE, WW3, CMEPS, GOCART) with a `use_mgr` pattern
  used by ATM/WW3 and later extended to OCN/ICE.
- Product tables moved from `COMOUT_CONF` to `DATA`, then to
  `DATAjob` for shared access with the manager.
- Stale COM tables are removed on forecast rerun so a rewound
  segment does not immediately re-trigger the manager.

### Sentinel model
- `fcst_started` — written just before model launch, cleaned on exit.
- `fcst_table_ready_seg#` — written after postdet completes for a
  segment.
- Model-done fallback — manager writes synthetic OCN/ICE COM log
  when the model finishes but no history-file sentinel appears
  (visibility issue on shared filesystems).
- `finalized` — end-of-job sentinel for downstream synchronization.

## GDAS/ENKFGDAS-specific work
- Fire `release_<RUN>_fcst_manager` event for both `gfs` and `gdas`.
- Add enkfgdas forecast manager file generation to the setup script.
- Restrict OCN/ICE product managers to the full GFS cycle in
  `config.resources`.
- Skip enkfgdas OCN/ICE product tasks on the first cycle.
- Correct enkfgdas `efcs_manager` datadep and add OCN/ICE prod tasks.
- Adjust cycledef in `gfs_tasks.py` so enkf runs use the correct
  cycle definition (`self.run` directly rather than `gfs`).

## Naming and hygiene
- Renamed `fcst_mgr` → `fcst_manager` and `forecast_mgr.sh` →
  `forecast_manager.sh` across scripts, configs, ecf, and Rocoto.
- Reverted a `HOMEglobal`/`USHglobal` rename in the fcst_mgr path for
  CI compatibility, then re-standardized on `HOMEgfs`/`USHgfs` for
  gfsv17 while `HOMEglobal` remains valid elsewhere.
- Added default `*)` cases to `RUN` switches (shellcheck SC2249).
- Consolidated forecast segment logging.

## Related Upstream
- Merges from `dev/gfs.v17` are interspersed throughout; the branch
  reintegrates upstream changes multiple times.
- Related preexisting PRs on `dev/gfs.v17`: #4907 (Forecast Manager
  real-time product copy, initial GFS-only implementation), #4980
  (Forecast Manager configs).

## Open / Follow-ups
- `TODO for gefs/sfs/gcafs`: manager currently restricted to gfs+gdas.
- Some intermediate commits carry `KEEPDATA revert this when merging`
  and similar reversion-flags — verify none linger in the tip.
- The submodule bump in `03c41de83` (gfs_utils.fd, ufs_model.fd)
  must be paired with a matching UFS-WM release for MOM6 hourly
  logs.

---

## 2026-07-08 — Finalized-sentinel race fixes + trap machinery simplification

Debug session covering three related race conditions between JGLOBAL_FORECAST
and JGLOBAL_FORECAST_MANAGER around `fcst_finalized_seg${SEG}`. Final design:
no shared helper, no EXIT trap — two plain `echo` writes in JGLOBAL_FORECAST
handle both success and the primary failure path.

### Bugs found and fixes applied

**Bug 1 — Manager's graceful exit gave up while `*_out` was still running.**
On GDAS, after model exec returned and `fcst_history_done_seg` appeared, the
manager's atmf rank had processed every regular product row but still had one
row pending: the `fcst_finalized_seg${SEG}` row (added to instance-0 atmf table
by `forecast_postdet.sh:429`). The `*_out` phase (`FV3_out`, `MOM6_out`, `WW3_out`,
`CICE_out`, `GOCART_out`, `CMEPS_out`) takes longer than
`FCST_MGR_DONE_IDLE_MAX × FCST_MGR_SLEEP` = 3 × 5 = 15 s, so the manager's idle
counter climbed to 3, break-exited with "not produced by model — skipping",
and JGLOBAL_FORECAST_MANAGER's tail `rm -rf "${DATAjob}"` ran while
`*_out` was still copying restarts out of DATAjob.

**Fix 1 — commit `a5da9b0bd` (`ush/forecast_manager.sh`).** In the graceful-exit
block, scan the pending rows for any whose sentinel filename starts with
`fcst_finalized_seg`. If one exists, hold the idle counter at 0. Other pending
rows (genuinely missing products) still hit the 3-idle-cycle graceful exit
exactly as before.

**Bug 2 — `fcst_finalized_seg` was written too early, in `exglobal_forecast.sh`
right after `*_out`, but BEFORE JGLOBAL_FORECAST's tail cleanup block
(`rm -rf "${DATA}"` and `rm -rf "${DATArestart}"` when it's the last segment).**
Reviewer observed on commit `a5da9b0b0`: manager successfully copied all files,
then JGLOBAL_FORECAST_MANAGER's `rm -rf "${DATAjob}"` beat JGLOBAL_FORECAST's own
tail cleanup and left the JGLOBAL_FORECAST tail block failing.

**Fix 2 — commit `ac4fa17fc` (`dev/scripts/exglobal_forecast.sh`) + JGLOBAL_FORECAST
edits.** Removed the explicit sentinel write in `exglobal_forecast.sh`. Added
an explicit `echo` at the very last line of JGLOBAL_FORECAST (after its cleanup
block), so the sentinel appears only after DATAjob is fully quiescent.

**Bug 3 — `err_exit` clears the EXIT trap.** `ush/err_exit.sh:22` runs
`trap - EXIT` before `qdel/scancel`, so the trap-based sentinel writer never
fired on the primary failure path (FORECASTSH returns non-zero → JGLOBAL_FORECAST
hits `err_exit` block). Manager saw no sentinel and could only fall back to
`FCST_MGR_TIMEOUT` (which is currently disabled with `FCST_MGR_TIMEOUT=0`).
Confirmed with a minimal reproducer:
```bash
trap 'echo TRAP FIRED' EXIT
(...); trap - EXIT; exit 1   # trap did NOT fire
```

**Fix 3 — commit `09115f1db` (JGLOBAL_FORECAST):** wrote the failure sentinel
BEFORE calling `err_exit` in the FORECASTSH-failure branch.

**Bug 4 — Walltime kill wrote sentinel with `finalized` content (not `aborted`).**
Force-fail test with `walltime=2 min`. Sentinel content came out as
`finalized at <timestamp>`, so the manager's propagate-failure block did NOT
fire (checks for `*aborted*`), and the manager sat waiting for a row that
would never resolve. Root cause: `$?` at trap-firing time on signal-death
mid-`wait` can be 0 (not the expected `128 + SIGTERM`), so
`write_status_sentinel.sh`'s `rc=0 → finalized` branch triggered.

**Fix 4 — simplification chosen over patching the helper.** Removed the EXIT
trap and deleted `ush/write_status_sentinel.sh` entirely. Two `echo` lines
now cover the two paths we can control:

```bash
# Failure branch (after FORECASTSH returns non-zero):
echo "aborted rc=${err} at $(date --utc +%Y%m%d%H%M%S)" \
    > "${DATAjob}/fcst_finalized_seg${FCST_SEGMENT:-0}"
err_exit "..."

# Success (very last action of JGLOBAL_FORECAST, after tail cleanup):
echo "${RUN}_fcst_seg${FCST_SEGMENT:-0} finalized" \
    > "${DATAjob}/fcst_finalized_seg${FCST_SEGMENT:-0}"
exit 0
```

### Failure-path coverage after simplification

| Path | Sentinel written | Manager sees | Time to failure |
|------|-----------------|-------------|-----------------|
| Success | `..._fcst_seg0 finalized` | Data-file-trigger row; writes synthetic COM log, exits clean | — |
| FORECASTSH returns non-zero | `aborted rc=<N> at ...` | Propagate-failure block, exits rc=N | ~5 s (one poll) |
| set_strict trip / walltime SIGTERM / operator qdel | none | Neither block fires | fcst_manager batch walltime (or `FCST_MGR_TIMEOUT` if set) |
| SIGKILL | none (untrappable) | Same as above | fcst_manager batch walltime |

Tradeoff explicitly accepted: implicit failure paths now depend on the batch
walltime for detection. To cap that, set `FCST_MGR_TIMEOUT` in
`dev/parm/config/gfs/config.fcst_manager` to `~2 × expected forecast wall time`.
Currently `FCST_MGR_TIMEOUT=0` (disabled).

### Side-effect (accidental improvement)

`jjob_shell_setup.sh` installs a `postamble` EXIT trap when `TRAP_POSTAMBLE=YES`
(dev default in `config.base.j2`). The old finalized-sentinel trap was
clobbering it. Now that we've removed our trap, postamble timing reporting
works again on JGLOBAL_FORECAST's success path.

### Files touched this session

```
M  dev/jobs/JGLOBAL_FORECAST     trap removed; inline echoes for success + failure
M  ush/forecast_manager.sh       graceful-exit suppression when finalized_seg pending
M  ush/forecast_postdet.sh       comment updated to reflect new sentinel write location
M  dev/scripts/exglobal_forecast.sh   removed premature explicit sentinel write
D  ush/write_status_sentinel.sh  deleted (no callers)
```

### Related shellcheck / shfmt gotchas hit or avoided

- `2> /dev/null` needs the space; `2>/dev/null` is auto-rewritten by CI.
- Inline comments: exactly one space before `#`.
- Multi-line `[[ ]]`: `&&` at end of line, no `\` continuation to next line;
  arithmetic inside `[[ ]]` (array indices) needs spaces around `-`
  (`count - 1`, not `count-1`).
- SC2129: group consecutive `echo ... >> file` in `{ ... } >> file`.

### Open follow-ups

- Set `FCST_MGR_TIMEOUT` to a non-zero value in `config.fcst_manager` if the
  batch-walltime fallback on implicit failure paths is too slow for CI/dev.
- Optional: add a pre-`history_done` idle counter to the manager
  (`FCST_MGR_PRE_HISTORY_IDLE_MAX`) so a stalled model with no `history_done`
  can be detected before batch walltime kicks in.

---

## 2026-07-27 — Diagnosis: manager `rm -rf "${DATAjob}"` destroys the running next segment

Field report from M.Fernando / D.Huber testing this PR combined with others on
`gw_candidate` (case `C48_S2SW_extended_candidate_072726`, cycle `2021032312`).
Symptom: `JGLOBAL_FORECAST_MANAGER` for `gfs_fcst_manager_seg0` went DEAD and its
teardown deleted the shared `gfs_forecast.2021032312` directory while
`gfs_fcst_seg1` was still RUNNING. Log tail:

```
JGLOBAL_FORECAST_MANAGER[102] rm -rf .../gfs_forecast.2021032312/manager.fcst_manager.752814
JGLOBAL_FORECAST_MANAGER[103] rm -rf .../gfs_forecast.2021032312
rm: cannot remove '.../gfs_forecast.2021032312': Directory not empty
```

### Root cause (confirmed)

`dev/jobs/JGLOBAL_FORECAST_MANAGER` lines 102–103 on this branch run two
removals in the `KEEPDATA == NO` block:

```bash
rm -rf "${DATA}"       # manager.${jobid}          -- job-private, fine
rm -rf "${DATAjob}"    # ${RUN}_forecast.${PDY}${cyc} -- SHARED, destructive
```

`DATAjob = ${DATAROOT}/${RUN}_forecast.${PDY}${cyc}` has **no segment number**.
It is the umbrella shared by (a) the concurrent `JGLOBAL_FORECAST` and (b) every
forecast segment. The seg0 manager exits normally once seg0 finishes, then its
designed final action `rm -rf "${DATAjob}"` nukes the umbrella — but seg1's
forecast has already started in the *same* DATAjob. So the seg0 manager teardown
races with and destroys the seg1 forecast. The `Directory not empty` error is
seg1's live files resisting deletion after `rm -rf` had already clobbered the
rest. Matches the user's "exiting early when the second segment starts"
hypothesis, refined: not a poll-loop early-exit, but a per-segment teardown of a
cross-segment shared directory.

The 2026-07-08 finalized-sentinel handshake only synchronizes seg0-manager vs
seg0-forecast; it cannot protect seg1's forecast, which reuses the umbrella.
The "manager owns DATAjob teardown" design (see stale comments in
`JGLOBAL_FORECAST` lines ~171–176: "…before JGLOBAL_FORECAST_MANAGER's
`rm -rf \"${DATAjob}\"` can run") is unworkable in multi-segment mode.

### Cross-branch check

| Branch | Manager cleanup |
|---|---|
| `feature/gfsv1-gdas-forecast-mgr` (this) | `rm -rf "${DATA}"` **+ `rm -rf "${DATAjob}"`** ← bug |
| `feature/gfsv17-forecast_manager` | `rm -rf "${DATA}"` only |
| `feature/gfsv17-gdas-manager` | `rm -rf "${DATA}"` only |
| `feature/develop-forecast_manager` | `rm -rf "${DATA}"` only |
| `feature/gfsv17-build` | `rm -rf "${DATA}"` only |

`JGLOBAL_FORECAST` on this branch already leaves DATAjob alone ("do not remove
DATAjob. It contains DATAoutput"; removes only `${DATA}`, and `${DATArestart}`
on the last segment).

### Proposed fix (not yet applied)

- Delete `rm -rf "${DATAjob}"` (line 103) from `dev/jobs/JGLOBAL_FORECAST_MANAGER`;
  the manager removes only its own `${DATA}`, matching the sibling branches.
- Remove the now-stale comment block in `dev/jobs/JGLOBAL_FORECAST` (~171–176)
  that references the manager performing the DATAjob teardown.
- DATAjob umbrella cleanup is left to the workflow-level cleanup / DATAROOT
  teardown, consistent with every other job family and the sibling branches.

### Files implicated

```
dev/jobs/JGLOBAL_FORECAST_MANAGER   remove line 103 rm -rf "${DATAjob}"
dev/jobs/JGLOBAL_FORECAST           drop stale DATAjob-teardown comment block
```

No commits made and no code changed this turn — diagnosis only, pending user
go-ahead to apply.

### Open questions / follow-ups

- Confirm the workflow-level cleanup (JGLOBAL_CLEANUP / RUNDIRS teardown) does
  remove `${RUN}_forecast.${PDY}${cyc}` so DATAjob does not leak in stmp after
  dropping the manager's removal (sibling branches already rely on this).
- Working-tree vs committed-tree discrepancy noticed this session: `read_file`
  on `JGLOBAL_FORECAST_MANAGER` showed only `rm -rf "${DATA}"`, while
  `git grep` on the branch shows lines 102–103 with the `${DATAjob}` removal.
  Verify whether the working tree already has an uncommitted partial fix before
  editing, to avoid double-applying.

### 2026-07-27 (cont.) — Fix applied: manager no longer removes shared DATAjob

Confirmed the working tree on this branch had the buggy
`rm -rf "${DATAjob}"` at `JGLOBAL_FORECAST_MANAGER:103` (the earlier `read_file`
that showed only `rm -rf "${DATA}"` was reading the `feature/gfsv17-build`
checkout; the branch had since switched to `feature/gfsv1-gdas-forecast-mgr`).
No partial fix present, so applied the full change.

**Files touched (no commit made — working-tree edits only):**

```
M dev/jobs/JGLOBAL_FORECAST_MANAGER  removed `rm -rf "${DATAjob}"`; manager now
                                     cleans only its private ${DATA}. Added comment
                                     explaining the shared/cross-segment umbrella
                                     must not be torn down by a per-segment job.
M dev/jobs/JGLOBAL_FORECAST          rewrote stale tail comment: finalized sentinel
                                     is the per-segment quiescence handshake, not a
                                     guard for the manager's DATAjob teardown; noted
                                     neither job removes the umbrella.
M ush/forecast_manager.sh            reworded idle-cycle comment (line ~316) to drop
                                     the false `rm -rf "${DATAjob}"` reference; kept
                                     the *_out restart-copy race rationale.
M ush/forecast_postdet.sh            reworded finalized-sentinel comment (line ~421)
                                     likewise.
```

**Verification:**
- `git grep` confirms no remaining reference to the manager removing DATAjob. The
  only surviving `rm -rf "${DATAjob}"` is in `JGLOBAL_MARINE_ANALYSIS_FINALIZE`
  (owns its own non-shared DATAjob — unrelated, correct).
- shellcheck not installed in this environment; could not run the branch lint
  gate. Changes are one line deletion + comment edits (no syntax risk). Run CI /
  local shellcheck before pushing.

**Net effect:** seg0 manager teardown can no longer delete
`${RUN}_forecast.${PDY}${cyc}` out from under the running seg1 forecast. DATAjob
cleanup deferred to workflow-level teardown, matching sibling manager branches
(`feature/gfsv17-forecast_manager`, `feature/gfsv17-gdas-manager`,
`feature/develop-forecast_manager`).

**Open questions:**
- Verify workflow-level cleanup (JGLOBAL_CLEANUP / RUNDIRS teardown) removes
  `${RUN}_forecast.${PDY}${cyc}` so DATAjob does not leak in stmp — the single
  assumption this fix rests on.
- Not yet committed or pushed; needs CI run (shellcheck/shfmt) and a re-test of
  the multi-segment case (`C48_S2SW_extended_candidate`, cycle 2021032312) to
  confirm seg1 survives seg0 manager completion.

### 2026-07-27 (cont.) — Where does DATAjob get deleted? JGLOBAL_CLEANUP already covers it

Follow-up to the manager DATAjob fix: confirmed the shared umbrella is NOT leaked
by removing the manager's `rm -rf "${DATAjob}"`.

**Finding.** `dev/jobs/JGLOBAL_CLEANUP` runs `rm -rf "${DATAROOT}"` at end of cycle
(only after the entire cycle succeeds), where
`DATAROOT="${STMP}/RUNDIRS/${PSLOT}/${RUN}.${PDY}${cyc}"`. Since
`DATAjob=${DATAROOT}/${RUN}_forecast.${PDY}${cyc}` lives inside DATAROOT (log path
`.../gfs.2021032312/gfs_forecast.2021032312`), JGLOBAL_CLEANUP already deletes
DATAjob. DATArestart is separately pruned by the last-segment JGLOBAL_FORECAST, so
only DATAoutput/tables persist through post/products/archive (which read from COM).

**Decision presented to user (no code change this turn):**
- Option 1 (recommended): rely on JGLOBAL_CLEANUP; current fix is complete.
- Option 2: free DATAjob right after the last segment via a last-segment-gated
  `rm -rf "${DATAjob}"` in the *manager* (correct owner — on the final segment the
  manager finishes after JGLOBAL_FORECAST because it waits on `fcst_finalized_seg`,
  and the 2026-07-08 idle-suppression prevents early exit while that row is pending).

**Caveat blocking a naive Option 2.** JGLOBAL_FORECAST's last-segment test uses
`FCST_SEGMENTS` (config.base) vs `FCST_SEGMENT`. But `gfs_tasks.py` forces
`num_fcst_segments = 1` for non-gfs runs (gdas/enkfgdas) while config.base still
exports the GFS `FCST_SEGMENTS` breakpoints. So the `FCST_SEGMENTS`-based check can
misfire for GDAS (would compute >1 segment and never hit "last"). A correct Option 2
needs Rocoto to pass an explicit total-segments / is-last-segment var to the
fcst_manager task rather than reconstructing it in bash.

**Files inspected:** `dev/jobs/JGLOBAL_CLEANUP`, `dev/parm/config/gfs/config.base.j2`
(`FCST_SEGMENTS`), `dev/workflow/rocoto/gfs_tasks.py` (fcst/fcst_manager metatasks,
`num_fcst_segments`).

**Open question:** awaiting user decision — rely on JGLOBAL_CLEANUP (option 1) or
implement the Rocoto-signalled last-segment teardown in the manager (option 2). If
option 2, note the same `FCST_SEGMENTS` vs actual-segments discrepancy may already
affect JGLOBAL_FORECAST's DATArestart removal for GDAS — worth verifying separately.

### 2026-07-27 (cont.) — ecFlow has no cleanup task → manager tears down DATAjob on the last segment

User pointed out JGLOBAL_CLEANUP is Rocoto-only, so relying on it leaks DATAjob
under ecFlow/ops. Confirmed: `grep` over `dev/ecf/**` finds no cleanup task;
`JGLOBAL_CLEANUP`/`exglobal_cleanup.sh` wire only into Rocoto
(`dev/job_cards/rocoto/cleanup.sh`). So the forecast family must remove DATAjob
itself.

**Revised fix (supersedes the "manager removes only DATA" change from earlier
today).** Restored `rm -rf "${DATAjob}"` in the manager but gated to the FINAL
segment only, with run-aware last-segment detection.

```bash
# dev/jobs/JGLOBAL_FORECAST_MANAGER (cleanup block)
if [[ "${KEEPDATA}" == "NO" ]]; then
    rm -rf "${DATA}"                       # always: job-private
    if [[ "${RUN}" == "gfs" ]]; then       # only gfs is segmented
        _commas="${FCST_SEGMENTS//[^,]/}"
        _last_segment=$((${#_commas} - 1))
    else
        _last_segment=0                     # gdas/enkfgdas: single segment
    fi
    if ((${FCST_SEGMENT:-0} == _last_segment)); then
        rm -rf "${DATAjob}"                 # shared umbrella, last segment only
    fi
fi
```

**Why safe / correct:**
- Manager (not forecast) owns teardown: on the last segment the manager finishes
  after JGLOBAL_FORECAST because it waits on `fcst_finalized_seg` (2026-07-08
  idle-suppression keeps it from exiting while that row is pending) → it is the
  last actor on DATAjob.
- Gated to last segment → earlier segments leave the umbrella intact (prevents
  the original seg0-manager-nukes-seg1 incident).
- Run-aware detection mirrors `gfs_tasks.py` (`num_fcst_segments = len(FCST_SEGMENTS)
  - 1` for gfs; 1 otherwise), so gdas/enkfgdas clean up at seg0 — avoids the
  plain-FCST_SEGMENTS misfire flagged earlier. Self-contained: identical under
  Rocoto and ecFlow, no new envar plumbing.
- Fail-safe: empty/unset FCST_SEGMENTS for gfs → `_last_segment=-1` → no match →
  DATAjob left in place (leak, never a destructive delete).
- Confirmed manager DATAjob definition matches the forecast's for both
  deterministic (`${RUN}_forecast.${PDY}${cyc}`) and ensemble
  (`${RUN}efcs${ENSMEM}.${PDY}${cyc}`) — enkfgdas targets the right dir.

**Files touched this turn (working-tree only, no commit):**
```
M dev/jobs/JGLOBAL_FORECAST_MANAGER   last-segment-gated rm -rf "${DATAjob}" restored
M dev/jobs/JGLOBAL_FORECAST           tail comment updated: sentinel now also enables
                                      the last-segment manager teardown; this job
                                      never removes DATAjob itself
```

**Verification:** `bash -n` passes on both J-Jobs. shellcheck still not installed
in this env — run CI/local shellcheck before pushing.

**Open questions / follow-ups (both out of scope, flagged to user):**
- JGLOBAL_FORECAST's own `DATArestart` last-segment test uses plain FCST_SEGMENTS
  WITHOUT the `RUN == gfs` guard → likely never fires for gdas (restarts may not be
  pruned). Separate latent quirk worth verifying.
- If fcst_manager can be DISABLED while segmentation is on, nothing cleans DATAjob
  under ecFlow (forecast job never removes it). Confirm the manager is mandatory
  whenever use_mgr paths are active.
- Still needs re-test of multi-segment case (C48_S2SW_extended_candidate, cycle
  2021032312): verify seg1 survives seg0 manager completion AND DATAjob is gone
  after the final segment's manager.

### 2026-07-27 (cont.) — Resolved: last-segment DATAjob teardown owned by the manager (committed)

Decision reached (option 2) after the user pointed out the blocker on option 1:
**JGLOBAL_CLEANUP does not run under ecFlow (operations)** — it is a dev/ROCOTO-only
step. Confirmed via mcp-rag (`search_documentation`, gw docs `develop` tenant): GFS
config docs list `cleanup` as an "additional step in experimental mode" and note ops
= ecFlow, dev = ROCOTO. (`get_code_context` failed — Neptune timeout; KB has no
forecast-manager content for this branch, indexed on `develop`.) So relying on
JGLOBAL_CLEANUP would leak DATAjob in ops; the manager must own the teardown.

**Design:** the last-segment manager removes DATAjob. Safe because on the final
segment the manager finishes after JGLOBAL_FORECAST (waits on `fcst_finalized_seg`,
and idle-suppression prevents early exit while that row is pending); no seg+1 forecast
exists; on forecast failure the manager exits via `err_exit` before this cleanup, so
DATAjob is preserved for debugging.

**Last-segment detection** (mirrors gfs_tasks.py, fixes the GDAS misfire flagged
earlier):
```bash
if [[ "${RUN}" == "gfs" ]]; then
    _commas="${FCST_SEGMENTS//[^,]/}"
    _last_segment=$((${#_commas} - 1))
else
    _last_segment=0
fi
if ((${FCST_SEGMENT:-0} == _last_segment)); then
    rm -rf "${DATAjob}"
fi
```
`${FCST_SEGMENTS//[^,]/}` strips non-commas; #commas = #segments; last idx = #commas-1.
`gfs_tasks.py` forces num_fcst_segments=1 for non-gfs while config.base still exports
the GFS breakpoints, so the `RUN == gfs` guard is required for gdas/enkfgdas.

**Committed:** `109459832` "fix(forecast): Fix DATAjob lifecycle management to prevent
mid-run deletion" (author Anton Fernando, 2026-07-27). Working tree clean.

```
dev/jobs/JGLOBAL_FORECAST         (+8/-3)  sentinel comment: manager tears down DATAjob
                                           on final segment; this job never removes it
dev/jobs/JGLOBAL_FORECAST_MANAGER (+27/-1) last-segment-gated rm -rf "${DATAjob}"
ush/forecast_manager.sh           (+5/-2)  reworded idle-suppression comment
ush/forecast_postdet.sh           (+6/-3)  reworded finalized-sentinel comment
```

Verification: both J-Jobs pass `bash -n`. shellcheck not installed locally — run the
branch lint gate (bash_code_analysis) in CI before PR.

**Open follow-ups:**
- `JGLOBAL_FORECAST`'s `DATArestart` teardown (lines ~163-167) still uses the bare
  `FCST_SEGMENTS`/`n_segs` check WITHOUT the `RUN == gfs` guard — so restarts are
  likely NOT pruned for GDAS/ENKFGDAS. Same class of bug; separate fix candidate.
- Manager-disabled runs (fallback to plain `fcst`): nobody removes DATAjob under
  ecFlow. Confirm whether any enabled-manager assumption holds in ops, or add a
  symmetric last-segment DATAjob teardown to JGLOBAL_FORECAST for that path.
- Re-test the multi-segment case (C48_S2SW_extended_candidate, cycle 2021032312) to
  confirm seg1 survives seg0 manager completion and DATAjob is gone after the last seg.

### 2026-07-27 (cont.) — Clarification: one JGLOBAL_FORECAST (and one manager) per segment

Q&A only, no code change. Confirmed from `dev/workflow/rocoto/gfs_tasks.py` (`fcst`
metatask, ~lines 1013–1044): the metatask expands to one task per segment
(`{run}_fcst_seg#seg#`, envar `FCST_SEGMENT=#seg#`, `is_serial=True`), so each
segment is a **separate** JGLOBAL_FORECAST submission with its own `jobid` and its
own private `DATA=${DATAjob}/${jobid}`, run sequentially (seg1 starts only after
seg0 succeeds). `num_fcst_segments = len(fcst_segments)-1` for gfs, else 1 — so
gdas/enkfgdas run a single seg0. The `fcst_manager` metatask mirrors this (one
manager job per segment).

Key tie-in to the DATAjob bug: all segment jobs share the same
`DATAjob=${DATAROOT}/${RUN}_forecast.${PDY}${cyc}` (no seg number) and
`DATArestart=${DATAjob}/restart`. The shared DATArestart is the warm-restart
handoff — seg0 writes restarts at its breakpoint, seg1's model warm-starts from
them in the same dir. That shared umbrella across separate jobs is exactly why
seg0's manager `rm -rf "${DATAjob}"` destroyed the running seg1. Reinforces that
the teardown must be gated to the final segment (the committed fix, `109459832`).

mcp-rag (develop tenant) lacks this branch's segment task code; it corroborated
the concept only — UFS-WM docs (successive restart segments, warm_start) and EE2
standards (break long restart-capable jobs so a failure reruns only the affected
part, = per-segment is_serial tasks). No new open questions.

### 2026-07-27 (cont.) — Risk review of the committed DATAjob fix (109459832)

Analysis only, no code change. Verified two potential concerns and cleared both:
- **EE2 compliance** of the new cleanup block: `analyze_ee2_compliance` returned
  clean (no error-handling / env-var / code-standard concerns).
- **Ensemble path**: earlier worry that the manager sets DATAjob unconditionally is
  unfounded — the committed JGLOBAL_FORECAST_MANAGER header branches on ENSMEM
  (`${RUN}efcs${ENSMEM}...` for members, `${RUN}_forecast...` otherwise), matching
  JGLOBAL_FORECAST. enkf members run single-segment, so `_last_segment=0` fires the
  teardown on the correct per-member dir.

Tooling note: mcp-rag is indexed on the `develop` tenant and has none of this
branch's forecast-manager code — it can confirm standards/concepts only, not branch
specifics. Risk items below came from reading the committed code directly.

**Risks flagged to user (priority order):**
1. Fix correctness depends entirely on the finalized-sentinel handshake +
   idle-suppression (2026-07-08). The finalized row is added in forecast_postdet.sh
   only when `use_mgr == YES` (ATM). If that regresses / isn't added, the manager
   could reach cleanup before the final segment's `*_out`/tail finishes and race it.
   Blast radius now small (last segment only, no seg+1), but real. MUST re-test.
2. Manager-disabled fallback (plain `fcst`) still leaks DATAjob under ecFlow — no
   owner removes it. Moot iff gfsv17 ops always enables the manager; else needs a
   symmetric last-segment teardown in JGLOBAL_FORECAST. OPEN.
3. Pre-existing GDAS bug: JGLOBAL_FORECAST's `DATArestart` teardown (~lines 163-167)
   uses bare `FCST_SEGMENTS`/`n_segs` WITHOUT the `RUN == gfs` guard, so restarts
   likely never pruned for gdas/enkfgdas. Same idiom as the fix — candidate for the
   same PR. (Offered to take this on; awaiting user go-ahead.)
4. Failed final segment: manager err_exits before cleanup (keeps data for debug), so
   an aborted cycle leaves DATAjob in stmp under ecFlow until manual removal.
   Operational note, acceptable.
5. Lint gate (bash_code_analysis shellcheck/shfmt) not run locally — arithmetic looks
   clean but confirm in CI before PR.
6. Reproduce original failure: re-run C48_S2SW_extended_candidate cycle 2021032312;
   confirm seg1 survives seg0 manager completion and DATAjob gone only after last seg.

**Must-do before merge:** #1, #5, #6. Same-PR-or-follow-up: #2, #3. Note only: #4.

**Open question:** user asked whether to take on #3 (add `RUN == gfs` guard to the
DATArestart teardown) now — awaiting confirmation.

### 2026-07-27 (cont.) — New hook: commit & comment style guard

Per user direction ("we dont need comments on how a problem is fixed. But what the
code does" + "add this to the hooks"), created a new agent hook.

**File added:** `.kiro/hooks/commit-comment-style.kiro.hook` (valid JSON, matches
existing hook schema). Trigger: `fileEdited` on `*.sh`, `*.bash`, `*.py`, `*.j2`,
`JG*`. Action: askAgent enforcing two rules —
1. Comments state WHAT the code does (behavior/contract/constraints), not a
   narrative of how a bug was diagnosed/fixed; one-line present-tense rationale OK,
   incident writeups not.
2. Commit messages: short imperative subject (<70), brief factual body about what
   changed; no diagnosis narrative / "Fixes bug where..." change-logs — that stays
   in context.md.

mcp-rag not used: this is agent-config, not indexed code (KB has nothing relevant).

**Open question:** offered to retrofit the comments added in commit `109459832`
(e.g. JGLOBAL_FORECAST_MANAGER's `(the original bug)` + multi-line mid-run-deletion
explanation) to the new what-it-does form and commit that cleanup — awaiting user
go-ahead.

### 2026-07-27 (cont.) — Full review of forecast-manager subsystem scripts

Review only, no code change. Scoped to the ~15 substantive files (branch diff vs
merge-base 865eed8e is 430 files, rest is upstream-merge churn). Read in full:
forecast_manager.sh, forecast_atm_barrier.sh, run_mpmd.sh, exglobal_forecast_manager.sh,
JGLOBAL_FORECAST(_MANAGER), config.fcst_manager, gfs_tasks.py fcst/fcst_manager metatasks.
`analyze_ee2_compliance` clean on new scripts. mcp-rag otherwise unhelpful (develop tenant).

Resolved a false alarm: sentinel var names are now consistent — exglobal exports
FCST_TABLE_READY_SENTINEL + FCST_HISTORY_DONE_SENTINEL (line 166-167), matching
forecast_manager.sh (124, 321) and the barrier (57). Earlier FCST_DONE_SENTINEL is gone.

**Findings (grep-confirmed):**

SHOULD-FIX before merge:
1. Dead config knob. config.fcst_manager (gfs:22, sfs:10) exports
   `FCST_MGR_INIT_TIMEOUT`, but scripts read `FCST_MANAGER_INIT_TIMEOUT`
   (exglobal_forecast_manager.sh:31, forecast_manager.sh:67). Tree-wide grep: the read
   name is set nowhere, the exported name is read nowhere → knob is dead, scripts always
   use `:-7200`. Rename to one name.
2. Barrier/idle knobs not in config: `FCST_MGR_POLL_INTERVAL` (:-5), `FCST_MGR_POSTDONE_TIMEOUT`
   (:-120), `FCST_MGR_DONE_IDLE_MAX` (:-3) exported nowhere → untunable. Barrier uses
   FCST_MGR_POLL_INTERVAL while component mgrs use FCST_MGR_SLEEP (in config) — two names,
   one concept. Consolidate on FCST_MGR_SLEEP + add the two timeouts to config.
3. VERIFY enkfgdas manager DATAjob path: gfs_tasks.py fcst_manager() reconstructs
   `…/{run}_forecast.@Y@m@d@H`, but JGLOBAL_FORECAST for ensemble members uses
   `{run}efcs{ENSMEM}…`. If fcst_manager() is wired for enkfgdas in rocoto the data-dep
   path won't match where the enkf fcst writes tables. May be ecFlow-master-only — confirm.

MEDIUM:
4. run_mpmd.sh serial fallback (USE_CFP!=YES / unsupported launcher / unset
   ntasks|max_tasks_per_node) runs component managers one-at-a-time → real-time COM copy
   degrades to end-of-run copy; barrier runs after all product ranks. Manager should
   warn/require MPMD or document the degradation.

PRE-EXISTING (not this PR):
5. run_mpmd.sh srun branch: `err=$?` captures `source set_strict.sh`, not the srun
   launcher → srun MPMD failures masked. PR only renamed USHgfs→USHglobal on that line
   (correct for this branch's HOMEglobal/USHglobal convention). Separate fix; affects all
   MPMD jobs.

MINOR / carry-over:
6. New comments in JGLOBAL_FORECAST_MANAGER + manager scripts carry fix-narrative
   ("the original bug", incident write-ups) — violates the new commit-comment-style hook.
   Trim to what-the-code-does.
7. JGLOBAL_FORECAST DATArestart teardown (~163-167) still lacks the `RUN == gfs` guard →
   restarts likely not pruned for gdas/enkfgdas (same idiom as the DATAjob fix).

**Proposed plan (awaiting user go-ahead):** apply safe contained batch #1, #2, #6, #7 in
one commit; open #3/#4/#5 as follow-ups pending enkf-wiring confirmation and a serial-mode
policy decision.

**Open questions:** (a) which name wins for #1/#2 (FCST_MANAGER_* vs FCST_MGR_*)?
(b) is fcst_manager() invoked for enkfgdas in rocoto, or ecFlow-master-only? (#3)
(c) serial-mode policy for the manager (#4).

### 2026-07-27 (cont.) — #3 resolved (not a bug) + new duplicate-task finding (#3b)

Investigation only, no code change. Traced how the per-RUN task list is assembled.

**#3 CLEARED — fcst_manager() is not wired for enkfgdas.** Task lists are built in the
applications layer (`gfs_cycled.py` get_task_names), not gfs_tasks.py:
- gfs/gdas → task `fcst_manager` → builder `fcst_manager()` (gfs_tasks.py:1130) →
  path `…/{run}_forecast.@Y@m@d@H` (correct; both are non-ensemble).
- enkfgdas → task `efcs_manager` → builder `efcs_manager()` (gfs_tasks.py:3185) →
  path `…/{run}efcs#member#.@Y@m@d@H`, passes ENSMEM=#member#, MEMDIR=mem#member#.
  Matches JGLOBAL_FORECAST_MANAGER's ENSMEM branch (DATAjob=`${RUN}efcs${ENSMEM}…`) and
  JGLOBAL_FORECAST ensemble naming.
The two builders are correctly split; the `{run}_forecast` path never serves enkf. So the
earlier DATAjob-mismatch worry is a non-issue. Drop #3 from the risk list.
Also confirmed fcst_manager wired for gfs/gdas in gfs_forecast_only.py + rocoto/tasks.py
TASK list; postsnd/wave/archive fall back to `{run}_fcst` when fcst_manager absent
(gfs_tasks.py:1595).

**NEW #3b — duplicate task-list entries in gfs_cycled.py (no dedup on return):**
1. gfs gets `fcst_manager` TWICE — line 316 (`run in ['gfs','gdas']`) and line 320
   (`run == 'gfs'`, under the ocean/ice "products" block). Line 320 is a stray copy-paste;
   safe to delete (316 already covers gfs).
2. enkfgdas JEDI path double-adds `efcs`/`efcs_manager`/`epos` — once inside
   `if do_jediatmens` (~415) and again in the common block (~431). efcs/epos duplication is
   PRE-EXISTING; this PR's efcs_manager follows the same pattern. Clean fix: keep the common
   block, drop the inner copies.
Severity depends on whether the XML builder dedups task names — could not find explicit
dedup, but JEDI-enkf runs work, suggesting dedup/overwrite tolerates it → likely redundancy
not breakage. Both clearly unintended; gfs line 320 is a trivial delete.

**Plan update:** safe batch now #1, #2, #6, #7 + the gfs line-320 delete (#3b part 1).
Hold the enkf de-dup (#3b part 2) until XML-builder dedup behavior is confirmed (don't want
to perturb task ordering). #4 (serial-mode policy) and #5 (pre-existing srun err capture)
remain follow-ups.

**Open questions:** (a) #1/#2 name choice (FCST_MANAGER_* vs FCST_MGR_*); (b) does
rocoto_xml dedup task names? (governs #3b part 2 and true severity); (c) serial-mode policy (#4).
