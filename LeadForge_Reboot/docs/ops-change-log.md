# LeadForge Ops Change Log

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
