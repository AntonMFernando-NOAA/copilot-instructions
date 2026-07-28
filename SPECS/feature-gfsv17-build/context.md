# Context — `feature/gfsv17-build`

## Purpose

Deliver a GFS-specific automated CI profile for the `dev/gfs.v17` line of
work so pipelines build and test only GFS-relevant components and never
schedule SFS / GEFS / GCAFS work that this branch does not carry.

## Problem statement (from CM request)

- CI on `dev/gfs.v17` attempts to run/build systems beyond intended scope
  (SFS, GEFS, GCAFS), causing avoidable failures on branch-specific
  content/layout changes.
- Downstream logic (e.g. `sorc/link_workflow.sh`) assumes GEFS/GCAFS/SFS
  components exist and fails when branch-intentional paths are absent.

## Findings — current CI architecture (read-only survey)

Pipeline is GitLab-based, triggered from GitHub Actions
(`.github/workflows/trigger-gitlab-pipelines.yml`) or GitLab scheduled
pipelines.

- `.gitlab-ci.yml` — orchestration. Stages: build → setup_tests →
  run_tests → finalize. Defaults: `PIPELINE_TYPE=pr_cases`,
  `RUN_ON_MACHINES=all`, `GFS_CI_RUN_TYPE=pr_cases`. `.build_template`
  comment explicitly lists modalities "GFS, GEFS, SFS, GCAFS". The build
  script calls `dev/ci/scripts/utils/ci_utils.sh build` then
  `sorc/link_workflow.sh`.
- `dev/ci/scripts/utils/ci_utils.sh` → `build()` runs
  `sorc/build_compute.sh -A "${HPC_ACCOUNT}" all`  ← **broad `all` target**.
- `sorc/build_compute.sh` — supports explicit systems:
  `gfs gefs sfs gcafs gsi gdas all` (default `gfs`). So explicit
  per-system builds are already supported by the underlying tool.
- `dev/ci/gitlab-ci-hosts.yml` — per-host case matrices include non-GFS
  cases: `C48_S2SWA_gefs` (GEFS), `C96_gcafs_cycled`,
  `C96_gcafs_cycled_noDA` (GCAFS). CTest matrix
  (`.ctests_cases_template`) includes `C48_S2SWA_gefs-gefs_fcst_mem001_seg0`.
- `dev/ci/gitlab-ci-cases.yml` — setup/run/finalize templates; case name
  comes from matrix `caseName`, resolved to
  `dev/ci/cases/pr/${caseName}.yaml`.
- `sorc/link_workflow.sh` — unconditional non-GFS references:
  - `for dir in gfs gcafs gefs sfs` → links `sorc/upp.fd/parm/${dir}`
    (unguarded; ~line 188).
  - `for file in ice_gfs.csv ice_gefs.csv ocean_gfs.csv ocean_gefs.csv ...`
    (unguarded; ~line 198).
  - `model_systems=("gfs" "gefs" "sfs" "gcafs")` and `wave_systems`
    (gfs/gefs/sfs) — these ARE guarded by `[[ -f ... ]]` / `[[ -d ... ]]`
    so they degrade gracefully already.

## Case inventory

- `dev/ci/cases/pr/` — PR cases (mixed systems, incl. gefs/gcafs).
- `dev/ci/cases/gfsv17/` — GFS-v17-specific cases (retro/s2sw streams,
  marine, C1152mx025, etc.).
- `dev/ci/cases/{gcafsv1,sfs}/` — non-GFS system cases.

## Design directions under consideration (not yet decided)

1. Branch-scoped build system list variable (e.g. `GW_BUILD_SYSTEMS`)
   consumed by `ci_utils.sh build()`, defaulting to current behavior.
2. GFS-only case/CTest matrices selectable by a profile variable so
   develop-branch matrices stay intact.
3. Guard the unconditional non-GFS link loops in `link_workflow.sh` with
   source-path existence checks.

## Decisions

- **Build command (CM-confirmed):** the GFS-v17 build is
  `./build_all.sh gsi gfs gdas` (direct parallel build), NOT
  `build_compute.sh ... all`. `ci_utils.sh build()` now calls it directly.
- **Profile placement:** because `dev/gfs.v17` is an independent,
  system-specific line of work, the GFS-only profile is expressed as
  branch-local edits to the shared CI files rather than a runtime toggle.
  This branch is not intended to merge these CI edits back to develop.

