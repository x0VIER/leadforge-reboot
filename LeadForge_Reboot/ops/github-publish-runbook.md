# GitHub Publish Runbook

The LeadForge repo root is:

```powershell
C:\Users\loc9o\Desktop\AGR 1226
```

The local branch is `master`.

## Current blocker

The local `gh` CLI is installed but not authenticated, and the GitHub connector available to Codex can write to existing repositories but does not expose repository creation. Chrome is signed in, but GitHub repository creation is blocked while an extension UI is open on the GitHub page.

## Finish publish after GitHub repo exists

Create an empty GitHub repository, then run:

```powershell
cd "C:\Users\loc9o\Desktop\AGR 1226"
git remote add origin https://github.com/x0VIER/<repo-name>.git
git push -u origin master
```

If `origin` already exists, update it instead:

```powershell
git remote set-url origin https://github.com/x0VIER/<repo-name>.git
git push -u origin master
```

## CLI auth fallback

If Chrome creation remains blocked, authenticate the local GitHub CLI:

```powershell
gh auth login
gh repo create x0VIER/leadforge-reboot --private --source "C:\Users\loc9o\Desktop\AGR 1226" --remote origin --push
```
