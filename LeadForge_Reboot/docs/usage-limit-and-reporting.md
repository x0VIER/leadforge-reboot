# Usage Limit And Daily Reporting Protocol

LeadForge should protect continuity before speed. If the day is ending, a Codex 5-hour window is almost over, a weekly usage limit is near, or the worker may not have enough room to finish another collector/review cycle, switch into closeout mode.

## Closeout Mode

1. Do not start a new collector.
2. Finish only the active atomic unit of work.
3. If raw rows exist, triage them into `final/`, `tmp/*.pending-enrichment.csv`, or `tmp/*.rejected.csv`.
4. QA and merge only reviewed final rows.
5. Leave unresolved rows pending with `triage_reason`, `lead_type`, `public_research_note`, and `recommended_action`.
6. Run reports in order: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health.
7. Run `scripts/build-daily-ops-report.ps1 -Mode UsageLimitHandoff -RefreshStatus`.
8. Commit local durable work before the worker stops.

## Daily Reports

Start-of-day:

```powershell
& .\LeadForge_Reboot\scripts\build-daily-ops-report.ps1 -Mode StartOfDay -RefreshStatus
```

End-of-day:

```powershell
& .\LeadForge_Reboot\scripts\build-daily-ops-report.ps1 -Mode EndOfDay -RefreshStatus
```

Usage-limit handoff:

```powershell
& .\LeadForge_Reboot\scripts\build-daily-ops-report.ps1 -Mode UsageLimitHandoff -RefreshStatus
```

Reports are written under `agent_shared/reports/<yyyy-mm-dd>/` and indexed in `agent_shared/reports/INDEX.md`.

## Callback Categories

- `missing_owner`: owner or decision-maker not publicly verified.
- `missing_first_party_contact_path`: only third-party or weak contact path found.
- `no_website`: no official website found.
- `phone_only_listing`: phone exists but public identity is weak.
- `status_conflict`: public sources disagree about whether the business is active.
- `domain_mismatch`: website/domain evidence does not clearly match the business.
- `low_signal`: not enough public evidence for this campaign.

No-web or weak-web companies can still be valuable, but they should live in a callback lane instead of being mixed with clean owner-verified leads.
