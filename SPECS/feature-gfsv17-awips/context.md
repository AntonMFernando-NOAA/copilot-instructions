# Branch Context: `feature/gfsv17-awips`

**Repo:** `global-workflow_gfsv17`
**Branch slug:** `feature-gfsv17-awips`
**Base:** `dev/gfs.v17` (merge-base `995ee8468` after the mid-branch
merge in `775bf8ed7`)
**Tip:** `a02f02e29`

## Summary

Align the `gfs_awips_20km_1p0deg` metatask fanout with the parm-file
cadence of `parm/wmo/grib2_awpgfs_20km_${GRID}f${FHR}`, so scheduled
rocoto tasks map cleanly onto actual JJOB runs. Groups the parm-file
hours 3-per-group in each frequency band without crossing the 3h/6h
boundary, delegating the segmented split to the existing
`Tasks.get_job_groups` helper rather than a bespoke chunker.

## Why

The AWIPS 20km job is driven by per-fhr WMO header parm files at:

```
${PARMglobal}/wmo/grib2_awpgfs_20km_${GRID}f${FHR}
```

These files are only shipped every 3 h out to f084 and every 6 h to
f240. The rest of the GFS forecast emits high-frequency output at
`FHOUT_HF_GFS=1` to `FHMAX_HF_GFS=120` then `FHOUT_GFS=3` thereafter.
If AWIPS uses the model cadence, the metatask spins up rocoto tasks
for forecast hours that have no parm file, and either fails hard on
`cpreq` of the missing parm or gets silently skipped by the shell
driver's `fhr%3==0 / fhr%6==0` filter — hiding the design mismatch
behind no-op tasks.

The fix introduces AWIPS-scoped `_AWIPS` overrides that the metatask
reads instead of the model rates, and reuses `Tasks.get_job_groups`
(already used by other tasks in this file) to bucket the parm-file
hours into rocoto groups that never straddle the 3h/6h boundary.

## Commits (only on this branch)

| SHA         | Message                                                                                            |
| ----------- | -------------------------------------------------------------------------------------------------- |
| `8faf44cd5` | feat(gfs/awips): Add FHOUT_HF_GFS_AWIPS override for high-frequency output and update gfs_tasks.py |
| `5939f3d6d` | feat(gfs/awips): Add FHOUT_GFS_AWIPS and FHMAX_HF_GFS_AWIPS overrides                              |
| `775bf8ed7` | Merge branch 'dev/gfs.v17' into feature/gfsv17-awips                                               |
| `0b8b7ee6b` | feat(gfs/awips): Optimize MAX_TASKS and improve metatask naming                                    |
| `d97dcca55` | feat(gfs/awips): Split forecast-hour bands and improve MAX_TASKS sizing                            |
| `30aaeca18` | feat(gfs/awips): Simplify forecast-hour grouping to fixed 3-per-group                              |
| `333fec3f6` | feat(gfs/awips): Simplify forecast-hour group naming format                                        |
| `2e07a7d91` | feat(gfs/awips): Reduce MAX_TASKS and refactor grouping logic                                      |
| `a02f02e29` | feat(gfs/awips): Refactor forecast-hour grouping logic for unified handling                        |

## Files Touched

### `dev/parm/config/gfs/config.awips`

Adds three AWIPS-scoped env-var overrides and drops `MAX_TASKS` from
42 down to 19 (the total group count, now the sum of the two-band
proportional split).

```bash
export MAX_TASKS=19             # total AWIPS metatask groups

export FHOUT_HF_GFS_AWIPS=3     # HF step: parm files at 3 h to f084
export FHMAX_HF_GFS_AWIPS=84    # end of the HF band
export FHOUT_GFS_AWIPS=6        # LF step: parm files at 6 h to f240
```

### `dev/workflow/rocoto/gfs_tasks.py`

`_get_awipsgroups` refactored so both `run` branches share the same
tail. The `if run` block only prepares the fhr list and breakpoints;
grouping, formatting, and the three-`<var>` output all live in the
common code:

```python
if run == 'gdas':
    fhrs = list(range(fhmin, fhmax + fhout, fhout))
    breakpoints = []
elif run == 'gfs':
    # AWIPS-specific overrides with fallback to model values
    fhmax    = min(config['FHMAX_GFS'], 240)
    fhout    = config.get('FHOUT_GFS_AWIPS',    config['FHOUT_GFS'])
    fhmax_hf = min(config.get('FHMAX_HF_GFS_AWIPS', config['FHMAX_HF_GFS']), 240)
    fhout_hf = config.get('FHOUT_HF_GFS_AWIPS', config['FHOUT_HF_GFS'])
    fhrs_hf = list(range(fhmin, fhmax_hf + fhout_hf, fhout_hf))
    fhrs_lf = list(range(fhrs_hf[-1] + fhout, fhmax + fhout, fhout))
    fhrs = fhrs_hf + fhrs_lf
    breakpoints = [fhmax_hf]

ngrps = min(MAX_TASKS, len(fhrs))
groups = [[f'f{h:03d}' for h in d['fhrs']]
          for d in Tasks.get_job_groups(fhrs=fhrs, ngroups=ngrps,
                                        breakpoints=breakpoints)]
```

