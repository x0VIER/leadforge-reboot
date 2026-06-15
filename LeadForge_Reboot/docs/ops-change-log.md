# LeadForge Ops Change Log

## 2026-06-15T07:30Z - Second partial dry pass, no rotation

- Guarded collector ran after the source cooldown cleared and produced no fresh rows. No raw rows were staged and no master rows were changed.
- Rotation check refused to rotate because the Louisville / Birmingham / Greenville window is still partially scanned: source cursor is at `24` of `45`, so remaining niches should continue on the next safe collector cycle.
- Safety: this was a correct no-merge/no-rotation cycle. Certification and commit preserve the current state so future wakeups do not retry stale assumptions or force an early city-window change.

## 2026-06-15T07:15Z - Partial dry pass, no rotation

- Guarded collector ran after the Louisville HVAC source cooldown cleared and produced no fresh rows. No raw rows were staged and no master rows were changed.
- Rotation check refused to rotate because this was only a partial dry pass: source cursor is at `18` of `45`, so the Louisville / Birmingham / Greenville window still has remaining niches to scan.
- Safety: the correct next action is certification and a local commit, then the next heartbeat can continue the remaining current-window niches after checking the guard. Do not force-rotate this window yet.

## 2026-06-15T07:00Z - Birmingham/Greenville HVAC merge

- Collector output produced 4 HVAC candidates while scanning Louisville, Birmingham, and Greenville. Louisville HVAC hit HTTP 429, so the next collector must respect guard status before any retry.
- Air Conditioning Experts was promoted cautiously after public Nextdoor and Zillow profile evidence matched business name, phone, address, website, and Chris Allen as owner. Because no BBB or first-party owner page surfaced, its risk score remains `3` and the row is marked public-profile verified rather than BBB-verified.
- Wilbur's Air Conditioning, Heating & Plumbing was promoted after official site/contact evidence and BBB evidence verified the Birmingham service business, corporation context, and Wilbur Doonan as President/principal/customer contact.
- Hiller Plumbing, Heating, Cooling & Electrical was promoted after official Birmingham location evidence plus BBB headquarters evidence verified service categories and James/Jimmy Hiller president/owner context.
- Home Service Nerds HVAC, AC & Furnace Repair was promoted after official Greenville service-page evidence and BBB evidence verified Home Service Nerds LLC and Jason Poucher as Owner.
- Safety: no raw rows were merged. The QA-clean final rows merged as `LF-0188` through `LF-0191`, and master grew from 502 to 506 rows. Public phones remain business phones only; no private owner-direct number was inferred.

## 2026-06-15T06:45Z - Greenville plumbing owner-verified merge

- Collector output produced 3 Greenville plumbing-lane candidates after the lane window rotated to Louisville, Birmingham, and Greenville. H2Flow Plumbing and Chisholm Plumbing, Heating & Air Conditioning were promoted; Gateway Supply Co was rejected.
- H2Flow Plumbing was promoted after official site evidence verified Greenville/Upstate plumbing service, public phone/contact path, and owner-led positioning; BBB verified Phillip H. Waters as Owner/principal/customer contact.
- Chisholm Plumbing, Heating & Air Conditioning was promoted after official site/contact/about evidence verified public contact path, Greenville-area addresses, phone, email, license number, and founder context; BBB verified John B Chisholm as Owner/principal/customer contact.
- Gateway Supply Co was rejected as a real but out-of-scope plumbing/HVAC supplier and distributor. Official Gateway/Watsco evidence confirms showroom/supply-counter and distributor/acquisition context, so it was kept out of the local service-contractor master.
- Safety: no raw rows were merged. The final QA-clean rows merged as `LF-0186` and `LF-0187`, and master grew from 500 to 502 rows. Public phones remain business phones only; no owner-direct private number was inferred.

## 2026-06-15T06:30Z - Dry Tucson/Chicago/Indianapolis pass rotated

