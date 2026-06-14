# AZ Pending Owner Advancement

Timestamp: 2026-06-14T12:20:10-04:00

## Advanced From Pending

Two AZ pending rows were moved to reviewed/final and merged through the locked merge script after public owner or decision-maker evidence was found:

- 1st Class Foam Roofing and Coating, LLC
- All Vee's Plumbing Services

## Evidence Summary

1st Class Foam Roofing and Coating, LLC:

- BBB profile identifies Jason Rex Rivers as owner, principal contact, and customer contact.
- Official 1stClassFoam.com confirms the business website, Glendale/Phoenix service footprint, and public phone.

All Vee's Plumbing Services:

- Official All Vee's about page says Perry Villarreal started the company with his son Cody Villarreal in Phoenix in 2006.
- Official contact page confirms Phoenix address, phone, website, and Cody email.
- BuildZoom contractor profile corroborates Cody Wayne Villarreal and James Perry Villarreal against the Arizona contractor record.

## Safety

Rows were not raw-merged. They were written to reviewed/final artifacts, passed QA review with no findings, then merged through `scripts/merge-new-leads.ps1`. The pending artifact was reduced from 6 unresolved rows to 4 unresolved rows so the queue does not double-count completed owner enrichment.
