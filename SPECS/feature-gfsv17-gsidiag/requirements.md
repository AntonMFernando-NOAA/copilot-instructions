# Requirements Document

## Introduction

In the GFSv17 global-workflow, the analysis jobs `gdas_anal`
(`JGLOBAL_ATMOS_ANALYSIS`) and `enkfgdas_eobs` (`JGLOBAL_ENKF_SELECT_OBS`)
produce GSI diagnostic data into a shared `gsidiags` directory located on the
DATAROOT side of the COM tree. That directory is created via
`dataroot_com_path` and resolves to a path of the form
`${DATAROOT}/${RUN}.${PDY}/${cyc}/.../gsidiags` (exposed to the jobs as
`${pCOMIN_ATMOS_ANALYSIS}/gsidiags`). The downstream diagnostic jobs
`gdas_analdiag` (`JGLOBAL_ATMOS_ANALYSIS_DIAG`) and `enkfgdas_ediag`
(`JGLOBAL_ENKF_DIAG`) consume that shared data to build the final diagnostic
tarballs (cnvstat, oznstat, radstat, pcpstat).

Today each diagnostic job removes only its own per-job working directory
(`${DATA}`) when `KEEPDATA` is `NO`. The shared `gsidiags` staging directory
under DATAROOT is left behind, wasting scratch space. Because the diagnostic
jobs are the last consumers of that shared data, they are the correct place to
delete it once processing has completed.

This feature makes the diagnostic jobs delete the shared temporary diagnostic
directory once it is no longer needed, while honoring the existing `KEEPDATA`
retention convention and an optional new `KEEP_TEMP_DIAGS` override so that
operators can preserve the data for debugging when desired.

## Glossary

- **GDAS_Diag_Job**: The `gdas_analdiag` job defined in
  `JGLOBAL_ATMOS_ANALYSIS_DIAG`. It runs `exglobal_diag.sh` to build
  deterministic GSI diagnostic tarballs from the shared diagnostic data.
- **EnKF_EDiag_Job**: The `enkfgdas_ediag` job defined in `JGLOBAL_ENKF_DIAG`.
  It runs `exglobal_diag.sh` to build ensemble-mean GSI diagnostic tarballs
  from the shared diagnostic data.
- **Diag_Job**: Either GDAS_Diag_Job or EnKF_EDiag_Job. Used for requirements
  that apply identically to both jobs.
- **Temp_Diag_Dir**: The shared temporary diagnostic staging directory on the
  DATAROOT side of the COM tree, resolved as `${pCOMIN_ATMOS_ANALYSIS}/gsidiags`
  (i.e. the `gsidiags` directory beneath the `dataroot_com_path` translation of
  the analysis COM directory). It is created and populated by the upstream
  `gdas_anal` and `enkfgdas_eobs` jobs.
- **Producer_Job**: An upstream analysis job (`gdas_anal` or `enkfgdas_eobs`)
  that creates and populates Temp_Diag_Dir.
- **Job_Working_Dir**: The per-job scratch directory referenced as `${DATA}`,
  distinct from Temp_Diag_Dir.
- **KEEPDATA**: The existing workflow flag that, when set to `YES`, preserves
  working data that would otherwise be removed at the end of a job.
- **KEEP_TEMP_DIAGS**: An optional new configuration flag scoped to the
  diagnostic jobs that, when set to `YES`, preserves Temp_Diag_Dir independently
  of `KEEPDATA`.
- **Diag_Config**: The diagnostics job configuration sourced by the Diag_Jobs
  (`config.analdiag` for GDAS_Diag_Job and `config.ediag` for EnKF_EDiag_Job).
- **Operations**: The operational (NCO) run configuration of the workflow.

## Requirements

### Requirement 1: GDAS_Diag_Job removes shared temporary diagnostic data

**User Story:** As a workflow operator, I want the `gdas_analdiag` job to delete
the shared GSI diagnostic staging directory it consumed, so that DATAROOT
scratch space is reclaimed after deterministic diagnostics are produced.

#### Acceptance Criteria

1. WHERE both KEEPDATA and KEEP_TEMP_DIAGS are disabled, WHEN GDAS_Diag_Job
   completes writing all diagnostic tarballs to the output COM directory, THE
   GDAS_Diag_Job SHALL remove Temp_Diag_Dir.
2. WHEN GDAS_Diag_Job removes Temp_Diag_Dir, THE GDAS_Diag_Job SHALL remove the
   entire Temp_Diag_Dir directory tree and its contents only after all
   diagnostic tarballs have been successfully written to the output COM
   directory.
3. IF Temp_Diag_Dir does not exist when GDAS_Diag_Job attempts removal, THEN THE
   GDAS_Diag_Job SHALL complete removal handling without reporting an error and
   without failing the job.
4. IF either KEEPDATA or KEEP_TEMP_DIAGS is enabled when GDAS_Diag_Job completes
   diagnostic processing, THEN THE GDAS_Diag_Job SHALL retain Temp_Diag_Dir and
   its contents without removal.
5. IF removal of Temp_Diag_Dir fails after all diagnostic tarballs have been
   written to the output COM directory, THEN THE GDAS_Diag_Job SHALL emit a
   warning indicating the removal failure and complete without failing the job.

### Requirement 2: EnKF_EDiag_Job removes shared temporary diagnostic data

**User Story:** As a workflow operator, I want the `enkfgdas_ediag` job to delete
the shared GSI diagnostic staging directory it consumed, so that DATAROOT
scratch space is reclaimed after ensemble diagnostics are produced.

#### Acceptance Criteria

1. WHEN EnKF_EDiag_Job has written all ensemble-mean diagnostic tarballs to the
   output COM directory AND neither KEEPDATA nor KEEP_TEMP_DIAGS is enabled, THE
   EnKF_EDiag_Job SHALL remove Temp_Diag_Dir together with all of its contents.
