# 2026-06-14 Philadelphia Burke batch 028

## Result
- Collector guard was clear before the run.
- Guarded collector completed in-bounds and staged 1 Philadelphia PA raw candidate.
- Triage moved the candidate to owner enrichment because the raw row had no owner fields.
- Public research verified Burke Plumbing & Heating through the official site/contact page and BBB profile.
- QA passed and `merge-new-leads.ps1` added 1 reviewed row to `data/master_leads.csv`, moving master from 386 to 387 rows.

## Merged Lead
- Burke Plumbing & Heating: BBB profile lists Kevin Burke as Owner at 2808 E Pacific St Philadelphia, and the official Burke Plumbing site confirms Philadelphia residential/commercial plumbing and heating services, 24/7 availability, contact form, and the same address.

## QA Notes
- No raw rows were merged.
- No rejected rows were needed for this batch.
- The row notes that BBB/public listing phone and official site phone differ. This is recorded as the visible conversion gap and offer angle instead of being hidden.
- Contamination audit stayed stable at 36 existing suspicious rows; this merge did not increase the suspicious-row count.

## Next Loop State
- Active lane window remains Philadelphia PA, Richmond VA, Virginia Beach VA because the window still produced one clean reviewed lead.
- Repeated Overpass timeouts on VA and several non-plumbing lanes should be watched; rotate if the next pass is dry or only repeats timeout noise.
- Health is yellow for recent failure noise only; collector guard is clear and the next loop can continue.