- Guarded collector completed cleanly with no fresh rows and no timeout. The collector log explicitly reported that no fresh leads were produced, so the current lane window was treated as dry rather than retried.
- Rotation: `scripts/rotate-source-lanes.ps1` moved the active window from Tucson, AZ / Chicago, IL / Indianapolis, IN to Louisville, KY / Birmingham, AL / Greenville, SC.
- Safety: no raw rows were staged, no rows were merged, and no master rows were changed. The action only advanced source lanes to avoid stale repeated collection.
- Certification: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, master viewer workbook, and desktop lead hub were rebuilt. Master remains at 500 rows; health remains yellow only because of historical recent failure noise.

## 2026-06-15T06:15Z - Tucson windows/doors merge and 500-row milestone

- Collector output produced 2 Tucson windows/doors candidates: Window Depot and Olander's Window Replacement. Chicago and Indianapolis windows/doors rows were filtered out by the collector, and tree-service lanes returned no staged rows.
- Window Depot was promoted after official site/location evidence verified the Tucson Speedway location, contact path, Michael Kron as Store Manager, and corporate BBB/Real Estate Daily News context for The Window Depot / Solar Industries Inc.
- Olander's Window Replacement was promoted after official site/about/contact evidence, BBB managing-member evidence, Milgard dealer profile evidence, and public Patrick Olander owner-profile evidence verified identity, contact path, and owner or decision-maker context.
- Safety: no raw rows were merged. The generated pending scratch file from initial triage was removed only after reviewed/final artifacts, QA, merge, and manifest state existed. Master grew from 498 to 500 rows; durable IDs are `LF-0184` and `LF-0185`.
- Certification: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, master viewer workbook, and desktop lead hub were rebuilt. Health remains yellow only because of historical recent failure noise; collector guard is clear.

## 2026-06-15T06:00Z - Tucson carpentry and no-website property-management merge

- Collector output produced 2 Tucson carpentry-lane candidates: Gover Property Management and Tom White Carpentry. The same source cycle hit HTTP 429 on Indianapolis carpentry and Tucson masonry, so the collector guard entered cooldown after certification.
- Gover Property Management was corrected from `carpentry` to `property management` after public entity evidence verified Gover Property Management LLC and William C Gover as Member/Manager. No first-party website surfaced, so it was intentionally kept as a no-website service-business lead with a website/intake offer angle.
- Tom White Carpentry was promoted as a carpentry contractor after BuildZoom, Procore, Southern Arizona Home Builders Association, and ROC-style public evidence verified the contractor identity, Tucson contact data, active license context, and Darlene White / Thomas White decision-maker context.
- Safety: no raw rows were merged. QA flagged Gover Property Management with `missing_website`, which was expected and recorded in the manifest as a no-website lead rather than a blocking error. Master grew from 496 to 498 rows; durable IDs are `LF-0182` and `LF-0183`.
- Certification: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, master viewer workbook, and desktop lead hub were rebuilt. The Desktop hub now includes `Property Management Leads.xlsx`; collector guard is blocked by source cooldown until `2026-06-15T06:01:05Z`.

## 2026-06-15T05:45Z - Tucson floor-plan service niche-corrected merge

- Collector output produced 1 Tucson candidate in the flooring lane, Floor Plans First, after painting/flooring scans across Tucson, Chicago, and Indianapolis. Collector-level filters rejected 10 other painting/flooring candidates.
- Floor Plans First was promoted to reviewed/final after official site/contact evidence, BBB, Tucson Association of Executives, and Real Producers evidence verified business identity, contact path, and David Goff as Owner / Architect.
- Data cleanup: the raw lane labeled the row as `flooring`, but public evidence showed a floor-plan measurement and real-estate marketing service, not a flooring contractor. The reviewed/final row corrected the niche to `floor plan services`, keeping the business because it is still a service-based local company with clear offer fit.
- Safety: no raw rows were merged. The generated pending scratch file from initial triage was removed only after reviewed/final artifacts, QA, merge, and manifest state existed. Master grew from 495 to 496 rows, and the durable lead ID is `LF-0181`.
- Certification: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, master viewer workbook, and desktop lead hub were rebuilt. The Desktop hub now includes `Floor Plan Services Leads.xlsx`; health remains yellow because of historical recent failure noise.

