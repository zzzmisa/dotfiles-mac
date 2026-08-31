---
name: zzzmisa-ios-release
description: iOS App Storeのリリースを整合・準備・提出する。ASC公開後に欠けているGitHubのタグ・Releaseの復旧、ASCとGitの状態確認、バージョンとストア素材の更新、ビルドのアップロードを行う。週次リリース準備、公開後処理、タグ・GitHub Release作成、ASCアップロード、メタデータ同期、審査提出で使う。審査提出は明示的な指示があったときだけ実行する。
---

# iOS App Storeリリース

Misaの個人開発iOSアプリのリリースフロー。プロジェクト固有の手順（fastlaneレーン名・
素材の作り方など）は各リポジトリの `docs/app-store-fastlane.md` と `promo/README.md` を
先に確認し、このスキルは共通の流れと約束事として使う。
ストア素材の置き場所と命名の規約は `zzzmisa-store-assets`。

**リリースではなく動作確認のためにTestFlightへ上げたいだけの場合は、このスキルではなく
`zzzmisa-install-ios` の TestFlight リファレンスを使う**（バージョンバンプ・ストア素材・
タグ・審査提出を伴わない確認用ビルド）。

実施するステップに対応するリファレンスだけを読む:

- アーカイブ・エクスポート・バイナリのアップロード: [references/build-upload.md](references/build-upload.md)
- メタデータ・スクリーンショット・プレビューの同期: [references/store-sync.md](references/store-sync.md)
- 審査提出・提出の取り消し: [references/review-submission.md](references/review-submission.md)

リリース対象の判定を始める前に、`scripts/asc_release_state.rb` でASC上の公開済み版・
作業中バージョン・VALIDビルドを確認し、GitHubのタグ・Releaseと照合する。
**Misaからの公開報告、Gitタグ、automation memoryだけを前回リリースの根拠にしない**。

## 大原則（Guardrails）

- **審査提出はMisaの明示的な指示があってから実行する**。自律判断では提出しない。
  それ以前（ビルド、ASCアップロード、ドラフトへのメタデータ・スクショ・プレビュー流し込み、
  GitHubリリース下書き）は指示がなくても進めてよい。
- **ユーザーの目に触れる文言**（`release_notes.txt`、ストア説明文、スクショのキャプション等）を
  新規作成・変更したときは、**提出前に必ずチャットで全文を見せて確認を取る**。
- **リリース公開（承認後の公開ボタン）とPRマージはMisaが行う**。エージェントは行わない。
- **ASCを公開状態の正とする**。`READY_FOR_DISTRIBUTION`（旧APIの `READY_FOR_SALE` を含む）を
  確認するまで、タグとGitHub Releaseは公開せず下書きのままにする。Misaからの報告は
  公開後処理を早く始めるための合図として扱い、報告がなくてもASCから公開を検出する。
  公開済みのマーケティングバージョンへ新しいビルドを提出しない。
- GitHub APIでリポジトリの可視性を毎回確認する。**非公開リポジトリでは**、ASC公開済み版に
  対応するタグ／GitHub Releaseの自動作成・公開を許可し、次回の週次実行でも未完了分を補完する。
  **公開リポジトリでは**自動公開せず、Misaの内容確認と明示指示を待つ。
- ASC公開版とGitHubの不一致を検出したら、次版のPR作成、バージョン変更、ビルド、素材同期より
  先に前回版を復旧する。安全に復旧できない場合だけ停止し、不整合と必要な対応を報告する。
- automation memoryは前回結果の補助情報としてのみ使い、ASCとGitの照合結果で必ず上書きする。

## リリースフロー

