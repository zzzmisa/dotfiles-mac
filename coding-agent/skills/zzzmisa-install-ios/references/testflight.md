# TestFlight（リモートでの動作確認）

Misaが実機にビルドできないとき（Macから離れている、ケーブルが無い、別の場所から
確認したい）に使う経路。目的は**動作確認であってリリースではない**。ストアメタデータ、
リリースノート、タグ、審査提出のいずれも扱わない。

実際のApp Storeリリースは `zzzmisa-ios-release` の担当。バージョンバンプ、ストア素材、
タグ、提出はあちらが持つ。

## 1. 事前確認 — ビルド前にチェックする

アプリが登録されていないと、TestFlightへのアップロードは時間をかけたうえで最後に
失敗する。次を全部先に確認し、1つでも欠けていたら早い段階で止まる。

```bash
source ~/.appstoreconnect/asc.env   # ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_FILEPATH
security show-keychain-info ~/Library/Keychains/login.keychain-db
```

**まずキーチェーンを確認する。** Misaが外出しているときはMacがロックされていることが
多く、そうするとloginキーチェーンもロックされる。すると原因から遠く離れた場所で
次々に失敗する:

| 症状 | コマンド |
| --- | --- |
| `The user name or passphrase you entered is not correct` | `security show-keychain-info` |
| `CodeSign` で `errSecInternalComponent` | `xcodebuild archive` |
| `could not read Username` / キーチェーンの `-25293` | `git fetch` |
| `The token in default is invalid` | `gh auth status` |

ロック中でも `security find-identity -p codesigning -v` は証明書を一覧するので、
Apple Distribution証明書が見えることは署名が通る保証にならない。Misaにロック解除を
依頼するか、Misa自身に
`security unlock-keychain ~/Library/Keychains/login.keychain-db` を実行してもらう。
**Misaのログインパスワードは絶対に扱わない。** 解除されるまでここで止まる。この先は
何をやっても成功しない。

対象のバンドルIDについて、Developer PortalのBundle IDと、App Store Connectの
アプリレコードの両方が存在することを確認する:

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

- **両方 true** → 続行する。
- **どちらかが false** → 止まって、Developer Portal / App Store ConnectのUIで作成する
  ようMisaに依頼する。**Bundle IDやアプリレコードを自分で作らない**。Bundle IDは一度
  使うと削除できず、アプリレコードは名前・SKU・主要言語を固定してしまう。どちらが
  欠けているかを正確に報告する。
- APIキーが特定アプリに限定されている可能性もある。PortalにBundle IDがあるのにASCの
  レコードが見えない場合は、レコードが無いと断定せず、両方の可能性があると伝える。

### 既存のアプリレコードを借りる

アプリレコードがまだ無く、目的がビルドを見ることだけなら、既存のアプリレコードで
アップロードすることをMisaが許可する場合がある。プレースホルダの
`com.zzzmisa.example` はそのために用意してある。**やる前に必ず聞く。** 代わりの
バンドルIDを勝手に選ばない。公開中のアプリのレコードは絶対に借りない。

`PRODUCT_BUNDLE_IDENTIFIER` は、使い捨てworktreeの `project.yml` 側でパッチする
（`xcodebuild` のコマンドラインで指定すると全ターゲットに適用されてしまう）。差分が
意図したターゲットだけに当たっていることを確認する。絶対にコミットしない。インストール
されたアプリは自分の `CFBundleDisplayName` を表示し続けるので、TestFlight上では借りた
レコードの名前で並んでいても、デバイス上では見分けがつく。

### アプリアイコン

1024×1024のマーケティングアイコンが無いとアップロードは弾かれる。新規アプリの
ターゲットは、実物のアイコンを描くまで `ASSETCATALOG_COMPILER_APPICON_NAME: ""` の
ままになっていることが多い。使い捨てのプレースホルダを生成して、使い捨てworktreeの
アセットカタログに入れ（`universal` の1024×1024エントリ1つ）、ビルド設定をそれに向ける。
プレースホルダはコミットしない。ビルドに入っているアイコンは本物ではないとMisaに伝える。

