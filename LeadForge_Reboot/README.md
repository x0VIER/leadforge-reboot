# LeadForge Reboot

This subfolder is the new working project inside the recovered `AGR 1226` archive.

It exists to keep the original recovery files untouched while giving us a clean, versioned place to:

- preserve the recovered lead schema
- run fresh public-data sourcing batches
- store rebooted agent definitions
- log each run so the project never has to be rebuilt from memory again

## What stays unchanged

The parent folder still contains the recovered source artifacts:

- `Recovered_Leads_Database.csv`
- `Chat_History_Transcript_Summary.md`
- the original agent dossiers
- `LeadForge_Control_Center/`

This reboot project reads those files for reference and deduplication. It does not overwrite or delete them.

## Workflow

1. `npm run source:batch`
2. Review the newest CSV in `data/output/`
3. Keep qualified rows moving into your review or outreach flow
4. Commit changes so the sourcing history is preserved

See `docs/operating-rules.md` for the durable Codex rules that govern automation behavior, lead quality, cadence, dedupe, evidence, and recovery from errors.

## Current objective

Re-create the lead generation motion from the recovered project with a reproducible Node pipeline that gathers only public business data, scores visible contact friction, and writes fresh leads in the same schema as the recovered database.
