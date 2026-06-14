# LeadForge Ops Change Log

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
