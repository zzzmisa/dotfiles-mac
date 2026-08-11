# App Store Connect 実務チェックリストとコマンド

2026-07-28 の animal-vision-explorer 1.0.1 リリースで確立した手順。
プロジェクト固有のレーン定義は各リポジトリの `fastlane/Fastfile` と `docs/` を参照。

## 認証

- ASC APIキーの環境変数は `~/.appstoreconnect/asc.env` に定義済み。
  各コマンドの前に `source ~/.appstoreconnect/asc.env` する。
- `.p8` は `~/.appstoreconnect/private_keys/`。キー・issuer IDは秘密ではないが、
  リポジトリにはコミットしない。

## ビルド（archive → export → upload）

Apple Distribution 証明書がローカルにあればCLIで完結する（Organizer不要）:

```sh
xcodebuild archive -project <Name>.xcodeproj -scheme <Scheme> \
  -destination 'generic/platform=iOS' -archivePath build/<name>.xcarchive

xcodebuild -exportArchive -archivePath build/<name>.xcarchive \
  -exportPath build/export -exportOptionsPlist <method: app-store-connect / signingStyle: automatic / teamID> \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_FILEPATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

xcrun altool --upload-app -f build/export/<App>.ipa -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

- アップロード後、ASCでの処理完了（Build一覧に出て `VALID`）まで数分〜十数分。
  完了したらバージョンドラフトへ紐付ける（Spaceship:
  `patch_app_store_version_with_build(app_store_version_id:, build_id:)`）。

## ストア素材同期後の検証（毎回やる）

- 今回の変更が反映された素材だけを同期する。未変更のスクリーンショット・プレビュー動画は
  再アップロードしない。
- スクリーンショットの**枚数と並び順**をAPIで確認する。
- **deliverの既知バグ**: `overwrite_screenshots` で同じファイルが1枚重複することがある
  （複数回発生実績あり）。`file_name` の重複を検出して `delete!` する。
- プレビュー動画はアップロード後にASC側でトランスコードされる。ポスターフレームは
  `previewFrameTimeCode`（例 `"00:00:01:00"`）。新規アップロード時はレーンの
  `frame_time_code:` オプション、既存分は `AppPreview#update` でパッチ。

## 審査提出前チェックリスト

- [ ] リリースノート等の文言をチャットで見せてMisaの承認を得た
- [ ] ビルドが `VALID` でバージョンドラフトに紐付いている
- [ ] `releaseType` が `MANUAL`（公開はMisaの手動操作）
- [ ] IAPの状態確認: 変更がなければ提出物に含めない。変更がある場合は、
      `PREPARE_FOR_SUBMISSION` のIAPバージョンをアプリと同じ提出物に追加し、親IAPの
      App Review Screenshot が `COMPLETE` であることを確認する（漏れると 2.1(b) リジェクト）。
- [ ] 輸出コンプライアンス: `ITSAppUsesNonExemptEncryption = NO` がビルド設定にあること
      （あれば提出時の質問は出ない）
- [ ] スクリーンショット・プレビューの枚数/並び/重複を最終確認

## 審査提出（Spaceship ConnectAPI）

`ASC_APP_ID`、`ASC_APP_STORE_VERSION_ID`、`ASC_IAP_ID` にASCのリソースIDを指定して実行する。

```sh
source ~/.appstoreconnect/asc.env
ASC_APP_ID="<app-id>" \
ASC_APP_STORE_VERSION_ID="<app-store-version-id>" \
ASC_IAP_ID="<iap-id>" \
ruby <<'RUBY'
require "spaceship"

required = %w[
  ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_FILEPATH
  ASC_APP_ID ASC_APP_STORE_VERSION_ID ASC_IAP_ID
]
missing = required.reject { |name| ENV[name]&.length&.positive? }
abort "Missing environment variables: #{missing.join(', ')}" unless missing.empty?

Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("ASC_KEY_ID"),
  issuer_id: ENV.fetch("ASC_ISSUER_ID"),
  filepath: ENV.fetch("ASC_KEY_FILEPATH")
)
api = Spaceship::ConnectAPI.client
request = api.tunes_request_client

versions = request.get(
  "v2/inAppPurchases/#{ENV.fetch('ASC_IAP_ID')}/versions",
  { "fields[inAppPurchaseVersions]" => "state", "limit" => 200 }
).body.fetch("data")
drafts = versions.select do |item|
  item.dig("attributes", "state") == "PREPARE_FOR_SUBMISSION"
end
abort "Expected one PREPARE_FOR_SUBMISSION IAP version, found #{drafts.size}" unless drafts.one?
iap_version_id = drafts.first.fetch("id")

sub = api.post_review_submission(
  app_id: ENV.fetch("ASC_APP_ID"),
  platform: "IOS"
).to_models.first
app_item = sub.add_app_store_version_to_review_items(
  app_store_version_id: ENV.fetch("ASC_APP_STORE_VERSION_ID")
)
abort "App version is not READY_FOR_REVIEW" unless app_item.state == "READY_FOR_REVIEW"

# 変更したIAPバージョンを同じ提出物に加える。
iap_item = request.post("v1/reviewSubmissionItems", {
  data: {
    type: "reviewSubmissionItems",
    relationships: {
      reviewSubmission: {
        data: { type: "reviewSubmissions", id: sub.id }
      },
      inAppPurchaseVersion: {
        data: { type: "inAppPurchaseVersions", id: iap_version_id }
      }
    }
  }
}).body.fetch("data")
abort "IAP version is not READY_FOR_REVIEW" unless \
  iap_item.dig("attributes", "state") == "READY_FOR_REVIEW"

# Misaから審査提出の明示指示を受けた後にだけ実行する。
submitted = sub.submit_for_review
abort "Submission failed: #{submitted.state}" unless submitted.state == "WAITING_FOR_REVIEW"
puts "Submitted: #{submitted.state}"
RUBY
```

- 取り消し: `sub.cancel_submission`。取り消すとバージョンは `DEVELOPER_REJECTED` に
  なるが正常（そのまま編集・再提出できる。再提出時のstateチェックは
  `PREPARE_FOR_SUBMISSION` と `DEVELOPER_REJECTED` の両方を許容すること）。
- リジェクト時: `sub.latest_resolution_center_messages` で指摘内容を取得できる。

## メタデータの直接パッチ（再提出前の文言修正など）

deliverのフル実行を避けたい小修正は、ロケールごとに直接パッチできる:

```ruby
localization.update(attributes: { whatsNew: "..." })
```

パッチ後は `fastlane/metadata/` のファイルも同期し、PRを作ること（実態とリポジトリを一致させる）。
