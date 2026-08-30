# App Storeビルドのアップロード

## 認証

- App Store Connect APIの認証情報は `~/.appstoreconnect/asc.env` から読み込む。
- `.p8` キーは `~/.appstoreconnect/private_keys/` の下に置く。認証情報は絶対にコミットしない。

## アーカイブ・エクスポート・アップロード

プロジェクト/ワークスペース、スキーム、アーカイブ名、エクスポート用plist、アプリ名は
そのリポジトリのものを使う:

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

## フォールバック: 手動署名

ASC APIキーにクラウド署名の権限が無いと `-allowProvisioningUpdates` は失敗する:

```
error: exportArchive Cloud signing permission error
error: exportArchive No profiles for '<bundle-id>' were found
```

アーカイブ自体は成功する（開発用の証明書で署名される）。失敗するのはエクスポートだけ。
新しい証明書を作らないこと。既存の `IOS_APP_STORE` プロファイルを探して手動で署名する:

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

エクスポートの前に、そのプロファイルが使えることを確認する:

- `security cms -D -i <file>` → `application-identifier` がバンドルIDと一致し、
  `ExpirationDate` が未来であること。
- `DeveloperCertificates` の各エントリのSHA1が
  `security find-identity -p codesigning -v` に出ていること。証明書の秘密鍵が
  キーチェーンに無いプロファイルでは署名できないが、エクスポートのエラーはそれを
  教えてくれない。

プロファイルは**両方の**ディレクトリに置く（Xcodeのバージョンによってどちらを読むかが
異なるため）:

```
~/Library/MobileDevice/Provisioning Profiles/<uuid>.mobileprovision
~/Library/Developer/Xcode/UserData/Provisioning Profiles/<uuid>.mobileprovision
```

そのうえで、`signingStyle` = `manual`、`signingCertificate` = `Apple Distribution`、
`provisioningProfiles` でバンドルIDをプロファイル**名**にマッピングしてエクスポートする。
エクスポートのコマンドからは `-allowProvisioningUpdates` と認証系のフラグを外す。
これらはクラウド署名のときだけ必要。

署名やエクスポートの値が分からないときに推測で埋めない。リポジトリにリリースレーンや
手順化されたコマンドがあれば、そちらを優先する。

アップロード後は、App Store Connectがビルドを `VALID` と報告するまで待ってから、
対象バージョンの下書きに紐付ける。アップロード後の処理には数分かかることがある。
