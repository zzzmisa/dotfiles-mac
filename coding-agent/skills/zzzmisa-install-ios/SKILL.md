---
name: zzzmisa-install-ios
description: Build, install, launch, and verify Flutter or Swift/Xcode apps on `MisaのiPhone`, `ミサのiPad`, Misa's named iOS simulators, or TestFlight when Misa is away from the Mac. Use for 実機確認, iPhone/iPadインストール, simulator verification, TestFlightにあげて確認, 出先・リモートでの動作確認, screenshots, or permission-state testing.
---

# iOSアプリのインストールと動作確認

## ターゲットを選ぶ

ユーザーが指定したターゲットを使う。指定が無いときは:

- 通常の実機確認は `MisaのiPhone` を優先する。
- iPad固有の挙動やレイアウトの確認は `ミサのiPad` を使う。
- App Store用のスクリーンショットは `Screenshot iPhone 14 Plus` または
  `Screenshot iPad Pro 13-inch` を使う。
- 小さい画面のレイアウト確認や、再現性のあるシミュレータ権限テストは `iPhone SE2` を使う。
- MisaがMacから離れていて実機ビルドができないとき（出先・リモートでの動作確認）は
  TestFlightを使う。これは動作確認であって、リリースではない。

選んだターゲットのリファレンスだけを読む:

- 実機: [references/physical-devices.md](references/physical-devices.md)
- シミュレータ: [references/simulators.md](references/simulators.md)
- TestFlight（リモートでの動作確認）: [references/testflight.md](references/testflight.md)
- 権限まわり・コンソールのデバッグ: [references/debugging.md](references/debugging.md)

## プロジェクト種別を判定する

- `pubspec.yaml` と `ios/` があればFlutterプロジェクトとして扱う。
- Flutterのマーカーが無く `.xcodeproj` か `.xcworkspace` があればSwift/Xcodeとして扱う。
- 両方に見える場合は、ユーザーがネイティブプロジェクトを明示的に指定しない限りFlutterを優先する。
- どちらとも判定できない場合は、見つからなかったマーカーを報告して止まる。

## Guardrails

- インストールの前に、必ずビルドを通し直す。
- デバイス、シミュレータ、ビルドモード、プロジェクト/ワークスペース、スキーム、
  バンドルID、アプリのパス、derived dataのパスを、黙って変更しない。
- 設定どおりの名前のシミュレータが既にあれば、それを使う。重複して作らない。
- デバイスのサービス、Simulator.app、Flutter/Xcodeのキャッシュ、ワークスペース外のパスに
  触る必要があるときは、範囲を絞って承認を求める。
- プロジェクト種別、ターゲット、ビルド・インストール・起動の結果、関連するエラーを報告する。
- TestFlightの確認用ビルドは `main` から作る。作業ブランチからは作らない。また、この
  スキルからApp Storeの審査提出やストアメタデータの変更は絶対にしない。実際のリリースは
  `zzzmisa-ios-release` の担当。
