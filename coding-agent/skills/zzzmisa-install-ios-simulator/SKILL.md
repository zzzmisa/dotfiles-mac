---
name: zzzmisa-install-ios-simulator
description: Use when the coding agent needs to verify the current Flutter or Swift/Xcode iOS app on one of Misa's named iOS simulators: `iPhone SE2`, `Screenshot iPhone 14 Plus`, or `Screenshot iPad Pro 13-inch`. Detect Flutter vs Swift from the project, create or reuse the requested simulator, boot it, install/run the app, and leave the simulator ready for visual checking or screenshots.
---

# iOS Simulator

When testing permission-related behavior, read [references/debugging-tips.md](references/debugging-tips.md) for scripting simulator permission (TCC) state.

## Project Detection

- Treat the project as Flutter when `pubspec.yaml` and `ios/` exist.
- Treat the project as Swift/Xcode when an `.xcodeproj` or `.xcworkspace` exists and no Flutter project markers are present.
- If both appear, prefer Flutter unless the user explicitly asks for Swift/Xcode.
- If neither is discoverable, stop and explain what project markers were missing.

## Simulator Targets

Use the user's requested target when specified. If the request only says "SE2", "iPhone 14 Plus", "iPad Pro 13-inch", or screenshot verification, map it as follows:

| Request | Simulator name | Device type |
| --- | --- | --- |
| SE2, iPhone SE2 | `iPhone SE2` | `com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-` |
| iPhone 14 Plus, screenshot iPhone | `Screenshot iPhone 14 Plus` | `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus` |
| iPad Pro 13-inch, screenshot iPad | `Screenshot iPad Pro 13-inch` | Prefer the newest available device type containing `iPad-Pro-13-inch` |

If no target is specified and no prior context selects one, ask which simulator to use.

## Shared Simulator Workflow

1. Detect the project type and simulator target.
2. Check whether the named simulator already exists:

   ```bash
   xcrun simctl list devices available
   ```

3. If no matching simulator exists, confirm the requested device type and runtime are available:

   ```bash
   xcrun simctl list devicetypes
   xcrun simctl list runtimes available
   ```

   Create the simulator using the newest available iOS runtime:

   ```bash
   xcrun simctl create "<simulator-name>" <device-type-id> <runtime-id>
   ```

4. Boot the simulator and open Simulator.app:

   ```bash
   xcrun simctl boot <UDID>
   open -a Simulator
   ```

   If the simulator is already booted, continue.

## Flutter Workflow

1. Verify Flutter can see the simulator:

   ```bash
   flutter devices
   ```

2. Run and install the development app on the simulator:

   ```bash
   flutter run -d <UDID>
   ```

3. Wait until Flutter reports that the Dart VM Service is available. That indicates the app launched.
4. If the `flutter run` process must be stopped after launch, stop only that run process and avoid touching unrelated Flutter daemons from editors:

   ```bash
   pgrep -alf flutter
   pkill -f "flutter_tools.snapshot run -d <UDID>"
   ```

5. Confirm the simulator remains booted. If needed, relaunch the installed app by bundle identifier:

   ```bash
   xcrun simctl launch <UDID> <bundle-id>
   ```

## Swift/Xcode Workflow

1. Identify the project or workspace and scheme. When unknown, list them with:

   ```bash
   xcodebuild -list
   ```

2. Build the app for the simulator (use `-workspace <Name>.xcworkspace` instead of `-project` when the project uses a workspace):

   ```bash
   xcodebuild build -project <Name>.xcodeproj -scheme <Scheme> -configuration Debug -destination "platform=iOS Simulator,id=<UDID>" -derivedDataPath build/DerivedData
   ```

3. Install the built simulator app:

   ```bash
   xcrun simctl install <UDID> build/DerivedData/Build/Products/Debug-iphonesimulator/<AppName>.app
   ```

4. Launch the installed app by bundle identifier:

   ```bash
   xcrun simctl launch <UDID> <bundle-id>
   ```

   If the bundle ID is unknown, read it from Xcode build settings:

   ```bash
   xcodebuild -project <Name>.xcodeproj -scheme <Scheme> -showBuildSettings
   ```

   Use the `PRODUCT_BUNDLE_IDENTIFIER` value for the app target.

## Guardrails

- Prefer an existing simulator with the exact target name over creating duplicates.
- Do not substitute a different screen size unless the requested device type is unavailable; explain the mismatch before adapting.
- Do not run `simctl install` before a fresh successful simulator build.
- Use the exact UDID from `simctl` output for boot, run, install, and launch commands.
- Commands that access CoreSimulatorService, Simulator.app, Flutter caches, Xcode, or derived data outside the workspace usually require approval. Request narrow approval for those commands.
- Report the project type, simulator name, UDID, bundle ID when known, and any build, install, launch, or runtime issue observed.
