---
name: zzzmisa-merge-cleanup
description: Clean up merged branches and stale git worktrees safely. Use when Misa says a PR was merged (マージしました, マージ済み, merged), when asked to clean up or 掃除 branches/worktrees, or right before creating a new working branch for a new task (sweep leftovers from previous merged work first).
---

# Merge Cleanup

Remove local branches and worktrees whose PRs are already merged, without ever
deleting unmerged work. When in doubt, report instead of delete.

## Workflow

1. **Sync remote state.**
   ```
   git fetch --prune
   ```
2. **Return to the default branch and update it.**
   ```
   git switch main   # or master — check the repo's default branch
   git pull
   ```
3. **Clean up worktrees** (`git worktree list`):
   - For each worktree other than the main one, check its branch and its
     `git status`.
   - If the worktree has uncommitted changes, do NOT remove it; report it and skip.
   - If its branch is confirmed merged (step 4 criteria), remove with
     `git worktree remove <path>`, then `git worktree prune`.
4. **Clean up local branches.** For each branch other than the default branch:
   - `git branch -d <branch>` — succeeds only for branches Git knows are merged.
   - If `-d` fails, the branch may still be merged via **squash merge** (Git
     cannot detect this). Verify with:
     ```
     gh pr view <branch> --json state,mergedAt
     ```
     Only when the PR state is `MERGED`, delete with `git branch -D <branch>`.
   - A branch with no PR, an open PR, or unpushed commits is NOT deleted;
     list it in the report instead.
5. **Report**: what was deleted (branches, worktrees), and what was kept with
   the reason (uncommitted changes, open PR, no PR found).

## Guardrails

- Never delete a branch or worktree whose merge status cannot be positively
  confirmed; keeping garbage is cheaper than losing work.
- Never use `git branch -D` without confirming `MERGED` via `gh pr view`.
- Do not touch remote branches; GitHub's "delete branch on merge" and
  `git fetch --prune` handle those.
- Do not delete stashes or uncommitted changes; surface them in the report.