## Open questions

- None blocking. If a runtime toggle is later required (to keep these
  files byte-identical with develop), lift the system list and matrices
  behind a `CI_PROFILE`/`GW_BUILD_SYSTEMS` variable.

## Files likely to change

- `dev/ci/scripts/utils/ci_utils.sh` (build target)
- `dev/ci/gitlab-ci-hosts.yml` (matrices)
- `sorc/link_workflow.sh` (guard non-GFS links)
- possibly `.gitlab-ci.yml` (profile variable default)

## Changes made (2026-07-22)

1. `dev/ci/scripts/utils/ci_utils.sh` — `build()` now runs
   `sorc/build_all.sh gsi gfs gdas` instead of
   `sorc/build_compute.sh -A "${HPC_ACCOUNT}" all`.
2. `dev/ci/gitlab-ci-hosts.yml` — removed `C48_S2SWA_gefs`,
   `C96_gcafs_cycled`, `C96_gcafs_cycled_noDA` from all five host case
   matrices (hera/gaeac6/orion/hercules/ursa); removed
   `C48_S2SWA_gefs-gefs_fcst_mem001_seg0` from the CTest matrix.
3. `sorc/link_workflow.sh` — guarded the UPP parm loop
   (`gfs gcafs gefs sfs`) and the ocnicepost CSV loop so non-GFS
   (`gcafs`/`gefs`/`sfs`, `*_gefs.csv`) sources are skipped when absent;
   GFS sources remain required.

Validated: `bash -n` on both shell scripts, YAML parse on hosts file.
(shellcheck not available on this host.)

## Status

- 2026-07-22: Requirements drafted (requirements-first) and GFS-only CI
  profile implemented on the branch per CM confirmation
  (`build_all.sh gsi gfs gdas`). Ready for review / CI dry-run.

## Changes made (2026-07-24)

Rationale: extend the GFS-only profile to the `build_all.sh all` target so
that even a broad `all` invocation builds only GFS-relevant executables and
never schedules GEFS / SFS / GCAFS work on this branch.

4. `sorc/build_all.sh` — redefined the `["all"]` entry in `system_builds`.
   Previously `all` expanded to the full multi-system set
   (`ufs_gfs gfs_utils ufs_utils upp ww3_gfs ufs_gefs ufs_sfs ufs_gcafs
   ww3_gefs gdas gsi_enkf gsi_monitor gsi_utils nexus`). It now expands to
   the GFS-relevant union of `gfs` + `gsi` + `gdas`:
   `ufs_gfs gfs_utils ufs_utils upp ww3_gfs gdas gsi_enkf gsi_monitor
   gsi_utils`. Excluded non-GFS components: `ufs_gefs`, `ufs_sfs`,
   `ufs_gcafs`, `ww3_gefs`, `nexus`. Added an explanatory comment above the
   entry. This makes `build_all.sh all` equivalent to the CM-confirmed
   `build_all.sh gsi gfs gdas`.

Validated: `bash -n sorc/build_all.sh` (syntax OK).

Open questions: none. If develop-parity is later required, gate the `all`
system list behind a branch/profile variable rather than editing the map
in place.

## Review (2026-07-24) — does `link_workflow.sh` need updating for GFS-only `all`?

Rationale: verify the `build_all.sh all` -> GFS-only change does not break
`sorc/link_workflow.sh`, which references GEFS/SFS/GCAFS/NEXUS artifacts.

Finding: **No code change required.** Traced every non-GFS reference in
`link_workflow.sh` against the GFS-only artifact set (`ufs_gfs gfs_utils
ufs_utils upp ww3_gfs gdas gsi_enkf gsi_monitor gsi_utils`):

- `model_systems=(gfs gefs sfs gcafs)` loop — link guarded by
  `[[ -f ufs_model.fd/tests/${sys}_model.x ]]`; only `gfs_model.x` exists,
  others skipped.
- `wave_systems` (gfs/gefs/sfs) — guarded by `[[ -d .../WW3/install/${build_loc} ]]`;
  `ww3_gefs` not built so `pdlib_OFF` absent/skipped, `gfs` pdlib_ON links.
- NEXUS parm/exec blocks — guarded by `[[ -d sorc/nexus.fd ]]` and
  `[[ -d sorc/nexus.fd/build/bin ]]`; exec skipped when not built.
