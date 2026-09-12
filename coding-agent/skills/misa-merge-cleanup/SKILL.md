---
name: misa-merge-cleanup
description: マージ後の片付け依頼や新しい作業前の点検で、ローカルブランチとworktreeの削除可否を調べる。マージ済みPRとローカルの状態を確認し、削除が許可された対象だけを片付ける。
---

# マージ後の後片付け

削除するのは、PRがマージ済みで、その後の作業が残っていないローカルブランチと
worktreeだけ。片付け依頼に含まれる対象は確認後に処理する。単にマージを知らされた場合や
新しい作業前の自動点検では、既存の削除許可がなければ候補の調査まで進める。

## 削除前の確認

1. `git status --short` と `git worktree list --porcelain` で作業中の変更・配置を確認する。
   デフォルトブランチはリポジトリ情報で特定し、`main` と決めつけない。
2. 対象リポジトリを明示してGitHubのPR情報を取得し、対象ブランチに対応するPRの
   `MERGED`、headリポジトリ、headブランチ、マージ時のhead SHAを確認する。
   同名ブランチの古いPRや別リポジトリのPRを根拠にしない。
3. ローカル先端とマージされたPRのhead SHAが一致することを確認する。
   squashマージではデフォルトブランチへの祖先判定だけで決めない。
   SHAを取得できない場合や不一致の場合は、その後のコミットが残っている可能性があるため保留する。
4. 対象worktreeの未コミット・未追跡ファイル、進行中のmerge/rebase、他タスクの利用を確認する。
   未保存の作業や利用中のworktreeは残す。ロックされたworktreeも強制解除しない。

必要な同期は `git fetch --prune` で行う。片付けのために変更をstashしたり、無条件に
`git switch` / `git pull` を実行したりしない。現在使用中のworktreeを削除する必要がある場合は、
安全な作業場所へ移動できることを確認してから行う。

## 削除と報告

- デフォルトブランチ、`main`、`master`、`develop`、`dev`、現在のブランチは保護する。
- 確認済みのworktreeを `git worktree remove <path>` で削除し、成功後にブランチを
  `git branch -d <branch>` で削除する。worktree削除に失敗したらブランチも残す。
- squashマージ等で `-d` が拒否した場合だけ、上記のPR・SHA・作業状態の確認が揃った
  対象に `git branch -D <branch>` を使う。worktreeの `--force` は使わない。
- リモートブランチ、stash、未コミットの変更は削除しない。
- 削除した対象と、残した対象・理由を簡潔に報告する。根拠が不足するものは保留する。

`~/dotfiles-mac/bin/common/misa-delete-merged-local-branches` はGitの祖先関係による
一括削除であり、PRの有無・マージ後の作業をこの手順と同じようには検証しない。
このスキルのPR確認を代替するものとして実行しない。
