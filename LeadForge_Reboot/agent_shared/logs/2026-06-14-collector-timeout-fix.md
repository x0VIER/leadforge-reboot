# 2026-06-14 Collector Timeout Fix

## Problem

The collector was launched directly with `node scripts/run-source-batch.mjs` from Codex. The shell command timed out while the child Node process continued running. That left an active collector claim and `CURRENT_STATUS.json` in `running`, which could block future work or cause overlap if ignored.

## Cause

The collector scans multiple city/niche lanes with network calls and configured pauses. Running it directly inside a bounded Codex shell command can exceed the tool budget before the collector finishes its own cleanup.

## Fix

- Stopped only the active collector process for `run-source-batch.mjs`.
- Moved its claim from `agent_shared/working` to `agent_shared/failed` as `timeout_killed`.
- Updated `CURRENT_STATUS.json` to `timeout_killed` with an error note.
- Added `scripts/run-collector-guarded.ps1` to launch collectors with a max runtime, poll safely, and clean up claims/status on timeout.
- Patched the guarded runner to quote the Node script path and capture stdout/stderr logs because the workspace path contains a space.
- Tuned `config/source-lanes.json` to smaller faster batches: 2 active cities, 2 per-niche limit, 8 max output rows, shorter pauses.
- Documented that direct long-running collector calls are not allowed from Codex turns.

## Safety

No master leads were edited by the timed-out collector. The interrupted run had written 0 rows and no output CSV. The existing remote remains configured so GitHub push remains available, but the computer/local git history is the primary save point.
