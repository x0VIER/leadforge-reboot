# LeadForge Reboot Architecture

## Principles

- Preserve all recovered material exactly as found.
- Generate fresh leads from public sources only.
- Deduplicate against the recovered master CSV before writing new outputs.
- Keep every sourcing run reproducible through config, scripts, and logs.

## Reboot pipeline

1. `Sindy` opens a new sourcing sprint and chooses the active lane config.
2. `Hermes` runs the batch script and records the run log.
3. `Elena Voss` handles public discovery using Overpass business records and website signals.
4. `Marcus Hale` scores data quality, filters weak rows, and assigns priority tiers.
5. `Sophia Lang` can later turn qualified rows into offer angles and outreach hooks.

## Output contract

Every generated lead row follows the recovered CSV schema:

- `lead_id`
- `business_name`
- `niche`
- `city`
- `state`
- `website`
- `public_phone`
- `public_email`
- `contact_url`
- `source_type`
- `source_query`
- `source_evidence`
- `visible_gap`
- `offer_angle`
- `risk_score_1_5`
- `validation_status`
- `priority_tier`
- `last_checked`

## Safety

- Public data only
- No form submissions
- No automated outreach
- No paid APIs
- No deletion of recovered project files
