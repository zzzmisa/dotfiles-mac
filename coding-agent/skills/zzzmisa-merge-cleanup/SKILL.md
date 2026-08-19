---
name: zzzmisa-merge-cleanup
description: Safely remove local branches and worktrees only after confirming their PRs are merged. Use when told a PR was merged, asked to 掃除・後片付け, or before a new task when stale worktrees may exist.
---

# Merge Cleanup

Remove local branches and worktrees whose PRs are already merged, without ever
deleting unmerged work. When in doubt, report instead of delete.

## Workflow

1. **Return to the default branch and update it.**
   ```
   git switch main   # or master — check the repo's default branch
   git pull
   ```
2. **Run the mechanical first pass.**
   ```
   "$HOME/dotfiles-mac/bin/zzzmisa-delete-merged-local-branches"
   ```
   This runs `git fetch --prune`, then deletes local branches Git can prove
   are merged (`git branch --merged`), removing each branch's worktree first.
   Protected branches (`main`, `master`, `develop`, `dev`, current branch) are
   skipped, and worktrees that fail to remove (e.g. uncommitted changes) are
   skipped with their branches. Pass a base branch argument if the repo's
   default is not `main`.
3. **Handle squash-merged branches** — the script cannot detect these. For
   each remaining branch except the protected ones:
   - Verify with:
     ```
     gh pr view <branch> --json state,mergedAt
     ```
   - Only when the PR state is `MERGED`: if the branch has a worktree, check
     its `git status` first — if it has uncommitted changes, do NOT remove it;
     report it and skip. Otherwise `git worktree remove <path>`, then delete
     the branch with `git branch -D <branch>`.
   - A branch with no PR, an open PR, or unpushed commits is NOT deleted;
     list it in the report instead.
4. **Prune worktree metadata.**
   ```
   git worktree prune
   ```
5. **Report**: what was deleted (branches, worktrees), and what was kept with
   the reason (uncommitted changes, open PR, no PR found).

## Guardrails

- Never delete a branch or worktree whose merge status cannot be positively
  confirmed; keeping garbage is cheaper than losing work.
- Never use `git branch -D` without confirming `MERGED` via `gh pr view`.
- Do not touch remote branches; GitHub's "delete branch on merge" and
  `git fetch --prune` handle those.
- Do not delete stashes or uncommitted changes; surface them in the report.