- GSI / gsi_utils / gsi_monitor / GDASApp — guarded by `[[ -d .../install ]]`
  and all in the GFS set anyway.
- UPP parm loop + ocnicepost `*_gefs.csv` loop — already guarded 2026-07-22.

All remaining unconditional links map to components the GFS-only `all`
actually builds. So `link_workflow.sh` degrades gracefully; no edit made.

Open question: the ufs parm-template loop still links `post_itag_gcafs` and
`ufs.configure.atmaero.IN` / `atmaero`-related templates. These come from the
`ufs_model.fd` source tree (present regardless of which system compiled), so
they are build-safe and do not fail. Undecided whether to prune them so the
linked `parm/` tree is strictly GFS-only vs. leaving as-is (build-safe).
Awaiting user direction.

## PR authoring (2026-07-27)

Rationale: drafted a PR title and description for the GFS-only CI profile
so the branch work can be opened against `dev/gfs.v17`.

- Verified scope from git: commit `50ec93bf6`
  ("ci: Remove GEFS/GCAFS cases and update build target for GFS-v17 profile")
  on `feature/gfsv17-build` covers the 2026-07-22 changes —
  `dev/ci/gitlab-ci-hosts.yml`, `dev/ci/scripts/utils/ci_utils.sh`,
  `sorc/link_workflow.sh` (3 files, +30/-10).
- Produced PR title `ci: GFS-only CI profile for dev/gfs.v17 (exclude
  GEFS/GCAFS/SFS)` and a full description (problem, changes grouped by
  build targets / test matrices / downstream robustness, design note on
  branch-local profile, test evidence, checklist).
- No code changes made this turn (documentation/PR text only).

Open questions / flags:
- The 2026-07-24 `sorc/build_all.sh` `all`-target change is NOT in commit
  `50ec93bf6`, and no later commit on `feature/gfsv17-build` touches
  `sorc/build_all.sh`. It appears uncommitted; needs to be committed if it
  is to be part of this PR.
- Issue number still to be filled into `Fixes #<issue-number>`.
- Note: authored while checked out on `feature/gfsv17-gsidiag`; logged here
  because the work pertains to the `feature/gfsv17-build` profile.

## CI failures triaged (2026-07-27)

Branch state: three commits now sit on top of the dev/gfs.v17 base —
`50ec93bf6` (CI cases + build target), `84440cf83` (build_all.sh "all"
target trimmed to GFS set — this resolves the earlier "uncommitted"
flag), and `eeba67fd3` (skip_ci_on_hosts edits, see below). All pushed to
`origin/feature/gfsv17-build`.

### 1. ci-pytest `test_ci_matrix_validation.py::test_matrices_are_valid`
Rationale: removing GEFS/GCAFS cases from the host matrices in
`gitlab-ci-hosts.yml` made them inconsistent with the case files. The
validator (`dev/ci/scripts/unittests/test_ci_matrix_validation.py`) builds
expected matrices from each case file's `skip_ci_on_hosts` and flagged the
removed cases as "missing cases that should run on this host" for the five
matrix hosts (hera/gaeac6/orion/hercules/ursa).

Fix (committed as `eeba67fd3`): set `skip_ci_on_hosts` to all hosts in the
three case files so they are skipped everywhere, matching the trimmed
matrices:
- `dev/ci/cases/pr/C48_S2SWA_gefs.yaml` (was `- None`)
- `dev/ci/cases/pr/C96_gcafs_cycled.yaml`
- `dev/ci/cases/pr/C96_gcafs_cycled_noDA.yaml`
Each now skips: hera, gaeac5, gaeac6, orion, hercules, ursa,
awsepicglobalworkflow. Could not run pytest locally (no python/pytest on
host); logic verified by hand against the validator.

