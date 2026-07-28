# Branch Context: `feature/gfsv17-reloc`

**Repo:** `global-workflow_gfsv17`
**Branch slug:** `feature-gfsv17-reloc`
**Base:** `dev/gfs.v17` (branch cut at `cc2b3ae77`)
**Tip:** `33b5410a7` (committed + pushed to `origin/feature/gfsv17-reloc`; working tree clean)

## Summary

Clean up the tropical-cyclone prep job so it reflects reality: only the
**tcvitals QC** portion runs in the GFS/GDAS workflow — hurricane
**relocation** has never been active (`DO_RELOCATE` is hard-wired to
`NO`). The job/scripts were named `..._TROPCY_QC_RELOC`, which misleads
readers into thinking relocation is part of GFS prep. This branch
removes all relocation code paths and renames the job, scripts, ecflow
tasks, and config variable to a QC-only identity.

Tracks issue #4622 (comment): remove `tc_reloc*` references, make it
clear only QC runs, and remove the option to run relocation.

## Why

`JGLOBAL_ATMOS_TROPCY_QC_RELOC` wrapped two independent operations
gated by two switches in `exglobal_atmos_tropcy_qc_reloc.sh`:

- **QC** (`PROCESS_TROPCY`) — runs `ush/syndat_qctropcy.sh`, producing
  the `*.syndata.tcvitals` / `*.jtwc-fnoc.tcvitals` files. **Kept.**
- **Relocation** (`DO_RELOCATE`) — ran `ush/tropcy_relocate.sh` →
  `ush/tropcy_relocate_extrkr.sh` → external `relocate_mv_nvortex`,
  produced `sg*prep` guess files and the `tropcy_relocation_status`
  sentinel. **Dead code** — `parm/config/gfs/config.prep` set
  `DO_RELOCATE="NO"` unconditionally and nothing ever overrode it.

## Naming changes

| Old | New |
|---|---|
| `dev/jobs/JGLOBAL_ATMOS_TROPCY_QC_RELOC` | `dev/jobs/JGLOBAL_ATMOS_TROPCY_QC` |
| `dev/scripts/exglobal_atmos_tropcy_qc_reloc.sh` | `dev/scripts/exglobal_atmos_tropcy_qc.sh` |
| `ecf/.../jgfs_atmos_tropcy_qc_reloc.ecf` | `ecf/.../jgfs_atmos_tropcy_qc.ecf` |
| `ecf/.../jgdas_atmos_tropcy_qc_reloc.ecf` | `ecf/.../jgdas_atmos_tropcy_qc.ecf` |
| ecflow tasks `j{gfs,gdas}_atmos_tropcy_qc_reloc` | `j{gfs,gdas}_atmos_tropcy_qc` |
| config var `TROPCYQCRELOSH` | `TROPCYQCSH` |

## Commits (only on this branch)

| SHA | Message |
|---|---|
| `97ed6e9e3` | feat(tropcy): consolidate tropical cyclone QC, remove relocation processing |
| `a9e53f351` | Update exglobal_atmos_tropcy_qc.sh — drop dead `RUN=ndas` messaging branch |
| `33b5410a7` | Update config.prep.j2 — remove `copy_back="NO"` override (rely on `envir` gating for DCOM) |

(The `exgfs_wave_prdgen_bulls.sh` / #5141 wave-bulletin commits between
`97ed6e9e3` and these are the separate concern noted below — they landed
on this branch but belong to their own PR.)

Diffstat: 15 files changed, 110 insertions(+), 2249 deletions(-) — the
bulk of the deletions are `ush/tropcy_relocate.sh` (568) and
`ush/tropcy_relocate_extrkr.sh` (1476).

## Files Touched (committed in `97ed6e9e3`)

**Deleted (relocation-only):**
- `ush/tropcy_relocate.sh`
- `ush/tropcy_relocate_extrkr.sh`

**Renamed + rewritten:**
- `dev/scripts/exglobal_atmos_tropcy_qc.sh` — rewritten QC-only. The
  `PROCESS_TROPCY` QC branch is preserved byte-for-byte (same
  `syndat_qctropcy.sh` call, same COM/ARCHSYND listing, same null-file
  fallback). Removed the entire `DO_RELOCATE == YES` block (the
  `sg*prep` copies + `tropcy_relocation_status` write) and the NDAS
  `DO_RELOCATE` messaging branch; header comment updated.
  (`scripts/` is a symlink to `dev/scripts/`, so this is one file.)
