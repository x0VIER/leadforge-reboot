# AZ/IL Pending Schema Alignment Fix

Timestamp: 2026-06-14T12:16:00-04:00

## Blockage

The AZ/IL batch 029 pending enrichment artifact imported with several fields shifted for no-contact rows. The affected rows were:

- 1st Class Foam Roofing and Coating, LLC
- All Vee's Plumbing Services
- Hays Cooling Heating & Plumbing
- Arizona Electric
- The Sunny Plumber Tucson

Those rows were missing one empty CSV field before `source_type`, which moved `source_type`, `source_query`, `source_evidence`, `triage_reason`, `pending_state`, `public_research_note`, and `recommended_action` into the wrong columns.

## Fix

Added the missing empty field separator for the affected no-contact rows in:

`LeadForge_Reboot/data/runs/2026-06-14-160553-2026-06-14-usa-home-services-sprint/tmp/2026-06-14-az-il-batch-029.pending-enrichment.csv`

Verified the repaired CSV with `Import-Csv` so every pending row now keeps:

- blank owner fields when owner evidence is missing
- `source_type=overpass_public_business_record`
- correct `triage_reason`
- correct `pending_state`
- correct `public_research_note`
- correct `recommended_action`

## Safety

No master lead rows were changed. No raw collector output was merged. No archive files were deleted. This was a generated pending metadata repair only.

## Certification

Rebuilt the contamination audit, owner backlog, pending queue, ops snapshot, health report, and factory metrics after the fix. Health remains yellow only because of pre-existing `recent_failure_noise`; the collector guard remains clear for the next loop.
