# 2026-06-14 Midwest Timeout Tuning

## What Happened
- The Midwest collector started on Columbus, Cincinnati, and Pittsburgh after the Texas lane rotation.
- `run-collector-guarded.ps1` stopped the run at the 240 second cap to prevent ghost overlap.
- `CURRENT_STATUS.json` showed 8 rows discovered, but `run-source-batch.mjs` had not reached its final CSV/log flush step, so no raw run folder was safely staged.

## Root Cause
- The active window runs up to 12 city/niche lane queries.
- With `overpassAttempts: 2`, `overpassTimeoutMs: 12000`, and multi-second pauses, a few 429/timeout lanes can push a run beyond the guard.
- The collector currently writes final artifacts at completion, so timeout-killed runs can lose otherwise useful discovered rows.

## Fix Applied
- Reduced public-source retry pressure in `config/source-lanes.json`:
  - `overpassAttempts`: 2 -> 1
  - `overpassTimeoutMs`: 12000 -> 9000
  - `overpassPauseMs`: 4500 -> 2500
  - `lanePauseMs`: 1200 -> 700
- This favors fast lane rotation and later retry over waiting on slow/rate-limited Overpass responses.

## Safety
- No master rows were changed.
- No raw rows were merged from the timeout run.
- Collector guard is clear after cleanup, so the next run can proceed safely.

## Follow-Up Improvement
- Add incremental checkpoint staging to `run-source-batch.mjs` so timeout-killed runs can preserve discovered rows without raw-merging.
