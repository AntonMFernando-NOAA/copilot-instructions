# Branch Context: feature/gfsv17-gsidiag

## Summary

Running working notes for the `feature/gfsv17-gsidiag` branch of the GFSv17
global-workflow repo. This is the companion summary file (not surfaced in the
Kiro SPECS panel until a requirements/design/tasks/bugfix doc exists).

- **Branch:** `feature/gfsv17-gsidiag`
- **Spec slug:** `feature-gfsv17-gsidiag`
- **Base line:** `dev/gfs.v17`
- **HEAD at setup:** `2a816908e` — [dev/gfs.v17] Remove marine prep fsm from ecflow def (#5100)

## Rationale / Goal

Make the GSI diagnostic jobs delete the shared temporary `gsidiags` staging
directory under DATAROOT once diagnostics are produced, reclaiming scratch space.
The producer jobs (`gdas_anal`, `enkfgdas_eobs`) create
`${pCOMIN_ATMOS_ANALYSIS}/gsidiags`; the consumer jobs (`gdas_analdiag` /
`JGLOBAL_ATMOS_ANALYSIS_DIAG` and `enkfgdas_ediag` / `JGLOBAL_ENKF_DIAG`) are the
last readers and today only remove their own `${DATA}`. Cleanup must honor the
existing `KEEPDATA` convention plus an optional new `KEEP_TEMP_DIAGS` override
(default `NO`, forced `NO` in operations).

Requirements captured in `requirements.md` (EARS, 5 requirements).

## Design Decisions (design.md)

**Simplified approach (current, per reviewer feedback).** Cleanup is done inline
at the end of `dev/scripts/exglobal_diag.sh` — the single ex-script both
`JGLOBAL_ATMOS_ANALYSIS_DIAG` and `JGLOBAL_ENKF_DIAG` run (via
`${ANALDIAGSH:-${SCRglobal}/exglobal_diag.sh}`). Doing it there means:

- `GSIDIAGDIR` is already defined and validated to exist earlier in the script,
  so there is no path reconstruction and no need for the basename / DATAROOT /
  COM containment / symlink safety guard that a standalone helper required.
- Retention is a simple OR: retain if `KEEPDATA` **or** `KEEP_TEMP_DIAGS` is
  `YES` (case-insensitive); otherwise `rm -rf "${GSIDIAGDIR}"`. Both read with
  `:-NO` defaults so it is safe under `set -eu`. This drops the earlier
  override/decision-table and the "KEEP_TEMP_DIAGS=NO forces delete" behavior.
- Runs only on the successful path (before the final `exit 0`), so a failed run
  (`err_exit`) leaves `gsidiags` in place for debugging.
- `KEEP_TEMP_DIAGS` declared `NO` in `config.analdiag`/`config.ediag`.

**Superseded design.** The former plan — a standalone `ush/remove_temp_diags.sh`
helper called from both J-Job postambles, with a fail-loud exit-code policy and
a safety guard (basename/DATAROOT/protected-path/symlink checks) — was removed.
The helper file is deleted. design.md/requirements.md still describe that helper
and need syncing.

- PBT intentionally NOT used (finite decision + filesystem side effects).
  Testing = `bash -n` + 1–2 CI cycle runs.

## Files Touched

- `dev/scripts/exglobal_diag.sh` — added inline gsidiags cleanup before final
  `exit 0`.
- `dev/jobs/JGLOBAL_ATMOS_ANALYSIS_DIAG`, `dev/jobs/JGLOBAL_ENKF_DIAG` — removed
  the temporary test instrumentation and the `remove_temp_diags.sh` call.
- `dev/parm/config/gfs/config.analdiag`, `dev/parm/config/gfs/config.ediag` —
  added `KEEP_TEMP_DIAGS="NO"`.
- `ush/remove_temp_diags.sh` — **deleted** (superseded by inline cleanup).

## Commits

_None specific to this branch's feature work recorded yet; currently even with
`origin/feature/gfsv17-gsidiag`._

## Open Questions

- What is the specific scope of the gsidiag change on this branch?
- Which jobs / scripts are in play (e.g. `ush/forecast_manager.sh`,
  `dev/jobs/JGLOBAL_FORECAST`)?

## Session Log

- **2026-07-27** — Confirmed the simplified gsidiags cleanup is committed on
  this branch: inline block at the end of `dev/scripts/exglobal_diag.sh`
  (retain if `KEEPDATA` or `KEEP_TEMP_DIAGS` is `YES`, else `rm -rf
  "${GSIDIAGDIR}"`), the standalone `ush/remove_temp_diags.sh` helper deleted,
  the `remove_temp_diags.sh` call removed from both `JGLOBAL_ATMOS_ANALYSIS_DIAG`
  and `JGLOBAL_ENKF_DIAG`, and `KEEP_TEMP_DIAGS="NO"` set in
  `config.analdiag`/`config.ediag`. All touched shell files pass `bash -n`.
- Pending: add temporary `TEMP TEST INSTRUMENTATION` echo blocks around the
  cleanup in `exglobal_diag.sh` to log whether `${GSIDIAGDIR}` exists
  before/after removal (and the `KEEPDATA`/`KEEP_TEMP_DIAGS` values) so a CI
  cycle shows `gsidiags REMOVED` vs `STILL EXISTS`. To be removed after
  verification.
- Note: briefly observed the working tree checked out on
  `feature/gfsv1-gdas-forecast-mgr` mid-session; the gsidiags test work belongs
  on `feature/gfsv17-gsidiag` (current). No cross-branch edits were made.

- **2026-07-27 (cont.)** — Added temporary test instrumentation around the
  cleanup in `dev/scripts/exglobal_diag.sh`: two `TEMP TEST INSTRUMENTATION`
  blocks (marked with `# >>> ... >>>` / `# <<< ... <<<`) logging `${GSIDIAGDIR}`
  existence and the `KEEPDATA`/`KEEP_TEMP_DIAGS` values BEFORE and REMOVED/
  retained AFTER the `rm`. Both `gdas_analdiag` and `enkfgdas_ediag` run this
  script, so both job logs will show `TEST gsidiag:` lines. Verified with
  `bash -n` and a standalone logic test (NO/NO → REMOVED; `KEEP_TEMP_DIAGS=yes`
  and `KEEPDATA=YES` → retained). Open: remove the two marked blocks after a
  CI cycle confirms cleanup behavior.

- **2026-07-27 (cont.)** — Set up the first test scenario (retention path) in
  `dev/parm/config/gfs/config.analdiag` and `config.ediag`: `export
  KEEPDATA="NO"` + `export KEEP_TEMP_DIAGS="YES"`, wrapped in `# >>> TEMP TEST
  ... >>>` / `# <<< TEMP TEST <<<` markers. With the OR logic this hits the
  retain branch, so a CI cycle should log `BEFORE: gsidiags EXISTS` →
  `AFTER: gsidiags STILL EXISTS (retained)` in both `gdas_analdiag` and
  `enkfgdas_ediag`, confirming `KEEP_TEMP_DIAGS=YES` retains even when
  `KEEPDATA=NO`. Both configs pass `bash -n`. Open: after this run, flip
  `KEEP_TEMP_DIAGS` back to `NO` and drop the temp `KEEPDATA` line to test the
  removal path; then remove all TEMP TEST markers (configs + exglobal_diag.sh).

- **2026-07-27 (cont.)** — Non-code turn: explained the NOAA WCOSS2 → NIMBUS
  (Google Cloud / GCP) operational migration in response to an internal
  briefing. Key facts confirmed via web search: GCP (not AWS) was selected as
  the primary HPC provider for the WCOSS successor; AWS remains for public/Open
  Data (NODD) dissemination — hence the "AWS not used" surprise. Timeline: full
  user access Oct 2026, NOMADS operational in GCP Jan 2027, WCOSS2 decommissioned
  and ops 100% in GCP by Dec 2027. Repo impact discussed (not implemented): a
  future `dev/workflow/hosts/nimbus.yaml` host profile alongside the existing
  `wcoss2.yaml`; scrutiny of sentinel/barrier logic against cloud-storage
  consistency vs Lustre; CI host matrix likely to gain a GCP target over time.
  No files changed this turn — informational only; no bearing on the gsidiag
  cleanup work above.