1. **ASC・GitHub・Gitの照合と復旧（毎回最初に必ず実行）**
   - `source ~/.appstoreconnect/asc.env` 後、リポジトリのBundle IDを指定して実行する:
     `bundle exec ruby <skill-dir>/scripts/asc_release_state.rb <bundle-id>`
   - 出力の `latest_released` と `latest_released_build` を前回リリースとする。
     `highest_valid_build` でアップロード済みの最大ビルド番号も別途確認する。
   - `git fetch --tags` 後、`gh repo view --json visibility,nameWithOwner` と
     `gh release list` でリポジトリの可視性、公開済みRelease、下書きを確認する。
   - タグ名はリポジトリ既存の規約を使う。規約がなければ単一アプリは
     `v<version>+<build>`、モノレポは `<app>/v<version>+<build>` とする。
     GitHub Releaseのタイトルは `v<version>` とする。
   - ASCの最新公開版に対応するタグとGitHub Releaseが存在し、提出ビルドを作ったmainの
     commitを指すことを確認する。commitはGitHub Release下書きに記録したhashを使い、
     記録がなければバージョンバンプPRなどの一次情報で一意に確認する。推測しない。
   - **ASC公開済み・GitHub未完了**の場合は、次版準備より先に手順9を実行する。
     復旧成功後はこの照合をやり直し、整合すれば同じ実行内で手順2へ進む。
   - **ASC未公開・GitHub公開済み、commit不明、タグが別commitを指す**場合は停止する。
     タグやReleaseを削除・付け替えず、不整合を報告する。
   - `draft_versions` に審査中・承認済み手動リリース待ち・却下・提出準備中の版がある場合は、
     その状態を報告して新規リリース準備を開始しない。承認済み手動リリース待ちなら、
     MisaにASCでの公開操作を依頼する。既存提出の継続・取り下げはMisaの指示に従う。

2. **変更内容の確認**
   - 照合済みの公開版タグから最新mainまでを確認する
     （`git log <公開版タグ>..main --oneline`）。
   - リリースに含める変更がすべてmainにマージ済みであることを確認する。
   - ユーザー向け機能更新がなければリリース準備を終了する。
   - mainのマーケティングバージョンがASC公開版以下なら、その値を再利用せず次の
     マーケティングバージョンを選ぶ。ビルド番号は `highest_valid_build` より大きい連番にする。

3. **ストア素材の更新（UIに変更がある場合）**
   - 今回の変更がストア掲載中の画面や文言に影響するか確認する。既存素材が現在の内容と一致し、
     素材ファイルも未変更なら、再作成・再アップロードしない。
   - **スクリーンショットを撮り直す、または既存ファイルを差し替える前に、Misaへ必ず確認し、
     明示的な承認を得る**。対象画面、更新理由、言語・デバイス、撮影時の購入状態を提示する。
     UI変更があっても、承認前に撮影・差し替えを進めない。このルールは全アプリ共通とする。
   - ストア用スクリーンショットは、Misaから別の指定がない限り、**買い切りIAPの購入・復元後など、
     プレミアムが解除された状態で撮影する**。無料時間、鍵、購入案内など未購入状態の表示を
     掲載目的で残す必要がある場合は、その状態で撮ることも事前確認に含める。
   - UIに変更があり、**エージェントが撮れる画面**（シミュレータで再現できる画面）は、
     承認後にスクリーンショットを再撮影して `fastlane/screenshots/` を更新し、PRを作成する。
     撮影は screenshot 用シミュレータ（`Screenshot iPhone 14 Plus` = 6.5インチ、
     `Screenshot iPad Pro 13-inch` = 13インチ）を使う（`zzzmisa-install-ios` 参照）。
   - エージェントが撮れない画面（カメラ実写など実機でしか撮れないもの）は、
     Misaに再撮影を依頼するか既存素材を流用する。
   - プレビュー動画に影響がある場合は、差し替えるかMisaに確認する。承認後に
     `fastlane/previews/{locale}/{iphone,ipad}.mp4` を更新する。キャプションや加工が必要な場合は、
     各リポジトリの制作レシピ（`promo/app-store/README.md`）と `promo/scripts/` のスクリプトに従う。

4. **リリースノートの起草**
   - `fastlane/metadata/{ja,en-US,zh-Hans}/release_notes.txt` を更新する。
   - 書式: **箇条書き（行頭は「- 」）、体言止め**。例:
     ```
     - ひらがな表示の分かち書き（ことばの区切り）を改善
     - 図鑑カードの表示を調整
     ```
     変更が1件でも「- 」から始める。全対応言語で同じ内容にする。
   - **チャットで3言語の全文を見せて承認を得てから**次へ進む。