## 2026-06-15T05:30Z - Chicago cleaning phone-corrected merge

- Collector output produced 1 Chicago cleaning/disinfecting candidate, Environmental Virus Removal. Tucson locksmith hit a single Overpass timeout during the same collector cycle, but the run completed and staged one raw row.
- Environmental Virus Removal was promoted to reviewed/final after BBB verified the business profile, service category, sole proprietorship context, and Anthony Wilson as Member/principal/customer contact. CityOf.com matched the stronger Chicago public phone and 24-hour listing.
- Data cleanup: the raw Overpass row carried `+1-563-661-2157`, but BBB and CityOf both showed `(773) 673-0772`; the final row uses the BBB/CityOf phone and records the mismatch in `source_evidence`, `visible_gap`, and review notes. The phone remains public business phone only, not owner-direct.
- Safety: no raw rows were merged. The generated pending scratch file from initial triage was removed only after reviewed/final artifacts, QA, merge, and manifest state existed. Master grew from 494 to 495 rows, and the durable lead ID is `LF-0180`.
- Certification: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, master viewer workbook, and desktop lead hub were rebuilt. Health remains yellow because of historical recent failure noise; collector guard is clear.

## 2026-06-15T05:15Z - Tucson landscaping owner-verified merge

- Collector output produced 1 fresh Tucson landscaping candidate, All Yard Work, after scanning Tucson/Chicago/Indianapolis landscaping and pest-control lanes. The remaining candidates were rejected by collector filters before staging.
- All Yard Work was promoted to reviewed/final after public evidence verified business identity, phone, website/contact path, and Juan Rosales as owner or decision-maker. Evidence used BBB owner listing plus TucsonDirect's verified owner-published page with the same business phone, address, website, and key contact.
- Data cleanup: the automated triage first placed the row in a generated pending scratch file because the raw collector row lacked owner evidence. After public owner evidence was verified and reviewed/final artifacts were written, the stale `data/tmp` pending scratch files for this batch were removed so future workers do not see contradictory state.
- Safety: no raw rows were merged. The final row passed QA before merge, master grew from 493 to 494 rows, the durable lead ID is `LF-0179`, and the public phone remains labeled as business phone only rather than an owner-direct number.
- Certification: contamination audit, owner backlog, pending report, lead memory index, factory metrics, ops snapshot, ops health, offer readiness, master viewer workbook, and desktop lead hub were rebuilt. Health is yellow due to historical recent failure noise; collector guard is clear to continue.

## 2026-06-15T03:05Z - Phoenix roofing/plumbing owner-verified merge

- Collector output produced 3 Phoenix candidates: Hardacker Roofing LLC, Reliant Plumbing & Rooter, and Zippity Split Plumbing. Virginia Beach roofing timed out, and Richmond plumbing hit HTTP 429, so the guard cooldown should be respected before another source run.
- All 3 Phoenix candidates were promoted to reviewed/final after public owner or decision-maker evidence was verified. Hardacker Roofing LLC was verified through BBB and Arizona Roofing Contractors Association evidence; Reliant Plumbing & Rooter was verified through official website and BBB owner/operator evidence; Zippity Split Plumbing was verified through official website/team-page owner evidence.
- Data cleanup: Hardacker's collector row had no readable website/contact path during the sweep, so the reviewed row preserved the website as an offer gap while relying on BBB/trade-profile evidence for owner and business identity.
- Safety: no raw rows were merged. All 3 rows passed QA before merge, and master grew from 484 to 487 rows.

## 2026-06-15T02:51Z - Dry window completed and rotated

- The final Cincinnati/Pittsburgh/Philadelphia pool-service pass produced no fresh leads, then the source cursor wrapped from `42` back to `3` after replaying the first roofing lanes. This proved the current city window had fully cycled and was starting stale work again.
- Fix: `scripts/rotate-source-lanes.ps1` now recognizes a dry-pass cursor wrap using `scheduleCursorStart` and `scheduleCursorNext`, so a wrapped cursor is not misclassified as ordinary partial progress.
- Rotation: the active lane window moved to Richmond, VA, Virginia Beach, VA, and Phoenix, AZ without using `-Force`.
- Safety: no raw rows were staged or merged during the dry pass. The fix only prevents stale city-window replay; it does not delete archive data, pending rows, rejected rows, or master rows.

