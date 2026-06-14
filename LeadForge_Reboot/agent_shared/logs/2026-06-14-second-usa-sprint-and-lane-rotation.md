# 2026-06-14 second USA sprint and lane rotation

## Summary

- Ran the guarded collector against the USA sprint window.
- Runtime completed in about 146 seconds with no timeout and no stderr output.
- Produced 2 fresh raw Nashville plumbing candidates.
- Triaged both raw rows into pending, then verified public owner or decision-maker evidence and promoted both to reviewed/final.
- Merged 2 reviewed rows:
  - Lee Company Bellevue, Nashville TN, decision-maker Richard C. Perko, Chief Executive Officer.
  - Parthenon Plumbing, Heating, & AC Repair, Nashville TN, owner Trevor Garrett.
- Master rows increased from 353 to 355.

## Lane decision

- The Atlanta, Charlotte, Nashville window was low-yield on the second pass: 2 fresh rows, most lanes duplicate/rejected.
- Rotated the active lane window to Raleigh NC, Nashville TN, and Knoxville TN so the next heartbeat avoids repeating exhausted lanes.

## Current status

- Master rows: 355.
- Pending rows: 17.
- Immediate pending research rows: 0.
- Active lanes: Raleigh NC, Nashville TN, Knoxville TN.
- Collector guard: clear to start.
- Health: yellow only because recent failure-noise count still includes old timeout/log strings.
