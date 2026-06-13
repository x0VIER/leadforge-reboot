# Codex Agent Loop

## What "agent loop" maps to in Codex

The Codex manual does not document `agent loop` as a special product name. The closest documented features are:

- thread automations for recurring wake-ups in the same conversation
- project automations for detached scheduled runs
- explicit subagent workflows for parallel read-heavy work

For this project, the right loop is:

1. Keep this thread alive with a heartbeat automation.
2. Use explicit subagents for research and owner enrichment when the work can be parallelized safely.
3. Keep merges and file writes serialized in the main thread.

## Why this fits LeadForge

- Owner lookups and public-source verification are read-heavy and parallel-friendly.
- Database merges are write-heavy and should stay centralized.
- A recurring heartbeat lets Codex resume this exact sourcing context instead of starting cold each time.

## Operating pattern

1. Heartbeat wakes the thread.
2. Hermes checks for today's active run.
3. Research and owner enrichment run in parallel when useful.
4. QA and merge run in sequence.
5. Findings are reported back here and preserved in `LeadForge_Reboot`.
