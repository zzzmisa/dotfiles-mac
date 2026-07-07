# fastlane Setup (App Store metadata upload)

Standard layout from animal-vision-explorer: fastlane is the source of truth for App
Store Connect metadata, screenshots, categories, age rating, and review information
(replacing the old APP_STORE_SUBMISSION.md). Binary upload and review submission stay
manual, as do pricing, IAP product setup, and privacy labels.

## Files

```
fastlane/
  Appfile
  Fastfile
  Deliverfile
  rating_config.json             # age rating answers (uploaded via app_rating_config_path)
  metadata/{ja,en-US,zh-Hans}/   # description.txt, keywords.txt, name.txt,
                                 # promotional_text.txt, release_notes.txt, subtitle.txt
  screenshots/{ja,en-US,zh-Hans}/
docs/app-store-fastlane.md       # usage + required env vars + "Manual steps in
                                 # App Store Connect" section (pricing, IAP products,
                                 # privacy labels, review submission)
```

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

Also carries the submission info that used to live in APP_STORE_SUBMISSION.md
(categories, age rating, review info, copyright):

```ruby
app_identifier("com.zzzmisa.<projectname>")

metadata_path("fastlane/metadata")
screenshots_path("fastlane/screenshots")

# --- 申請情報 (formerly APP_STORE_SUBMISSION.md) ---
copyright("#{Time.now.year} zzzmisa")
primary_category("EDUCATION")        # adjust per app
secondary_category("LIFESTYLE")      # optional; remove when none
app_rating_config_path("fastlane/rating_config.json")
app_review_information(
  notes: "<review notes: what the app does, how to test; no account needed (offline app)>"
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

## Secrets (never commit)

`docs/app-store-fastlane.md` must document these local env vars; `.p8` keys and
`.env` files stay out of the repo:

```sh
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
# Optional for multiple accounts/teams:
export FASTLANE_APPLE_ID="apple-id@example.com"
export FASTLANE_TEAM_ID="APPLE_DEVELOPER_TEAM_ID"
export FASTLANE_ITC_TEAM_ID="APP_STORE_CONNECT_TEAM_ID"
```

## Usage

```sh
bundle exec fastlane ios upload_store_metadata   # or `fastlane ios upload_store_metadata`
```

Flutter projects: place the `fastlane/` directory at the repo root (not under `ios/`)
and keep paths as above, matching the animal-vision-explorer layout.
