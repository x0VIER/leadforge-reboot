# Efficiency And Memory Index

LeadForge should not keep rediscovering the same businesses, owners, dry lanes, or status facts. Treat the workspace like an idempotent data pipeline:

- raw collector output is the landing layer,
- reviewed/final CSVs are the clean layer,
- `data/master_leads.csv` is the gold layer,
- `agent_shared/status/LEAD_MEMORY_INDEX.*` is the callback/search index.

## Lead Memory Index

Before researching or merging a candidate, build or read the memory index:

```powershell
& .\LeadForge_Reboot\scripts\build-lead-memory-index.ps1
```

The index groups every master, raw, reviewed, final, pending, and rejected row by a normalized key:

- website host when a website exists,
- otherwise business name + city + state.

Use it to avoid repeats:

- If `should_skip_collection` is true, do not collect that candidate again unless the lane has new evidence.
- If `should_skip_research` is true, do not re-enrich the same master row unless a specific field is missing or stale.
- If a row is pending or rejected, improve the existing artifact instead of creating a duplicate row.

## Repetition Killers

- Dry lane: after a full active window produces no fresh rows, rotate lanes instead of retrying.
- Same business: search `LEAD_MEMORY_INDEX.csv` before owner research.
- Same website: use the website host as the primary dedupe key.
- Same public source: reuse `source_evidence` and `owner_source` from the existing artifact unless the data is stale or conflicting.
- Same reports: use the report scripts instead of manually rebuilding the same summary in chat.
- Same count mismatch: rebuild pending, metrics, snapshot, and health sequentially, not in parallel.

## Research Notes Applied

The system follows common data-pipeline advice: idempotent jobs, cache keys, checkpoints, and dedupe before expensive work. For public research, use OSINT-style evidence discipline: define the objective, collect public sources, corroborate claims, document source confidence, and avoid repeating searches when a cached source already answers the question.
