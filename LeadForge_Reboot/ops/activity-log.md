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

## 2026-06-14 17:36 EDT - Batch 056 Phoenix Landscaping Merge

- Ran the guarded collector with no overlap; it completed inside the 180-second budget and staged 2 Phoenix landscaping candidates after Tucson landscaping timed out.
- Enriched Goodman's Landscape Maintenance LLC and Apex Turf from official website, contact, license, and BBB owner/principal evidence, then promoted both rows to reviewed/final.
- No raw rows were merged. The run folder now has raw, reviewed, final, and header-only pending artifacts with manifest counts.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 462 to 464 rows with 2 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, and the desktop viewer workbook.
- Health remains yellow only because of accumulated `recent_failure_noise`; duplicate master key count is 0 and collector guard is clear for continued sourcing.

## 2026-06-14 17:50 EDT - Aire Texas Pending Status Conflict Follow-up

- Advanced the only immediate/manual pending research row instead of opening a new collector run.
- Rechecked Aire Texas Residential Services against public sources: official site remains active with 2026/contact/license signals, BBB lists Chad Faith but says the business has no rating because it is out of business, and official TDLR Active License Search returned no records for license 38788 or Aire Texas / Faith name searches.
- Safe decision: did not merge the row and did not guess current status. Updated the pending artifact, manifest notes, registration notes, and recommended action so future workers do not repeat the same TDLR check without new evidence.

## 2026-06-14 17:54 EDT - Dry Collector Lane Rotation

- Ran the guarded collector with no overlap; it completed inside the 180-second budget and produced 0 fresh rows.
- Root cause: the remaining Virginia Beach, Phoenix, and Tucson niche window had become dry, with Phoenix painting scanned/rejected and several later niche checks hitting timeout or HTTP 429 noise.
- Safe fix: rotated the active lane window to Chicago, IL; Indianapolis, IN; and Louisville, KY using `scripts/rotate-source-lanes.ps1` instead of retrying the stale window.

## 2026-06-14 17:58 EDT - Batch 057 Midwest Roofing/Plumbing/HVAC Merge

- Ran the guarded collector on the rotated Chicago, Indianapolis, and Louisville lane window; it completed inside the 180-second budget and staged 8 raw candidates.
- Promoted 7 owner/decision-maker verified rows to reviewed/final: Bone Dry Commercial Roofing, R&B Roofing and Remodeling, Kuhn Plumbing, Rocket Plumbing, Altstadt Hoffman Plumbing Services, Blythe Heating & Cooling, and Vital Heating & Air.
- Kept Rodding Rooter pending because public identity and contact data are valid but no strong owner, founder, officer, BBB principal, registry contact, or first-party leadership source was found.
- No raw rows were merged. Merged only the final reviewed CSV through `scripts/merge-new-leads.ps1`; master moved from 464 to 471 rows with 7 added and 0 existing-row enrichments.

## 2026-06-14 18:04 EDT - Palmetto Outdoor Lighting Pending Research Cleanup

- Advanced the highest-priority pending owner-research row before opening another collector run.
- Rechecked Palmetto Outdoor Lighting from public sources. Official website/contact data is valid, but search results surfaced unrelated Palmetto lighting/exterior-lighting entities and no reliable owner, founder, officer, BBB principal, registry contact, or first-party leadership source for the exact Charlotte business.
- Safe fix: did not merge and did not guess an owner. Updated the pending artifact to `monitor_or_move_on_until_stronger_public_evidence` with registration notes so future workers avoid repeating the same weak search.

## 2026-06-14 23:28 EDT - Batch 066 Phoenix HVAC Merge

- Ran the guarded collector with no overlap after the prior cooldown cleared; it completed inside the 180-second budget and staged 1 Phoenix HVAC candidate.
- Enriched Mountainside Air Conditioning Repair from public official site/contact/terms evidence, plus public directory and press corroboration, and verified Tom Doepke as the public business owner/contact.
- No raw rows were merged. The collector-local `LFR-*` ID was allowed through the final reviewed file because `scripts/merge-new-leads.ps1` strips those temporary IDs and assigns the next durable `LF-*` master ID.
- Merged through `scripts/merge-new-leads.ps1`; master moved from 487 to 488 rows with 1 added and 0 existing-row enrichments.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, the polished viewer workbook, and the desktop lead hub.
- Health remains yellow because Virginia Beach HVAC hit an HTTP 429 and the collector guard is cooling down until `2026-06-15T03:32:40Z`; next worker should wait for the guard instead of retrying immediately.

## 2026-06-14 23:42 EDT - Batch 067 Phoenix Pest-Control Rejection

