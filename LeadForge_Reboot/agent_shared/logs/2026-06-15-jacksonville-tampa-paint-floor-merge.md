# 2026-06-15 Jacksonville/Tampa painting-flooring merge

Completed the guarded USA home-services sprint from `2026-06-15T09-33-22-495Z-usa-home-services-sprint-fresh-leads.csv`.

- Collector summary: Orlando painting scanned 1 and rejected 1, Tampa painting scanned 0, Jacksonville painting scanned 3 and added 3, Orlando flooring scanned 0, Tampa flooring scanned 1 and added 1, Jacksonville flooring hit HTTP 429 and was not retried in-loop.
- QA path: `triage-raw-batch.ps1` staged all 4 rows for enrichment, manual public review promoted all 4, and `qa-review-batch.ps1` returned clean before merge.
- Merge result: `merge-new-leads.ps1` moved master from 508 to 512 rows with 4 added rows and 0 enriched existing rows.
- Added leads: `LF-0194` Myers Painting Inc, `LF-0195` Colorwise Painting, `LF-0196` A New Leaf Painting, `LF-0197` Bob's Carpet and Flooring.
- Evidence posture: no raw rows were merged directly, no owners were guessed, and Bob's Carpet and Flooring was kept as a cautious P1/risk 3 because it is a larger multi-location family-owned flooring business.

Next worker note: continue through the full audit/report/viewer/hub stack before any new collector; if Florida painting/flooring lanes go dry again, rotate source lanes rather than looping stale windows.
