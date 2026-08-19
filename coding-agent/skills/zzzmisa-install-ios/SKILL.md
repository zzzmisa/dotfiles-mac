---
name: zzzmisa-install-ios
description: Build, install, launch, and verify Flutter or Swift/Xcode apps on `MisaのiPhone`, `ミサのiPad`, or Misa's named iOS simulators. Use for 実機確認, iPhone/iPadインストール, simulator verification, screenshots, or permission-state testing.
---

# Install and Verify an iOS App

## Choose the target

Use the target named by the user. When none is specified:

- Prefer `MisaのiPhone` for ordinary phone verification.
- Use `ミサのiPad` for iPad-specific behavior or layout.
- Use `Screenshot iPhone 14 Plus` or `Screenshot iPad Pro 13-inch` for App Store screenshots.
- Use `iPhone SE2` for small-screen layout checks or reproducible simulator permission tests.

Read only the reference for the selected target:

- Physical device: [references/physical-devices.md](references/physical-devices.md)
- Simulator: [references/simulators.md](references/simulators.md)
- Permission or console debugging: [references/debugging.md](references/debugging.md)

## Detect the project

- Treat the project as Flutter when `pubspec.yaml` and `ios/` exist.
- Treat it as Swift/Xcode when an `.xcodeproj` or `.xcworkspace` exists without Flutter markers.
- Prefer Flutter when both appear unless the user explicitly requests the native project.
- If neither is discoverable, report the missing project markers and stop.

## Guardrails

- Run a fresh successful build before installing.
- Do not silently change the device, simulator, build mode, project/workspace, scheme, bundle ID, app path, or derived-data path.
- Prefer an existing simulator with the exact configured name over creating a duplicate.
- Request narrow approval when device services, Simulator.app, Flutter/Xcode caches, or paths outside the workspace require it.
- Report the project type, target, build/install/launch results, and relevant errors.
