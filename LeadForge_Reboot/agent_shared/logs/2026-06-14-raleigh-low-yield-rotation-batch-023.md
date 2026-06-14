# 2026-06-14 Raleigh Low-Yield Rotation Batch 023

## What Ran
- Continued the USA sprint loop after collector guard confirmed `can_start_collector: true`.
- Ran `run-collector-guarded.ps1` with a 240 second cap. It completed in about 141 seconds with no timeout.
- The collector produced 4 raw Raleigh candidates from the Raleigh/Nashville/Knoxville window.

## Lead Decisions
- Merged 2 reviewed owner-verified leads:
  - Rhino Roofing: owner evidence from BBB North Carolina profile; first-party site confirmed Raleigh roofing service context.
  - The Shingle Master: owner evidence from official about page and BBB profile.
- Kept 1 row pending:
  - MTC Heating and Air Conditioning: public business identity is confirmed, but owner or decision-maker evidence remains unresolved.
- Rejected 1 row:
  - Peak Metal Products: official site indicates sheet-metal fabrication/supplier intelligence, not a local home-service contractor lead.

## Blockage And Fix
- Blockage: Raleigh/Nashville/Knoxville dropped from useful output to 4 raw rows, with Nashville and Knoxville returning only duplicate/rejected rows.
- Fix: Rotated the active lane window to Dallas, Houston, and Austin using `rotate-source-lanes.ps1 -Force`.
- Safety: Existing master rows were not overwritten or deleted. Raw output stayed in its run folder, reviewed rows were QA checked, and only final reviewed rows were merged.

## Certification
- Master rows after merge: 364.
- Pending queue after reports: 25.
- Collector guard after reports: clear to start.
- Health remains yellow only because old failure-noise strings are still counted; no active claim or duplicate master key is blocking the loop.
