# 2026-06-14 Texas Second Pass Rotation Batch 025

## What Ran
- Continued the USA sprint loop after collector guard confirmed the collector was clear to start.
- Ran `run-collector-guarded.ps1` with a 240 second cap. It completed without timeout or overlapping claims.
- The second Texas pass produced 11 raw candidates across Dallas, Houston, and Austin.

## Lead Decisions
- Merged 5 reviewed owner-verified leads:
  - Cyclone Heating & Air
  - Ellis Air Conditioning & Heating
  - Lumens Electric LLC
  - Mr. Reliable Heating & Air
  - Economy Plumbing Services, LLC
- Kept 5 rows pending because owner evidence was not strong enough:
  - Texaire
  - Peoples Choice Electric, Inc.
  - OneCall Houston
  - Water Damage & Roofing of Austin
  - McDowd Plumbing
- Rejected 1 row:
  - Bluebonnet Roofers: suspicious domain/brand mismatch against stronger Bluebonnet Roof Co. public evidence.

## Blockage And Fix
- Blockage: Texas output dropped from 20 raw rows to 11, with repeated duplicate-heavy lanes and HTTP 429/504/timeout notes.
- Fix: Finished the staged run, merged only QA-clean reviewed rows, then rotated lanes to Columbus, Cincinnati, and Pittsburgh to avoid stagnating on the same Texas window.
- Safety: Existing master rows were not overwritten or deleted. Raw output remained staged, pending/rejected rows were separated with notes, and only reviewed final rows were merged.

## Certification
- Master rows after merge: 381.
- Active lanes after rotation: Columbus OH, Cincinnati OH, Pittsburgh PA.
- Health/audit reports were rebuilt after merge and rotation.
