---
name: zzzmisa-new-app
description: FlutterまたはSwiftのモバイルアプリを、Misaの標準（バックエンドなしのオフライン・買い切りIAP・ドキュメント・多言語対応・デザイントークン・設定画面・テスト・プライバシー・fastlane）で新規作成する、または既存アプリをその標準に合わせる。新規アプリ作成、雛形・初期設定、既存アプリを標準に揃えたいときに使う。
---

# 新規アプリの雛形

Misaの既存アプリ（animal-vision-explorer、chibireco、quiz-apps）に共通する構造を、
新しいアプリでも最初から備えた状態にする。

具体的な規約（ドキュメント、多言語対応、設定メニュー、URL、方針）は
[references/standard-components.md](references/standard-components.md) を、
fastlaneのファイル構成は [references/fastlane-setup.md](references/fastlane-setup.md) を読む。

## 先に適用範囲を確認する

- クイズシリーズの新作なら、このスキルの雛形は使わない。quiz-appsモノレポ
  （`~/mySources/confusing-hiragana`）の `tools/new_app.md` に従う。
- それ以外はこのまま進める。

## 確認する入力

既存アプリの場合は、まずリポジトリから値を読み取る。雛形や既存構成の是正に実質的な
影響がある未確定の選択だけを聞く:

1. アプリ名（日本語と英語。zh-Hansは任意）。
2. プロジェクト名: 小文字ASCII。バンドルIDは `com.zzzmisa.<projectname>` になる。
3. プラットフォーム: 既定はFlutter。ネイティブ依存の強い機能（カメラパイプライン、
   Core Image、マルチカム等）が必要ならSwift/Xcode。
4. 対象ユーザー（キッズ・ファミリー向けか一般向けか） — どのプライバシーポリシーURLを
   使うかがこれで決まる。

## Workflow

既存アプリの場合は、以下の各ステップに対して現状とのギャップを洗い出し、プロジェクト
作成の手順は飛ばす。

1. **新規ならプロジェクトを作成する。**
   - Flutter: `flutter create --platforms=ios --org com.zzzmisa --project-name <projectname> <app_dir>`
   - Swift: バンドルID `com.zzzmisa.<projectname>` でXcodeプロジェクトを作り、
     `PrivacyInfo.xcprivacy` を追加し、コードを機能単位でまとめる（`Features/<Name>/`、`Core/`、`Resources/`）。
   - 両方共通: App Store Connectで輸出コンプライアンスを聞かれないよう、Info.plistで
     暗号化コンプライアンスを宣言する。`ITSAppUsesNonExemptEncryption` を `false` にする
     （Flutterは `ios/Runner/Info.plist`。Info.plistを生成するXcodeプロジェクトはビルド設定
     `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`）。
2. **標準ドキュメントを追加する**（`AGENTS.md`、`CLAUDE.md`、`docs/product.md`、
   `docs/design.md`、`README.md`）。リファレンスに沿って骨組みだけ作る。ストア入稿情報は
   独立したドキュメントにしない。fastlane側に置く（ステップ7）。
3. **多言語対応を用意する**（日本語を主、英語を副。zh-Hansは任意）。リファレンスに従い、
   アプリ内の言語切り替えも必須要件として入れる。
4. **デザイントークン層を用意する**（色・余白・角丸・影・テキストスタイルを、1つのテーマ
   ディレクトリに名前付き定数として置く）。リファレンスに従い、画面を作り始める前にやる。
5. **設定画面を作る**。リファレンスの標準メニュー構成とURLを使い、実装に実際に配線する
   （バージョンはpackage infoから取得する等）。スタイルはデザイントークンだけで組む。
6. **標準の方針を適用する**: バックエンドなし、完全オフライン、解析・トラッキング・広告
   なし、買い切りIAPをフラグの裏に準備、ローカル永続化（shared_preferences / UserDefaults）、
   将来の無料枠グランドファザリングのために初回インストール日とバージョンをローカルに記録
   （iOSはKeychain）。
7. **fastlaneを用意する**。[references/fastlane-setup.md](references/fastlane-setup.md) に従い、
   `docs/app-store-fastlane.md`、ロケールごとのメタデータの雛形、APP_STORE_SUBMISSION.mdの
   代わりになるDeliverfileの項目（カテゴリ、年齢レーティング、審査情報）まで用意する。
8. **仕上げ**: アプリアイコンの生成（Flutterは `flutter_launcher_icons`）、意味のある
   データ駆動テストを最低1つ持つテストターゲット（Flutterは `test/`、Xcodeは `<App>Tests`）、
   ビルドが通ることのスモークチェック、そして人手でしかできない残作業の一覧
   （App Store Connectでのアプリ登録、アイコン・イラスト素材、ストアメタデータの文言）を報告する。

## Guardrails

- ストアメタデータの文言、価格、カテゴリの選択を勝手に作らない。分かりやすい
  プレースホルダを置き、残作業として報告する。
- 秘密情報をコミットしない。`.p8` キー、`.env`、App Store Connectの認証情報は入れない。
- 新しい規約を発明せず、リファレンスの標準URLと規約を再利用する。逸脱するときは先に聞く。
- 全部オフラインで動く状態を保つ。バックエンド依存や解析・トラッキングを足さない。
- シミュレータ・実機での動作確認は `zzzmisa-install-*` スキルの担当。
