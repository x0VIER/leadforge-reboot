# 2026-06-14 Philadelphia batch 027

## Result
- Collector guard was clear before the run.
- Guarded collector completed in-bounds and staged 4 Philadelphia PA raw candidates.
- Triage moved all 4 candidates to owner-enrichment review because raw rows had no owner fields.
- Public research verified owner or decision-maker evidence for all 4 candidates.
- QA passed and `merge-new-leads.ps1` added 4 reviewed rows to `data/master_leads.csv`, moving master from 382 to 386 rows.

## Merged Leads
- Roof Gurus: official site identifies Nicholas Bonifante and Joseph Potok as operators; BBB profile for related Roof Gurus/Gutter Gurus lists Joseph Potok as President/Owner and PA license context.
- ZBC General Contracting: BBB profile lists Joseph Zajko as President / CEO and PA license PA052357; official site confirms Philadelphia-area remodeling, repairs, renovations, and roofing work.
- Ameen General Contractor Inc: BBB profile lists Richard Smith as President and PA license PA049645; official site confirms general contracting, remodeling, plumbing, electrical, and hot-water-tank services.
- Economy Drain Cleaning & Plumbing: BBB Plumbing Pals profile lists Economy Drain Cleaning & Plumbing as an alternate name and Travas Marko as Owner with PA license PA154067; official site confirms Philadelphia plumbing/drain services and scheduling path.

## QA Notes
- No raw rows were merged.
- No rejected rows were needed for this batch.
- Economy Drain / Plumbing Pals was kept as `P1_owner_verified_review_before_outreach` because BBB complaint/rating signal increases outreach risk even though public owner evidence is usable.
- Contamination audit stayed stable at 36 existing suspicious rows; this merge did not increase the suspicious-row count.

## Next Loop State
- Active lane window remains Philadelphia PA, Richmond VA, Virginia Beach VA because this window still produced fresh reviewed leads.
- Health is yellow for recent failure noise only; collector guard is clear and the next loop can continue.
