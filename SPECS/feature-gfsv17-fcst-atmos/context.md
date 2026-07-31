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

### 2026-07-28 (cont.) — Change applied: retain per-product ATM dep logs

**Decision:** Keep dep logs in COM (user confirmed: "okay, let's keep the dep files").

**Change — `ush/forecast_atm_barrier.sh`:**
- Normal-completion path: removed `rm -f "${deps[@]}"` (line ~122). Updated
  comment to explain retention rationale and the RERUN guard benefit (GH#5130).
- WARN-drain path: removed `rm -f "${warn_deps[@]}"` and the now-dead
  `read -r -a warn_deps` declaration. Updated comment: retained dep logs help
  post-mortem analysis of which product types completed before the timeout.

**Verification:** `bash -n ush/forecast_atm_barrier.sh` passes. No commit yet.

**Net effect:**
- All per-product logs (`log.atm.{atmf,sfcf,grib,flux}.fHHH.txt`) remain in COM
  after each forecast hour completes. The combined `log.fHHH.txt` is still
  written unchanged — no downstream sentinel contract change.
- On segment rewind, `forecast_manager.sh`'s `if [[ -f "${this_cl}" ]]` RERUN
  guard now fires for already-copied hours → skips redundant re-copies.
- On WARN-drain (barrier timeout), any dep logs that arrived before the timeout
  survive in COM for post-mortem.

**Open follow-ups:**
- Commit and run CI (bash_code_analysis / shellcheck).
- Confirm with D.Huber / testing whether any downstream consumer (post/products/
  archive) is sensitive to the dep logs being present (expected: none — they only
  key off `log.fHHH.txt`).
- Partial-dep-log-on-crash risk noted (pre-existing, not introduced here):
  if a crash left a dep log in COM for an incomplete hour, the RERUN guard
  would skip re-copying the (potentially corrupt) data file. Defer to a
  separate issue if needed.

### 2026-07-29 — Inline documentation pass on `forecast_atm_barrier.sh`

**Rationale:** User requested richer inline comments explaining what each
variable does and *why* it exists — not just what it holds.

**Files touched:**
- `ush/forecast_atm_barrier.sh` — added detailed comments throughout:
  - `barrier_table`: `:?` bash abort-on-empty idiom explained.
  - `FCST_POLL_INTERVAL`, `FCST_HISTORY_DONE_SENTINEL`, `FCST_POSTDONE_TIMEOUT`:
    purpose and default-value rationale.
  - `final_logs[]`, `all_deps_arr[]`, `pending_idx`: what each array stores
    and why they are kept separate.
  - `dep_seen`: key annotation — associative array used as a hash set to detect
    *first observation* of each dep file, preventing stale files from falsely
    resetting the idle timer on every cycle.
  - `count`, `remaining`, `remaining_before`: lifecycle tracking explained.
  - `postdone_elapsed` / `postdone_announced`: idle-clock semantics and
    one-shot announcement flag.
  - `all_ready`: optimistic-start + break-on-first-miss pattern explained.
  - `progress_made`: two conditions that count as progress and why that
    distinction protects slow-but-active copy ranks from premature WARN drain.
  - WARN sentinel path: added note that retained dep logs help post-mortem.

**Verification:** `bash -n ush/forecast_atm_barrier.sh` passes (syntax OK).

**Commits:** None yet — documentation-only change, pending commit with the
earlier GH#5130 barrier edit.

**Open questions:** None new from this turn.

### 2026-07-29 — WARN dep log design question raised

**Topic:** User asked whether WARN dep logs are written for individual dep files
(e.g. `com_log_grib`, `com_log_flux`) that never arrive when the WARN drain fires.

**Finding:** No — the current WARN drain path only writes `final_log` with
`WARN: ATM barrier timed out...`. Missing dep logs simply remain absent in COM.
The original code only had `rm -f "${warn_deps[@]}"` (deleted whatever partial
deps existed) — it never wrote WARN content to missing dep logs either.

**Design decision raised (awaiting user response):**
- **Option A (current):** Missing dep log = product never confirmed. Absence is
  the signal. RERUN guard in `forecast_manager.sh` correctly re-copies on rewind
  because `this_cl` doesn't exist. Clean and simple.
- **Option B:** Write explicit WARN markers to missing dep logs on timeout for
  better post-mortem observability. Requires `forecast_manager.sh` RERUN guard
  to inspect file *content* (not just existence) before skipping — larger change,
  risk of skipping genuinely incomplete products.

**No code changes this turn. Awaiting user decision on Option A vs B.**

### 2026-07-29 — Grounding: manager/barrier MPMD wiring traced

**Rationale:** User asked how `forecast_manager.sh` and `forecast_atm_barrier.sh`
are connected. Traced the launch path (not previously recorded here).

**Findings (from reading the working tree, no code changed):**
- `scripts/exglobal_forecast_manager.sh` (~lines 102–111) builds the MPMD
  cmdfile: per ATM instance it emits 4 `forecast_manager.sh` copy ranks
  (atm_atmf, atm_sfcf, and — if `WRITE_DOPOST` — atm_grib, atm_flux) plus one
  `forecast_atm_barrier.sh` rank. `run_mpmd.sh` launches all 5 in parallel.
  Repeated per `MGR_NATM_INST` instance (default 2 → 10 ranks).
- The two scripts are **decoupled** — neither calls the other. Coupling is via
  COM files: the manager's `com_log` output path IS the barrier table's dep
  column. Shared table pair is built together in `FV3_postdet`
  (`forecast_postdet.sh`).
- Shared job sentinels (env-passed): `FCST_TABLE_READY_SENTINEL` (manager gate),
  `FCST_HISTORY_DONE_SENTINEL` (both: manager idle-exit, barrier WARN-drain),
  `FCST_SEGMENT` (per-segment paths).
- A `dev/scripts/exglobal_forecast_manager.sh` duplicate exists with identical
  wiring.

**Commits:** None. Documentation/understanding only.

**Open questions:** None new.

### 2026-07-29 — Grounding: barrier usage + downstream consumers traced

**Rationale:** User asked where the barrier is used. Traced launch site, input,
and — newly — the downstream consumers of its combined sentinel.

**Findings (working tree; no code changed):**
- **Launch:** `scripts/exglobal_forecast_manager.sh` line 109 (dup in
  `dev/scripts/...`) — 5th MPMD rank per ATM instance via `run_mpmd.sh`.
- **Input table:** `atm_barrier_seg*_inst*.txt` from `FV3_postdet`
  (`forecast_postdet.sh`).
- **Output combined sentinel** `${COMIN_ATMOS_HISTORY}/gfs.tCCz.log.fHHH.txt`
  is consumed by:
  - `scripts/exglobal_fsm.sh` (line 374, `atm_log=...log.f${fhr_3d}.txt`) — the
    Flexible Submit Manager gates per-hour downstream product release on this
    sentinel. **Primary consumer.**
  - `ush/gfs_bufr.sh` (lines 82/88) — BUFR sounding job requires current AND
    previous hour's `log.fHHH` present or it FATAL-errors.
- Confirms the earlier context.md open question: downstream consumers key off
  the **combined** `log.fHHH.txt`, NOT the per-product dep logs — so retaining
  dep logs (GH#5130) does not affect FSM/BUFR behavior.

**Commits:** None. Understanding/grounding only.

**Open questions:** Neither FSM nor gfs_bufr inspects sentinel *content*, so a
WARN combined sentinel would still release/consume the hour as if normal
(consistent with earlier WARN-awareness discussion — a potential separate issue).

### 2026-07-29 — Grounding: per-component group-copy behavior

**Rationale:** User asked whether OCN/ICE copy multi-file groups like ATM.

**Findings (working tree, no code changed):**
- Group-copy loop in `forecast_manager.sh` (copy all rows sharing one
  `local_log` before writing the sentinel) is generic to all components.
- **ATM** (`FV3_postdet`): multiple data files share one `log.atm.fHHH`
  sentinel — `atmf` + `cubed_sphere_grid_atmf` in the atm_atmf table (2-file
  group when JEDI/native-grid on), similarly sfcf. Real grouping.
- **OCN** (`MOM6_postdet`, ~line 904): one row per period, each with its own
  distinct period sentinel (`YYYYMMDD.HHMMSS.mom6.NNh`). Group size = 1.
- **ICE** (`CICE_postdet`, ~line 1134): one row per forecast hour, sentinel
  `log.ice.f${fhr4}`, one data file each (+ one-off IC row). Group size = 1.
- Conclusion: OCN/ICE run the group loop trivially (single member). Their
  reference-size heuristic substitutes for grouping as the per-file integrity
  check when the sentinel is absent.

**Commits:** None. Grounding/understanding only.

**Open questions:** None new.

### 2026-07-29 — Correction: real CICE COM filenames (size-check example)

**Rationale:** User flagged that an earlier size-check example used invented ICE
filenames (`icef006.nc`). Re-read `CICE_postdet` and corrected.

**Real CICE `dest_file` naming (COMOUT_ICE_HISTORY):**
- `gdas | enkfgdas`: `${RUN}.t${cyc}z.inst.f${fhr3}.nc`  (e.g. `gdas.t00z.inst.f006.nc`)
- `gfs | enkfgfs | gefs`: `${RUN}.t${cyc}z.${interval}hr_avg.f${fhr3}.nc`
  (e.g. `gfs.t00z.6hr_avg.f006.nc`)
- IC row: `${RUN}.t${cyc}z.ic.nc` (no forecast-hour token → normalizes to itself,
  never collides with history files in the reference-size loop).
- source_file: `iceh_inst.<vdatestr>.nc` / `iceh_<FHOUT_ICE>h.<vdatestr>.nc`;
  local sentinel `log.ice.f${fhr4}`.

**Correctness point (unchanged):** the reference-size selection mechanism I
described was right; only the example filenames were wrong. Real names confirm
the `sed 's/[Ff][0-9]\{2,3\}/fNNN/g'` normalization: `inst.fNNN` vs
`6hr_avg.fNNN` stay distinct, and `ic.nc` never matches history files.

**Note to self:** read actual filenames from source before giving concrete
examples — do not fabricate.

**Commits:** None. Correction to prior explanation; no code change.

### 2026-07-30 — Q&A: steering rule meaning + CI pipeline / PR-case layout

**Rationale:** User asked what `.kiro/steering/spec-branch-layout.md` means, and
"where is the merge from dev/gfs.v17 pipeline and build updates with the specific
PR Cases that can run on that branch?" Also flagged: the hook's `agentcore_mcp_rag`
tools are **not installed** in this workspace (no powers/MCP servers registered),
so this turn was grounded in repo files, not the KB.

**Explained (no code changed):**
- Steering rule = Kiro spec-layout convention: one spec dir per branch under
  `.kiro/specs/{branch-slug}` (slug = branch with `/`→`-`), flat, holding
  requirements/design/tasks + context.md + .config.kiro; SPECS panel shows a dir
  only once it has requirements/design/tasks/bugfix.md; `.kiro/` git-excluded.
  Guidance for Kiro only — no effect on the forecast/CI pipeline.
- Corrected user premise: CI is **not merge-driven**. Pipeline lives in
  `.gitlab-ci.yml` (stages build→setup_tests→run_tests→finalize) including
  `dev/ci/gitlab-ci-{cases,ctests,hosts}.yml`. Build = `.build_template` →
  `dev/ci/scripts/utils/ci_utils.sh build`.
- Trigger path: `.github/workflows/trigger-gitlab-pipelines.yml` is
  `workflow_dispatch` only (maintainer picks PR Cases/CTests + machines);
  host rules run only on `$CI_PIPELINE_SOURCE == trigger|schedule`, several carry
  `when: never # ...merges to develop`. Merges to develop/dev.v17 do NOT build.
- Runnable PR Cases = `dev/ci/cases/pr/*.yaml`, wired into per-host matrices in
  `gitlab-ci-hosts.yml` (Hera/Ursa fullest; Orion/Hercules trimmed subsets).
- **Gap flagged:** `dev/ci/cases/gfsv17/*` (C1152mx025_S2SW, gfs.v17_lowres_extended,
  retrov17_*/s2sw_* streams, marine3dvar/marinehyb) are NOT referenced in any
  GitLab matrix — case defs only, not in the automated PR-case pipeline.
- Current checkout is `feature/gfsv17-fcst-atmos`, not `dev/gfs.v17`. `git diff`
  across `dev/ci`, `.gitlab-ci.yml`, `.github/workflows` vs `dev/gfs.v17` = 91
  files changed (366 ins / 646 del) → CI config diverges between the branches.

**Commits:** None. Q&A/grounding only.

**Open questions:** Asked user to clarify merge direction (dev/gfs.v17 →
feature branch or vice versa) before staging any CI-config merge.

### 2026-07-30 (cont.) — Q&A: explained scan_and_release() (GH#5129)

**Rationale:** User asked for an explanation of `scan_and_release()` with an
example. Grounded in `dev/scripts/exglobal_fsm.sh` (identical copy in
`scripts/exglobal_fsm.sh`, lines ~83–153). Hook's `agentcore_mcp_rag` tools
still not installed — answered from the working tree.

**What it is (no code changed):**
- FSM helper (GH#5129) collapsing seven duplicated per-product scan/release
  blocks into one loop. Walks a forecast-hour list in order; per hour requires
  every COM file template (`%s` = 3-digit fhr) to exist & be non-empty (`-s`);
  on success sets `state[fhr]="YES"` and fires
  `ecflow_client --event <prefix>_fHHH`; on first miss sets `skip=YES` (enforce
  in-order release), re-arms `scan_flag=YES` and the shared global
  `proceed_trigger_scan=YES` so the outer `while` sweeps again.
- Args: `<scan_flag_var>` (nameref), `<state_array_name>` (nameref,
  `*_product_ready`), `<event_prefix>`, `<file_template(s)>` (space-separated,
  multi-file = all must be present; first names the "waiting" msg), `<fhr>...`.
- Namerefs (`local -n`) bind flag + state array by name; `read -r -a tmpls`
  splits multi-template string (e.g. master + sflux).
- Example given: gfs atmos-master (master.grib2 + sflux.grib2) over f000–f003
  with sflux.f002 missing → f000/f001 release, f002 waits, f003 skipped
  in-order; re-scans until all release.
- Noted log-sentinel variants (ocean/ice/wave) key off `.log.fHHH` copy-complete
  files rather than data files — same sentinel contract as the ATM barrier /
  GH#5130 work.

**Commits:** None. Q&A/grounding only.

**Open questions:** None new.

### 2026-07-30 (cont.) — Q&A: line-by-line of scan_and_release() header/loop-top

**Rationale:** User re-asked, focusing on the setup block + top of the for-loop
(arg capture through the two early `continue`s). Grounded in
`dev/scripts/exglobal_fsm.sh`; `agentcore_mcp_rag` tools still not installed.

**Explained (no code changed):**
- `local flag_var/arr_name/event/tmpl="${1..4}"` + `shift 4` → remaining `"$@"`
  is the forecast-hour list.
- `local -n scan_flag/state` = namerefs (indirect); writes hit the caller's
  `scan_release_*` flag and `*_product_ready` array (bash is pass-by-value
  otherwise) — this is the report-back mechanism.
- `read -r -a tmpls <<< "${tmpl}"` splits space-separated multi-template string
  (e.g. master + sflux) into an array.
- `scan_flag="NO"` = optimistic reset (flips back to YES on a miss).
- `fhr_3d=$(printf "%03d" ...)` zero-pads to match COM names / event suffix.
- `[[ ${state[fhr]:-NO} == YES ]] && continue` skips already-released hours
  (`:-NO` default for unset slots).
- `[[ ${skip} == YES ]] && continue` enforces in-order release: after the first
  missing hour, all later hours are skipped.

**Commits:** None. Q&A/grounding only.

**Open questions:** None new.

### 2026-07-30 (cont.) — Diagnosed agentcore-mcp-rag offline (boto3 missing)

**Rationale:** User reported the `agentcore-mcp-rag` MCP server offline and asked
me to bring it online. This is why the prior turns' hook-requested KB tools were
unavailable.

**Root cause (from user's Kiro MCP log + local checks):**
- Server log: `ModuleNotFoundError: No module named 'boto3'` raised at
  `/mdc-mcp-rag/eib-mcp-rag-server/tools/agentcore-kiro-proxy.py` line 53
  (`import boto3`) → proxy exits → `MCP error -32000: Connection closed`.
- `~/.kiro/settings/mcp.json` launches the proxy with `command: python3`
  (relies on PATH). Resolved `python3` = `/usr/bin/python3` (Python 3.9.25).
- Confirmed that interpreter lacks boto3:
  `python3 -c "import boto3"` → ModuleNotFoundError. The proxy's only dep is
  boto3 (Python 3.9+ per its header).
- `pip` present: pip 21.3.1 for python 3.9.

**Fix attempted:** `python3 -m pip install --user boto3` — **blocked**
("Tool use was not permitted"), so the install did not run. No changes made
this turn (no config edit, no package installed).

**Files touched:** None (mcp.json inspected only; proxy is outside workspace so
read via bash `head`).

**Commits:** None.

**Open questions / next steps to bring server online:**
1. Install boto3 for the exact interpreter Kiro uses. Options:
   - `python3 -m pip install --user boto3` (needs command permission), or
   - point mcp.json `command` at a venv python that has boto3, e.g. create
     `/mdc-mcp-rag/eib-mcp-rag-server/.venv`, `pip install boto3`, and set
     `command` to that venv's `python3` (most robust — pins the interpreter).
2. After install, verify `python3 -c "import boto3"` succeeds, then reconnect
   the server from the Kiro MCP Server view.
3. Also needs valid AWS creds/region (proxy calls `invoke_agent_runtime` in
   us-east-1) — verify IAM role/creds once boto3 imports.
