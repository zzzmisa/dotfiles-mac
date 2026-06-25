---
name: zzzmisa-swift-ios-simulator
description: Use when the coding agent needs to verify AnimalVisionExplorer or another Swift/Xcode iOS app on one of Misa's named iOS simulators: `iPhone SE2`, `Screenshot iPhone 14 Plus`, or `Screenshot iPad Pro 13-inch`. Create or reuse the requested simulator, boot it, build the app for iOS Simulator, install it with simctl, and launch it for visual checking or screenshots.
---

# Swift iOS Simulator

## Simulator Targets

Use the user's requested target when specified. If the request only says "SE2", "iPhone 14 Plus", "iPad Pro 13-inch", or screenshot verification, map it as follows:

| Request | Simulator name | Device type |
| --- | --- | --- |
| SE2, iPhone SE2 | `iPhone SE2` | `com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-` |
| iPhone 14 Plus, screenshot iPhone | `Screenshot iPhone 14 Plus` | `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus` |
| iPad Pro 13-inch, screenshot iPad | `Screenshot iPad Pro 13-inch` | Prefer the newest available device type containing `iPad-Pro-13-inch` |

## Workflow

1. Confirm the current repository contains an iOS Xcode project or workspace. For `AnimalVisionExplorer`, expect `AnimalVisionExplorer.xcodeproj` and scheme `AnimalVisionExplorer`.
2. Decide the simulator target from the request and the table above.
3. Check whether the named simulator already exists:

   ```bash
   xcrun simctl list devices available
   ```

4. If no matching simulator exists, confirm the requested device type and runtime are available:

   ```bash
   xcrun simctl list devicetypes
   xcrun simctl list runtimes available
   ```

   Create the simulator using the newest available iOS runtime:

   ```bash
   xcrun simctl create "<simulator-name>" <device-type-id> <runtime-id>
   ```

   Use identifiers actually present on the machine, for example runtime `com.apple.CoreSimulator.SimRuntime.iOS-26-5`.

5. Boot the simulator and open Simulator.app:

   ```bash
   xcrun simctl boot <UDID>
   open -a Simulator
   ```

   If the simulator is already booted, continue.

6. Build the app for the simulator. For `AnimalVisionExplorer`:

   ```bash
   xcodebuild build -project AnimalVisionExplorer.xcodeproj -scheme AnimalVisionExplorer -configuration Debug -destination "platform=iOS Simulator,id=<UDID>" -derivedDataPath build/DerivedData
   ```

   For other projects, preserve the same shape but replace the project or workspace, scheme, and derived data path as appropriate.

7. Install the built simulator app:

   ```bash
   xcrun simctl install <UDID> build/DerivedData/Build/Products/Debug-iphonesimulator/AnimalVisionExplorer.app
   ```

8. Launch the installed app by bundle identifier:

   ```bash
   xcrun simctl launch <UDID> <bundle-id>
   ```

   If the bundle ID is unknown, read it from Xcode build settings:

   ```bash
   xcodebuild -project AnimalVisionExplorer.xcodeproj -scheme AnimalVisionExplorer -showBuildSettings
   ```

   Use the `PRODUCT_BUNDLE_IDENTIFIER` value for the app target.

9. Report the simulator name, UDID, build result, install result, bundle ID, and any runtime exceptions observed after launch.

## Guardrails

- Prefer an existing simulator with the exact target name over creating duplicates.
- Do not substitute a different screen size unless the requested device type is unavailable; explain the mismatch before adapting.
- Do not run `simctl install` before a fresh successful simulator build.
- Do not silently change the project, workspace, scheme, configuration, derived data path, app path, or bundle ID. If the project layout differs, explain the mismatch and adapt only when the correct values are discoverable locally.
- Commands that access CoreSimulatorService, Simulator.app, Xcode, or derived data outside the workspace usually require approval. Request narrow approval for those commands.
