# LeadForge Ops Change Log

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
