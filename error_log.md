# Error Log — Anton Fernando
# Updated every time a debug session is run with Copilot.
# Reference in prompts: `#file:/home/Anton.Fernando/copilot-instructions/error_log.md`
#
# Entry format:
#   ## YYYY-MM-DD — <script or component>
#   **Error:** exact message or symptom
#   **Root cause:** what actually caused it
#   **Fix:** what was changed
#   **Files:** list of files involved
#   **Notes:** patterns to watch for, related gotchas

---

## 2026-05-04 — monitor_expdirs.sh (line 233)

**Error:** `/home/Anton.Fernando/utils/monitor_expdirs.sh: line 233: built: unbound variable`

**Root cause:** Variable `built` is declared and populated only inside the
`if [[ -f "${rich_info}" ]]` branch (line 176). For experiments that only have the
legacy `git_info.log` path, `built` is never initialised. The check at line 233
(`if [[ -n "${built}" ]]`) then hits an unbound variable under any strict-mode or
nounset-equivalent behaviour.

**Fix:** Initialise `built`, `build_current`, and `build_time` before the `if/elif`
block that reads metadata (not inside it), so they are always defined.

**Files:** `/home/Anton.Fernando/utils/monitor_expdirs.sh`

**Notes:** Classic shell trap — local variable declarations inside a conditional branch
are invisible to code that runs after the branch exits. Always initialise defensive
variables at function/script scope before any conditional reads them.
