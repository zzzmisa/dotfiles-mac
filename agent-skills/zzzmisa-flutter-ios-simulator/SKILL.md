---
name: zzzmisa-flutter-ios-simulator
description: Use when the coding agent needs to verify a Flutter iOS app on one of Misa's named iOS simulators: `iPhone SE2`, `Screenshot iPhone 14 Plus`, or `Screenshot iPad Pro 13-inch`. Create or reuse the requested simulator, boot it, run the Flutter app on it, and leave the simulator ready for visual checking or screenshots.
---

# Flutter iOS Simulator

## Simulator Targets

Use the user's requested target when specified. If the request only says "SE2", "iPhone 14 Plus", "iPad Pro 13-inch", or screenshot verification, map it as follows:

| Request | Simulator name | Device type |
| --- | --- | --- |
| SE2, iPhone SE2 | `iPhone SE2` | `com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-` |
| iPhone 14 Plus, screenshot iPhone | `Screenshot iPhone 14 Plus` | `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus` |
| iPad Pro 13-inch, screenshot iPad | `Screenshot iPad Pro 13-inch` | Prefer the newest available device type containing `iPad-Pro-13-inch` |

## Workflow

1. Confirm the current repository is a Flutter project with `pubspec.yaml` and an `ios/` directory.
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

6. Verify Flutter can see the simulator:

   ```bash
   flutter devices
   ```

7. Run and install the development app on the simulator:

   ```bash
   flutter run -d <UDID>
   ```

8. Wait until Flutter reports that the Dart VM Service is available. That indicates the app launched.
9. If the `flutter run` process must be stopped after launch, stop only that run process and avoid touching unrelated Flutter daemons from editors:

   ```bash
   pgrep -alf flutter
   pkill -f "flutter_tools.snapshot run -d <UDID>"
   ```

10. Confirm the simulator remains booted. If needed, relaunch the installed app by bundle identifier:

    ```bash
    xcrun simctl launch <UDID> <bundle-id>
    ```

## Guardrails

- Prefer an existing simulator with the exact target name over creating duplicates.
- Do not substitute a different screen size unless the requested device type is unavailable; explain the mismatch before adapting.
- Use the exact UDID from `simctl` output when running Flutter.
- Commands that access CoreSimulatorService, Simulator.app, Flutter caches, or Xcode state usually require approval outside the workspace sandbox. Request narrow approval for those commands.
- Report the simulator name, UDID, bundle ID when known, and any app runtime exceptions observed after launch.
