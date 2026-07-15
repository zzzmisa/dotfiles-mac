# Standard Components for Misa's Apps

Distilled from animal-vision-explorer (Swift), chibireco (Flutter), quiz-apps (Flutter monorepo).

## Product Policies (apply to every app)

- No backend, fully offline. No analytics, no tracking, no ads.
- Monetization: free app + single buy-once IAP (premium unlock). Implement the purchase
  service and gate it behind a flag so v1 can ship with purchase UI hidden
  (e.g. `isPurchaseUIEnabled = false`). Record first-install date/version locally
  (Keychain on iOS) so future free-tier limits can grandfather existing users.
- Bundle ID / applicationId: `com.zzzmisa.<projectname>` (lowercase ASCII).
- Local persistence: `shared_preferences` (Flutter) / `UserDefaults` + Keychain (Swift).

## Standard Documents

| File | Role | Notes |
|---|---|---|
| `AGENT.md` | 企画書 (product concept doc) | Starts with `# アプリ企画書`; concept, target, feature list. Agents read this as the product source of truth. |
| `docs/design.md` | 設計書 | Version number + 変更履歴 at the top of the file; update the version when design changes. |
| `README.md` | Repo overview | Short; build/run instructions. |

App Store submission info is managed fastlane-first (no `APP_STORE_SUBMISSION.md` for
new apps — older apps still migrating). Mapping:

| 申請情報 | Where it lives |
|---|---|
| 名前・サブタイトル・説明・キーワード・プロモテキスト・リリースノート | `fastlane/metadata/<locale>/*.txt` (per language) |
| カテゴリ | `Deliverfile` `primary_category` / `secondary_category` |
| 年齢制限指定 | `Deliverfile` `app_rating_config_path` (JSON) |
| 審査メモ・デモアカウント・連絡先 | `Deliverfile` `app_review_information` |
| 著作権表記 | `Deliverfile` `copyright` |
| 価格・IAP商品の登録と説明文・プライバシーラベル | App Store Connect manual — record in the "Manual steps" section of `docs/app-store-fastlane.md` |

## Localization

- Languages: Japanese (primary/template) + English required; zh-Hans optional but
  preferred for store reach.
- Flutter: `l10n.yaml` with
  `arb-dir: lib/l10n`, `template-arb-file: app_ja.arb`,
  `output-localization-file: app_localizations.dart`, `nullable-getter: false`.
- Swift: String Catalogs (`.xcstrings`), including `InfoPlist.xcstrings` for the
  display name and permission strings in all supported languages.
- The app must offer an in-app language picker in Settings (persisted locally),
  not only follow the OS locale.

## Design Token Layer

Every screen styles itself through named tokens; no hardcoded colors, spacing,
radii, or text styles inside widgets/views.

- Flutter: one theme directory (`lib/app/theme/` or the package equivalent) with
  one file per token family, classes named `<AppName>Colors`, `<AppName>Spacing`,
  `<AppName>Radii`, `<AppName>Shadows`, `<AppName>TextStyles` (private constructor,
  `static const` members), plus a `<AppName>Theme` that assembles the Material theme.
  Chibireco's `lib/app/theme/` is the reference implementation; quiz-apps'
  `QuizTheme` shows the multi-app variant (tokens in the shared package, per-app
  values injected via app config).
- Color tokens are grouped semantically: surface / background / brand / semantic
  (danger etc.) / text-border. The shared visual identity is one brand accent color
  plus a soft pastel background gradient (top→bottom color list).
- Swift: centralize presentation constants the same way (a `Presentation`/theme layer;
  animal-vision-explorer's `ModePresentation` pattern — name, emoji, color, symbol per
  content item — is the reference).
- Build reusable components (tiles, cards, buttons) on top of the tokens early,
  starting with the settings screen widgets.

## Settings Screen — Standard Menu

Order and grouping (omit sections that do not apply, keep the rest in this order):

1. **Language** — in-app language picker (ja/en/zh-Hans as supported).
2. **App-specific preferences** — e.g. BGM/sound toggles; app-dependent.
3. **Purchase** — buy-once unlock CTA, purchased state, and "Restore purchases".
   Hidden while the purchase flag is off.
4. **Links**
   - プライバシーポリシー: `https://policies.zzzmisa.com/privacy-kids` (kids/family apps)
     or the appropriate page under `https://policies.zzzmisa.com/`
   - 利用規約: `https://policies.zzzmisa.com/terms`
   - 著作権・ライセンス (in-app page; follow the specification below)
   - 開発者ホームページ: `https://zzzmisa.com`
   - External links open in the external browser (`LaunchMode.externalApplication` / `openURL`).
5. **Version** — display app version from package info (`package_info_plus` / Bundle).
6. **Reset** — restore settings to defaults (optional; include when settings are non-trivial).

### Copyright & Licenses Page

- Use `著作権・ライセンス` for both the Settings menu item and the page title.
  Localize the label for supported languages when appropriate (for example,
  `Copyright & Licenses` in English), and use a hiragana rendering such as
  `ちょさくけん・ライセンス` when the target audience requires it.
- Show the content in two cards: **About This App** and **Licenses**.
- Keep all content inside the cards in English in every app locale; do not add
  localization keys for the card headings or license entries.
- The **About This App** card shows the app icon, app name, and
  `© <initial release year> Misa Inome (zzzmisa)`.
- The **Licenses** card uses only the applicable sections from this format:

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

- For Flutter apps, include Flutter under `Framework:`. For native Swift/Xcode
  apps, omit the `Framework:` section entirely.
- Omit empty media sections. Use `Images:` instead of `Photos:` when the app
  credits both photographs and illustrations.
- Do not link work titles, creators, sources, or license names from this page.
- List libraries used by the shipped app at runtime. Omit development-only tools
  and dependencies used solely for builds, code generation, linting, or tests
  (for example, `build_runner`, generators, and test packages).
- Display the license name and copyright notice only; a full license-text view is
  not part of the standard page.

## Store Assets & Screenshots

- Screenshot sources: the dedicated simulators `Screenshot iPhone 14 Plus` and
  `Screenshot iPad Pro 13-inch` (see `zzzmisa-install-ios-simulator`).
- Store screenshots and illustration requests live under `store_assets/` or
  `fastlane/screenshots/{ja,en-US,...}` (when fastlane manages them).
- App icon: `flutter_launcher_icons` on Flutter (configure `image_path` in pubspec).

## Testing

- Keep a test target from day one (`test/` on Flutter, `<App>Tests` on Xcode).
- Prefer data-driven checks that iterate over all modes/content and validate
  consistency between code enums, JSON content, and docs.
