# 2026-06-14 pending owner promotions and merge lock

## Summary

- Advanced two pending rows with stronger public evidence:
  - Rainstoppers Roofing, Savannah GA: promoted with Scott Tebay as Owner and CEO from the official Rainstoppers About page, supported by BBB Savannah branch identity and BBB owner-contact evidence.
  - AAA City Plumbing, Charlotte NC: promoted with Travis Nichols as General Manager from York County Regional Chamber public data, supported by BBB and PRNewswire acquisition context for Dean Inkelaar and Founders Home Service Group.
- Merged both rows through reviewed/final CSV artifacts only.
- Reduced pending queue from 19 to 17 rows.
- Master increased from 351 to 353 rows.

## Blocker and fix

- Blocker: Two merge commands were started in parallel and one hit a file lock on `data/master_leads.csv`.
- Safety check: The master was not corrupted. AAA City Plumbing landed first; Rainstoppers Roofing did not.
- Fix: Re-ran Rainstoppers sequentially, then added a merge lock in `scripts/merge-new-leads.ps1` so future workers wait on `master_leads.csv.lock` instead of racing the master CSV.
- Verification: Re-running the AAA merge after the lock fix enriched the existing row without adding a duplicate.

## Current status

- Master rows: 353.
- Pending rows: 17.
- Immediate pending research rows: 0.
- Collector guard: clear to start.
- Health remains yellow only because recent failure-noise count still includes previous timeout/log strings.
