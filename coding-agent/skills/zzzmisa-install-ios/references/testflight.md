# TestFlight (remote verification)

Use this path when Misa cannot build to a physical device — away from the Mac,
no cable, or verifying from another location. The goal is **verification, not a
release**: no store metadata, no release notes, no tag, no review submission.

For an actual App Store release, use `zzzmisa-ios-release` instead. That skill
owns version bumps, store assets, tags, and submission.

## 1. Preflight — check before building

A TestFlight upload fails late and slowly when the app is not registered, so
verify all of the following first and stop early if any is missing.

```bash
source ~/.appstoreconnect/asc.env   # ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_FILEPATH
```

Confirm both the Developer Portal Bundle ID and the App Store Connect app
record exist for the target bundle ID:

```bash
bundle exec ruby -e '
require "spaceship"
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"], filepath: ENV["ASC_KEY_FILEPATH"])
id = "<bundle-id>"
puts "portal bundle id: #{Spaceship::ConnectAPI::BundleId.all.any? { |b| b.identifier == id }}"
puts "asc app record:   #{!Spaceship::ConnectAPI::App.find(id).nil?}"
'
```

- **Both true** → continue.
- **Either false** → stop and ask Misa to create them in the Developer Portal /
  App Store Connect UI. **Do not create a Bundle ID or an app record yourself**:
  a Bundle ID cannot be deleted once used, and the app record fixes the name,
  SKU, and primary language. Report exactly which one is missing.
- The API key may also be app-restricted. When the portal Bundle ID exists but
  the ASC record is invisible, say both are possible causes rather than
  asserting the record is missing.

Also confirm the App Store Connect agreements (contracts, tax, banking) are not
blocking, since TestFlight external testing requires them. Internal testing does
not.

## 2. Build the latest main, not the working branch

Verification builds must come from `main`, the same rule as a release build.

```bash
git fetch origin --prune
git log --oneline -1 origin/main
```

When `git fetch` or `gh auth status` fails, say so and report which commit the
build actually came from. **Do not claim the build is "the latest main" from a
stale local ref.**

Build from a throwaway worktree so the main checkout and any in-progress work
stay untouched:

```bash
git worktree add <scratch-dir>/tf-main origin/main --detach
```

Regenerate the project first when the repository uses XcodeGen (`project.yml`).

## 3. Choose a build number without committing a bump

TestFlight builds share the build-number space with release builds. Pick a
number greater than every build already uploaded (`highest_valid_build` from
`zzzmisa-ios-release/scripts/asc_release_state.rb`), and pass it on the command
line instead of committing a version bump for a throwaway build:

```bash
xcodebuild archive ... CURRENT_PROJECT_VERSION=<N>
```

Tell Misa which number was consumed, so the next release build continues the
sequence from there.

## 4. Archive, export, upload

```bash
xcodebuild archive -project <Name>.xcodeproj -scheme <Scheme> \
  -destination 'generic/platform=iOS' -archivePath build/<name>.xcarchive \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_FILEPATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  CURRENT_PROJECT_VERSION=<N>

xcodebuild -exportArchive -archivePath build/<name>.xcarchive \
  -exportPath build/export -exportOptionsPlist <ExportOptions.plist> \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_FILEPATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

xcrun altool --upload-app -f build/export/<App>.ipa -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

When the repository has no `ExportOptions.plist`, write one into the scratch
directory (do not commit it) with `method` = `app-store-connect`,
`destination` = `export`, the team ID, and `signingStyle` = `automatic`.

## 5. Wait for processing, then distribute

Upload processing takes several minutes. Poll until the build is `VALID`, then
assign it to the internal tester group so it appears in TestFlight.

Internal testing needs the export-compliance answer. Setting
`ITSAppUsesNonExemptEncryption` to `false` in the app's Info.plist avoids the
per-build prompt; without it, answer it on the build in ASC.

**Internal testers only.** External testing means a Beta App Review and is a
public-facing step — do not start it without Misa's explicit instruction.

## 6. Report

Tell Misa:

- the app, marketing version, and build number
- the commit the build came from, and whether `main` was verified as up to date
- that the build is on TestFlight and where to install it
- what changed since the last build, so there is something specific to check

## Guardrails

- Never submit for App Store review from this flow.
- Never upload or change store metadata, screenshots, previews, or release
  notes here — those belong to `zzzmisa-ios-release`.
- Do not create tags or GitHub Releases for a verification build.
- Do not create Bundle IDs or ASC app records; ask Misa to do it in the UI.
- Do not upload a build made from a working branch while calling it `main`.
