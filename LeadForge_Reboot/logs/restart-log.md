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
- Added Florida lane rotation so zero-yield collector passes advance to fresh city windows automatically.
- Fixed state leakage in Overpass city queries so ambiguous city names stay anchored to the requested state.
- Tightened collector quality gates to reject low-signal rows and ignore third-party social links as first-party contact paths.
- Merged an owner-enriched Miami roofing lead into master while preserving weaker Miami plumbing rows for later review.
- Added raw-batch triage so each run can preserve rejected and pending-enrichment rows with explicit reasons.
- Forced a fresh Florida lane rotation after the Miami batch, verified the Cape Coral/Tallahassee window as zero-yield, and reset the next live window to Jacksonville/Tampa/Orlando/St. Petersburg.
- Added a pending-enrichment queue report so unresolved rows across runs can be prioritized before new sourcing.
