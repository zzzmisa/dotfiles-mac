# App Store Review Submission

Read and execute this reference only after Misa explicitly asks to submit for review.

## Pre-submission checklist

- [ ] Misa approved all user-visible release notes and changed store copy in chat.
- [ ] The selected build is `VALID` and attached to the version draft.
- [ ] `releaseType` is `MANUAL`; Misa performs the public release.
- [ ] Unchanged IAPs are excluded. When an IAP changed, its `PREPARE_FOR_SUBMISSION` version and complete App Review Screenshot are included in the same submission.
- [ ] `ITSAppUsesNonExemptEncryption = NO` is present when applicable.
- [ ] Screenshot and preview counts, ordering, duplicates, and processing state are correct.

## Submit with Spaceship ConnectAPI

Set `ASC_APP_ID` and `ASC_APP_STORE_VERSION_ID`. Set `ASC_IAP_ID` only when an IAP version changed.

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

Do not silently omit a changed IAP. Pass `ASC_IAP_ID` only when that IAP changed;
the script then requires exactly one editable IAP version and verifies
its review item reaches `READY_FOR_REVIEW` before submitting.

## Cancellation and rejection

- Cancel with `submission.cancel_submission`. `DEVELOPER_REJECTED` after cancellation is normal and remains editable.
- Accept both `PREPARE_FOR_SUBMISSION` and `DEVELOPER_REJECTED` when validating a corrected resubmission.
- Read rejection details with `submission.latest_resolution_center_messages`, report the issue, then rerun the release flow after fixing it.
