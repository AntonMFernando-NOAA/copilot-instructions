# Requirements Document

_Spec branch: `feature/gfsv17-build`_

## Introduction

The `dev/gfs.v17` line of work delivers only the GFS system (plus its
GDAS / enkfGDAS data-assimilation cycle). The shared global-workflow CI
machinery, however, is written to be system-agnostic and always exercises
every modality — GFS, GEFS, SFS, and GCAFS. On `dev/gfs.v17` this causes
avoidable failures because:

- `dev/ci/scripts/utils/ci_utils.sh build()` invokes
  `sorc/build_compute.sh -A "${HPC_ACCOUNT}" all`, which builds the
  GEFS / SFS / GCAFS systems that this branch does not carry. The
  intended GFS-v17 build is `./build_all.sh gsi gfs gdas`.
- The per-host case matrices in `dev/ci/gitlab-ci-hosts.yml` schedule
  non-GFS cases (`C48_S2SWA_gefs`, `C96_gcafs_cycled`,
  `C96_gcafs_cycled_noDA`) and a GEFS CTest
  (`C48_S2SWA_gefs-gefs_fcst_mem001_seg0`).
- `sorc/link_workflow.sh` unconditionally references GEFS / SFS / GCAFS
  paths (`for dir in gfs gcafs gefs sfs`, `ice_gefs.csv`,
  `ocean_gefs.csv`), so linking fails when those branch-intentional
  paths are absent.

The goal is a **GFS-specific CI profile** for `dev/gfs.v17` that builds
and tests only GFS-relevant components, never schedules SFS / GEFS /
GCAFS pipelines, and keeps downstream linking robust when non-GFS
components are intentionally absent.

## Requirements

### Requirement 1: GFS-only build scope on this branch

**User Story:** As a CM, I want CI builds on `dev/gfs.v17` to compile
only GFS-relevant components, so that builds do not fail attempting to
compile systems the branch does not carry.

#### Acceptance Criteria

1. WHEN the CI build step runs on the `dev/gfs.v17` branch, THE build
   SHALL invoke `sorc/build_all.sh gsi gfs gdas` rather than
   `sorc/build_compute.sh ... all`.
2. THE build SHALL NOT request the `gefs`, `sfs`, or `gcafs` systems on
   this branch.
3. THE list of systems (`gsi gfs gdas`) SHALL be expressed explicitly at
   the single call site in `ci_utils.sh build()` so the profile is
   reviewable without tracing build internals.

### Requirement 2: GFS-only test/case matrix on this branch

**User Story:** As a CM, I want the CI case and CTest matrices on
`dev/gfs.v17` to contain only GFS-relevant experiments, so that no
GEFS / SFS / GCAFS experiment is scheduled or reported as failed.

#### Acceptance Criteria

1. WHEN the `pr_cases` pipeline runs on `dev/gfs.v17`, THE per-host case
   matrices SHALL NOT include `C48_S2SWA_gefs`, `C96_gcafs_cycled`, or
   `C96_gcafs_cycled_noDA`.
2. WHEN the `ctests` pipeline runs on `dev/gfs.v17`, THE CTest matrix
   SHALL NOT include the GEFS CTest
   (`C48_S2SWA_gefs-gefs_fcst_mem001_seg0`).
3. THE case matrices SHALL retain the GFS and GDAS / enkfGDAS cases that
   represent this branch's intended scope.
4. WHERE a case matrix is changed for this branch, THE change SHALL be
   scoped so it does not alter the develop-branch matrices when merged
   upstream (branch-local profile, clearly identifiable).

### Requirement 3: No scheduled SFS/GEFS/GCAFS pipelines on this branch

**User Story:** As a CM, I want scheduled and triggered pipelines on
`dev/gfs.v17` to run only the GFS profile, so that no non-GFS pipeline
is scheduled against this branch.

#### Acceptance Criteria

1. WHEN a pipeline is triggered or scheduled for `dev/gfs.v17`, THE
   pipeline SHALL execute only the GFS-relevant build and test jobs.
2. THE pipeline SHALL NOT create jobs whose sole purpose is to build or
   test SFS, GEFS, or GCAFS.

### Requirement 4: Robust linking when non-GFS components are absent

**User Story:** As a CM, I want `sorc/link_workflow.sh` to succeed when
GEFS / SFS / GCAFS components are intentionally absent, so that the CI
build step does not fail on missing branch-intentional paths.

#### Acceptance Criteria

1. WHEN `sorc/link_workflow.sh` links UPP parm directories, THE script
   SHALL skip any system directory (`gcafs`, `gefs`, `sfs`) whose source
   path does not exist instead of failing.
2. WHEN `sorc/link_workflow.sh` links ocean/ice CSV files, THE script
   SHALL skip GEFS-specific files (`ice_gefs.csv`, `ocean_gefs.csv`)
   whose source path does not exist instead of failing.
3. THE GFS-relevant links SHALL continue to be created unchanged.
4. WHERE a source path required by GFS is missing, THE script SHALL
   still fail (missing GFS content is a real error, not an intentional
   absence).

### Requirement 5: Preserve shared-repo compatibility

**User Story:** As a CM, I want the GFS-specific profile to be a
recognizable, contained overlay, so that the shared CI files remain
mergeable with develop and other system branches.

#### Acceptance Criteria

1. THE branch-specific CI profile SHALL be implemented so that the
   develop-branch behavior (build `all`, full multi-system matrix) is
   recoverable and not silently broken for other branches.
2. WHERE shared files are edited, THE edits SHALL be minimal and clearly
   attributable to the GFS-v17 profile.

## Glossary

- **CM**: Configuration Manager — owns branch health and CI policy.
- **GFS**: Global Forecast System — the deterministic system delivered on
  `dev/gfs.v17`.
- **GDAS / enkfGDAS**: Global Data Assimilation System and its ensemble
  Kalman filter cycle — the DA components in scope for this branch.
- **GEFS**: Global Ensemble Forecast System — a separate system, out of
  scope for this branch.
- **SFS**: Seasonal Forecast System — out of scope for this branch.
- **GCAFS**: Global Coupled Atmosphere Forecast System — out of scope for
  this branch.
- **CI profile**: A branch-scoped selection of build systems and test
  cases the pipeline exercises.
- **`pr_cases`**: Full end-to-end experiment pipeline modality.
- **`ctests`**: Fast per-job CTest pipeline modality.
- **Case matrix**: Per-host list of experiment `caseName`s the pipeline
  fans out over (`dev/ci/gitlab-ci-hosts.yml`).
- **`build_compute.sh`**: Compute-node build launcher accepting explicit
  system targets (`gfs gefs sfs gcafs gsi gdas all`).
- **`link_workflow.sh`**: Post-build script that links parm/fix/exec
  content from submodules into the workflow tree.

## Work Log

_Appended on demand — ask Kiro to "log the work" and a summary of
recent chat activity will be inserted here. Do not edit prior
entries — add new entries at the bottom._

<!-- WORKLOG:BEGIN -->
<!-- WORKLOG:END -->
