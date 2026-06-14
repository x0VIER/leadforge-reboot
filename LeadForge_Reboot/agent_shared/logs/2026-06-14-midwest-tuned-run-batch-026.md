# 2026-06-14 Midwest tuned run batch 026

## Result
- Collector guard was clear before the retry and remained clear after the run.
- The tuned collector completed instead of timing out, producing 2 raw candidates from the Columbus/Cincinnati/Pittsburgh lane window.
- QA approved 1 reviewed/final row and the merge moved `data/master_leads.csv` from 381 to 382 rows.
- 1 row was rejected before merge as non-target industrial/manufacturer market intelligence.

## Lead Decisions
- Merged: MaxForce Roofing and Siding LLC, Columbus OH roofing. Public evidence confirmed first-party site, phone, and BBB owner listing for Jennifer Enslow-Mance.
- Rejected: Younge & Bertke Company / Young & Bertke Air Systems Co., Cincinnati OH. Public evidence confirmed an industrial air-pollution, dust-collection, and sheet-metal systems company, not a local residential/commercial home-service HVAC lead for this campaign.

## Blockage And Fix
- Previous Midwest collector attempt was killed by the 240 second guard before `run-source-batch.mjs` could flush a CSV/log, even though status showed rows had been found.
- The fix reduced Overpass attempts, timeout, and lane pauses in `config/source-lanes.json` so guarded runs finish inside the lease window more reliably.
- This follow-up run completed in-bounds and produced durable output/run-log artifacts, validating the timing fix without touching existing lead rows outside the reviewed merge path.

## Next Loop State
- Current lanes were rotated because the Midwest window had low yield and multiple Overpass timeouts even after tuning.
- Next active lane window: Philadelphia PA, Richmond VA, Virginia Beach VA.
- Health remains yellow for recent failure noise only; no active collector claim or duplicate master-key blocker is present.
