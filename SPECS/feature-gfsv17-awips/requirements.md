# Requirements — `feature/gfsv17-awips`

## Introduction

Configure the GFS `awips_20km_1p0deg` metatask so it fans out at
forecast hours that match the shipped AWIPS WMO parm files
(`${PARMglobal}/wmo/grib2_awpgfs_20km_${GRID}f${FHR}`), independent of
the model's higher-frequency output cadence used by the rest of the
atmos products pipeline.

## Requirements

### Requirement 1: AWIPS-specific forecast-hour cadence

**User Story:** As a workflow operator, I want the AWIPS metatask to
launch only at forecast hours that have matching parm files, so that
no AWIPS job fails on a missing header parm.

#### Acceptance Criteria

1. WHERE `run == 'gfs'` AND the component is `awips`, THE workflow
   SHALL read `FHOUT_HF_GFS_AWIPS`, `FHMAX_HF_GFS_AWIPS`, and
   `FHOUT_GFS_AWIPS` from the merged config.
2. IF any of the three overrides is unset, THEN the workflow SHALL
   fall back to the corresponding model value (`FHOUT_HF_GFS`,
   `FHMAX_HF_GFS`, `FHOUT_GFS`).
3. THE `config.awips` file SHALL export the defaults
   `FHOUT_HF_GFS_AWIPS=3`, `FHMAX_HF_GFS_AWIPS=84`,
   `FHOUT_GFS_AWIPS=6`.
4. WHILE both the high-frequency window and the low-frequency window
   are populated, THE metatask fan-out SHALL contain exactly the hours
   `[FHMIN, FHMAX_HF_GFS_AWIPS]` stepped by `FHOUT_HF_GFS_AWIPS` and
   `[FHMAX_HF_GFS_AWIPS + FHOUT_GFS_AWIPS, min(FHMAX_GFS, 240)]`
   stepped by `FHOUT_GFS_AWIPS`.
5. THE existing `fhmax > 240` clamp SHALL be preserved.

### Requirement 2: No side effects on other components

**User Story:** As a workflow operator, I want the override to apply
only to the AWIPS component, so that atmos products, wave, ocean, and
other pipelines keep their previous cadence.

#### Acceptance Criteria

1. WHEN `_get_forecast_hours` is called for any component other than
   `awips`, THE workflow SHALL NOT read the `_AWIPS` overrides.
2. WHEN `_get_forecast_hours` is called with `run != 'gfs'`, THE
   workflow SHALL NOT read the `_AWIPS` overrides.

## Work Log

_Appended on demand — ask Kiro to "log the work" and a summary of
recent chat activity will be inserted here. Do not edit prior
entries — add new entries at the bottom._

<!-- WORKLOG:BEGIN -->

### 2026-07-06T19:50Z

- Established per-branch spec layout: `.kiro/specs/{branch-slug}/` (slashes in branch names replaced by dashes).
- Iterated on storage location: external `SPECS/` root → moved back inside workspace so the Kiro SPECS panel indexes it; excluded `.kiro/` via `.git/info/exclude` to keep the workflow repo clean.
- Confirmed panel indexes only dirs containing `requirements.md`, `design.md`, `tasks.md`, or `bugfix.md`; adopted flat layout with `context.md` as a companion file alongside standard spec files.
- Seeded `requirements.md` with two EARS requirements derived from the branch's committed work (AWIPS-specific `FHOUT/FHMAX` overrides and no-side-effect scope).
- Created steering rule `.kiro/steering/spec-branch-layout.md` codifying the layout.
- Registered `agentStop` hook `branch-worklog-2h` to append a chat summary here every ~2 hours.
- Files touched: `.kiro/steering/spec-branch-layout.md`, `.kiro/specs/feature-gfsv17-awips/context.md`, `.kiro/specs/feature-gfsv17-awips/requirements.md`, `.git/info/exclude`.
- Open: no additional AWIPS scope requested yet beyond the two committed overrides.

<!-- WORKLOG:END -->
