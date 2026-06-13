# Lead Data Schema

## Canonical columns

- `lead_id`
- `business_name`
- `niche`
- `city`
- `state`
- `website`
- `public_phone`
- `public_email`
- `contact_url`
- `owner_name`
- `owner_title`
- `owner_source`
- `source_type`
- `source_query`
- `source_evidence`
- `visible_gap`
- `offer_angle`
- `risk_score_1_5`
- `validation_status`
- `priority_tier`
- `last_checked`

## Research standard

- `owner_name`, `owner_title`, and `owner_source` should be filled from an official company page first, then a public state corporate registry when needed.
- `source_evidence` should explain why the row is valid using short public-facing facts, not vague summaries.
- `visible_gap` should describe a real conversion or intake weakness visible from public pages.
- `offer_angle` should be specific enough to route into an audit or outreach draft later.
- `validation_status` should only mark rows as validated when at least two public contact signals are present or the public evidence is otherwise strong.

## Merge behavior

- New reviewed rows can add net-new leads.
- Reviewed duplicates should enrich blank fields on existing master rows instead of being discarded.
- Archive snapshots stay immutable; only `data/master_leads.csv` is the live merge target.