2. WHEN EnKF_EDiag_Job removes Temp_Diag_Dir, THE EnKF_EDiag_Job SHALL perform
   the removal only after all ensemble-mean diagnostic tarballs have been
   written to the output COM directory.
3. IF Temp_Diag_Dir does not exist when EnKF_EDiag_Job attempts removal, THEN
   THE EnKF_EDiag_Job SHALL complete removal handling without reporting an error.
4. WHERE KEEPDATA or KEEP_TEMP_DIAGS is enabled, THE EnKF_EDiag_Job SHALL retain
   Temp_Diag_Dir and all of its contents.
5. IF EnKF_EDiag_Job diagnostic processing does not complete successfully, THEN
   THE EnKF_EDiag_Job SHALL retain Temp_Diag_Dir and all of its contents.
6. IF removal of Temp_Diag_Dir fails after being attempted, THEN THE
   EnKF_EDiag_Job SHALL emit an error indication reporting the removal failure
   and complete without aborting the job.

### Requirement 3: Retention honored via KEEPDATA

**User Story:** As a developer debugging analysis diagnostics, I want the shared
diagnostic staging directory preserved when `KEEPDATA` is enabled, so that I can
inspect the intermediate GSI diagnostic data after a run.

#### Acceptance Criteria

1. WHERE KEEP_TEMP_DIAGS is not defined, WHILE KEEPDATA is set to `YES`, WHEN the
   Diag_Job completes, THE Diag_Job SHALL retain Temp_Diag_Dir and all of its
   contents so they remain accessible after the run.
2. WHERE KEEP_TEMP_DIAGS is not defined, WHILE KEEPDATA is set to any value other
   than `YES` (including unset or empty), WHEN the Diag_Job completes, THE
   Diag_Job SHALL remove Temp_Diag_Dir and all of its contents.
3. WHERE KEEP_TEMP_DIAGS is not defined, WHEN the Diag_Job completes, THE
   Diag_Job SHALL apply to Temp_Diag_Dir the same retention decision (retain or
   remove) that KEEPDATA applies to the Job_Working_Dir.
4. WHERE KEEP_TEMP_DIAGS is set to `YES`, WHEN the Diag_Job completes, THE
   Diag_Job SHALL retain Temp_Diag_Dir and all of its contents regardless of the
   KEEPDATA value.
5. WHERE KEEP_TEMP_DIAGS is set to `NO`, WHEN the Diag_Job completes, THE
   Diag_Job SHALL remove Temp_Diag_Dir and all of its contents regardless of the
   KEEPDATA value.

### Requirement 4: Optional KEEP_TEMP_DIAGS override flag

**User Story:** As a developer, I want a dedicated flag that preserves only the
shared diagnostic staging directory, so that I can retain the intermediate GSI
diagnostic data without retaining every job working directory.

#### Acceptance Criteria

1. WHERE KEEP_TEMP_DIAGS is set to `YES`, WHEN the Diag_Job completes, THE
   Diag_Job SHALL retain Temp_Diag_Dir regardless of the value of KEEPDATA.
2. WHERE KEEP_TEMP_DIAGS is set to `NO`, WHEN the Diag_Job completes, THE
   Diag_Job SHALL remove Temp_Diag_Dir regardless of the value of KEEPDATA.
3. WHERE KEEP_TEMP_DIAGS is defined in Diag_Config, THE Diag_Config SHALL default
   the value of KEEP_TEMP_DIAGS to `NO`.
4. WHERE KEEP_TEMP_DIAGS is defined, WHILE the workflow runs in Operations, THE
   Diag_Config SHALL set KEEP_TEMP_DIAGS to `NO`.
5. IF KEEP_TEMP_DIAGS is unset or empty when the Diag_Job completes, THEN THE
   Diag_Job SHALL determine retention of Temp_Diag_Dir solely from the value of
   KEEPDATA, retaining Temp_Diag_Dir when KEEPDATA is `YES` and removing it when
   KEEPDATA is `NO`.
6. IF KEEP_TEMP_DIAGS is set to any value other than `YES` or `NO` when the
   Diag_Job completes, THEN THE Diag_Job SHALL remove Temp_Diag_Dir and emit an
   error indication reporting the unrecognized KEEP_TEMP_DIAGS value.

### Requirement 5: Removal isolated to the shared diagnostic directory

**User Story:** As a workflow maintainer, I want temporary-diagnostic cleanup
scoped to the diagnostic staging directory only, so that COM output products and
unrelated DATAROOT data are never deleted by the diagnostic jobs.

#### Acceptance Criteria

1. WHEN a Diag_Job removes Temp_Diag_Dir, THE Diag_Job SHALL delete only the
   resolved Temp_Diag_Dir path and all files and subdirectories it contains, and
   SHALL NOT delete any path outside the Temp_Diag_Dir subtree.
2. WHEN a Diag_Job removes Temp_Diag_Dir, THE Diag_Job SHALL preserve the
   diagnostic tarballs (cnvstat, oznstat, radstat, pcpstat) previously written
   to the output COM directory.
3. IF Temp_Diag_Dir cannot be resolved to a defined, non-empty path, THEN THE
   Diag_Job SHALL skip removal of Temp_Diag_Dir and record an indication that
   cleanup was skipped.
4. IF the resolved Temp_Diag_Dir path is equal to, or a parent directory of, the
   DATAROOT or the output COM directory, THEN THE Diag_Job SHALL skip removal of
   Temp_Diag_Dir and record an indication that cleanup was skipped.
5. WHILE removing Temp_Diag_Dir, THE Diag_Job SHALL NOT follow symbolic links
   that resolve to paths outside the Temp_Diag_Dir subtree.
