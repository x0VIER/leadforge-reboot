# Lead Pipeline

## Core agents

- `Hermes`: supervisor, run control, and momentum tracking
- `Elena Voss`: public-source research and evidence gathering
- `Marcus Hale`: scoring, validation, and priority tiering
- `Sophia Lang`: offer angle drafting for P0 and P1 leads
- `Lena Moreau`: human-reviewed outreach packaging

## New support agents

- `Quinn Slate`: dedupe and master-database merge control
- `Rowan Pike`: QA checks for schema, missing fields, and source hygiene

## Run flow

1. Create a run folder and manifest.
2. Collect candidate businesses from public websites, directories, or search results.
3. Store raw candidate rows in the run folder.
4. Review evidence, visible gap, and offer angle.
5. Score and tier the leads.
6. Merge approved rows into `data/master_leads.csv`.
7. Log the run and preserve all artifacts.

## Safety boundaries

- Public business data only
- No automated outreach
- No paid API assumptions
- Human review before anything leaves the system
