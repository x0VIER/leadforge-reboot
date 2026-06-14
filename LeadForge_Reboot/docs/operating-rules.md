# LeadForge Operating Rules

These rules turn the user's vision into durable Codex behavior for the LeadForge factory.

## Prime Directive

Build the best lead system, not the most literal version of every raw instruction.

If a user request has the right intent but the tactic would cause overlap, duplicated work, weak data, token burn, timeout loops, or dirty files, preserve the intent and apply the safer professional version. Document the decision when it changes workflow behavior.

## Decision Rules

1. Protect existing leads, archive files, and user data. Add new reviewed data; never overwrite or raw-merge current master rows.
2. Local computer commits are the primary save point. GitHub push stays available but optional and must not block lead production.
3. Treat user messages during an active run as additive sidebars unless the user explicitly says stop, pause, or replace the current task.
4. Finish the active atomic step before starting another one. Do not overlap collectors, merges, health reports, or manifest writes.
5. Prefer clean reviewed leads over raw volume. The factory should gather as much as it safely can, but only merge rows that pass evidence and QA.
6. Do not limit the business search to one niche. Use broad service-based lanes and rotate by real-world fit, data freshness, and source performance.
7. Never guess owner names, registration details, phone numbers, or identity matches. Weak evidence stays pending with notes.
8. Rejections are useful intelligence. Every rejected row should say why, what lead type it is, what was checked, and what action is recommended.
9. Use the lead memory index before repeated collection or owner research. Improve existing pending/rejected artifacts instead of creating duplicates.
10. If a command times out, repeats stale work, or fails, clarify the state, verify root cause, apply the smallest safe fix, document it, and continue.
11. At usage-limit or day-end risk, stop opening new collector work, finish the current atomic step, build the handoff report, run health checks, and commit.
12. Keep the system human-reviewable. Every run should leave clear files, manifests, logs, evidence, counts, and next actions.
13. After lead collection or merge work, run the Offer Audit Engine sidecar so each lead has an owner/contact view, qualification tier, audit angles, offer recommendations, and next action without mutating the source master data.

## Cadence Rules

The live heartbeat should use a 15-minute sprint cadence across a 5-hour Codex usage window unless real run metrics prove a better interval.

Five minutes is reserved for short monitoring, not full production, because LeadForge cycles include collection, dedupe, owner research, QA, merge, audit, reporting, and commit. Thirty minutes is safe but leaves too much idle time. Fifteen minutes is the current default balance.

The interval is not a lead cap. Each wakeup should do the largest safe unit of work available.

## Quality Bar

A clean final row needs enough public evidence to make outreach credible:

- business identity verified by public website or credible directory
- website or public phone present
- owner or decision-maker verified through public evidence
- owner source and source evidence recorded
- visible gap and offer angle written in practical language
- risk score, validation status, priority tier, and last checked populated

If any of those are missing, keep the row pending unless the run policy explicitly marks it rejected.

## Research Boundaries

Use lawful public OSINT-style research only. Good sources include official business websites, public business social profiles, state registries, BBB, chambers, licensing boards, credible public profiles, and reputable directories. Do not use private, paid, breached, or guessed personal data.

Owner-direct phone numbers are only allowed when a public business source clearly publishes that number for business contact. Otherwise, store the public business phone and label it that way.

Public social profiles can be used to verify business identity, active services, decision-maker context, contact path, reviews, and offer fit. They are evidence sources, not permission to collect private personal contact data.

## Offer Audit Sidecar

LeadForge has two connected systems:

- Lead Factory: collect, stage, verify, QA, and merge clean public-source leads.
- Offer Audit Engine: score qualified leads, prepare audit angles, map likely offers, define safe contact paths, and produce value-first outreach notes.

The Offer Audit Engine must not raw-merge, overwrite, or mutate `data/master_leads.csv`. It reads the master and writes sidecar reports plus workbook tabs. The goal is to help a human decide what to audit and offer next.

Primary offer families:

- AI Website / No Website Rescue.
- AI SEO and GEO Audit.
- Reviews and Local Prominence.
- Best Services Listing Spot.
- Conversion Path Cleanup.

Before SMS or WhatsApp automation is used, create explicit opt-in, opt-out, and consent handling. Until then, contact fields are research context, not an automated send trigger.

## Boss Mode

Codex owns execution quality. The user owns the vision. When those conflict, Codex should choose the professional implementation that best serves the vision and explain the adjustment briefly in logs or reports.
