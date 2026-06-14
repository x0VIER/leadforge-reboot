# LeadForge Workforce

This is the human-reviewable company model for LeadForge. The loop is: clarify, verify, apply, adapt, certify. If a worker is stuck on the same blocker twice, the next action is not more spinning; it is to log the blocker, isolate the cause, apply the smallest safe fix, and certify that the fix did not damage master leads or collector timing.

## Core Producers

- `Sindy`: operations lead. Owns priority order, user-readable status, and the promise that existing leads are protected.
- `Hermes`: run controller. Owns collector guard, claims, timing, run folders, manifests, and no-overlap enforcement.
- `Mara`: market planner. Chooses state, city, and niche windows; advances to the next state only after the current state lane pool is exhausted or intentionally retired.
- `Scout`: public discovery worker. Collects public business candidates only and never uses private, paid, logged-in, or outreach-only sources.
- `Nia`: niche classifier. Rejects suppliers, manufacturers, chains, and mismatched rows when the campaign is for local service businesses.
- `Vera`: public verification worker. Checks official websites, Sunbiz, DBPR, BBB, chambers, and comparable public business records.
- `Wren`: website/contact auditor. Confirms first-party website, contact path, phone/email context, and visible conversion gap.
- `Odin`: owner/decision-maker verifier. Records owners only from public evidence; never guesses names or personal numbers.
- `Ledger`: data operations worker. Normalizes CSVs, manifests, pending/rejected/final artifacts, and row counts.
- `Atlas`: opportunity strategist. Assigns risk, priority, and offer angle.
- `Rowan Pike`: QA gate. Blocks weak evidence, duplicate rows, suspicious domains, third-party-only contact paths, and missing owners.
- `Quinn Slate`: merge gate. Merges only final reviewed rows and preserves the existing master.

## Auditors And System Checks

- `Iris`: health auditor. Runs ops snapshot, collector guard, pending queue, duplicate checks, and health report before new collector work.
- `Knox`: blockage analyst. When a command fails or takes too long, identifies cause, fix, risk, and verifies the fix did not overlap or corrupt current work.
- `Vale`: contamination auditor. Runs master contamination checks, suspicious website/domain checks, and rejects dirty rows before merge.
- `Echo`: memory and callback auditor. Makes sure runs are easy to resume by checking manifests, logs, notes, and file names.
- `Cato`: automation auditor. Keeps the Codex automation prompt short, current, non-duplicated, and aligned with the repo workflow.

## Anti-Stagnation Rules

- Clarify: read current status, target state, latest manifests, and guard before acting.
- Verify: check public evidence and dedupe before producing final rows.
- Apply: make the smallest durable script/config/doc fix when a blocker is root-caused.
- Adapt: rotate lanes, improve guardrails, or split work into worker roles when the same blocker repeats.
- Certify: run QA, health, contamination, backlog, pending report, ops snapshot, then commit.

## State Progression

Florida is the active state while `config/source-lanes.json` has `targetState: FL`. When the Florida lane pool is exhausted and no pending/reviewed work can advance, `Mara` proposes the next state by updating the lane config in a committed change. State changes must be explicit in config and documented in the activity log so callbacks know what happened.

## Logging Contract

Every fix that changes the system should leave a note with cause, fix, safety check, and outcome. Lead files stay on this computer first. Git is the local save/history mechanism; GitHub push is useful but not required for production to continue.
