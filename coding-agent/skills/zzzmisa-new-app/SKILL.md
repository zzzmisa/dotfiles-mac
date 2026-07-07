---
name: zzzmisa-new-app
description: Scaffold a new mobile app project with Misa's standard skeleton (docs, localization, settings screen, fastlane, offline + buy-once IAP policy). Use when the user asks to start, create, or 新規作成 a new smartphone/iOS/Flutter app project, or to set up the standard project frame/枠/雛形 for one.
---

# New App Scaffold

Set up a new app project so it starts with the structures Misa's existing apps
(animal-vision-explorer, chibireco, quiz-apps) have in common.

Read [references/standard-components.md](references/standard-components.md) for the
concrete conventions (docs, localization, settings menu, URLs, policies) and
[references/fastlane-setup.md](references/fastlane-setup.md) for the fastlane files.

## Scope Check First

- If the new app is part of the quiz series, do NOT use this skill's scaffold;
  follow `tools/new_app.md` in the quiz-apps monorepo (`~/mySources/confusing-hiragana`).
- Otherwise continue here.

## Inputs to Confirm

Gather from the user (ask only for what is missing):

1. App name (Japanese and English; zh-Hans optional).
2. Project name: lowercase ASCII, becomes the Bundle ID `com.zzzmisa.<projectname>`.
3. Platform: Flutter by default; Swift/Xcode when the app depends on native-heavy
   features (camera pipelines, Core Image, multi-cam, etc.).
4. Target audience (kids/family vs general) — decides which privacy policy URL to use.

## Workflow

1. **Create the project.**
   - Flutter: `flutter create --platforms=ios --org com.zzzmisa --project-name <projectname> <app_dir>`
   - Swift: create the Xcode project with Bundle ID `com.zzzmisa.<projectname>`,
     add `PrivacyInfo.xcprivacy`, and group code by feature (`Features/<Name>/`, `Core/`, `Resources/`).
2. **Add the standard documents** (AGENT.md 企画書, docs/design.md 設計書, README.md)
   as skeletons per the reference file. Store submission info is NOT a separate
   document; it lives in fastlane (step 7).
3. **Set up localization** (Japanese primary + English; zh-Hans optional) per the
   reference file, including the in-app language picker requirement.
4. **Set up the design token layer** (colors, spacing, radii, shadows, text styles as
   named constants in one theme directory) per the reference file, before building
   any screens.
5. **Build the settings screen** with the standard menu sections and URLs from the
   reference file, wired to real implementations (version from package info, etc.),
   using only design tokens for styling.
6. **Apply the standard policies**: no backend, fully offline, no analytics/tracking/ads,
   buy-once IAP prepared behind a flag, local persistence (shared_preferences / UserDefaults),
   and record first-install date/version locally (Keychain on iOS) for future
   free-tier grandfathering.
7. **Set up fastlane** per [references/fastlane-setup.md](references/fastlane-setup.md),
   including `docs/app-store-fastlane.md`, metadata skeletons for each locale, and the
   Deliverfile fields that replace APP_STORE_SUBMISSION.md (categories, age rating,
   review information).
8. **Finish**: app icon generation (`flutter_launcher_icons` on Flutter), a test target
   with at least one meaningful data-driven test (`test/` on Flutter, `<App>Tests` on Xcode),
   a smoke check that the project builds, and a report listing the human-only follow-ups
   (App Store Connect registration, icon/illustration assets, store metadata text).

## Guardrails

- Do not invent store metadata text, pricing, or category choices; leave clear
  placeholders and list them as follow-ups.
- Do not commit secrets: no `.p8` keys, no `.env`, no App Store Connect credentials.
- Reuse the standard URLs and conventions from the reference file instead of
  inventing new ones; ask before deviating.
- Keep everything working offline; do not add backend dependencies or analytics/tracking.
- Verification on simulators/devices is covered by the `zzzmisa-install-*` skills.
