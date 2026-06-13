# Restart Plan

## Goal

Resume LeadForge as a durable local repo with a repeatable public-data lead workflow, keeping the recovered archive intact and moving all new production work into `LeadForge_Reboot`.

## What was recovered

- The agent roles and handoff model
- A reconstructed lead database with 501 rows
- Historical operating notes for the May 2026 sourcing sprints
- Control-center docs describing trigger-based sourcing and review

## What changes now

- Git now protects the whole recovered project root.
- New runs get isolated folders and manifests.
- The archived CSV is preserved as an immutable snapshot.
- Future batches merge through a repeatable dedupe script instead of ad hoc copy/paste.

## Immediate next loop

1. Analyze the baseline and assign lead IDs in the new master file.
2. Create a fresh run folder.
3. Source a small public batch in the same schema.
4. Review, score, and merge approved rows into the master file.
5. Repeat by niche and city.
