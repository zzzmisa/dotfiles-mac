# App Store Build Upload

## Authentication

- Load App Store Connect API credentials from `~/.appstoreconnect/asc.env`.
- Keep `.p8` keys under `~/.appstoreconnect/private_keys/`; never commit credentials.

## Archive, export, and upload

Use the repository's project/workspace, scheme, archive name, export plist, and app name:

```sh
xcodebuild archive -project <Name>.xcodeproj -scheme <Scheme> \
  -destination 'generic/platform=iOS' -archivePath build/<name>.xcarchive

xcodebuild -exportArchive -archivePath build/<name>.xcarchive \
  -exportPath build/export -exportOptionsPlist <ExportOptions.plist> \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_FILEPATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

xcrun altool --upload-app -f build/export/<App>.ipa -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

## Fallback: manual signing

`-allowProvisioningUpdates` fails when the ASC API key lacks cloud-signing
permission:

```
error: exportArchive Cloud signing permission error
error: exportArchive No profiles for '<bundle-id>' were found
```

The archive still succeeds (it signs with a development identity); only the
export fails. Do not create a new certificate. Look for an existing
`IOS_APP_STORE` profile and sign manually:

```bash
bundle exec ruby -e '
require "spaceship"; require "base64"
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"], filepath: ENV["ASC_KEY_FILEPATH"])
p = Spaceship::ConnectAPI::Profile.all.find { |x| x.name == "<profile-name>" }
File.binwrite("<scratch>/app.mobileprovision", Base64.decode64(p.profile_content))
puts p.uuid
'
```

Before exporting, confirm the profile is usable:

- `security cms -D -i <file>` → `application-identifier` matches the bundle ID
  and `ExpirationDate` is in the future.
- The SHA1 of each `DeveloperCertificates` entry appears in
  `security find-identity -p codesigning -v`. A profile whose certificate has no
  private key in the keychain cannot sign, and the export error will not say so.

Install the profile under **both** directories (Xcode versions disagree on
which one they read):

```
~/Library/MobileDevice/Provisioning Profiles/<uuid>.mobileprovision
~/Library/Developer/Xcode/UserData/Provisioning Profiles/<uuid>.mobileprovision
```

Then export with `signingStyle` = `manual`, `signingCertificate` =
`Apple Distribution`, and `provisioningProfiles` mapping the bundle ID to the
profile **name**. Drop the `-allowProvisioningUpdates` and authentication flags
from the export command; they are only needed for cloud signing.

Do not infer missing signing or export values. Prefer a repository-provided release lane or documented command when available.

After upload, wait until App Store Connect reports the build as `VALID`, then attach it to the intended version draft. Upload processing can take several minutes.
