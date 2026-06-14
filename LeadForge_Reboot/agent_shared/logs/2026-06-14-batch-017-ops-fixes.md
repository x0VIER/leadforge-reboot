# 2026-06-14 Batch 017 Ops Fixes

## What Was Done

- Merged coastal Florida batch 017 after owner/decision-maker enrichment and QA.
- Added 3 new reviewed leads to `data/master_leads.csv`; no raw rows were merged.
- Updated the LeadForge Seven Loop with auditor roles and the clarify, verify, apply, adapt, certify operating rule.
- Added `scripts/build-ops-health-report.ps1` to catch active blockers before new collector work.
- Updated `scripts/triage-raw-batch.ps1` so future pending/rejected rows include `lead_type`, `public_research_note`, `recommended_action`, and registration placeholders.
- Updated the Codex app automation `leadforge-florida-loop` with a clean 30-minute heartbeat prompt.

## Blockages Found And Fixed

- Blockage: rejected rows could be too thin for future human review.
  Fix: triage now adds lead type, public research note, recommended action, and registration placeholder columns for pending/rejected rows.
  Safety: master merge path was not changed; only unresolved/rejected artifact context was expanded.

- Blockage: the first health report falsely said the collector was blocked.
  Cause: `get-collector-guard-status.ps1` emits JSON, but the new health script initially treated that JSON as a plain PowerShell object.
  Fix: health script now parses guard output through `ConvertFrom-Json`.
  Safety: rerun health showed `collector_can_start: true`, no active claims, and no active unfinished runs.

- Blockage: legacy `public-reboot-batch-001` stayed at `created` and looked unfinished forever.
  Cause: old bootstrap manifest had a reviewed CSV but no active raw/final workflow trail.
  Fix: preserved the folder and marked the manifest `legacy_reviewed_superseded`.
  Safety: all 6 reviewed legacy rows already had matching master rows, so no data was deleted or merged again.

- Blockage: an ad hoc PowerShell duplicate-check one-liner failed from an unsafe loop-to-pipe pattern.
  Fix: use array-wrapped loop output before piping to JSON or formatting.
  Safety: no files were changed by the failed command.

## Certification

- QA batch check: no flags.
- Triage after reviewed exclusions: 3 reviewed, 0 pending, 0 rejected.
- Merge result: master 339 to 342, added 3, enriched 0 existing.
- Contamination audit: suspicious row count 0, duplicate master key count 0 in health report.
- Pending queue: 15 documented rows remain blocked on stronger public evidence.
- Health report: green; collector can start when the next loop runs.
