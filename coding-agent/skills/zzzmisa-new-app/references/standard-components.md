# Misaのアプリの標準構成要素

animal-vision-explorer（Swift）、chibireco（Flutter）、quiz-apps（Flutterモノレポ）から
抽出した共通の型。

## プロダクトの方針（全アプリ共通）

- バックエンドなし、完全オフライン。解析・トラッキング・広告は入れない。
- 収益化: 無料アプリ＋買い切りIAP1つ（プレミアム解放）。購入サービスは実装したうえで
  フラグの裏に置き、v1は購入UIを隠した状態でリリースできるようにする
  （例: `isPurchaseUIEnabled = false`）。将来の無料枠制限で既存ユーザーをグランド
  ファザリングできるよう、初回インストール日とバージョンをローカルに記録する
  （iOSはKeychain）。
- Bundle ID / applicationId: `com.zzzmisa.<projectname>`（小文字ASCII）。
- ローカル永続化: `shared_preferences`（Flutter）/ `UserDefaults` + Keychain（Swift）。

## 標準ドキュメント

| ファイル | 役割 | 備考 |
|---|---|---|
| `AGENTS.md` | エージェント共通の指示 | 企画書・設計書への参照と、リポジトリ固有の進め方を書く。Codexはこのファイルを読む。 |
| `CLAUDE.md` | Claudeのエントリポイント | 可能なら `AGENTS.md` へのシンボリックリンクにする。無理ならそちらを指す記述だけを置く。 |
| `docs/product.md` | 企画書 | `# アプリ企画書` で始める。コンセプト、ターゲット、機能一覧、プロダクト上の制約。 |
| `docs/design.md` | 設計書 | ファイル冒頭にバージョン番号と変更履歴。設計を変えたらバージョンを上げる。 |
| `README.md` | リポジトリの概要 | 短く。ビルド・実行手順。 |

プロダクトの知識は `docs/product.md` に置く。認識されない単数形の `AGENT.md` は使わない。
2つのエージェント用エントリポイントは、同じ企画書・設計書を指すようにする。

App Storeの申請情報はfastlaneを正として管理する（新規アプリで `APP_STORE_SUBMISSION.md`
は作らない。旧いアプリは移行中）。対応は次のとおり:

| 申請情報 | 置き場所 |
|---|---|
| 名前・サブタイトル・説明・キーワード・プロモテキスト・リリースノート | `fastlane/metadata/<locale>/*.txt`（言語ごと） |
| カテゴリ | `Deliverfile` の `primary_category` / `secondary_category` |
| 年齢制限指定 | `Deliverfile` の `app_rating_config_path`（JSON） |
| 審査メモ・デモアカウント・連絡先 | `Deliverfile` の `app_review_information` |
| 著作権表記 | `Deliverfile` の `copyright` |
| 価格・IAP商品の登録と説明文・プライバシーラベル | App Store Connectで手作業。`docs/app-store-fastlane.md` の「手作業の手順」節に記録する |

## 多言語対応

- 言語: 日本語（主言語・テンプレート）＋英語は必須。zh-Hansは任意だが、ストアでの
  リーチを考えると入れたい。
- Flutter: `l10n.yaml` に
  `arb-dir: lib/l10n`、`template-arb-file: app_ja.arb`、
  `output-localization-file: app_localizations.dart`、`nullable-getter: false`。
- Swift: String Catalog（`.xcstrings`）。表示名と権限の説明文を全対応言語で入れるため
  `InfoPlist.xcstrings` も含める。
- OSのロケールに追従するだけでなく、設定画面にアプリ内の言語切り替えを必ず用意する
  （選択はローカルに保存する）。

## デザイントークン層

すべての画面は名前付きトークン経由でスタイルを当てる。ウィジェット/ビューの中に色・
余白・角丸・テキストスタイルをハードコードしない。

- Flutter: テーマ用のディレクトリを1つ作り（`lib/app/theme/` またはパッケージ相当の場所）、
  トークンの種類ごとにファイルを分ける。クラス名は `<AppName>Colors`、`<AppName>Spacing`、
  `<AppName>Radii`、`<AppName>Shadows`、`<AppName>TextStyles`（privateコンストラクタ、
  メンバは `static const`）。加えてMaterialテーマを組み立てる `<AppName>Theme` を置く。
  chibirecoの `lib/app/theme/` が参照実装。quiz-appsの `QuizTheme` は複数アプリ版の例
  （トークンは共有パッケージ、アプリごとの値はapp config経由で注入）。
- 色トークンは意味で分類する: surface / background / brand / semantic（danger等）/
  text-border。共通のビジュアルアイデンティティは、ブランドのアクセントカラー1色＋
  淡いパステルの背景グラデーション（上→下の色リスト）。