## 2026-06-15T02:36Z - Partial dry pass, no rotation

- Collector output produced no fresh rows while scanning Cincinnati/Pittsburgh/Philadelphia windows/doors and tree-service lanes. Philadelphia windows/doors hit HTTP 429, so the guard cooldown must be respected again.
- Cursor check showed `nextIndex = 42` of `45`, with only the pool-service block left in the current city window. This is not a full lane-window exhaustion, so no lane rotation was applied.
- Safety: no raw rows were staged or merged. The next safe action is to wait for the source cooldown to clear, finish the remaining cursor lanes, then rotate only if the full window stays dry and no pending/reviewed work can advance.

## 2026-06-15T02:23Z - Philadelphia carpentry target-mismatch rejection

- Collector output produced 1 Philadelphia carpentry candidate and recorded fresh source pressure: Pittsburgh masonry hit HTTP 429, so the next collector must respect the guard cooldown again.
- Philadelphia Furniture Workshop was rejected instead of merged. Public evidence verified a real organization, but it is a woodworking/furniture-making school and 501(c)(3) educational nonprofit, not a service-based carpentry contractor for this campaign.
- Blockage fixed: the raw row did not include rejection-note columns, so direct property assignment failed before writing. The rejected row was rebuilt as an explicit extended object with `triage_reason`, `lead_type`, `public_research_note`, `recommended_action`, and registration/leadership fields.
- Metrics fix: `build-factory-metrics.ps1` now reads both legacy `*_rows` manifest fields and newer `*_count` fields, so reviewed/pending/rejected totals stay accurate across old and current run manifests.
- Safety: no raw rows were merged. The run manifest now marks the run `rejected`, and the rejected artifact preserves phone, address, nonprofit status, founder/executive-director context, and why it should not be contacted in this contractor lead lane.

## 2026-06-15T02:08Z - Cincinnati painting owner-verified merge

- Collector output produced 1 Cincinnati painting/carpentry candidate and recorded transient source pressure on later lanes: Philadelphia painting hit HTTP 429 and Pittsburgh flooring hit an Overpass timeout. The loop did not force immediate retries inside the same guarded cycle.
- Automatic triage correctly held Bill's Painting & Carpentry for missing owner fields. Manual public review found strong evidence from the official site and BBB: the site verifies business identity/contact details, and BBB lists Bill Charles as Owner/principal/customer contact.
- Fix applied: the reviewed row uses the canonical home-page website with the contact page kept in `contact_url`, preventing contact-page URLs from becoming separate duplicate website keys in master.
- Safety: no raw rows were merged. One QA-clean reviewed/final row was merged, and unresolved source-rate/timeout notes remain documented in the run manifest for future lane handling.

## 2026-06-15T01:02Z - Rotation preserves source cooldown

- Root cause: after rotating from the fully dry Houston/Austin/Columbus window to Cincinnati/Pittsburgh/Philadelphia, `rotate-source-lanes.ps1` rewrote `source-lanes.json` without preserving `sourceCooldownMinutesAfterRateLimit`.
- Fix: restored `sourceCooldownMinutesAfterRateLimit = 15` in `config/source-lanes.json` and updated the rotation script to carry that setting forward on future lane rotations.
- Verification: this was caught before opening a new collector on the fresh lane window, so no collection ran with the cooldown safety missing.
- Safety: no lead data changed. This only preserves source-protection behavior across lane rotations.

## 2026-06-15T00:42Z - Source rate-limit cooldown guard

