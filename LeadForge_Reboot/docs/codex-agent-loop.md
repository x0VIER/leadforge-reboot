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
2. Hermes reads `config/source-lanes.json` for the current `targetState`, refreshes `agent_shared/status/PENDING_ENRICHMENT_QUEUE.json`, `agent_shared/status/OWNER_ENRICHMENT_BACKLOG_<STATE>.json`, `agent_shared/status/MASTER_CONTAMINATION_AUDIT_<STATE>.json`, and `agent_shared/status/OPS_SNAPSHOT.json`, then runs `scripts/get-collector-guard-status.ps1` before starting new sourcing.
3. If no active claim exists, the collector opens a claim and writes progress as it works through lanes.
4. Refresh the pending-enrichment queue and prefer resolving those rows before starting a new collector pass.
5. If the latest pass completed with no fresh rows, rotate the configured state/city window before the next collector run.
6. Research and owner enrichment run in parallel when useful.
7. QA and merge run in sequence.
8. Findings are reported back here and preserved in `LeadForge_Reboot`.

## Loop guardrails

- Prefer heartbeat wake-ups for this thread because the next run depends on current queue, status, and run-manifest context.
- The live Codex heartbeat should follow `ops/leadforge-heartbeat-automation.toml`; keep that file updated when the app automation is changed.
- Read one consolidated state file first, but do not trust it blindly for overlap; verify claims with `scripts/get-collector-guard-status.ps1`.
- If the contamination audit shows cloned or suspicious rows, prefer cleaning that queue before treating those leads as enrichment targets.
- Keep file writes serialized in the main thread so pending queues, manifests, and master merges do not race each other.
