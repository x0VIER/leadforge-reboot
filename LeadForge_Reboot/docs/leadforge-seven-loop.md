# LeadForge Seven Loop

This loop is the professional lead-team contract recovered from the old transcript and adapted to the live `LeadForge_Reboot` workspace. It exists so Codex heartbeats do not degrade into dry lane rotation.

## Priority Order

1. Protect the current master. Read `git status`, `agent_shared/status/OPS_SNAPSHOT.json`, `config/source-lanes.json`, latest run manifests, and collector guard before doing work.
2. If any run is `raw_staged`, `reviewed`, or otherwise unfinished, finish that run before opening new sourcing.
3. If pending rows have enough public evidence to resolve, owner-enrich those rows before starting another collector.
4. Run the collector only through `scripts/run-collector-guarded.ps1` and only when `scripts/get-collector-guard-status.ps1` returns `can_start_collector: true`.
5. Stage raw output into a run folder. Never merge raw output.
6. Process each row through the LeadForge Seven roles: market lane check, business discovery, website audit, public owner verification, data ops, scoring, and offer readiness.
7. QA reviewed/final rows with `scripts/qa-review-batch.ps1`.
8. Merge only clean final rows with `scripts/merge-new-leads.ps1`.
9. Rebuild contamination audit, owner backlog, pending queue, and ops snapshot.
10. Commit durable work locally. Push only when a remote and GitHub authentication are available.

## Role Map

- `Sindy`: operations coordinator, archive protector, run prioritizer, and user-facing status owner.
- `Hermes`: collector guard, run controller, lane rotation, and manifest/status owner.
- `Market Intelligence Lead`: chooses USA-wide city/state/niche lanes from `config/source-lanes.json`.
- `Business Discovery Analyst`: gathers raw public candidates only.
- `Digital Presence Auditor`: checks websites, contact paths, visible gaps, and offer angles.
- `Public Data Verification Specialist`: confirms owners or decision-makers from official sites, state registries, BBB, chambers, or comparable public business sources.
- `Lead Data Operations Specialist`: writes normalized CSV rows, pending/rejected artifacts, and manifest counts.
- `Opportunity Scoring Strategist`: assigns risk and priority from evidence strength and conversion opportunity.
- `Offer Readiness Architect`: maps leads to concrete Elevor offers.
- `Rowan Pike`: QA gate.
- `Quinn Slate`: reviewed-only merge gate.
- `Iris`: health auditor for collector guard, ops health, pending queue, duplicate checks, and status checks.
- `Knox`: blockage analyst for command failures, timeouts, repeated stale work, and documented fixes.
- `Vale`: contamination auditor for state mismatches, duplicate keys, suspicious domains, placeholder data, and low-signal rows.
- `Echo`: callback and memory auditor for manifests, logs, notes, file naming, and commit hygiene.
- `Cato`: automation auditor for keeping the Codex automation prompt clean, current, and non-duplicated.

## Clarify, Verify, Apply, Adapt, Certify

- Clarify current state from `OPS_SNAPSHOT.json`, `source-lanes.json`, run manifests, collector guard, and `git status`.
- Verify candidate facts from public sources before a row reaches `final/`.
- Apply the smallest safe script, config, or documentation fix when a blocker is root-caused.
- Adapt lanes, timing, worker roles, or checks when the same problem repeats.
- Certify with QA, ops health, contamination audit, owner backlog, pending report, ops snapshot, and a local commit.

If the loop repeats the same failure twice, stop retrying blindly. Log the cause, fix or rotate the blocked lane, and leave a callback note so the next worker knows why the decision was made.

Collector work must be bounded. Do not call `node scripts/run-source-batch.mjs` directly from a long Codex shell command. Use `run-collector-guarded.ps1` so a timeout moves the claim to `failed/`, updates `CURRENT_STATUS.json`, logs the blockage, and prevents ghost overlap.

## New-Only Lead Rules

- Current `data/master_leads.csv` rows are protected.
- Do not overwrite or delete current leads while trying to get new ones.
- Deduplicate by business name, city, state, and website before merge.
- Reject location mismatches unless the run lane explicitly declares that city/state pair.
- Preserve unresolved rows in pending with `public_research_note`.
- Reject low-signal rows that have no website and no phone.
- Reject supplier/manufacturer rows when the campaign target is local service businesses.
- Reject placeholder emails and suspicious mismatches.

## Rejected Row Notes

Rejected leads must be useful later, not throwaway rows. Every rejected CSV should include `triage_reason`, `public_research_note`, `recommended_action`, and `lead_type`.

When public evidence is available, rejected rows should also preserve `business_address`, `registration_source`, `registration_status`, `registration_notes`, `owner_name`, `owner_title`, and `owner_source`. The note should say what type of lead it was, which public checks were done, and why the lead should not be contacted for this campaign.

Do not invent owner names, owner phone numbers, addresses, or registration details. Owner phone data should only be recorded when it is clearly public business contact data, not private personal data.

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
