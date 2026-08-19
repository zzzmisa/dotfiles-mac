---
name: zzzmisa-sns-post
description: Draft or edit posts for X, Facebook, or YouTube Shorts. Use for X投稿, tweet, SNS投稿, リリース告知, or Shorts title/description. Verify repository facts only for app-related posts; do not use for editing video files.
---

# SNS投稿文の作成・添削

MisaのSNS投稿文を作成・添削する。アプリ関連では、実仕様との整合を特に重視する。

## Workflow

1. `references/platform-rules.md` を先に読む。
2. 投稿先プラットフォーム（X / Facebook / YouTube Shorts）を確認する。指定がなければ聞く。
3. アプリ関連の投稿だけ、**文言が対象アプリの実仕様と矛盾しないか確認する**（最重要）。
   - アプリのリポジトリの README / docs と、エージェントのメモリにあるアプリ別制約を確認する。
   - 例: 「無料」は今後の課金予定と、「オフライン」はオンライン機能の有無と矛盾しないか。
   - 効果を保証する表現（「必ず」「絶対」）や、実装されていない機能への言及は書かない。
   一般的な個人投稿では、このリポジトリ確認を省略する。
4. トーンガイドに沿って下書きし、プラットフォーム別ルール（リンク位置・ハッシュタグ数・動画の扱い）を適用する。
5. 添削の場合は、元の文の意図と語彙をできるだけ残し、直した箇所と理由を短く添える。

## 原則

- **事実の報告 > 効果の主張**。宣伝文らしさが出たら削る。
- App Storeリンクは国コードを使い分ける（日本語向け `/jp/`、英語向け `/us/`）。
- 最終的な投稿はMisa自身が行う。エージェントは下書きまで。
