# 2026-06-14 Indianapolis batch 032 review

## What changed
- Advanced the staged `2026-06-14T16-36-32-989Z` collector run from raw/pending into reviewed/final rows.
- Verified All Star Roofing ownership from BBB/HomeSquad public evidence and marked it offer-ready with a contact-path cleanup gap.
- Verified Trojan Roofing ownership from the official team page plus BBB and Indiana DFI records, but kept risk high because BBB shows serious reputation flags.
- Cleared the generated pending artifact to header-only after both staged rows were resolved into reviewed/final rows.

## Blockage and fix
- Blockage: triage correctly held both rows because the raw collector does not guess owner names.
- Fix: public owner evidence was added only after verification. Existing master rows were not edited directly; merge will happen through `merge-new-leads.ps1`.

## Next sourcing adjustment
- The current lane window is over-producing roofing because that is the only lane returning fresh rows during the Overpass timeout window.
- Next rotation/config pass should broaden city/niche coverage across service businesses and rank lanes by likely buyer fit, not by one fixed trade.