- Root cause: after the tuned collector pass, Overpass returned multiple HTTP 429 rate-limit responses. The normal collector guard still reported `collector_clear_to_start`, which could let a near-immediate heartbeat hammer the public source again.
- Fix: `config/source-lanes.json` now defines `sourceCooldownMinutesAfterRateLimit = 15`, and `scripts/get-collector-guard-status.ps1` blocks new collector starts when the latest completed status contains HTTP 429 lane notes inside that cooldown window.
- Verification: the guard now reports `can_start_collector = false` with `source_rate_limit_cooldown_until:2026-06-15T00:52:06Z`, zero active claims, and five rate-limit notes from the latest collector status.
- Safety: no lead data was changed. This only prevents overlapping or too-fast collector starts after rate limits; pending, rejected, quarantine, and master lead artifacts remain intact.

## 2026-06-15T00:31Z - Dry cursor rotation fix

- Root cause: `complete_no_rows` was treated as a full lane-window failure even when the source cursor had only scanned the first 12 of 45 city/niche combinations. This made the loop look stuck and encouraged premature city rotation after a partial duplicate-heavy pass.
- Root cause: the second dry pass advanced to cursor `24 of 45`, but the middle niche block was dominated by Overpass request timeouts at the 9-second guard. This was too short for larger USA city/category queries and created fast failures instead of useful source coverage.
- Fix: `scripts/rotate-source-lanes.ps1` now reads `SOURCE_LANE_CURSOR.json` and refuses to rotate when `nextIndex` is still inside the current schedule. It reports the cursor position instead, so the next sprint continues the remaining niches in the same city window.
- Fix: `scripts/build-ops-snapshot.ps1` now includes source-cursor status and explains when a dry pass is only partial cursor progress. It also treats documented unresolved pending rows, including status-conflict rows already marked monitor/hold, as blocked-but-documented instead of immediate collector blockers.
- Timing fix: `config/source-lanes.json` now uses `overpassTimeoutMs = 15000`, `overpassPauseMs = 10000`, `lanePauseMs = 1500`, `maxLaneNicheChecksPerRun = 6`, and `querySampleLimit = 6`. This gives slower public Overpass queries enough time to return, reduces rate-limit pressure after HTTP 429 responses, and keeps each guarded collector inside the 180-second runtime cap.
- Verification: after the dry Houston/Austin/Columbus collector pass, the rotation tool returned `rotated = False` with cursor `12 of 45`, the full health/report/viewer stack rebuilt successfully, and health remained yellow only for historical `recent_failure_noise`.
- Contamination handling: the USA audit flagged 167 older/imported suspicious rows, mostly non-resolving website hosts. A fresh quarantine artifact was created with `scripts/quarantine-suspicious-leads.ps1 -State USA`; this copies the suspicious rows and lead IDs for review without deleting or changing the master.
- Safety: no master rows, archive files, pending rows, or rejected artifacts were deleted or overwritten. This change only prevents wasted lane rotation and makes the next action clearer for future Codex workers.

## 2026-06-15T01:56Z - Pittsburgh locksmith merge and Philadelphia pending

- Collector output produced 2 locksmith candidates. Murray Avenue Locksmith was promoted to reviewed/final after official website evidence and BBB evidence verified the storefront, public phone, alternate-name relationship, license context, and David Dvir as Owner/principal contact.
- Auto Locksmith Philadelphia Inc stayed pending. Official site and BBB confirm business identity, phone, email, address, A+ rating, and corporation dates, but no clean public owner, principal contact, officer, or decision-maker source surfaced during this pass.
- Safety: no raw rows were merged. The pending Philadelphia row has a public research note, registration/status context, and a specific next action to find owner or decision-maker evidence before any merge.

## 2026-06-15T01:39Z - Cincinnati landscaping merge and pest-control rejection

- Collector output produced 2 Cincinnati candidates. Druffel Design & Landscape was promoted to reviewed/final after official website/contact evidence and BBB evidence verified the business identity, public phone/email/contact path, corporation context, and Dan Druffel as President/principal contact.
- OCP Bed Bug Exterminator was rejected instead of merged. Public evidence looked like a bed-bug lead-generation or directory-style listing, the website did not return readable HTML during collection, and no clean owner, registration, BBB/licensing profile, or first-party contact path was verified.
- Safety: no raw rows were merged. The rejected row includes triage reason, lead type, public research note, recommended action, and registration-status note for future callback/source-quality analysis.

