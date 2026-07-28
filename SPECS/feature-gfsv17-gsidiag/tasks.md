# Implementation Plan: GSI Diagnostic Temp Directory Cleanup

## Overview

This is a small, self-contained shell/workflow change. It adds one sourceable
`ush` helper function (`remove_temp_diags`) that centralizes the retention
decision, safety guard, and removal of the shared `gsidiags` staging directory,
then wires that helper into the two diagnostic jobs and their configs.

The design intentionally omits a Correctness Properties section (the retention
logic is a finite decision table and the removal is a filesystem side effect),
so testing uses example/edge-case unit tests with a `mktemp -d` fixture rather
than property-based tests. Tasks are kept proportional to the change: one helper,
two call sites, two config defaults, one test script.

## Tasks

- [x] 1. Implement the shared cleanup helper
  - [x] 1.1 Create `ush/remove_temp_diags.sh`
    - Define a single `remove_temp_diags <temp_diag_dir>` function following the
      existing `ush` utility pattern (function body, then `declare -xf remove_temp_diags`).
    - Path validation: if `$1` is unset/empty, log a skip message and return 0.
      _Requirements: 5.3_
    - Retention decision implementing the design's decision table:
      `KEEP_TEMP_DIAGS=YES` → retain (any KEEPDATA); `KEEP_TEMP_DIAGS=NO` → remove
      (any KEEPDATA); unset/empty → follow `KEEPDATA` (retain when `YES`, remove
      otherwise); any other value → remove and emit an error indication naming the
      unrecognized value.
      _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.5, 4.6_
    - Safety guard before removal: resolved path basename is `gsidiags` and sits
      under `DATAROOT`; reject empty path, a path equal to or a parent of
      `DATAROOT`/`COMIN_ATMOS_ANALYSIS`/`COMOUT_ATMOS_ANALYSIS`, and a `gsidiags`
      symlink pointing outside `DATAROOT`. On any guard failure, log a skip
      message and return 0 without deleting anything.
      _Requirements: 5.1, 5.4, 5.5_
    - Removal: if the path does not exist, log INFO and return 0; otherwise
      `rm -rf` the resolved path only, and on failure emit a WARNING/error naming
      the path and still return 0.
      _Requirements: 1.1, 1.2, 1.3, 1.5, 2.1, 2.2, 2.3, 2.6_
    - Ensure every step is `set -e`/`set -eu -o pipefail` safe (use `[[ ]]` tests
      and failure-tolerant `rm`); the function always returns 0.
      _Requirements: 1.5, 2.6_

  - [x] 1.2 Write standalone bash unit test script for the helper
    - Self-contained script sourcing `remove_temp_diags.sh`, using `mktemp -d`
      fixtures (populated `gsidiags` dir plus a sibling "COM" dir with tarball
      files).
    - Enumerate the retention decision table:
      `KEEP_TEMP_DIAGS ∈ {YES, NO, unset, "maybe"}` × `KEEPDATA ∈ {YES, NO, unset}`,
      asserting the expected retain/remove outcome; `"maybe"` also asserts an error
      message is emitted.
      _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.5, 4.6_
    - Edge cases: missing `Temp_Diag_Dir` returns success with no error; empty/unset
      path argument skips with a message and returns success.
      _Requirements: 1.3, 2.3, 5.3_
    - Dangerous-path/guard cases: path equal to `DATAROOT`, path that is a parent
      of `DATAROOT`/COM, and a `gsidiags` symlink pointing outside `DATAROOT` are all
      skipped with nothing deleted.
      _Requirements: 5.1, 5.4, 5.5_
    - Side-effect and failure cases: a remove decision deletes the `gsidiags`
      fixture while the sibling COM tarballs remain; a non-removable path
      (read-only parent) emits a warning and returns success.
      _Requirements: 1.1, 1.2, 2.1, 2.2, 5.2, 1.5, 2.6_

- [x] 2. Wire the helper into the diagnostic jobs
  - [x] 2.1 Source the helper in `ush/jjob_shell_setup.sh`
    - Add `source "${USHglobal}/remove_temp_diags.sh"` alongside the other utility
      sources so both diag jobs pick it up without per-job wiring.
    - _Requirements: 1.1, 2.1_

  - [x] 2.2 Add the cleanup call in `dev/jobs/JGLOBAL_ATMOS_ANALYSIS_DIAG`
    - In the cleanup postamble (the "Remove the Temporary working directory" block),
      call `remove_temp_diags "${pCOMIN_ATMOS_ANALYSIS}/gsidiags"` before the
      existing `${DATA}` removal, so it runs only after tarballs are written.
    - _Requirements: 1.1, 1.2, 1.4, 1.5_

  - [x] 2.3 Add the cleanup call in `dev/jobs/JGLOBAL_ENKF_DIAG`
    - Identical insertion with the same argument in the cleanup postamble.
    - _Requirements: 2.1, 2.2, 2.4, 2.5, 2.6_

- [x] 3. Add `KEEP_TEMP_DIAGS` config defaults
  - [x] 3.1 Declare `export KEEP_TEMP_DIAGS="NO"` in `dev/parm/config/gfs/config.analdiag`
    - Default `NO`; comment that it retains the shared `gsidiags` dir for debugging
      and is forced `NO` in operations.
    - _Requirements: 4.3, 4.4_

  - [x] 3.2 Declare `export KEEP_TEMP_DIAGS="NO"` in `dev/parm/config/gfs/config.ediag`
    - Same default and comment as `config.analdiag`.
    - _Requirements: 4.3, 4.4_

- [x] 4. Checkpoint - static analysis and unit test
  - Run `shellcheck` on `ush/remove_temp_diags.sh`, the two modified `JGLOBAL_*_DIAG`
    jobs, `ush/jjob_shell_setup.sh`, and the two configs, and fix findings.
  - Run the helper unit test script and confirm all cases pass. Ask the user if
    questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP.
- Each task references specific acceptance criteria for traceability.
- Property-based testing is intentionally not used: the design has no Correctness
  Properties section (finite decision table + filesystem side effects). Testing is
  example/edge-case unit tests plus static analysis, per the design's Testing Strategy.
- Integration validation in a CI cycle is described in the design but is not a
  coding task and is therefore not listed here.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "3.1", "3.2"] },
    { "id": 1, "tasks": ["1.2", "2.1", "2.2", "2.3"] }
  ]
}
```
