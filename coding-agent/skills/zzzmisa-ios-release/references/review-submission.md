# App Store審査提出

このリファレンスは、Misaが明示的に審査提出を依頼したときだけ読み、実行する。

## 提出前チェックリスト

- [ ] ユーザーの目に触れるリリースノートと、変更したストア文言を、チャットでMisaに承認してもらった。
- [ ] 対象のビルドが `VALID` で、バージョンの下書きに紐付いている。
- [ ] `releaseType` が `MANUAL` になっている。公開はMisaが行う。
- [ ] 変更のないIAPを含めていない。IAPを変更した場合は、その `PREPARE_FOR_SUBMISSION` バージョンと完全なApp Review Screenshotを同じ提出に含めている。
- [ ] 該当する場合、`ITSAppUsesNonExemptEncryption = NO` が入っている。
- [ ] スクリーンショットとプレビューの枚数・順序・重複・処理状態が正しい。

## Spaceship ConnectAPIで提出する

`ASC_APP_ID` と `ASC_APP_STORE_VERSION_ID` を設定する。`ASC_IAP_ID` はIAPのバージョンを
変更したときだけ設定する。

```ruby
require "spaceship"

required = %w[ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_FILEPATH ASC_APP_ID ASC_APP_STORE_VERSION_ID]
missing = required.reject { |name| ENV[name]&.length&.positive? }
abort "Missing environment variables: #{missing.join(', ')}" unless missing.empty?

Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch("ASC_KEY_ID"),
  issuer_id: ENV.fetch("ASC_ISSUER_ID"),
  filepath: ENV.fetch("ASC_KEY_FILEPATH")
)

api = Spaceship::ConnectAPI.client
submission = api.post_review_submission(
  app_id: ENV.fetch("ASC_APP_ID"),
  platform: "IOS"
).to_models.first

app_item = submission.add_app_store_version_to_review_items(
  app_store_version_id: ENV.fetch("ASC_APP_STORE_VERSION_ID")
)
abort "App version is not READY_FOR_REVIEW" unless app_item.state == "READY_FOR_REVIEW"

if ENV["ASC_IAP_ID"]&.length&.positive?
  request = api.tunes_request_client
  versions = request.get(
    "v2/inAppPurchases/#{ENV.fetch('ASC_IAP_ID')}/versions",
    { "fields[inAppPurchaseVersions]" => "state", "limit" => 200 }
  ).body.fetch("data")
  editable_states = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED]
  drafts = versions.select do |item|
    editable_states.include?(item.dig("attributes", "state"))
  end
  abort "Expected one editable IAP version, found #{drafts.size}" unless drafts.one?

  iap_item = request.post("v1/reviewSubmissionItems", {
    data: {
      type: "reviewSubmissionItems",
      relationships: {
        reviewSubmission: {
          data: { type: "reviewSubmissions", id: submission.id }
        },
        inAppPurchaseVersion: {
          data: { type: "inAppPurchaseVersions", id: drafts.first.fetch("id") }
        }
      }
    }
  }).body.fetch("data")
  abort "IAP version is not READY_FOR_REVIEW" unless \
    iap_item.dig("attributes", "state") == "READY_FOR_REVIEW"
end

submitted = submission.submit_for_review
abort "Submission failed: #{submitted.state}" unless submitted.state == "WAITING_FOR_REVIEW"
puts "Submitted: #{submitted.state}"
```

変更したIAPを黙って外さない。`ASC_IAP_ID` はそのIAPを変更したときだけ渡す。渡すと
スクリプトは編集可能なIAPバージョンがちょうど1つあることを要求し、その審査アイテムが
`READY_FOR_REVIEW` になることを確認してから提出する。

## 提出の取り消しとリジェクト

- 取り消しは `submission.cancel_submission`。取り消し後に `DEVELOPER_REJECTED` になるのは正常で、編集可能なまま。
- 修正して再提出するときの検証では、`PREPARE_FOR_SUBMISSION` と `DEVELOPER_REJECTED` の両方を有効な状態として扱う。
- リジェクトの詳細は `submission.latest_resolution_center_messages` で読む。内容を報告し、修正してからリリースフローをやり直す。
