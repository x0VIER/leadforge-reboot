# 2026-06-15 Savannah GrassMaster merge

Completed the guarded GA/NC source pass from `2026-06-15T11-03-06-330Z-usa-home-services-sprint-fresh-leads.csv`.

- Collector summary: Savannah landscaping produced 1 fresh candidate; Atlanta landscaping produced no accepted rows; Charlotte landscaping and Atlanta pest-control hit HTTP 429; Savannah pest-control hit HTTP 504.
- QA path: `triage-raw-batch.ps1` held the candidate for owner enrichment, manual public review promoted it, and `qa-review-batch.ps1` returned clean before merge.
- Merge result: `merge-new-leads.ps1` moved master from 512 to 513 rows with 1 added row and 0 enriched existing rows.
- Added lead: `LF-0198` GrassMaster Lawn Care, Inc. in Savannah, GA.
- Evidence posture: official GrassMaster site/contact page verified business identity, Savannah service footprint, public phone/email/address, and free-estimate contact path; 24-7 PressRelease and Manta identified Mike Schuman as President/owner. No owner-direct private number was added.

Next worker note: continue GA/NC sourcing only through the collector guard; if source cooldown is active from the 429/504 events, wait for it instead of retrying immediately.