## 2026-06-15T01:27Z - Pittsburgh HVAC owner-verified batch

- Collector output produced 2 Pittsburgh HVAC candidates. Boehmer Heating & Cooling and Spurk HVAC, LLC were promoted to reviewed/final after public evidence verified official contact paths, business phone numbers, licensing/registration context, and owner or decision-maker sources.
- Data cleanup: the raw Spurk row surfaced a `connect.facebook.net` tracking URL as the contact path. The reviewed row replaced it with the first-party official contact page so QA and the human viewer show the usable business path instead of a tracking endpoint.
- Safety: no raw rows were merged. Both rows passed `scripts/qa-review-batch.ps1` before merge, and evidence was preserved in `source_evidence`, `owner_source`, `visible_gap`, and `offer_angle`.

## 2026-06-15T01:12Z - Pittsburgh/Cincinnati plumbing QA cleanup

- Collector output produced 4 plumbing candidates across Cincinnati and Pittsburgh. All 4 were promoted to reviewed/final after public evidence verified business identity, contact path, and owner or decision-maker context from official sites plus BBB profiles.
- QA initially flagged The Brookline Plumber because its official public contact email uses `msn.com`; the QA common-mailbox allowlist recognized Hotmail/Outlook/Live but not MSN, causing a false `email_domain_mismatch`.
- Fix: `scripts/qa-review-batch.ps1` now treats `msn.com` as a common mailbox domain while preserving placeholder-email and real off-domain mismatch checks. This keeps verified contact data instead of deleting it to satisfy the checker.
- Safety: no raw rows were merged. The final merge file keeps the master schema stable and carries source evidence in the existing `source_evidence`, `owner_source`, `visible_gap`, and `offer_angle` fields.

## 2026-06-14T23:25Z - Offer Audit Engine sidecar

- Added the Offer Audit Engine as a sidecar system instead of mixing offer planning into the raw collector. The lead factory still owns clean public-source collection and reviewed merges; the sidecar reads master leads and produces offer-readiness views without mutating source lead rows.
- Added `config/offer-audit-engine.json` and `docs/offer-audit-engine.md` to define public OSINT social-source boundaries, owner-number handling, qualification frameworks, offer families, and value-first contact rules.
- Added `scripts/build-offer-readiness-report.ps1`, which writes `OFFER_READINESS_REPORT.csv`, `.json`, and `.md` with qualification score, tier, public contact path, owner/business phone note, offer recommendations, audit angles, competitor research needs, compliance note, and next action.
- Updated `scripts/build-lead-viewer-workbook.ps1` to add `Owner Contact Points`, `Offer Readiness`, and `Qualification Guide` workbook tabs so the polished viewer shows contact paths, owner-number notes, qualification, and offer planning directly.
- Updated `scripts/build-desktop-lead-hub.ps1` so offer-readiness reports are copied into the simple Desktop `03 Reports` folder while raw CSVs stay tucked away as audit backups.
- Safety: owner-direct numbers are not guessed. The system uses public business phone unless a public business source clearly verifies an owner/direct business number. SMS and WhatsApp remain research context only until opt-in and opt-out handling is deliberately configured.

## 2026-06-14T23:03Z - LibreOffice recovery prevention

- Root cause: LibreOffice can show a document-recovery prompt when a generated workbook is overwritten or moved while Calc has that workbook open or still has a lock/recovery state for it.
- Fix: `scripts/build-lead-viewer-workbook.ps1` now builds the project viewer first and only refreshes the Desktop `OPEN ME - LeadForge Master Viewer.xlsx` when the target workbook is writable and has no LibreOffice `.~lock` file.
- Fix: `scripts/build-desktop-lead-hub.ps1` now checks each polished niche workbook before rebuilding. If a workbook is open, such as `Carpentry Leads.xlsx`, the script keeps it in place, skips that one rebuild, and reports the skip instead of forcing a write or moving it to legacy.
- Efficiency cleanup: the hub builder no longer moves every generated niche workbook into legacy on each run. It overwrites safe generated workbooks in place, which avoids duplicate audit clutter while still preserving source project data and raw CSV backups.
- Verification: while LibreOffice had `Carpentry Leads.xlsx` open, the hub rebuild completed successfully, skipped only the locked Carpentry workbook, kept 20 visible niche `.xlsx` files, and left 0 visible CSV files in the root or niche viewing folders.

