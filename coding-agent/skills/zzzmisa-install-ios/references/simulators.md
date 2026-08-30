# iOSシミュレータ

## 設定済みのターゲット

| 呼び方 | シミュレータ名 | デバイスタイプ |
| --- | --- | --- |
| SE2、iPhone SE2 | `iPhone SE2` | `com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-` |
| iPhone 14 Plus、スクショ用iPhone | `Screenshot iPhone 14 Plus` | `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus` |
| iPad Pro 13-inch、スクショ用iPad | `Screenshot iPad Pro 13-inch` | `iPad-Pro-13-inch` を含むもののうち最新のタイプ |

## シミュレータを準備する

1. `xcrun simctl list devices available` で、その名前のシミュレータを探す。
2. 無ければ、要求されたタイプと、利用できる最新のiOSランタイムを確認して作る:

   ```bash
   xcrun simctl list devicetypes
   xcrun simctl list runtimes available
   xcrun simctl create "<simulator-name>" <device-type-id> <runtime-id>
   ```

3. 起動してSimulator.appを開く:

   ```bash
   xcrun simctl boot <UDID>
   open -a Simulator
   ```

既に起動済みならそのまま進める。以降のコマンドでは、必ず同じUDIDを使う。

## Flutter

1. `flutter devices` にそのシミュレータが出ることを確認する。
2. `flutter run -d <UDID>` でアプリを実行する。
3. Dart VM Serviceのメッセージが出れば、アプリが起動したと判断してよい。
4. 実行中のプロセスを止める必要があるときは `pgrep -alf flutter` で確認し、この
   ターゲットの `flutter_tools.snapshot run -d <UDID>` だけを止める。無関係な
   エディタのデーモンをkillしない。
5. インストール済みのビルドを起動し直すときは `xcrun simctl launch <UDID> <bundle-id>`。

## Swift/Xcode

1. 必要なら `xcodebuild -list` でプロジェクト/ワークスペースとスキームを特定する。
2. 対象のシミュレータ向けにDebugでビルドする:

   ```bash
   xcodebuild build -project <Name>.xcodeproj -scheme <Scheme> \
     -configuration Debug -destination "platform=iOS Simulator,id=<UDID>" \
     -derivedDataPath build/DerivedData
   ```

3. ビルドが成功したらインストールして起動する:

   ```bash
   xcrun simctl install <UDID> \
     build/DerivedData/Build/Products/Debug-iphonesimulator/<AppName>.app
   xcrun simctl launch <UDID> <bundle-id>
   ```

バンドルIDが分からないときは `xcodebuild -showBuildSettings` の
`PRODUCT_BUNDLE_IDENTIFIER` を読む。
