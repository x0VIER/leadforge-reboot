# LeadForge Seven Loop

This loop is the professional lead-team contract recovered from the old transcript and adapted to the live `LeadForge_Reboot` workspace. It exists so Codex heartbeats do not degrade into dry lane rotation.

## Priority Order

1. Protect the current master. Read `git status`, `agent_shared/status/OPS_SNAPSHOT.json`, `config/source-lanes.json`, latest run manifests, and collector guard before doing work.
2. If any run is `raw_staged`, `reviewed`, or otherwise unfinished, finish that run before opening new sourcing.
3. If pending rows have enough public evidence to resolve, owner-enrich those rows before starting another collector.
4. Run the collector only when `scripts/get-collector-guard-status.ps1` returns `can_start_collector: true`.
5. Stage raw output into a run folder. Never merge raw output.
6. Process each row through the LeadForge Seven roles: market lane check, business discovery, website audit, public owner verification, data ops, scoring, and offer readiness.
7. QA reviewed/final rows with `scripts/qa-review-batch.ps1`.
8. Merge only clean final rows with `scripts/merge-new-leads.ps1`.
9. Rebuild contamination audit, owner backlog, pending queue, and ops snapshot.
10. Commit durable work locally. Push only when a remote and GitHub authentication are available.

## Role Map

- `Sindy`: operations coordinator, archive protector, run prioritizer, and user-facing status owner.
- `Hermes`: collector guard, run controller, lane rotation, and manifest/status owner.
- `Market Intelligence Lead`: chooses state/city/niche lanes from `config/source-lanes.json`.
- `Business Discovery Analyst`: gathers raw public candidates only.
- `Digital Presence Auditor`: checks websites, contact paths, visible gaps, and offer angles.
- `Public Data Verification Specialist`: confirms owners or decision-makers from official sites, state registries, BBB, chambers, or comparable public business sources.
- `Lead Data Operations Specialist`: writes normalized CSV rows, pending/rejected artifacts, and manifest counts.
- `Opportunity Scoring Strategist`: assigns risk and priority from evidence strength and conversion opportunity.
- `Offer Readiness Architect`: maps leads to concrete Elevor offers.
- `Rowan Pike`: QA gate.
- `Quinn Slate`: reviewed-only merge gate.

## New-Only Lead Rules

- Current `data/master_leads.csv` rows are protected.
- Do not overwrite or delete current leads while trying to get new ones.
- Deduplicate by business name, city, state, and website before merge.
- Reject target-state mismatches unless the run explicitly declares a different state.
- Preserve unresolved rows in pending with `public_research_note`.
- Reject low-signal rows that have no website and no phone.
- Reject supplier/manufacturer rows when the campaign target is local service businesses.
- Reject placeholder emails and suspicious mismatches.

## Clean Row Minimum

A row can reach `final/` only when it has:

- `business_name`, `niche`, `city`, `state`
- `website` or `public_phone`
- first-party website check or clear public business evidence
- `owner_name`, `owner_title`, and `owner_source`
- `source_evidence`, `visible_gap`, `offer_angle`
- `risk_score_1_5`, `validation_status`, `priority_tier`, `last_checked`

If owner data is not public and clean, the row stays pending. No guessing.

## Contact Data Boundary

Contact data is context, not an action trigger. Record a public contact path only when it is visibly public and useful for lead context. Do not send outreach, verify deliverability, OCR hidden contact data, scrape private sources, use logged-in sources, or upload contact data to external systems.
