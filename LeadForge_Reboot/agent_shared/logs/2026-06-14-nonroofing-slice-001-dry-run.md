# 2026-06-14 non-roofing slice 001 dry run

## What happened
- Ran the guarded collector after the Palmetto decision-maker merge.
- The source cursor started at index 12 and advanced through landscaping, pest control, cleaning, and locksmith lanes for Greenville SC, Orlando FL, and Tampa FL.
- No raw lead rows were produced in this slice.

## Why this is useful
- The run completed inside the guard window, so the cursor-budget fix prevented another long timeout.
- The cursor advanced to index 24, which means the next collector run will continue with the next service categories instead of repeating this dry slice.

## Current action
- Do not merge anything from this run because there is no raw output.
- Continue the next guarded collector slice from index 24 unless pending enrichment with stronger public evidence is available.