5. **バージョンバンプとビルドアップロード**
   - **最新のmainをビルドしてアップロードする**（作業ブランチのビルドは上げない）。
   - バージョンは `1.0.1` のような `MARKETING_VERSION` 形式。
     **ビルド番号（`CURRENT_PROJECT_VERSION`）はバージョンを跨いだ通しの連番**
     （例: 1.0.0が1〜3なら、1.0.1は4から）。
   - `release-<version>-build-<N>` ブランチでバンプし、PRを作成する。
   - archive → export → アップロードの具体的なコマンドは `references/build-upload.md` を参照。

6. **ASCドラフトへの流し込み**
   - メタデータ、スクリーンショット、プレビュー動画のうち、変更したものだけを同期する。
   - メタデータ＋変更済みスクリーンショット:
     `fastlane ios upload_store_metadata version:<version>`
   - メタデータのみ: レーンの対象指定またはASC APIで直接パッチする。
   - **変更済みプレビュー動画がある場合のみ**:
     `fastlane ios upload_store_previews version:<version>`
   - 同期後は `references/store-sync.md` のチェックリストで検証する
     （重複スクショの既知バグあり）。
   - ビルドの処理完了（VALID）を待ち、バージョンドラフトに紐付ける。

7. **GitHubリリースノートの下書き更新**
   - 手順1で決めた `<release-tag>` を使い、
     `gh release create <release-tag> --draft --target <main-commit> --title "v<version>" --notes <本文>`
     （既存の下書きがあれば `gh release edit` で更新）。
   - `gh release view <release-tag> --json isDraft,tagName,targetCommitish,body` で、下書きの
     `targetCommitish` が提出ビルドのmain commitと一致することを確認する。不一致なら公開前に
     `gh release edit <release-tag> --target <main-commit>` で修正し、再取得して確認する。
   - 本文はASCのリリースノート（日本語）＋主なPRへのリンク。提出ビルドを作った
     mainのcommit hashも記載しておく（タグを打つ位置の記録）。
   - **下書きのままにする**（publishしない。下書きはタグを作らない）。

8. **審査提出（Misaの明示指示後のみ）**
   - `references/review-submission.md` の提出前チェックリストを通してから提出する。
   - 提出後の状態（WAITING_FOR_REVIEW）を確認して報告する。
   - 文言修正などで取り下げる場合: 提出取り消し→修正→再提出はペナルティなし。
     取り消し後にバージョンが `DEVELOPER_REJECTED` 表示になるのは正常。

9. **ASC公開後のタグ・GitHub Release補完**
   - Misaから公開報告を受けたときと、週次実行の手順1でASC公開済み・GitHub未完了を
     検出したときに実行する。報告の有無にかかわらずASC状態を再取得する。
   - ASCがまだ公開状態でなければ何も公開しない。承認済み手動リリース待ちなら、Misaに
     ASCでの公開操作を依頼する。
   - GitHub Release下書きのcommit hash、ASCのversion/build、タグ名を照合する。
     下書きがない場合でもcommitを一次情報から一意に確認できれば、同じ本文で作成する。
   - 下書きの `targetCommitish` が提出ビルドのmain commitと一致することをAPIで確認する。
     本文中のhashだけでは一致確認とみなさない。不一致なら下書きのtargetを修正し、再確認する。
   - リポジトリが非公開なら、`gh release edit <release-tag> --target <main-commit> --draft=false` で
     下書きをpublishしてタグを作成する。タグだけ存在する場合は、そのタグを使って
     GitHub Releaseを作成・公開する。すでに両方あれば何もしない。
   - リポジトリが公開なら、公開予定のタグ、commit、Release本文をMisaに提示し、明示指示を
     受けてからpublishする。
   - ASC公開版、GitHub Release、タグのversion/build/commitが一致することを
     `scripts/asc_release_state.rb`、GitHub API、`git fetch --tags` 後のGitで再確認する。
     整合確認後にだけ手順2へ進む。
   - 復旧できない不整合を次回へ持ち越したまま、次版の準備を進めない。

## リジェクト時

- Resolution Center のメッセージは ASC API で取得できる
  （`ReviewSubmission#latest_resolution_center_messages`）。内容を確認して対応方針を報告し、
  修正→再提出はこのフローを再度実行する。
