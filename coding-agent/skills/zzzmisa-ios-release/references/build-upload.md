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

Do not infer missing signing or export values. Prefer a repository-provided release lane or documented command when available.

After upload, wait until App Store Connect reports the build as `VALID`, then attach it to the intended version draft. Upload processing can take several minutes.
