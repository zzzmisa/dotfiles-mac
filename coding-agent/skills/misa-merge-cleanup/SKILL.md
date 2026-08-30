---
name: misa-merge-cleanup
description: Safely remove local branches and worktrees only after confirming their PRs are merged. Use when told a PR was merged, asked to 掃除・後片付け, or before a new task when stale worktrees may exist.
---

# マージ後の後片付け

PRが既にマージされたローカルブランチとworktreeを削除する。未マージの作業は絶対に
消さない。判断がつかないものは、削除せず報告する。

## Workflow

1. **デフォルトブランチに戻して更新する。**
   ```
   git switch main   # main か master か、リポジトリのデフォルトブランチを確認する
   git pull
   ```
2. **機械的な一次処理を流す。**
   ```
   "$HOME/dotfiles-mac/bin/common/misa-delete-merged-local-branches"
   ```
   `git fetch --prune` を実行したうえで、Gitがマージ済みと判定できるブランチ
   （`git branch --merged`）を、worktreeを先に削除してからブランチごと削除する。
   保護ブランチ（`main`、`master`、`develop`、`dev`、現在のブランチ）はスキップし、
   worktreeの削除に失敗したもの（未コミットの変更がある等）はブランチごとスキップする。
   リポジトリのデフォルトが `main` でない場合は、ベースブランチを引数で渡す。
3. **squashマージされたブランチを処理する** — スクリプトはこれを検出できない。
   保護ブランチを除く残りのブランチそれぞれについて:
   - 状態を確認する:
     ```
     gh pr view <branch> --json state,mergedAt
     ```
   - PRの状態が `MERGED` のときだけ処理する。worktreeがある場合は先に `git status` を
     確認し、未コミットの変更があれば削除しない（報告してスキップ）。無ければ
     `git worktree remove <path>` してから `git branch -D <branch>` で削除する。
   - PRが無いブランチ、オープンなPRのブランチ、未pushのコミットがあるブランチは
     削除しない。報告に一覧として載せる。
4. **worktreeのメタデータを掃除する。**
   ```
   git worktree prune
   ```
5. **報告する**: 削除したもの（ブランチ・worktree）と、残したものとその理由
   （未コミットの変更あり、PRがオープン、PRが見つからない）。

## Guardrails

- マージ済みだと確証が取れないブランチ・worktreeは削除しない。ゴミが残るコストより、
  作業を失うコストのほうが高い。
- `gh pr view` で `MERGED` を確認せずに `git branch -D` を使わない。
- リモートブランチには触らない。GitHubの「マージ時にブランチを削除」と
  `git fetch --prune` が処理する。
- stashや未コミットの変更は削除しない。報告に載せて可視化する。