- `dev/jobs/JGLOBAL_ATMOS_TROPCY_QC` — dropped `DO_RELOCATE` export and
  the relocation-only setup vars `CRES`/`LATB`/`LONB`/`BKGFREQ`
  (confirmed unused by the QC chain); dispatch now
  `${TROPCYQCSH:-.../exglobal_atmos_tropcy_qc.sh}`; error message
  "...QC and/or relocation" → "...QC".

**Modified (rename/removal only):**
- `parm/config/gfs/config.prep` — removed `DO_RELOCATE="NO"`, renamed
  `TROPCYQCRELOSH`→`TROPCYQCSH` + script path; comment "Relocation and
  syndata QC" → "Syndata (tcvitals) QC".
- `dev/parm/config/gfs/config.prep.j2` — same var/script/comment rename
  (`dev/parm/config/gcafs/config.prep.j2` is a symlink to it).
- `dev/job_cards/rocoto/prep.sh` — job path → `JGLOBAL_ATMOS_TROPCY_QC`.
- `dev/ush/setup_gfs_for_nco.py` — job + script names in the NCO copy
  lists.
- `.github/CODEOWNERS` — renamed job + script entries; removed the two
  deleted `ush/tropcy_relocate*.sh` lines.
- `ecf/scripts/{gfs,gdas}/prep/atmos/jgfs,jgdas_atmos_tropcy_qc.ecf` —
  removed `export DO_RELOCATE=NO`, renamed `#PBS -N` and the J-job path.
- `dev/workflow/prod.yml` — ecflow task names (incl. the
  `jgfs_atmos_post_manager` trigger) `tropcy_qc_reloc`→`tropcy_qc`.
- `ecf/defs/gfs_prod.def` — 8 `tropcy_qc_reloc`→`tropcy_qc` task/trigger
  references (mechanical `sed`).
- `ush/syndat_qctropcy.sh` — stale doc comment "connects to the later
  RELOCATE and/or PREP scripts" → "...PREP scripts". Functional QC code
  untouched.

## Verification done

- `bash -n` clean on `exglobal_atmos_tropcy_qc.sh`,
  `JGLOBAL_ATMOS_TROPCY_QC`, `config.prep`, `prep.sh`.
- `python3 -m py_compile` clean on `setup_gfs_for_nco.py`.
- Repo-wide grep: zero remaining `TROPCY_QC_RELOC` / `tropcy_qc_reloc` /
  `TROPCYQCRELOSH` / `DO_RELOCATE` / `tropcy_relocate` /
  `relocate_extrkr` / `relocate_mv_nvortex` / `tropcy_relocation_status`
  / `RELOX` references (outside `.kiro/`).
- ecflow trigger→task names confirmed consistent in `prod.yml` and
  `gfs_prod.def`.

## Notes

- No `relocate_mv_nvortex` source/build entry exists in `sorc/` — that
  executable came from an external package, so no CMake/link cleanup was
  needed.
- `parm/relo/` (holds `syndat_qctropcy.{gfs,gdas}.parm`) was left as-is:
  it feeds the QC we're keeping. Renaming the dir would ripple into
  `syndat_qctropcy.sh` + `link_workflow.sh` and isn't required to remove
  relocation.

## Fix: QC write-back to operational NHC dir (parallel permission error)

`ush/syndat_qctropcy.sh` attempted `cpfs nhc "${HOMENHC}/tcvitals"`
(`HOMENHC=/lfs/h1/ops/prod/dcom/nhc/atcf/ncep`) — a write into the
operational **DCOM** NHC directory — which must never happen from an EMC
parallel.

**Correct control (per reviewer, David Huber):** separate the COM
write-back from the DCOM write-back.

- **DCOM write** (`cpfs nhc "${HOMENHC}/tcvitals"`) is gated on
  `copy_back == YES && envir == prod` in `syndat_qctropcy.sh`. This guard
  is **upstream/original** — it already exists in the base
  (`865eed8ecd`); the reloc branch did not add it. Because rocoto sets
  `envir` from `self._base.get('envir', 'para')`
  (`dev/workflow/rocoto/tasks.py`) and nothing in `config.base.j2`,
  `config.prep.j2`, or the case YAMLs overrides it, parallels run with
  `envir=para`. So the DCOM write is **already** skipped in parallels —
  no extra config needed.
- **COM write-back** (the `ARCHSYND` appends/copies, gated only on
  `copy_back == YES`) targets `ARCHSYND=${ROTDIR}/syndat` — the
  parallel's own writable ROTDIR, set in
  `dev/jobs/JGLOBAL_ATMOS_TROPCY_QC`. These are desirable and safe, so
  `copy_back` should stay at its default `YES`.

