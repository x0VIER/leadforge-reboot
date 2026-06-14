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

## 2026-06-14 16:20 EDT - Dry Collector Rotation

- Re-read operating rules, ops snapshot, source lanes, LeadForge Seven config, lead memory index, collector guard, latest manifests, and git status before opening new work.
- Confirmed the only manual-review pending row, Aire Texas Residential Services, still has conflicted public evidence and should remain pending rather than be forced into master.
- Ran the guarded collector after `can_start_collector` returned true; it completed without overlap or timeout but produced 0 fresh rows.
- Root cause: the active Austin, Columbus, and Cincinnati lane window had gone dry/stale for the current schedule cursor, with prior Overpass timeout noise already tracked in health reports.
- Safe fix: rotated the active lane window to Pittsburgh, PA; Philadelphia, PA; and Richmond, VA using `scripts/rotate-source-lanes.ps1` instead of retrying the same dry lanes.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook after the lane rotation.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for the next sourcing pass.

## 2026-06-14 16:26 EDT - Batch 052 Philadelphia HVAC Merge

- Ran the guarded collector on the rotated Pittsburgh, Philadelphia, and Richmond lane window; it completed inside the 180-second budget with no overlap and wrote 5 fresh Philadelphia HVAC/plumbing candidates.
- Enriched all 5 rows from public official/BBB/site evidence and promoted them to reviewed/final: Jarman Sales & Service Inc, Tinneny Plumbing & Heating Inc, AirMaster Heating & Cooling Specialists, Summers Quality Service, and EMCO Tech Heating & Cooling.
- No raw rows were merged. The run folder now has raw, reviewed, final, and header-only pending artifacts with manifest counts.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 453 to 458 rows with 5 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for continued sourcing.

## 2026-06-14 16:35 EDT - Batch 053 Landscaping Merge

- Ran the guarded collector with no overlap; it completed inside the 180-second budget and staged 2 Pittsburgh/Philadelphia landscaping and tree-service candidates.
- Enriched both rows from public official/chamber/news evidence and promoted them to reviewed/final: Greater Pitt Tree Service LLC and Four Seasons Total Landscaping.
- No raw rows were merged. The run folder now has raw, reviewed, final, and header-only pending artifacts with manifest counts.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 458 to 460 rows with 2 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for continued sourcing.

## 2026-06-14 16:49 EDT - Batch 054 Low-Fit Painting Rejection

- Ran the guarded collector with no overlap; it completed inside the 180-second budget and staged 1 Philadelphia painting candidate.
- Rejected Perry Milou Studios because public evidence shows it is an artist/gallery/art-commerce business, not a local house-painting, commercial painting, or home-services contractor for the current campaign.
- Wrote a rejected artifact with triage reason, lead type, public research note, recommended action, owner/principal context, and registration notes where available.
- No raw rows were merged and master stayed at 460 rows.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for continued sourcing.

## 2026-06-14 17:03 EDT - Dry Collector Rotation

- Ran the guarded collector with no overlap; it completed inside the 180-second budget but produced 0 fresh rows.
- Root cause: the Pittsburgh, Philadelphia, and Richmond window had just yielded a rejection and then a dry cycle, while Overpass timeout noise continued on several remaining niche checks.
- Safe fix: rotated the active lane window to Virginia Beach, VA; Phoenix, AZ; and Tucson, AZ using `scripts/rotate-source-lanes.ps1` instead of retrying the stale window.
- No raw rows were merged and master stayed at 460 rows.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook after the lane rotation.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for continued sourcing.

## 2026-06-14 17:21 EDT - Batch 055 Phoenix Roofing/Plumbing Merge

- Ran the guarded collector with no overlap; it completed inside the 180-second budget and staged 3 Phoenix roofing/plumbing candidates.
- Enriched Stapleton Roofing and Goettl Air Conditioning & Plumbing from public official/BBB/leadership evidence and promoted them to reviewed/final.
- Kept Pipe and Wrench LLC pending because public checks confirmed business identity and contact details but did not produce a strong owner or decision-maker source.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 460 to 462 rows with 2 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for continued sourcing.
