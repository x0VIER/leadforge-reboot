# Lead Pipeline

## Core agents

- `Hermes`: supervisor, run control, and momentum tracking
- `Elena Voss`: public-source research and evidence gathering
- `Marcus Hale`: scoring, validation, and priority tiering
- `Sophia Lang`: offer angle drafting for P0 and P1 leads
- `Lena Moreau`: human-reviewed outreach packaging

## New support agents

- `Quinn Slate`: dedupe and master-database merge control
- `Rowan Pike`: QA checks for schema, missing fields, and source hygiene

## Run flow

1. Create a run folder and manifest.
2. Collect candidate businesses from public websites, directories, or search results.
3. Store raw candidate rows in the run folder.
4. Triage raw rows into rejected, pending enrichment, and reviewed candidates.
5. Review evidence, visible gap, and offer angle.
6. Score and tier the leads.
7. Run QA against the reviewed CSV before merge.
8. Merge approved rows into `data/master_leads.csv`.
9. Log the run and preserve all artifacts.

## Runtime guards

- Only one source collector can be active at a time. It must claim `agent_shared/working/` before it runs.
- Collector progress is written to `agent_shared/status/CURRENT_STATUS.json`.
- Successful runs update `agent_shared/status/LAST_SUCCESS.json`.
- Pending enrichment rows are consolidated into `agent_shared/status/PENDING_ENRICHMENT_QUEUE.json`.
- Pending queue entries should carry age and recommended-action context so wake-ups can tell the difference between fresh owner research and stale unresolved rows.
- Overall operating state is consolidated into `agent_shared/status/OPS_SNAPSHOT.json`.
- `scripts/get-collector-guard-status.ps1` is the explicit preflight check for overlap; it reports active claims, stale claims, and whether the collector is actually clear to start.
- `scripts/build-owner-enrichment-backlog.ps1` builds a live owner-gap queue from `data/master_leads.csv` so enrichment work can be prioritized by state, niche, city, and priority tier.
- `scripts/build-master-contamination-audit.ps1` scans the live master for suspicious duplicate-website and cloned-row patterns so low-trust rows can be reviewed before more enrichment work lands on them.
- `scripts/quarantine-suspicious-leads.ps1` exports suspicious master rows and lead IDs into `data/quarantine/` so `scripts/rebuild-master.ps1` can rebuild a cleaner live master without deleting audit evidence.
- Fresh source batches write to temp files first and then move into `data/output/` and `data/run-logs/`.
- `config/source-lanes.json` is the state selector: update `targetState`, `targetStateName`, `lanePool`, and `lanes` together when moving the factory to another state.
- If a completed pass returns no fresh rows, rotate to the next configured city window before the next sourcing run.
- When triaging a partial run, exclude already reviewed rows so pending-enrichment artifacts represent only unresolved work.
- `data/master_leads.csv` should be rebuilt from archive plus reviewed batches if a raw merge ever contaminates master.
- When a just-written status report matters, rebuild it and re-read it sequentially instead of relying on parallel reads from immediately adjacent writes.

## Safety boundaries

- Public business data only
- No automated outreach
- No paid API assumptions
- Human review before anything leaves the system
