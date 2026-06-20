---
name: zzzmisa-swift-se2-simulator
description: Use when the coding agent needs to verify AnimalVisionExplorer or another Swift/Xcode iOS app on an iPhone SE 2nd generation simulator. Create or reuse an iPhone SE2 simulator, boot it, build the app for iOS Simulator, install it with simctl, and launch it for visual checking.
---

# Swift iPhone SE2 Simulator

## Workflow

1. Confirm the current repository contains an iOS Xcode project or workspace. For `AnimalVisionExplorer`, expect `AnimalVisionExplorer.xcodeproj` and scheme `AnimalVisionExplorer`.
2. Check whether an iPhone SE 2nd generation simulator already exists:

   ```bash
   xcrun simctl list devices available
   ```

3. If no suitable simulator exists, confirm the device type and runtime are available:

   ```bash
   xcrun simctl list devicetypes
   xcrun simctl list runtimes available
   ```

   Create a dedicated simulator using the newest available iOS runtime. Prefer a project-specific name such as `iPhone SE2 - AnimalVisionExplorer`:

   ```bash
   xcrun simctl create "iPhone SE2 - <project-name>" com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation- <runtime-id>
   ```

   Use the runtime identifier actually present on the machine, for example `com.apple.CoreSimulator.SimRuntime.iOS-26-5`.

4. Boot the simulator and open Simulator.app:

   ```bash
   xcrun simctl boot <UDID>
   open -a Simulator
   ```

   If the simulator is already booted, continue.

5. Build the app for the SE2 simulator. For `AnimalVisionExplorer`:

   ```bash
   xcodebuild build -project AnimalVisionExplorer.xcodeproj -scheme AnimalVisionExplorer -configuration Debug -destination "platform=iOS Simulator,id=<UDID>" -derivedDataPath build/DerivedData
   ```

   For other projects, preserve the same shape but replace the project or workspace, scheme, and derived data path as appropriate.

6. Install the built simulator app:

   ```bash
   xcrun simctl install <UDID> build/DerivedData/Build/Products/Debug-iphonesimulator/AnimalVisionExplorer.app
   ```

7. Launch the installed app by bundle identifier:

   ```bash
   xcrun simctl launch <UDID> <bundle-id>
   ```

   If the bundle ID is unknown, read it from Xcode build settings:

   ```bash
   xcodebuild -project AnimalVisionExplorer.xcodeproj -scheme AnimalVisionExplorer -showBuildSettings
   ```

   Use the `PRODUCT_BUNDLE_IDENTIFIER` value for the app target.

8. Report the simulator name, UDID, build result, install result, bundle ID, and any runtime exceptions observed after launch.

## Guardrails

- Prefer an existing iPhone SE 2nd generation simulator over creating duplicates.
- Do not substitute a different screen size unless the SE2 device type is unavailable; explain the mismatch before adapting.
- Do not run `simctl install` before a fresh successful simulator build.
- Do not silently change the project, workspace, scheme, configuration, derived data path, app path, or bundle ID. If the project layout differs, explain the mismatch and adapt only when the correct values are discoverable locally.
- Commands that access CoreSimulatorService, Simulator.app, Xcode, or derived data outside the workspace usually require approval. Request narrow approval for those commands.
