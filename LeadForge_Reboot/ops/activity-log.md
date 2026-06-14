# LeadForge Activity Log

## 2026-06-14 15:49 EDT - Batch 049 Pending Promotion

- Promoted House to House Lawncare from pending to reviewed/final after public directory evidence named Andrew Combs as owner with matching website and phone.
- Preserved raw collector output and converted the pending artifact to header-only so the same row is not researched repeatedly.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 440 to 441 rows, adding 1 new row and recognizing 4 existing batch rows.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Health remains yellow only because of existing `recent_failure_noise:38`; collector guard reports clear to start.

## 2026-06-14 15:57 EDT - Batch 050 Trades Merge

- Ran the guarded collector with no overlap; it completed inside the 180-second budget and staged 12 painting, flooring, carpentry, and masonry candidates.
- Split the run into 8 reviewed/final owner-verified rows, 2 pending owner-evidence rows, and 2 rejected low-fit/low-signal rows.
- Rejected TDS Manufacturing LLC for the current campaign because public evidence points to a manufacturer/supplier/commercial fabricator rather than a local service lead.
- Rejected Benchdog Woodworking because the raw row was phone-only and public search showed a possible identity mismatch/no first-party Cincinnati business website.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 441 to 449 rows with 8 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Small command fix: avoid `$host` as a PowerShell variable name because it collides with built-in `$Host`; use `$leadHost` for future lead-key checks.

## 2026-06-14 16:07 EDT - Batch 051 Windows/Doors Merge

- Checked the immediate pending Aire Texas row, but kept it pending because public evidence is still conflicted: official site appears active while BBB reports an out-of-business status and owner/CEO evidence is not strong enough.
- Ran the guarded collector with no overlap; it completed inside the 180-second budget and staged 6 windows/doors candidates.
- Split the run into 4 reviewed/final owner-verified rows, 0 pending rows, and 2 rejected rows.
- Rejected Hutchins Garage Doors because hutchinsgaragedoors.com redirects to Cedar Park Garage Doors and BBB lists Hutchins as a related business under Cedar Park Overhead Doors.
- Rejected Champion because it was a generic phone-only listing with no website, owner, registration, or first-party identity evidence.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 449 to 453 rows with 4 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