The custom `_chunk` helper introduced in `30aaeca18` is gone. Both
branches now flow through `Tasks.get_job_groups`, which was already
used by `atmos_products`, `wave`, and other metatask-generating
methods in this file.

## Behavior

With overrides set (default in `config.awips`):

- HF band: `[f000, f003, ..., f084]` → 29 fhrs
- LF band: `[f090, f096, ..., f240]` → 26 fhrs
- Total: 55 fhrs, grouped into 19 rocoto tasks with the HF/LF
  boundary as a `get_job_groups` breakpoint.
- Distribution: 10 HF groups + 9 LF groups. Every group is size 3
  except the tail of each band (size 2). No group straddles f084/f090.
- Task names: `gfs_awips_20km_1p0deg_f000-f006, _f009-f015, ...,
  _f081-f084, _f090-f102, ..., _f234-f240`.

With overrides absent (e.g. a caller sourcing something that isn't
`config.awips`): each `config.get('X_AWIPS', config['X'])` falls back
to the model value, `breakpoints` is still `[fhmax_hf]`, so nothing
downstream breaks; grouping just uses model cadence.

`run == 'gdas'` behavior is preserved bit-for-bit: `breakpoints=[]`
plus no AWIPS overrides means `Tasks.get_job_groups` degenerates into
plain `np.array_split(fhrs, ngroups)`, matching the pre-refactor
inline code.

No other tasks are affected — the overrides are read only inside the
`awips` branch of `_get_awipsgroups`.

## Implementation Walk-through — `_get_awipsgroups`

Prepare-then-group. Both branches do just enough work to hand a flat
`fhrs` list and a `breakpoints` list to `Tasks.get_job_groups`; the
grouping and rocoto-`<var>` formatting are shared.

### Branch prep

- **GDAS:** single-band, `range(fhmin, fhmax + fhout, fhout)`.
  `breakpoints` stays empty.
- **GFS:** two bands built from AWIPS overrides
  (`FHOUT_HF_GFS_AWIPS`, `FHMAX_HF_GFS_AWIPS`, `FHOUT_GFS_AWIPS`,
  each with a fallback to its model counterpart). HF and LF are
  concatenated into one flat `fhrs` list; the HF end (`fhmax_hf`) is
  passed as the breakpoint so no group can straddle it.

The `+ fhout_hf` / `+ fhout` at the top of each `range(...)` is
Python's idiom for making the range inclusive of the end value.

### Shared tail

```python
ngrps = MAX_TASKS if len(fhrs) > MAX_TASKS else len(fhrs)
groups = [[f'f{h:03d}' for h in d['fhrs']]
          for d in Tasks.get_job_groups(fhrs=fhrs, ngroups=ngrps,
                                        breakpoints=breakpoints)]
```

`Tasks.get_job_groups` splits `fhrs` at each breakpoint using
`bisect_right`, then distributes `ngroups` across segments
proportional to segment size (weighting each segment by
`size/current_groups`, incrementing whichever ratio is largest until
all groups are placed). Each segment is finally `np.array_split` into
its allotted group count. For AWIPS with 19 groups and one breakpoint
at f084 this yields 10 HF + 9 LF groups.

The list comprehension unwraps each `{'fhrs': [...], 'seg': N}` dict
into a flat list of `fNNN` strings so the downstream string joins can
stay the same.

### Three rocoto `<var>` strings

```python
grp = ' '.join(f'_{fhr[0]}-{fhr[-1]}' for fhr in groups)
dep = ' '.join(fhr[-1] for fhr in groups)
lst = ' '.join('_'.join(fhr) for fhr in groups)
```

- `grp` — one `_{first}-{last}` token per group; becomes the metatask
  suffix, so every task ends up named
  `gfs_awips_20km_1p0deg_fXXX-fYYY`.
- `dep` — the last hour of each group; used to build upstream data
  dependencies (a group is only ready when its final hour's inputs
  are).
- `lst` — every hour in a group joined with `_`; exported as `FHRLST`
  so the shell driver `dev/job_cards/rocoto/awips_20km_1p0deg.sh` can
  iterate over each fhr in the group and invoke
  `JGFS_ATMOS_AWIPS_20KM_1P0DEG` once per fhr.

Three encodings of the same grouping, one for the metatask name, one
for edges, one for iteration.

## Open / Follow-ups

_None recorded yet. Add here as work progresses._

## Related Specs

_No feature specs created under this branch yet. When one is added it
will live at
`/mdc-mcp-rag/SCRATCH/Anton.Fernando/SPECS/feature-gfsv17-awips/{feature-name}/`._
