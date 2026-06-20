---
name: zzzmisa-swift-iphone
description: Use when the coding agent modifies AnimalVisionExplorer or another Swift/Xcode iOS app and the change needs real-device verification on MisaのiPhone. Run the Release build targeting MisaのiPhone by device name, then install it with devicectl targeting the same device name before reporting completion.
---

# Swift iPhone Release Install

## Workflow

1. Confirm the current repository contains `AnimalVisionExplorer.xcodeproj`.
2. Run the Release build for `MisaのiPhone` by device name:

   ```bash
   xcodebuild build -project AnimalVisionExplorer.xcodeproj -scheme AnimalVisionExplorer -configuration Release -destination "platform=iOS,name=MisaのiPhone" -derivedDataPath build/DerivedData
   ```

3. If the build succeeds, reinstall the app on `MisaのiPhone` by device name:

   ```bash
   xcrun devicectl device install app --device "MisaのiPhone" build/DerivedData/Build/Products/Release-iphoneos/AnimalVisionExplorer.app
   ```

4. Report the build and install result. If either command fails, include the relevant error.

## Guardrails

- Do not run the install command before a fresh successful Release build.
- Do not silently change the project, scheme, device name, derived data path, or app path. If the project layout differs, explain the mismatch and ask before adapting the commands.
- If command execution requires approval because it accesses the physical device or writes outside the sandbox, request the narrow approval needed for that command.
