# 2026-06-14 Clean Automation Reset

## What Changed

- Deleted the old noisy Codex heartbeat automation `leadforge-florida-loop`.
- Created a clean replacement heartbeat automation named `LeadForge Factory Loop`.
- New automation id: `leadforge-factory-loop`.
- Schedule: every 30 minutes.
- Scope: continue LeadForge from `C:\Users\loc9o\Desktop\AGR 1226`.

## Operating Rules

- Local computer git commits are the primary save point.
- GitHub remote/push stays available but optional.
- Collector runs must use `scripts/run-collector-guarded.ps1`.
- No raw merges, no overlapping collectors, no overwriting master rows.
- Finish staged/reviewed work before opening new collector work.
- Log durable system fixes and commit them locally.

## Reason

The old automation prompt had grown too long and noisy. This reset keeps the heartbeat concise and aligned with the current guarded collector, health checks, reviewed-only merge rules, and local-first save policy.

## First Follow-Up

After the reset, the guarded collector ran the final Florida window (`Largo`, `Plantation`) and returned `complete_no_rows`. Because that was the end of the Florida lane pool, the source config was advanced to Georgia with a smaller guarded batch window.
