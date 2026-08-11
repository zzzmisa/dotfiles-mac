---
name: zzzmisa-ios-release
description: Run Misa's iOS App Store release flow - version bump, build upload, store assets (screenshots/previews/metadata) sync to App Store Connect, GitHub release draft, and review submission. Use when asked to リリース準備, release a new version, upload a build to ASC, or 審査提出 an iOS app.
---

# iOS App Store Release

Misaの個人開発iOSアプリのリリースフロー。プロジェクト固有の手順（fastlaneレーン名・
素材の作り方など）は各リポジトリの `docs/app-store-fastlane.md` と `promo/README.md` を
先に確認し、このスキルは共通の流れと約束事として使う。
ストア素材の置き場所と命名の規約は `zzzmisa-store-assets`。

Read [references/asc-checklist.md](references/asc-checklist.md) before the ASC
upload and submission steps (credentials, pre-submission checks, known pitfalls).

## 大原則（Guardrails）

- **審査提出はMisaの明示的な指示があってから実行する**。自律判断では提出しない。
  それ以前（ビルド、ASCアップロード、ドラフトへのメタデータ・スクショ・プレビュー流し込み、
  GitHubリリース下書き）は指示がなくても進めてよい。
- **ユーザーの目に触れる文言**（`release_notes.txt`、ストア説明文、スクショのキャプション等）を
  新規作成・変更したときは、**提出前に必ずチャットで全文を見せて確認を取る**。
- **リリース公開（承認後の公開ボタン）とPRマージはMisaが行う**。エージェントは行わない。
- タグ・GitHubリリースの公開は、審査が通ってリリースバージョンが確定してから
  （Misaから連絡が来る。それまでは下書きのまま）。

## リリースフロー

1. **変更内容の確認**
   - 前回リリースからの差分を確認する（`git log <前回タグ>..main --oneline`）。
   - リリースに含める変更がすべてmainにマージ済みであることを確認する。

2. **ストア素材の更新（UIに変更がある場合）**
   - 今回の変更がストア掲載中の画面や文言に影響するか確認する。既存素材が現在の内容と一致し、
     素材ファイルも未変更なら、再作成・再アップロードしない。
   - UIに変更があり、**エージェントが撮れる画面**（シミュレータで再現できる画面）は、
     スクリーンショットを再撮影して `fastlane/screenshots/` を更新し、PRを作成する。
     撮影は screenshot 用シミュレータ（`Screenshot iPhone 14 Plus` = 6.5インチ、
     `Screenshot iPad Pro 13-inch` = 13インチ）を使う（`zzzmisa-install-ios-simulator` 参照）。
   - エージェントが撮れない画面（カメラ実写など実機でしか撮れないもの）は、
     Misaに再撮影を依頼するか既存素材を流用する。
   - プレビュー動画に影響がある場合は、差し替えるかMisaに確認する。承認後に
     `fastlane/previews/{locale}/{iphone,ipad}.mp4` を更新する。キャプションや加工が必要な場合は、
     各リポジトリの制作レシピ（`promo/app-store/README.md`）と `promo/scripts/` のスクリプトに従う。

3. **リリースノートの起草**
   - `fastlane/metadata/{ja,en-US,zh-Hans}/release_notes.txt` を更新する。
   - 書式: **箇条書き（行頭は「- 」）、体言止め**。例:
     ```
     - ひらがな表示の分かち書き（ことばの区切り）を改善
     - 図鑑カードの表示を調整
     ```
     変更が1件でも「- 」から始める。全対応言語で同じ内容にする。
   - **チャットで3言語の全文を見せて承認を得てから**次へ進む。

4. **バージョンバンプとビルドアップロード**
   - **最新のmainをビルドしてアップロードする**（作業ブランチのビルドは上げない）。
   - バージョンは `1.0.1` のような `MARKETING_VERSION` 形式。
     **ビルド番号（`CURRENT_PROJECT_VERSION`）はバージョンを跨いだ通しの連番**
     （例: 1.0.0が1〜3なら、1.0.1は4から）。
   - `release-<version>-build-<N>` ブランチでバンプし、PRを作成する。
   - archive → export → アップロードの具体的なコマンドは references を参照。

5. **ASCドラフトへの流し込み**
   - メタデータ、スクリーンショット、プレビュー動画のうち、変更したものだけを同期する。
   - メタデータ＋変更済みスクリーンショット:
     `fastlane ios upload_store_metadata version:<version>`
   - メタデータのみ: レーンの対象指定またはASC APIで直接パッチする。
   - **変更済みプレビュー動画がある場合のみ**:
     `fastlane ios upload_store_previews version:<version>`
   - 同期後は references のチェックリストで検証する（重複スクショの既知バグあり）。
   - ビルドの処理完了（VALID）を待ち、バージョンドラフトに紐付ける。

6. **GitHubリリースノートの下書き更新**
   - `gh release create v<version> --draft --title "v<version>" --notes <本文>`
     （既存の下書きがあれば `gh release edit` で更新）。
   - 本文はASCのリリースノート（日本語）＋主なPRへのリンク。提出ビルドを作った
     mainのcommit hashも記載しておく（タグを打つ位置の記録）。
   - **下書きのままにする**（publishしない。下書きはタグを作らない）。

7. **審査提出（Misaの明示指示後のみ）**
   - references の提出前チェックリストを通してから提出する。
   - 提出後の状態（WAITING_FOR_REVIEW）を確認して報告する。
   - 文言修正などで取り下げる場合: 提出取り消し→修正→再提出はペナルティなし。
     取り消し後にバージョンが `DEVELOPER_REJECTED` 表示になるのは正常。

8. **審査通過後（Misaから連絡が来たら）**
   - GitHubリリースの下書きを、記録しておいたcommitを対象に publish する
     （このときタグ `v<version>` が作られる）。
   - リリース公開の操作自体はMisaが行う。

## リジェクト時

- Resolution Center のメッセージは ASC API で取得できる
  （`ReviewSubmission#latest_resolution_center_messages`）。内容を確認して対応方針を報告し、
  修正→再提出はこのフローを再度実行する。