**Fix applied (commit `33b5410a7`):** removed the
`export copy_back="NO"` override from `dev/parm/config/gfs/config.prep.j2`
(`gcafs/config.prep.j2` is a symlink). `copy_back` now defaults to `YES`
→ COM archive copies proceed (ROTDIR/syndat), DCOM write stays blocked by
the `envir == prod` guard. `syndat_qctropcy.sh` is unchanged (original
guard intact).

**Superseded / rejected earlier attempts** (do NOT reintroduce):
- Setting `export copy_back="NO"` in `config.prep.j2` — over-broad; it
  also suppressed the wanted COM (`ROTDIR/syndat`) archive appends.
  Removed.
- Adding a `RUN_ENVIR == nco` / `RUN_ENVIR` check to the copy_back
  condition in `syndat_qctropcy.sh` (intermediate commits `7aa891c77`,
  `2410e43a7`) — EE2 disallows branching workflow logic on `RUN_ENVIR`.
  Reverted; the file matches upstream structure + the reloc renames.

No experiment regen is required for a code-only revert of the override,
but experiments created while `copy_back="NO"` was in `config.prep.j2`
carry it in `EXPDIR/<pslot>/config.prep`; re-run `create_experiment.py`
(or delete the `export copy_back="NO"` line in the EXPDIR config) so the
in-flight experiment picks up the default `YES`.

**Update (debug run, per Anton):** in `config.prep.j2` now set both
explicitly for the prep job:
- `export copy_back="YES"` — explicit (same as the default; NOT the
  rejected `="NO"`). Keeps the `ROTDIR/syndat` archive copies; DCOM
  write still blocked by `envir==prod` (parallels run `envir=para`).
  Caveat: if a run ever has `envir=prod`, `copy_back=YES` re-triggers the
  ops NHC `Permission denied`.
- `export KEEPDATA="YES"` — retain the prep `DATA` dir for debugging the
  tcvitals QC (overrides the global `config.base` default for prep only).

Requires `create_experiment.py` regen (or an `EXPDIR/<pslot>/config.prep`
edit) to take effect.

## Unrelated fix picked up during realtime testing — issue #5141 (wave bulletins)

While running the realtime parallel (`DO_AWIPS=YES` + `envir=para`), the
`gfs_waveawipsbulls` job hung in `make_ntc_bull.pl`.

Correct root cause (revised): the executed `make_ntc_bull.pl` (NCO
`util_shared` version) gates BOTH the bulletin write and the loop terminator
`$ix = 1` inside `if ($SENDCOM eq "YES")`. When `SENDCOM` is not `YES`, the
`else { $ix = 1 }` never runs, so the `while ($ix == 0)` loop never
terminates → infinite loop. ecflow sets `SENDCOM=YES` in
`ecf/include/head.h`; the Rocoto equivalent `ush/jjob_standard_vars.sh` does
NOT set `SENDCOM`, so in the parallel it is unset → hang. (In ecflow the
bulletins are correct precisely because `SENDCOM=YES`.)

