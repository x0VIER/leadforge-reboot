# Lane Rotation After AZ/IL Timeout Noise

Timestamp: 2026-06-14T12:28:00-04:00

## Cause

The Phoenix/Tucson/Chicago active lane window produced two clean reviewed leads in batch 030, but the collector also repeated high timeout and HTTP failure noise across most niches. Health reported `recent_failure_noise:42` after the pass.

## Fix

Forced `scripts/rotate-source-lanes.ps1` after the run was fully reviewed, merged, rejected, audited, and committed. The active lane window advanced to:

- Indianapolis, IN
- Louisville, KY
- Birmingham, AL

## Safety

The rotation only changed `config/source-lanes.json`. It did not alter master lead data, pending artifacts, rejected artifacts, or archived recovery data. This keeps the next collector run productive without overlapping collectors or retrying the same timeout-heavy lane window.
