---
name: zzzmisa-flutter-iphone
description: Use when the coding agent modifies a Flutter mobile app and the change needs real-device verification on MisaのiPhone. Run the iOS Release build, then install it with flutter install targeting MisaのiPhone by device name before reporting completion.
---

# Flutter iPhone Release Install

## Workflow

1. Confirm the current repository is a Flutter project with `pubspec.yaml` and an `ios/` directory.
2. Build the iOS Release app for a physical device:

   ```bash
   flutter build ios --release
   ```

3. If the build succeeds, install the Release build on `MisaのiPhone` by device name:

   ```bash
   flutter install -d "MisaのiPhone" --release
   ```

4. Report the build and install result. If either command fails, include the relevant error.

## Guardrails

- Do not run the install command before a fresh successful Release build.
- Do not silently change the device name, build mode, platform target, or install command. If the project layout differs, explain the mismatch and ask before adapting the commands.
- If command execution requires approval because it accesses the physical device or writes outside the sandbox, request the narrow approval needed for that command.