- Waited for the source-rate cooldown to clear, then ran one guarded collector with no overlap; it completed inside the 180-second budget and staged 2 Phoenix pest-control candidates.
- Rejected Mike's Swat Team Pest & Termite Control because public evidence verifies Michelle Ledune as President/CEO, but BBB also shows an out-of-business status conflict.
- Rejected Arizona's Best Choice Pest & Termite Services because the row now routes to Green Mango contact paths and public transition/acquisition evidence, creating a current-brand/contact mismatch.
- No raw rows were merged. Removed only the stale generated pending artifact after writing the replacement rejected artifact and updating the manifest.

## 2026-06-14 23:39 EDT - Partial Dry Collector Pass

- Ran one additional guarded collector with no overlap after committing Batch 067.
- The cleaning/locksmith lane segment returned 0 fresh rows across Richmond, Virginia Beach, and Phoenix; no output CSV or run folder was created.
- Safe decision: did not rotate yet because the source cursor advanced from 18 to 24 inside the active 45-lane schedule and has not wrapped or proven the full window dry.

## 2026-06-14 23:48 EDT - Partial Dry Painting/Flooring Pass

- Ran one guarded collector with no overlap from the clean `e80407f` handoff.
- The painting/flooring lane segment returned 0 fresh rows; Phoenix painting timed out once, and Phoenix flooring scanned 2 candidates that were rejected by collector filters.
- Safe decision: did not rotate yet because the source cursor advanced from 24 to 30 inside the active 45-lane schedule and has not wrapped or proven the full window dry.

## 2026-06-14 23:50 EDT - Partial Dry Carpentry/Masonry Pass

- Ran one guarded collector with no overlap from the clean `5445525` handoff.
- The carpentry/masonry lane segment returned 0 fresh rows; Phoenix carpentry and masonry scanned 24 total candidates that were rejected by collector filters.
- Safe decision: did not rotate yet because the source cursor advanced from 30 to 36 inside the active 45-lane schedule and has not wrapped or proven the full window dry.

## 2026-06-15 00:12 EDT - Batch 068 Phoenix Windows/Doors Review And Merge

- Ran one guarded collector with no overlap; it completed inside the 180-second guard budget and staged 3 Phoenix windows/doors candidates.
- Promoted Mirage Glass & Mirror Inc after official website/contact/about evidence verified Phoenix-area custom glass/window services and contact paths, BBB corroborated the window/glass category, and a public decision-maker profile identified Richard Craft as President.
- Rejected Hirschi Masonry because public evidence verified a real masonry/specialty contractor, not a windows/doors lead; merging it under the collected niche would contaminate niche accuracy.
- Rejected Prime Builders because official public evidence points to a broad general contractor, the collector phone mismatched official site phone references, and no public owner/decision-maker source was found.
- No raw rows were merged. Merged only the QA-clean final row through `scripts/merge-new-leads.ps1`; master moved from 488 to 489 rows with 1 added and 0 existing-row enrichments.
- Removed only the stale generated pending artifact after the manifest recorded the replacement reviewed/final/rejected state, preserving raw output and rejected intelligence.
- Rebuilt contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, the polished viewer workbook, and the desktop lead hub. Health remains yellow only for recent failure noise; collector guard is clear for the next atomic step.

## 2026-06-15 00:18 EDT - Dry Wrap And Lane Rotation

- Ran one guarded collector with no overlap from the clean `bb8b748` handoff.
- The final active-window segment returned 0 fresh rows: Richmond, Virginia Beach, and Phoenix pool-service lanes scanned 0 each, then the wrapped roofing segment scanned 12 Phoenix candidates and collector filters rejected all 12.
- The source cursor wrapped from 42 to 3, so retrying the same window would waste cycles. Applied the safe professional fix: rotated lanes with `scripts/rotate-source-lanes.ps1` instead of repeating stale Richmond/Virginia Beach/Phoenix work.
- New active lane window is Tucson, AZ; Chicago, IL; Indianapolis, IN. No raw rows were created or merged, and no master data changed during this dry pass.

## 2026-06-15 00:33 EDT - Dry Tucson/Chicago/Indianapolis Roofing-Plumbing Pass

- Ran one guarded collector with no overlap from the clean `2922d63` handoff.
- The roofing/plumbing segment returned 0 fresh rows: Tucson roofing scanned 1/rejected 1, Chicago roofing scanned 4/rejected 4, Indianapolis roofing scanned 12/rejected 12, Tucson plumbing scanned 4/rejected 4, Chicago plumbing scanned 7/rejected 7, and Indianapolis plumbing scanned 4/rejected 4.
- No output CSV or run folder was created, so there was nothing safe to triage or merge. Master data was not changed.
- Safe decision: did not rotate lanes yet because the new active window only advanced from cursor 0 to 6 inside the 45-lane schedule. Continue with the next guarded segment rather than retrying roofing/plumbing immediately.
