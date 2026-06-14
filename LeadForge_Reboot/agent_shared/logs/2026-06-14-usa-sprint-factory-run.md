# 2026-06-14 USA sprint factory run

## Summary

- Replaced the 30-minute `leadforge-factory-loop` automation with `leadforge-usa-sprint-factory-loop`, a 5-minute heartbeat sprint for 24 runs.
- Switched `config/source-lanes.json` from a single-state Georgia window to a USA-wide lane pool with Atlanta GA, Charlotte NC, and Nashville TN active first.
- Added national audit compatibility and `scripts/build-factory-metrics.ps1` so the loop can measure throughput, pending load, state coverage, and rejection pressure.
- Guarded collector completed in 161 seconds under the 240-second cap.
- Collector produced 12 raw USA candidates.
- Reviewed and merged 8 owner-verified leads.
- Kept 3 rows pending for stronger current-owner or identity evidence.
- Rejected 1 suspicious keyword-template electrician row with reason notes.

## Blockers and fixes

- Blocker: The system was still state-shaped, so a USA-wide sprint would have made reports look at only one target state.
  Fix: Made audits/backlog/snapshot accept `USA` as national scope and updated lane rotation to support city/state lane objects.
- Blocker: Raw collector IDs can repeat across runs.
  Fix: `merge-new-leads.ps1` now clears raw `LFR-*` IDs on incoming rows so the merge assigns durable master IDs.
- Blocker: One pending-report command had a quote typo during post-merge reporting.
  Fix: Rebuilt pending, snapshot, health, and metrics sequentially so `OPS_SNAPSHOT` reflects the real pending count.
- Blocker: Overpass timed out on Atlanta electrician and Nashville plumbing lanes.
  Fix: Guarded collector contained the run safely; output was still usable. Next loop can rotate or continue without overlap.

## Current status

- Master rows: 351.
- New merged rows this run: 8.
- Pending queue rows: 19.
- Health: yellow due recent failure-noise count only.
- Collector guard: clear to start.