Fix: `dev/parm/... ` no — set it in the job. Added
`export SENDCOM=${SENDCOM:-YES}` at the top of
`dev/scripts/exgfs_wave_prdgen_bulls.sh` (next to the existing
`export envir=${envir:-ops}`), mirroring `head.h`. This lets
`make_ntc_bull.pl` terminate and write the bulletin; `SENDDBN=NO` in the
para branch still suppresses the DBN alert, matching intent ("make NTC
bulletin for parallel env, but do not alert"). `bash -n` clean.

Reverted my earlier wrong fix: the loop-guard edit to `ush/make_ntc_bull.pl`
was aimed at the repo copy, which is NOT the script actually executed (PATH
resolves to the `util_shared` version), and it addressed a non-existent
shrinking-loop instead of the real `SENDCOM`-gated terminator. `git checkout`
restored it.

Broader option (not taken): add `export SENDCOM=${SENDCOM:-YES}` to
`ush/jjob_standard_vars.sh` so ALL Rocoto jobs match ecflow's `head.h`. That is
the true root gap but has wider blast radius; the job-local fix is the minimal
change for #5141.

**Separate concern from the reloc cleanup (issue #5141, not #4622) — own
branch/PR, do NOT fold into the reloc PR.** Currently uncommitted in this
working tree.

## Fix: DCOMROOT unset → empty jtwc-fnoc.tcvitals

`config.base.j2` has `export DCOMROOT="{{ DCOMROOT }}"` (a placeholder filled
from the host yaml). `dev/workflow/hosts/wcoss2.yaml` defined `COMINsyn` but
NOT `DCOMROOT`, so it rendered empty. `TANK_TROPCY=${TANK_TROPCY:-${DCOMROOT}}`
→ `syndat_getjtbul` couldn't find the JTWC/FNMOC bulletins in the DCOM tank →
`jtwc-fnoc.tcvitals` came out empty/different from ops.
Fix: added `DCOMROOT: '/lfs/h1/ops/prod/dcom'` to `dev/workflow/hosts/wcoss2.yaml`
(machine-specific, survives regen).

## Consolidated checklist to get a clean tcvitals QC comparison

Config (all applied on this branch / working tree):
1. `s2sw_realtime.yaml` `prep.PROCESS_TROPCY: "YES"` — QC job actually runs.
2. `config.prep.j2` `copy_back="YES"` + `KEEPDATA="YES"` — archive copies +
   keep DATA for debug (safe because `envir=para`).
3. `wcoss2.yaml` `DCOMROOT=/lfs/h1/ops/prod/dcom` — fixes the jtwc side.
4. Case dates target a runnable cycle (`idate/SDATE_GFS/edate`).
5. Run with `envir=para` — DCOM/NHC write-back stays skipped (envir!=prod).

Run:
6. `create_experiment.py` to bake all of the above into EXPDIR; let `stage_ic`
   + upstream complete so `prep` is ready.
7. **Timing-critical** (syndat_dateck + live DCOM tank): `rocotoboot` the prep
   task inside the window when the operational cycle matches — `gfs_prep`
   11:00–11:30 EST, `gdas_prep` 14:00–14:30 EST. The booted rocoto cycle must
   equal the live operational cycle at that moment.
8. Compare (v17 obs/ vs ops atmos/):
   - `syndata.tcvitals`: `gfs.${PDY}/${cyc}/obs/gfs.t${cyc}z.syndata.tcvitals.tm00`
   - `jtwc-fnoc.tcvitals`: same dir, `...jtwc-fnoc.tcvitals.tm00`
   vs `/lfs/h1/ops/prod/com/gfs/v16.3/gfs.${PDY}/${cyc}/atmos/...`.

## Open / Follow-ups (Definition of Done)

- [x] Commit the working-tree changes (`97ed6e9e3`).
- [x] Push branch to `origin/feature/gfsv17-reloc`.
- [ ] Open a PR and get it merged into **both** `develop` and
      `dev/gfs.v17` (issue DoD requires both branches).
- [ ] Run a prep/QC regression test on HPC to confirm the
      `syndata.tcvitals` / `jtwc-fnoc.tcvitals` output is unchanged vs.
      pre-cleanup (QC branch preserved byte-for-byte; needs runtime
      confirmation). Cannot be run from this workstation.
- [ ] Validate the ecflow def on WCOSS2:
      `ecflow_client --load=ecf/defs/gfs_prod.def check_only`.

## Realtime test setup (for QC regression)

Configured the realtime cycled case per David Huber's runbook gist
(`gist.github.com/DavidHuber-NOAA/ab2ae48124bbfe5313b7338ab365fb12`) to
drive the prep/tropcy-QC path on WCOSS2:

- `dev/ci/cases/gfsv17/retrov17_realtime.yaml` — `comroot`/`expdir`
  repointed to `/lfs/h2/emc/ptmp/${USER}/realtime_test/{COM,EXP}`;
  `icsdir` → `.../comroot/retrov17_01_realtime`. Dates track the live
  operational cycle (`syndat_dateck` was at `2026072306` = 07/23 06Z
  done, so target the next cycle, 12Z):
  `idate 2026072306` (06Z warm start; prev-cycle restarts from
  `gdas.20260723/00`), `SDATE_GFS 2026072312` (first GFS fcst at 12Z),
  `edate 2026072318` (covers the 12Z target cycle).
  NOTE: the case-yaml dates keep getting reverted when the dev/ tree is
  reset — re-apply the full realtime block (comroot/expdir/icsdir,
  DO_AWIPS/DO_NPOESS=YES, PROCESS_TROPCY=YES, dates) after any reset.
- `dev/ci/cases/gfsv17/s2sw_realtime.yaml` — `DO_AWIPS`/`DO_NPOESS`
  → `YES`; `SDATE_GFS 2026072212` (idate + 6h = first GFS fcst at 12Z).
  `DO_GOES` and `FHMAX_HF_GFS=120` already set.

Notes:
- `idate` must be a date present in `icsdir` with a preceding cycle for
  the warm start; `SDATE_GFS = idate + 6h`, `edate >= idate + 6h`.
- Run procedure: `create_experiment.py` → let `stage_ic` run for the 06Z
  cycle → `rocotoboot` the 12Z `gdas_prep` / `gfs_prep` tasks
  (`cycle 202607221200`). gfs_prep runnable ≥11:00 EST, gdas_prep
  ≥14:00 EST (waits on realtime obs availability).
- Rocoto prep task names confirmed as `gfs_prep` / `gdas_prep`
  (`{run}_prep` in `gfs_tasks.py`).
- `prep.PROCESS_TROPCY` set to `"YES"` so `JGLOBAL_ATMOS_TROPCY_QC`
  actually runs `syndat_qctropcy.sh` and produces
  `gfs.t{cyc}z.syndata.tcvitals.tm00` in `${ROTDIR}/gfs.${PDY}/${cyc}/obs/`
  (v17 puts it under `obs/`, not `atmos/` like ops v16.3). Diff that
  against `/lfs/h1/ops/prod/com/gfs/v16.3/gfs.{PDY}/{cyc}/atmos/...` to
  validate QC output is unchanged. With `PROCESS_TROPCY=NO`, prep only
  copies the tcvitals from the dump (QC job does not run).
- `DO_AWIPS=YES` means the `gfs_waveawipsbulls` job runs — needs the
  `SENDCOM=YES` fix (see #5141 section) or it hangs.
- **Editing the case YAML does not update an already-created EXPDIR.**
  After changing dates, re-run `create_experiment.py` (or
  `setup_expt.py`) so the EXPDIR `config.base` picks up the new
  `idate`/`edate`. The `gdas.20260223` stage_ic failure was the stale
  pre-fix experiment.
- `prep.PROCESS_TROPCY` is still `"NO"` in `s2sw_realtime.yaml`. To
  actually exercise the cleaned-up tropcy QC job, flip it to `"YES"`
  (comment there notes it "can only be enabled in realtime").
- Optional debug logging (`config.base` `DEBUG_POSTSCRIPT="YES"` +
  `setup_workflow.py` regen) from the gist was NOT applied.
- Build/`create_experiment.py`/crontab steps are manual on WCOSS2.

## Related Specs

_No formal requirements/design/tasks spec created for this branch yet.
If one is desired for the SPECS panel, add `requirements.md` /
`design.md` / `tasks.md` here._

## Run-day checklist — fresh experiment targeting 07/24 12Z (WCOSS2)

Missed the 07/23 12Z window; rebuilding for 07/24. Dates now:
`idate 2026072406`, `SDATE_GFS 2026072412`, `edate 2026072418`.
Warm start reads `gdas.20260724/00` restarts (idate−3h = 2026072403).

Do TODAY (spin up so it's ready tomorrow):
1. In the WCOSS2 checkout, apply the same case-YAML edits as the
   reference here (comroot/expdir→ptmp, icsdir→retrov17_01_realtime,
   idate/edate/SDATE_GFS, DO_AWIPS/DO_NPOESS=YES, PROCESS_TROPCY=YES).
2. Confirm code fixes are present in that checkout: `DCOMROOT` in
   `dev/workflow/hosts/wcoss2.yaml`, `copy_back`/`KEEPDATA` in
   `config.prep.j2`, `SENDCOM` in `exgfs_wave_prdgen_bulls.sh`, reloc
   cleanup.
3. `rm -rf EXP/<pslot> COM/<pslot>` (clean slate), then
   `create_experiment.py --yaml ...retrov17_realtime.yaml`.
4. Verify rendered EXPDIR: `SDATE/EDATE/SDATE_GFS`, cycledefs
   (`202607240600` gdas_half, `202607241200` gfs), `DCOMROOT`,
   `PROCESS_TROPCY=YES`, `copy_back=YES`, `KEEPDATA=YES`, `envir=para`.
5. `crontab <pslot>.crontab`; let stage_ic + gdas chain run overnight.

Do TOMORROW (~11:00 EST):
6. Watch the marker:
   `watch -n 30 'cat /lfs/h1/ops/prod/com/gfs/v16.3/syndat/syndat_dateck'`
7. When it reads `2026072412`, immediately:
   `rocotoboot -w <xml> -d <db> -c 202607241200 -t gfs_prep`
8. For gdas (~14:00 EST), when the marker matches:
   `rocotoboot ... -c 202607241200 -t gdas_prep`
9. Compare (v17 obs/ vs ops atmos/):
   `.../gfs.20260724/12/obs/gfs.t12z.{syndata,jtwc-fnoc}.tcvitals.tm00`
   vs `/lfs/h1/ops/prod/com/gfs/v16.3/gfs.20260724/12/atmos/...`.
