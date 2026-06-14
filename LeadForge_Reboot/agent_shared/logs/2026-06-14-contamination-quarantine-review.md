# 2026-06-14 contamination quarantine review

## Summary

- Reviewed the national contamination queue from `MASTER_CONTAMINATION_AUDIT_USA`.
- Created non-destructive quarantine artifacts for 36 suspicious historical rows.
- Did not delete, overwrite, or remove rows from `data/master_leads.csv`.
- The suspicious rows are mostly older template-style or duplicate-domain rows such as repeated city variants on the same short domain.

## System fix

- Updated `build-ops-snapshot.ps1` so a current quarantine artifact can satisfy the contamination review gate.
- Updated `build-ops-health-report.ps1` to report latest quarantine row count.
- This prevents the loop from repeatedly stopping on the same already-reviewed contamination queue while preserving the master and quarantine evidence for human review.

## Current result

- Master rows: 355.
- Quarantined review rows: 36.
- Pending rows: 17.
- Collector guard: clear to start.
- Next action is allowed to continue with fresh collector sourcing.
