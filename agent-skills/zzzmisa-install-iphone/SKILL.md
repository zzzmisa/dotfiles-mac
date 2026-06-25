---
name: zzzmisa-install-iphone
description: Use when the coding agent modifies a Flutter or Swift/Xcode iOS app and the change needs real-device verification on `MisaのiPhone`. Detect Flutter vs Swift from the project, run the iOS Release build, then install the Release app on `MisaのiPhone` before reporting completion.
---

# iPhone Release Install

## Project Detection

- Treat the project as Flutter when `pubspec.yaml` and `ios/` exist.
- Treat the project as Swift/Xcode when an `.xcodeproj` or `.xcworkspace` exists and no Flutter project markers are present.
- If both appear, prefer Flutter unless the user explicitly asks for Swift/Xcode.
- If neither is discoverable, stop and explain what project markers were missing.

## Flutter Workflow

1. Build the iOS Release app for a physical device:

   ```bash
   flutter build ios --release
   ```

2. If the build succeeds, install the Release build on `MisaのiPhone` by device name:

   ```bash
   flutter install -d "MisaのiPhone" --release
   ```

## Swift/Xcode Workflow

1. Identify the project or workspace and scheme. For `AnimalVisionExplorer`, expect `AnimalVisionExplorer.xcodeproj` and scheme `AnimalVisionExplorer`.
2. Run the Release build for `MisaのiPhone` by device name:

   ```bash
   xcodebuild build -project AnimalVisionExplorer.xcodeproj -scheme AnimalVisionExplorer -configuration Release -destination "platform=iOS,name=MisaのiPhone" -derivedDataPath build/DerivedData
   ```

3. If the build succeeds, reinstall the app on `MisaのiPhone` by device name:

   ```bash
   xcrun devicectl device install app --device "MisaのiPhone" build/DerivedData/Build/Products/Release-iphoneos/AnimalVisionExplorer.app
   ```

## Guardrails

- Do not run the install command before a fresh successful Release build.
- Do not silently change the device name, build mode, platform target, project, workspace, scheme, derived data path, bundle identifier, app path, or install command.
- If the project layout differs, explain the mismatch and adapt only when the correct values are discoverable locally.
- If command execution requires approval because it accesses the physical device or writes outside the sandbox, request the narrow approval needed for that command.
- Report the detected project type, build result, install result, and any relevant error.
