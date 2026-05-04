# GitHub Copilot — Personal Persistent Instructions
# Anton Fernando | NOAA/NCEP Global Workflow Developer
# Loaded automatically into every Copilot Chat session via VS Code user settings.

## Identity and Domain Context

I work on NOAA's Global Workflow (global-workflow), a production weather forecasting framework
supporting GFS, GEFS, and SFS. My primary HPC platforms are:
- **Hera** (NOAA RDHPCS, SLURM, /scratch3)
- **WCOSS2** (NOAA operational, PBS/ecFlow)
- **Hercules** (MSU, SLURM)

Primary repo: https://github.com/NOAA-EMC/global-workflow
My fork: https://github.com/AntonMFernando-NOAA/global-workflow
Working directory base: /scratch3/NCEPDEV/global/Anton.Fernando/

## Code Style — Shell (Bash)

- Follow the existing style in any file being edited; never introduce a new style.
- Use `"${variable}"` (double-quoted braces) for all variable expansions.
- Use 2-space indentation for shell scripts unless the file already uses a different width.
- Use `[[ ]]` for conditionals, `(( ))` for arithmetic.
- No trailing whitespace; no blank lines added at end of file unless already present.
- Prefer `$()` over backticks.
- Run `shellcheck` and `shfmt` mentally before suggesting shell code.
- Never use `set -u` without also initialising all local variables that could be unset.

## Code Style — Python

- Follow PEP 8 / pycodestyle.
- Use numpy-style docstrings for all public functions and classes.
- 4-space indentation.
- Type hints only if the surrounding code already uses them.

## Architecture Patterns I Follow

- **Sentinel-driven readiness**: data files are copied first, sentinel log last. Never
  gate downstream tasks on file size heuristics — always use a sentinel log file.
- **Factory pattern** for workflow applications (GFS, GEFS, SFS, GCAFS).
- **ABC base classes** for Rocoto XML generators; always implement all abstract methods.
- **Forecast manager / FSM**: MPMD SLURM execution; one rank per active model component
  (atm, ww3, ocn, ice). Product tables drive the manager; sentinel logs drive ecFlow/Rocoto events.

## Git Conventions

- Never commit submodule pointer changes unless explicitly requested.
- Keep commits focused — one logical change per commit.
- Commit message format: `<scope>: <short description>` (lowercase, imperative, no period).
- Never force-push to shared branches.
- Never change the branch I started on without asking first.

## Response Preferences

- Be brief and direct. Skip preambles, conclusions, and restatements of the question.
- Default to implementing changes rather than only explaining them.
- No emojis.
- When editing files, always read the current contents before editing.
- After edits, confirm briefly what changed — do not re-explain the whole file.
- Use markdown links for file references, never bare backtick filenames.

## Environment / Paths I Use Frequently

- Experiment run directory: /scratch3/NCEPDEV/global/Anton.Fernando/RUNTESTS/
- Utilities: /home/Anton.Fernando/utils/
- Global Workflow source: /scratch3/NCEPDEV/global/Anton.Fernando/global-workflow/
- Cron logs: /home/Anton.Fernando/logs/
- Copilot instructions repo: /home/Anton.Fernando/copilot-instructions/ (https://github.com/AntonMFernando-NOAA/copilot-instructions)
- Work log (full history): /home/Anton.Fernando/copilot-instructions/work_log.md
- Error log (debug history): /home/Anton.Fernando/copilot-instructions/error_log.md

## Recent Work (keep to last 5 entries; full history in work_log.md)

- 2026-05-04 | feature/gfsv17-forecast_manager | Fixed MOM6 sentinel: replaced hardcoded
  TARGET_SIZE file-size check with ocn.log.f*.txt sentinel poll in exglobal_fsm.sh.
  Updated archive manifest (ocean_6hravg.yaml.j2) to include sentinel files.
- 2026-05-04 | feature/gfsv17-forecast_manager | Renamed forecast_mgr → forecast_manager
  in exglobal_forecast_manager.sh. Simplified MANAGER_INIT_TIMEOUT assignment.
- 2026-05-04 | utils | Created copilot-instructions.md and wired into VS Code user
  settings for persistent context. Created work_log.md for full history.

## Debug / Error History

An error log is maintained at /home/Anton.Fernando/copilot-instructions/error_log.md.
It is updated after every debug session. Reference it in prompts when debugging:
  `#file:/home/Anton.Fernando/copilot-instructions/error_log.md`
Known recurring patterns are recorded there — check it before suggesting a fix.

## Instructions for Copilot Use

- Always use mcp-tools for context when available.
- Always ask before pushing to any remote.
- When a debug session resolves an error, append an entry to error_log.md.
- When finishing a task, append an entry to work_log.md and rotate Recent Work (keep ≤5).
