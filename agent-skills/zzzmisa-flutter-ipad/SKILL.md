---
name: zzzmisa-flutter-ipad
description: Use when the coding agent modifies a Flutter mobile app and the change needs real-device verification on ミサのiPad. Run the iOS Release build, then install it with devicectl targeting ミサのiPad by device name before reporting completion.
---

# Flutter iPad Release Install

## Workflow

1. Confirm the current repository is a Flutter project with `pubspec.yaml` and an `ios/` directory.
2. Build the iOS Release app for a physical device:

   ```bash
   flutter build ios --release
   ```

3. If the build succeeds, install the Release build on `ミサのiPad` by device name:

   ```bash
   xcrun devicectl device install app --device "ミサのiPad" build/ios/iphoneos/Runner.app
   ```

4. Report the build and install result. If either command fails, include the relevant error.

## Guardrails

- Do not run the install command before a fresh successful Release build.
- Do not silently change the device name, build mode, platform target, bundle identifier, app path, or install command. If the project layout differs, explain the mismatch and ask before adapting the commands.
- If command execution requires approval because it accesses the physical device or writes outside the sandbox, request the narrow approval needed for that command.
