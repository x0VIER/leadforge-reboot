# Restart Log

## 2026-06-13

- Created `LeadForge_Reboot` as the new live workspace.
- Archived the recovered lead database snapshot into `data/archive/`.
- Added local scripts for analysis, run creation, and lead merging.
- Rebuilt the active agent roster with added merge and QA roles.
- Added project-scoped Codex agents in `.codex/agents/` and a root `AGENTS.md`.
- Upgraded the live master schema to preserve owner metadata.
- Merged a first Florida owner-enriched batch into `data/master_leads.csv`.
- Created the recurring heartbeat automation `leadforge-florida-loop`.
- Tightened the Node sourcing script to filter fake email captures from asset filenames.
- Added claim-based collector locking, status-first loop files, and temp-file output staging.
- Added deterministic reviewed-only master rebuild logging to recover from raw-output contamination.