## 2026-06-14T22:59Z - Human viewer hub and windows/doors batch

- Collector output produced 4 windows/doors candidates. Crystal Overhead Door Inc and Aventus Group LLC were promoted to reviewed/final and merged after public owner or decision-maker evidence was verified. New Era Windows Cooperative and Urban Street Window Works stayed pending because no clean public owner or decision-maker source was verified.
- The Desktop hub was simplified for non-technical human review. `scripts/build-desktop-lead-hub.ps1` now exposes polished `.xlsx` files in `C:\Users\loc9o\Desktop\LeadForge Lead Files\01 Leads By Niche`, keeps `OPEN ME - LeadForge Master Viewer.xlsx` at the top, and moves raw CSV exports plus old generated shortcuts into `99 Audit Backups` instead of making them normal click targets.
- The master viewer workbook now forces sheets to open at `A1` so LibreOffice does not reopen into blank-looking scrolled space. CSV files remain audit/source backups only, which avoids the LibreOffice text-import popup during normal review.
- Blockage fixed: the niche workbook builder initially failed because PowerShell wrote a JSON handoff with a UTF-8 BOM and this Windows PowerShell version does not support `utf8NoBOM`. The script now writes with a .NET UTF8 encoder and the Python reader is BOM-tolerant. The script also throws if the niche builder fails instead of printing a misleading success summary.
- Blockage fixed: manifest updates initially failed when adding new JSON properties to a deserialized PowerShell object. The run manifest was corrected with explicit add/update semantics so reviewed, final, pending, merged, and added counts are present.
- Safety: source project data and archive data were not moved or deleted. Old generated Desktop hub clutter was moved into audit/legacy backup folders, not removed. Raw rows were not merged.

## 2026-06-14T22:16Z - Chicago locksmith batch and viewer hub cleanup

- Collector output produced 2 Chicago locksmith candidates. Omega Locksmith was promoted to reviewed/final and merged after public owner evidence from the official Omega Locksmith site and BBB. 24/7 Lightning Locksmith Chicago stayed pending because the public profile confirms business identity, but owner evidence and the redirected domain relationship need stronger verification before merge.
- Triage was upgraded to flag `contact_domain_mismatch` so future rows with first-party-looking contact paths on a different host are held pending until the domain or redirect relationship is verified. This prevents raw or suspicious rows from reaching the reviewed merge path.
- Desktop viewing was rebuilt as a durable hub instead of a one-off folder cleanup. `scripts/build-desktop-lead-hub.ps1` refreshes `C:\Users\loc9o\Desktop\LeadForge Lead Files` with a top-level `OPEN ME - LeadForge Master Viewer.xlsx`, simple folder shortcuts, niche subfolders, pending/rejected shortcuts, and legacy shortcut archiving.
- `scripts/build-lead-viewer-workbook.ps1` now generates a warmer polished workbook, friendlier tab names, all-niche tabs, and less harsh rejected-row coloring. Raw CSVs remain available as audit backups, but the workbook is the intended human review surface.
- Safety: no archive data or prior master rows were deleted. Old generated Desktop shortcuts were moved into `06 System And Logs\Legacy Shortcuts` instead of removed. Source project data remains in place, and local git remains the durable save point.

## 2026-06-14T22:34Z - Chicago masonry batch

- Collector output produced 2 Chicago masonry candidates. Edmar Corporation was promoted to reviewed/final and merged after public evidence from BBB and official Edmar pages verified Edward Marciszewski as President/CEO and confirmed a contact path.
- Retaining Walls Chicago stayed pending because the website timed out during verification and no reliable owner, founder, officer, contact page, BBB profile, or registration evidence was surfaced for the exact business identity.
- Safety: no raw rows were merged. The unresolved row remains in the run pending file with `website_timeout`, owner-evidence, and recommended-action notes for future callback.
