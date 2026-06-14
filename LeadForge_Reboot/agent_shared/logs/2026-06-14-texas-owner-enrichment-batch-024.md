# 2026-06-14 Texas Owner Enrichment Batch 024

## What Ran
- Continued the USA sprint loop after collector guard confirmed `can_start_collector: true`.
- Ran `run-collector-guarded.ps1` with a 240 second cap. It completed in about 221 seconds without timeout or overlapping claims.
- The collector produced 20 raw candidates across Dallas, Houston, and Austin.

## Lead Decisions
- Merged 12 reviewed owner/decision-maker verified leads:
  - Salis Roofing
  - NOMI - Bathroom Remodeling Dallas Tx
  - On Time Experts
  - New Image Roofing
  - Amstill Roofing
  - Acuity Electric
  - All Star Roofing
  - JC Roof Construction LLC
  - Kidd Roofing
  - Beckett Electrical Services
  - Smart Charge America
  - TruTec Electric
- Kept 5 rows pending because owner evidence was not strong enough:
  - Bob - Emergency Plumbing Services
  - Coalwood Electric I Limited Partnership
  - Kingwood AC Repair Pros
  - Superior HVAC
  - Cool Care Heating and Air Conditioning
- Rejected 3 rows as non-target lead types:
  - Plumbers Local 68: union/training organization.
  - Plumbers Local Union No. 68 Group Protection Plan and Benefit Office: union benefit office.
  - Electrical Training Center: apprenticeship/training center.

## Blockage And Fix
- Blockage: Dallas electrician, Dallas HVAC, Austin plumbing, and Austin HVAC public-source lanes returned HTTP 429 or 504 notes.
- Fix: Treated the rate-limit/server notes as non-blocking because the guarded collector still completed and yielded 20 fresh candidates. No raw data was merged, and the affected lanes can be retried in a later cycle rather than forcing repeated immediate retries.
- Safety: QA flagged a missing phone for On Time Experts before merge; the reviewed/final artifacts were patched with its public phone and QA reran cleanly.

## Certification
- Master rows after merge: 376.
- Pending queue after reports: 30.
- Collector guard after reports: clear to start.
- Health remains yellow due to recent failure-noise counting public-source HTTP notes; no active claim or duplicate master key is blocking the loop.
