# 2026-06-14 State Transition FL To GA

## Trigger

The guarded collector ran the final Florida active window (`Largo`, `Plantation`) and returned `complete_no_rows`.

## Decision

Advance `config/source-lanes.json` from Florida to Georgia instead of wrapping back to already-scanned Florida cities.

## New State

- Target state: `GA`
- Batch name: `georgia-home-services-reboot`
- Active cities: `Atlanta`, `Savannah`
- Batch sizing: 2 active cities, 2 per-niche limit, 8 max output rows

## Safety

No Florida master rows were deleted or overwritten. Existing Florida pending rows stay in the pending queue for future public-evidence review. The change only affects new collector sourcing lanes.
