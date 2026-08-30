# iOS実機

## ターゲット

| 用途 | デバイス名 |
| --- | --- |
| iPhoneでの確認 | `MisaのiPhone` |
| iPadでの確認 | `ミサのiPad` |

ビルドからインストールまで、デバイス名は常にこの表記どおりに使う。

## Flutter

1. Releaseビルドを作る:

   ```bash
   flutter build ios --release
   ```

2. ビルドが成功したらインストールする:

   ```bash
   flutter install -d "<device-name>" --release
   ```

## Swift/Xcode

1. プロジェクト/ワークスペースとスキームを特定する。分からなければ `xcodebuild -list` を使う。
2. 対象デバイス向けにReleaseでビルドする。ワークスペースの場合は `-project` ではなく
   `-workspace` を使う:

   ```bash
   xcodebuild build -project <Name>.xcodeproj -scheme <Scheme> \
     -configuration Release -destination "platform=iOS,name=<device-name>" \
     -derivedDataPath build/DerivedData
   ```

3. ビルドが成功したらインストールする:

   ```bash
   xcrun devicectl device install app --device "<device-name>" \
     build/DerivedData/Build/Products/Release-iphoneos/<AppName>.app
   ```

UUIDが必要な場合は `xcrun devicectl list devices` で調べる。推測で書かない。
