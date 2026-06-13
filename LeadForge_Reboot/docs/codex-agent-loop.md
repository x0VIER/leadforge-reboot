# Codex Agent Loop

## What "agent loop" maps to in Codex

The Codex manual does not document `agent loop` as a special product name. The closest documented features are:

- thread automations for recurring wake-ups in the same conversation
- project automations for detached scheduled runs
- explicit subagent workflows for parallel read-heavy work

For this project, the right loop is:

1. Keep this thread alive with a heartbeat automation.
2. Use explicit subagents for research and owner enrichment when the work can be parallelized safely.
3. Use claim files and status files so the loop can see whether sourcing is already running.
4. Keep merges and file writes serialized in the main thread.

## Why this fits LeadForge

- Owner lookups and public-source verification are read-heavy and parallel-friendly.
- Database merges are write-heavy and should stay centralized.
- A recurring heartbeat lets Codex resume this exact sourcing context instead of starting cold each time.

## Operating pattern

1. Heartbeat wakes the thread.
2. Hermes refreshes `agent_shared/status/OPS_SNAPSHOT.json`, checks `CURRENT_STATUS.json`, and inspects `agent_shared/working/` before starting new sourcing.
3. If no active claim exists, the collector opens a claim and writes progress as it works through lanes.
4. Refresh the pending-enrichment queue and prefer resolving those rows before starting a new collector pass.
5. If the latest pass completed with no fresh rows, rotate Florida cities before the next collector run.
6. Research and owner enrichment run in parallel when useful.
7. QA and merge run in sequence.
8. Findings are reported back here and preserved in `LeadForge_Reboot`.
