# LeadForge Offer Audit Engine

The Offer Audit Engine is a sidecar loop for LeadForge. The lead factory finds and verifies public business leads; this engine turns those leads into qualified, human-readable selling opportunities.

## Why This Exists

The master lead database answers: who is the business, where are they, and what public evidence proves the row is real?

The offer engine answers: what do they likely need, how ready is the lead, what public contact path can be used, and what value-first audit should be prepared before outreach?

## Loop Design

This follows loop-engineering practice: scheduled work, durable state on disk, skills/docs instead of repeated prompts, maker/checker separation, and memory outside the conversation. The engine should not re-explain itself every run; it reads config, master data, status reports, and writes fresh sidecar artifacts.

## Public OSINT Rules

Allowed:

- Official business websites and contact pages.
- Public business social profiles.
- Public owner or decision-maker profiles only when used for business identity evidence.
- State registries, licensing boards, BBB, chambers, and credible directories.
- Public reviews/listing facts when manually reviewed and documented.

Not allowed:

- Guessed private owner numbers.
- Personal contact data not published for business use.
- Breached/private/paid datasets.
- Outreach automation through SMS or WhatsApp without opt-in, consent, and opt-out workflow.

## Qualification Model

LeadForge uses a blended local-service qualification score:

- Authority: owner or decision-maker evidence exists.
- Need: website, SEO, GEO, reviews, local listing, or conversion gap is visible.
- Contactability: public business phone, public email, or contact URL exists.
- Evidence strength: validation status and source evidence are strong.
- Risk: low duplication, clean domain, and low mismatch risk.
- Local fit: service niche and city are suitable for local search/listing offers.

BANT is useful for fast triage, MEDDIC-lite is useful for deeper account planning, and GPCT is useful for value-first discovery. The engine is intentionally not one-framework-only because small local businesses often reveal need and authority before budget or timeline.

## Offer Families

- AI Website / No Website Rescue: for missing or weak websites.
- AI SEO and GEO Audit: for businesses with websites that need better search and answer-engine visibility.
- Reviews and Local Prominence: for businesses where trust, reviews, citations, and local reputation can move outcomes.
- Best Services Listing Spot: for high-fit local categories where a curated local directory can become an offer.
- Conversion Path Cleanup: for sites with weak contact forms, unclear CTAs, phone-only friction, or third-party-only booking paths.

## Human Review Outputs

The engine writes:

- `agent_shared/status/OFFER_READINESS_REPORT.csv`
- `agent_shared/status/OFFER_READINESS_REPORT.json`
- `agent_shared/status/OFFER_READINESS_REPORT.md`
- Workbook tabs: `Owner Contact Points`, `Offer Readiness`, and `Qualification Guide`

These outputs are for review and planning. They do not send outreach and they do not mutate `data/master_leads.csv`.

## Owner Number Rule

Owner-direct numbers are only stored when a public business source clearly publishes that number for business contact. Otherwise, the viewer shows the public business phone and a note that no owner-direct number is verified. This keeps the data useful without crossing into guessed or private contact data.

## Sources Used For The Design

- Addy Osmani, Loop Engineering: https://addyosmani.com/blog/loop-engineering/
- Salesforce, BANT vs MEDDIC: https://www.salesforce.com/blog/sales/bant-vs-meddic/
- HubSpot, GPCT sales qualification: https://blog.hubspot.com/sales/gpct-sales-qualification
- Google Business Profile local ranking factors: https://support.google.com/business/answer/7091?hl=en
- Twilio SMS opt-in and opt-out guidelines: https://www.twilio.com/en-us/blog/insights/compliance/opt-in-opt-out-text-messages
- Twilio WhatsApp compliance guidance: https://www.twilio.com/en-us/lp/global-regulatory-compliance-guide-marketers/chapter-2