App Store Connectの各種契約（契約・税務・銀行情報）がブロックしていないことも確認する。
TestFlightの外部テストにはこれが必要（内部テストには不要）。

## 2. 作業ブランチではなく最新のmainからビルドする

確認用ビルドも `main` から作る。リリースビルドと同じルール。

```bash
git fetch origin --prune
git log --oneline -1 origin/main
```

`git fetch` や `gh auth status` が失敗したときは、そのことを伝え、ビルドが実際には
どのコミットから作られたかを報告する。**古いローカル参照を根拠に「最新のmain」だと
主張しない。**

メインのチェックアウトと作業中の変更に触れないよう、使い捨てのworktreeからビルドする:

```bash
git worktree add <scratch-dir>/tf-main origin/main --detach
```

XcodeGen（`project.yml`）を使っているリポジトリでは、先にプロジェクトを再生成する。

## 3. バンプをコミットせずにビルド番号を決める

TestFlightのビルドは、リリースビルドとビルド番号の空間を共有する。既にアップロード済みの
どのビルドよりも大きい番号を選び（`zzzmisa-ios-release/scripts/asc_release_state.rb` の
`highest_valid_build`）、使い捨てビルドのためにバージョンバンプをコミットするのではなく、
コマンドラインで渡す:

```bash
xcodebuild archive ... CURRENT_PROJECT_VERSION=<N>
```

次のリリースビルドがその続きから採番できるよう、どの番号を消費したかをMisaに伝える。

## 4. アーカイブ・エクスポート・アップロード

アーカイブ、エクスポート、アップロードのコマンドは
`zzzmisa-ios-release/references/build-upload.md` に従う。クラウド署名が拒否された
ときの手動署名フォールバックも同様。確認用ビルドで違うのは次の点だけ:

- バージョンバンプをコミットする代わりに、`xcodebuild archive` のコマンドラインで
  `CURRENT_PROJECT_VERSION=<N>` を渡す（ステップ3）。
- リポジトリに `ExportOptions.plist` が無い場合は、スクラッチディレクトリに書き、
  コミットしない。`method` = `app-store-connect`、`destination` = `export`、team ID。
- `altool` が出す `visionOS` / `UIRequiredDeviceCapabilities: [arkit]` の警告(90984)は、
  ARKitアプリでは想定どおりで、アップロードは止まらない。

## 5. 処理の完了を待ってから配布する

アップロード後の処理には数分かかる。ビルドが `VALID` になるまでポーリングし、内部
テスターグループに割り当ててTestFlightに出す。

内部テストでも輸出コンプライアンスの回答が要る。アプリのInfo.plistで
`ITSAppUsesNonExemptEncryption` を `false` にしておけばビルドごとの確認は出ない。
設定していない場合はASC上でそのビルドに対して回答する。

**内部テスターのみ。** 外部テストはBeta App Reviewを伴う対外的な操作なので、Misaの
明示的な指示なしに開始しない。

## 6. 報告する

Misaに次を伝える:

- アプリ名、マーケティングバージョン、ビルド番号
- ビルド元のコミットと、`main` が最新であることを確認できたかどうか
- TestFlightに上がっていることと、どこからインストールするか
- 前回のビルドからの変更点（確認すべき箇所が具体的に分かるように）

## Guardrails

- このフローからApp Storeの審査提出は絶対にしない。
- ストアメタデータ、スクリーンショット、プレビュー、リリースノートをここで
  アップロード・変更しない。`zzzmisa-ios-release` の担当。
- 確認用ビルドにタグやGitHub Releaseを作らない。
- Bundle IDやASCのアプリレコードを作らない。UIでの作成をMisaに依頼する。
- 作業ブランチから作ったビルドを `main` だと言ってアップロードしない。
