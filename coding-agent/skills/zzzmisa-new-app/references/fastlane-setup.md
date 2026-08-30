# fastlaneのセットアップ（App Storeメタデータのアップロード）

animal-vision-explorerで確立した標準構成。App Store Connectのメタデータ、スクリーン
ショット、カテゴリ、年齢制限、審査情報は、fastlaneを正とする（旧APP_STORE_SUBMISSION.md
の置き換え）。バイナリのアップロードと審査提出は手作業のまま。価格、IAP商品の登録、
プライバシーラベルも手作業。

## ファイル構成

```
fastlane/
  Appfile
  Fastfile
  Deliverfile
  rating_config.json             # 年齢制限の回答（app_rating_config_path でアップロード）
  metadata/{ja,en-US,zh-Hans}/   # description.txt, keywords.txt, name.txt,
                                 # promotional_text.txt, release_notes.txt, subtitle.txt
  screenshots/{ja,en-US,zh-Hans}/
  previews/{ja,en-US,zh-Hans}/   # iphone.mp4 / ipad.mp4（専用レーンでアップロード。
                                 # deliverはApp Previewに対応していない）
docs/app-store-fastlane.md       # 使い方＋必要な環境変数＋「App Store Connectでの
                                 # 手作業の手順」節（価格、IAP商品、プライバシーラベル、
                                 # 審査提出）
```

`fastlane/` にはApp Store Connectへアップロードするものだけを置く。それらを作るための
未加工の録画、スクリーンショットの原本、ビルドスクリプト、レシピは `promo/` 配下に置く。
配置と命名のルールは `zzzmisa-store-assets` を参照。

## Appfile

```ruby
app_identifier("com.zzzmisa.<projectname>")

apple_id(ENV["FASTLANE_APPLE_ID"]) if ENV["FASTLANE_APPLE_ID"]
team_id(ENV["FASTLANE_TEAM_ID"]) if ENV["FASTLANE_TEAM_ID"]
itc_team_id(ENV["FASTLANE_ITC_TEAM_ID"]) if ENV["FASTLANE_ITC_TEAM_ID"]
```

## Fastfile

```ruby
default_platform(:ios)

platform :ios do
  desc "Upload App Store metadata and screenshots without uploading a binary or submitting for review"
  lane :upload_store_metadata do
    api_key = app_store_connect_api_key(
      key_id: ENV.fetch("ASC_KEY_ID"),
      issuer_id: ENV.fetch("ASC_ISSUER_ID"),
      key_filepath: ENV.fetch("ASC_KEY_FILEPATH"),
      duration: 1200,
      in_house: false
    )

    deliver(
      api_key: api_key,
      metadata_path: "fastlane/metadata",
      screenshots_path: "fastlane/screenshots",
      skip_binary_upload: true,
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: false,
      force: true,
      overwrite_screenshots: true,
      precheck_include_in_app_purchases: false
    )
  end
end
```

## Deliverfile

APP_STORE_SUBMISSION.mdにあった申請情報（カテゴリ、年齢制限、審査情報、著作権表記）も
ここが持つ:

```ruby
app_identifier("com.zzzmisa.<projectname>")

metadata_path("fastlane/metadata")
screenshots_path("fastlane/screenshots")

# --- 申請情報（旧APP_STORE_SUBMISSION.md） ---
copyright("#{Time.now.year} zzzmisa")
primary_category("EDUCATION")        # アプリに合わせて変える
secondary_category("LIFESTYLE")      # 任意。無ければ削除する
app_rating_config_path("fastlane/rating_config.json")
app_review_information(
  notes: "<審査メモ: 何をするアプリか、どう試すか。オフラインアプリなのでアカウント不要>"
)

skip_binary_upload(true)
skip_metadata(false)
skip_screenshots(false)
submit_for_review(false)
automatic_release(false)
force(true)
overwrite_screenshots(true)
precheck_include_in_app_purchases(false)
```

## 秘密情報（絶対にコミットしない）

`docs/app-store-fastlane.md` に、ローカルの環境変数として次を記載する。`.p8` キーと
`.env` はリポジトリに入れない:

```sh
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
# 複数アカウント・複数チームのときだけ:
export FASTLANE_APPLE_ID="apple-id@example.com"
export FASTLANE_TEAM_ID="APPLE_DEVELOPER_TEAM_ID"
export FASTLANE_ITC_TEAM_ID="APP_STORE_CONNECT_TEAM_ID"
```

## 使い方

```sh
bundle exec fastlane ios upload_store_metadata   # または `fastlane ios upload_store_metadata`
```

Flutterプロジェクトでは、`fastlane/` をリポジトリルートに置く（`ios/` の下ではない）。
パスは上記のまま、animal-vision-explorerの構成に合わせる。