- Swift: 表示用の定数を同じように一箇所へ集約する（`Presentation`/テーマ層。
  animal-vision-explorerの `ModePresentation` パターン — コンテンツ項目ごとに名前・
  絵文字・色・シンボルを持つ — が参照実装）。
- トークンの上に再利用可能なコンポーネント（タイル、カード、ボタン）を早めに作る。
  設定画面のウィジェットから始めるとよい。

## 設定画面 — 標準メニュー

並び順とグルーピング（該当しないセクションは省き、残りはこの順を保つ）:

1. **言語** — アプリ内の言語切り替え（対応する ja/en/zh-Hans）。個別のメニュー項目や
   別画面ではなく、選択肢がその場で開くインラインの単一選択ドロップダウン/リストとして
   実装する。
2. **アプリ固有の設定** — BGM・効果音のオン/オフなど。アプリによる。
3. **購入** — 買い切り解放のCTA、購入済み状態、「購入を復元」。購入フラグがオフの間は隠す。
4. **リンク**
   - プライバシーポリシー: `https://policies.zzzmisa.com/privacy-kids`（キッズ・
     ファミリー向けアプリ）、または `https://policies.zzzmisa.com/` 配下の該当ページ
   - 利用規約: `https://policies.zzzmisa.com/terms`
   - 著作権・ライセンス（アプリ内ページ。仕様は下記）
   - 開発者ホームページ: `https://zzzmisa.com`
   - 外部リンクは外部ブラウザで開く（`LaunchMode.externalApplication` / `openURL`）。
5. **リセット** — 設定を初期値に戻す（任意。設定項目が少なくないときに入れる）。

- メニューのグループに見出しは付けない。論理的なグループの区切りは水平線で表現する。
- 最後のメニュー項目の下にもう1本区切り線を引き、画面下部に小さいフッターテキストとして
  バージョンを表示する。メニュー項目としては表示しない。表記は
  `<ローカライズしたバージョンのラベル>: <version>+<build number>`（例: `バージョン: 1.0.0+6`）。
  どちらの値もパッケージ情報から読む（`package_info_plus` / Bundle）。

### 著作権・ライセンスページ

- 設定メニューの項目名もページタイトルも `著作権・ライセンス` にする。対応言語では
  適宜ローカライズし（英語なら `Copyright & Licenses` など）、対象ユーザーによっては
  `ちょさくけん・ライセンス` のようにひらがな表記にする。
- 内容は2枚のカードで見せる: **About This App** と **Licenses**。
- カードの中身は、どのロケールでも英語のまま表示する。カードの見出しやライセンス項目に
  ローカライズキーを作らない。
- **About This App** カードには、アプリアイコン、アプリ名、
  `© <初回リリース年> Misa Inome (zzzmisa)` を表示する。
- **Licenses** カードは、この形式のうち該当するセクションだけを使う:

  ```text
  Framework:
  - <framework name> (<license name>)
    <copyright notice>

  Libraries:
  - <library name> (<license name>)
    <copyright notice>

  Photos:
  - <work title> (<usage terms, such as CC0 1.0 Universal>)
    by <creator name>

  Music:
  - <track title> (<usage terms>)
    by <creator name>
  ```

- FlutterアプリはFlutterを `Framework:` に載せる。ネイティブのSwift/Xcodeアプリでは
  `Framework:` セクションごと省く。
- 該当のないメディアのセクションは省く。写真とイラストの両方をクレジットするアプリでは
  `Photos:` の代わりに `Images:` を使う。
- このページから作品名・作者・出典・ライセンス名へリンクを張らない。
- 出荷したアプリが実行時に使うライブラリを載せる。開発時だけのツールや、ビルド・
  コード生成・lint・テストのためだけの依存は省く（`build_runner`、各種ジェネレータ、
  テスト用パッケージなど）。
- 表示するのはライセンス名と著作権表記だけ。ライセンス全文の表示は標準ページに含めない。

## ストア素材・スクリーンショット

- スクリーンショットの撮影元: 専用シミュレータの `Screenshot iPhone 14 Plus` と
  `Screenshot iPad Pro 13-inch`（`zzzmisa-install-ios` 参照）。
- ストア用スクリーンショットは `fastlane/screenshots/{ja,en-US,...}`、プレビュー動画は
  `fastlane/previews/{locale}/`。それらを*作るため*のもの（未加工の録画、
  スクリーンショットの原本、ビルドスクリプト、レシピ）は `promo/` 配下に置く。
  配置と命名の全ルールは `zzzmisa-store-assets` に従う。
- アプリアイコン: Flutterは `flutter_launcher_icons`（pubspecで `image_path` を設定）。

## テスト

- 初日からテストターゲットを持つ（Flutterは `test/`、Xcodeは `<App>Tests`）。
- 全モード・全コンテンツをイテレートして、コードのenum・JSONのコンテンツ・ドキュメントの
  整合を検証する、データ駆動のチェックを優先する。
