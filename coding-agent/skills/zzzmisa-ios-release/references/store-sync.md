# App Store Metadata and Asset Sync

## Upload only changed data

- Do not re-upload unchanged screenshots or previews.
- After a screenshot sync, verify the count, order, and file names through the ASC API.
- `overwrite_screenshots` can occasionally duplicate one file. Detect duplicate `file_name` values and delete only the confirmed duplicate.
- Preview videos are transcoded after upload. Set the poster frame with `previewFrameTimeCode`; use the lane's `frame_time_code` for new uploads or patch an existing preview.

## Direct metadata patch

For a small text-only correction where a full deliver run is unnecessary, patch the localization directly:

```ruby
localization.update(attributes: { whatsNew: "..." })
```

Apply the same change to `fastlane/metadata/` and create a PR so the repository remains the source of truth.

## Verification

- Confirm every changed locale and field in ASC.
- Confirm screenshot counts, ordering, and duplicates.
- Confirm preview processing and poster frames when previews changed.
- Leave untouched assets unchanged.
