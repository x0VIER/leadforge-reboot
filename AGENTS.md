# LeadForge Workspace Guide

This workspace is a Git repo rooted at `C:\Users\loc9o\Desktop\AGR 1226`. Treat the recovered top-level files as archive material and do new work inside `LeadForge_Reboot`.

## Safety rules

- Do not delete or overwrite the recovered root files.
- Use public business information only.
- Keep outreach human-reviewed.
- Use parallel subagents for read-heavy research only; keep merges and file writes serialized.

## Working directories

- `LeadForge_Reboot/data/archive/` stores frozen recovery snapshots.
- `LeadForge_Reboot/data/runs/` stores dated run folders created by `new-run.ps1`.
- `LeadForge_Reboot/data/output/` stores fresh source batches from `run-source-batch.mjs`.
- `LeadForge_Reboot/data/run-logs/` stores JSON logs from sourcing runs.
- `LeadForge_Reboot/agent_shared/working/` stores active collector claims.
- `LeadForge_Reboot/agent_shared/status/` stores current loop status and last-success markers.
- `LeadForge_Reboot/agent_shared/shared_activity_log.md` is the append-only coordination log.
- `LeadForge_Reboot/data/master_leads.csv` is the live merged master list.

## Grounded commands

- Baseline analysis:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\analyze-leads.ps1`
- Create a new run folder:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\new-run.ps1 -RunName "florida-owner-batch"`
- Merge reviewed leads into the live master:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\merge-new-leads.ps1 -NewCsv .\LeadForge_Reboot\data\runs\<run>\reviewed\<file>.csv`
- Run the Node sourcing lane from the reboot folder:
  `node .\scripts\run-source-batch.mjs`
- Rebuild master from archive plus reviewed batches only:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\rebuild-master.ps1`
- Rotate Florida sourcing cities after a zero-yield pass:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\rotate-source-lanes.ps1`
- Split a raw run into pending-enrichment and rejected artifacts before review:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\triage-raw-batch.ps1 -InputCsv .\LeadForge_Reboot\data\runs\<run>\raw\<file>.csv`
  If a reviewed CSV already exists for the run, pass `-ReviewedCsv` so merged or reviewed rows are excluded from the pending list.
- Build the live pending-enrichment queue before a new sourcing sprint:
  `powershell -ExecutionPolicy Bypass -File .\LeadForge_Reboot\scripts\build-pending-enrichment-report.ps1`

## Source-lane facts

- `LeadForge_Reboot/scripts/run-source-batch.mjs` reads `LeadForge_Reboot/config/source-lanes.json`.
- It reads historical dedupe context from the recovered root `Recovered_Leads_Database.csv` and prior CSVs in `LeadForge_Reboot/data/output/`.
- It writes fresh lead CSVs to `LeadForge_Reboot/data/output/`, JSON run logs to `LeadForge_Reboot/data/run-logs/`, and claim/status files under `LeadForge_Reboot/agent_shared/`.
- It stages temp files before moving them into place, so partial runs do not clobber final outputs.
- Current configured lanes target Florida and New York home-service niches through public Overpass data plus public website checks.

## Agent loop guidance

- If asked to continue the loop, prefer the current thread plus a Codex heartbeat automation so context is preserved.
- If parallel work helps, explicitly ask for subagents or spawn them for research, owner enrichment, and QA summaries.
- Keep `LeadForge_Reboot/logs/restart-log.md`, `LeadForge_Reboot/agent_shared/status/`, and run artifacts updated when meaningful work is completed.
