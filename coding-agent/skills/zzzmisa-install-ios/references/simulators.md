# iOS Simulators

## Configured targets

| Request | Simulator name | Device type |
| --- | --- | --- |
| SE2, iPhone SE2 | `iPhone SE2` | `com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-` |
| iPhone 14 Plus, screenshot iPhone | `Screenshot iPhone 14 Plus` | `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus` |
| iPad Pro 13-inch, screenshot iPad | `Screenshot iPad Pro 13-inch` | Newest available type containing `iPad-Pro-13-inch` |

## Prepare the simulator

1. Find the named simulator with `xcrun simctl list devices available`.
2. If it is missing, confirm the requested type and newest available iOS runtime:

   ```bash
   xcrun simctl list devicetypes
   xcrun simctl list runtimes available
   xcrun simctl create "<simulator-name>" <device-type-id> <runtime-id>
   ```

3. Boot it and open Simulator.app:

   ```bash
   xcrun simctl boot <UDID>
   open -a Simulator
   ```

Continue when it is already booted. Use the same exact UDID for every later command.

## Flutter

1. Confirm `flutter devices` lists the simulator.
2. Run the app with `flutter run -d <UDID>`.
3. Treat the Dart VM Service message as evidence that the app launched.
4. If the run process must stop, inspect `pgrep -alf flutter` and stop only
   `flutter_tools.snapshot run -d <UDID>` for this target; do not kill unrelated editor daemons.
5. Relaunch an installed build when needed with `xcrun simctl launch <UDID> <bundle-id>`.

## Swift/Xcode

1. Resolve the project/workspace and scheme with `xcodebuild -list` when necessary.
2. Build Debug for the exact simulator:

   ```bash
   xcodebuild build -project <Name>.xcodeproj -scheme <Scheme> \
     -configuration Debug -destination "platform=iOS Simulator,id=<UDID>" \
     -derivedDataPath build/DerivedData
   ```

3. Install and launch the successful build:

   ```bash
   xcrun simctl install <UDID> \
     build/DerivedData/Build/Products/Debug-iphonesimulator/<AppName>.app
   xcrun simctl launch <UDID> <bundle-id>
   ```

Read `PRODUCT_BUNDLE_IDENTIFIER` from `xcodebuild -showBuildSettings` when it is unknown.
