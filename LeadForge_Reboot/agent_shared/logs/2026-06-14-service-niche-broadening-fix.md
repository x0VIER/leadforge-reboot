# 2026-06-14 service niche broadening fix

## Issue
- The collector was effectively biased toward the first supported trade categories because `run-source-batch.mjs` only mapped roofing, plumbing, electrician, and HVAC.
- The nested loop also processed one city through every niche before moving on, which could let early city/trade combinations consume the output window.
- `perNicheLimit` acted like a hard city/niche cap even when a lane had more clean public candidates available.

## Fix
- Added broader service-business categories: landscaping, pest control, cleaning, locksmith, painting, flooring, carpentry, masonry, windows/doors, tree service, and pool service.
- Changed scheduling to a fair lane/niche sequence so the collector samples the same niche index across active cities before moving deeper into one city.
- Added `querySampleLimit` as the scan safety control and allowed `perNicheLimit: null` so useful lanes are not artificially capped by city/niche.
- Patched lane rotation to preserve the new query-sample field and broader niche template.

## Safety
- The global `maxOutputRows` remains as a runtime safety cap so an automation run cannot grow without bound or burn tokens/time indefinitely.
- Existing leads and archived data were not edited directly. The prior merge still used the reviewed-only merge script.

## Result
- Active lanes rotated from the degraded Indianapolis/Louisville/Birmingham timeout window to Greenville SC, Orlando FL, and Tampa FL.
- Future collector runs will source across a wider service-business mix instead of focusing on roofing first.