### 2. build-gaeac6 failure (exit 128) — gdas.cd submodule
Real error: `remote error: upload-pack: not our ref bfc5cd19...` for
submodule `sorc/gdas.cd`. Diagnosis:
- HEAD records `sorc/gdas.cd` gitlink = `bfc5cd19015e5e386b1870c213e1f82b1c449b37`.
- That gitlink was set by `4e9c66bdf` (PR #4922, "Add marine observation
  processing to dev/gfs.v17"), i.e. inherited dev/gfs.v17 history — NOT by
  any of this branch's three commits.
- `.gitmodules`: `sorc/gdas.cd.url = https://github.com/NOAA-EMC/GDASApp.git`,
  branch `release/gfs.v17`. Remote reports `bfc5cd19...` is "not our ref"
  (orphaned by a force-push/rebase, or only ever on a deleted PR/fork branch).
- The build template runs `git submodule update --init --recursive`
  unconditionally before the build, so this is independent of the GFS-only
  build-target change (GDAS is legitimately in scope for GFS-v17).
- Stale local `dev/gfs.v17` ref (`865eed8ec`) previously pointed gdas.cd at
  `32d2cce8...`.

No code change made for #2 — pointing the gitlink at a commit is
correctness-sensitive and needs the GDAS owner's confirmed hash.

Open questions / next steps:
- Confirm the intended GDASApp `release/gfs.v17` commit for GFS-v17 with the
  PR #4922 / GDAS owner, then either bump `sorc/gdas.cd` to a
  remote-reachable commit OR have `bfc5cd19...` pushed to the GDASApp remote.
- Re-run ci-pytest once python/pytest is available to confirm
  `test_matrices_are_valid` passes.

## How to test this PR (2026-07-27, Q&A — no code change)

Clarified the CI execution model (no personal runner needed):
- Runners are shared infra already registered on the RDHPCS machines
  (Hera/Gaea C6/Orion/Hercules/Ursa) via `launch_gitlab_runner.sh`. You do
  NOT register your own runner to test a PR.
- The GitLab pipeline is keyed off a real PR on `NOAA-EMC/global-workflow`
  (build stage runs `gh pr checkout ${PR_NUMBER}`), so the branch must be
  pushed and opened as a PR — a local feature branch alone can't be tested.
- Trigger gate is authorization, not runners: the actor must be in the
  `AUTHORIZED_GITLAB_TRIGGER_USERS` GitHub repo variable to run
  `.github/workflows/trigger-gitlab-pipelines.yml`. If not listed, ask a
  maintainer to trigger, or get added.
- Trigger path: Actions tab → "Trigger GitLab Pipelines" → enter PR number,
  choose PR Cases/CTests, select machine(s).
- Registering a personal runner only applies when adding a new host platform.

Reminder: even after triggering, the build stage will still fail on the
`sorc/gdas.cd` submodule (`bfc5cd19...` "not our ref") until the gitlink is
fixed (see 2026-07-27 triage entry).

Open question: is Anton's GitHub handle in `AUTHORIZED_GITLAB_TRIGGER_USERS`,
or should a maintainer kick off the run?

## gdas.cd submodule — corrected diagnosis (2026-07-27)

New evidence (corrects the earlier "commit gone from remote" triage):
`git ls-remote https://github.com/NOAA-EMC/GDASApp.git release/gfs.v17`
returns `bfc5cd19015e5e386b1870c213e1f82b1c449b37` — i.e. the remote branch
tip now equals the exact gitlink the superproject records. The commit is NOT
orphaned; no gitlink change is needed.

Revised root cause of the CI "upload-pack: not our ref bfc5cd19..." error —
a fetch-reachability problem at run time, most likely one of:
1. Branch caught up: when CI ran, `release/gfs.v17` did not yet point at
   `bfc5cd19...`; it has since advanced to it, so a fresh run should fetch it.
2. Shallow-fetch miss: `.gitlab-ci.yml` sets `GIT_DEPTH: 10` and GitLab's
   recursive submodule fetch is shallow; if it fetched GDASApp's default
   branch (develop) or only 10 commits, `bfc5cd19...` wasn't in the fetched
   set, so git fell back to a direct-SHA fetch which the server rejects.

Recommended next steps (no code change made this turn):
- Re-trigger the pipeline first (user is an authorized triggerer). Pointer
  now matches the remote tip, so the recursive checkout may just succeed.
- If it still fails with "not our ref", deepen submodule fetch: set
  `GIT_SUBMODULE_DEPTH: 0` (or a large `GIT_DEPTH`) in `.gitlab-ci.yml` so
  the SHA is always reachable. Offered to make this edit pending user choice.

Note: user confirmed they are an authorized GitLab pipeline triggerer, so the
`AUTHORIZED_GITLAB_TRIGGER_USERS` gate is satisfied.
