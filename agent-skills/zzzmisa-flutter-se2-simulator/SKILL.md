---
name: zzzmisa-flutter-se2-simulator
description: Use when the coding agent needs to verify a Flutter iOS app on an iPhone SE 2nd generation simulator. Create or reuse an iPhone SE2 simulator, boot it, run the Flutter app on that simulator, and leave the Simulator app ready for visual checking.
---

# Flutter iPhone SE2 Simulator

## Workflow

1. Confirm the current repository is a Flutter project with `pubspec.yaml` and an `ios/` directory.
2. Check whether an iPhone SE 2nd generation simulator already exists:

   ```bash
   xcrun simctl list devices available
   ```

3. If no suitable simulator exists, confirm the device type and runtime are available:

   ```bash
   xcrun simctl list devicetypes
   xcrun simctl list runtimes available
   ```

   Create a dedicated simulator using the newest available iOS runtime. Prefer a project-specific name such as `iPhone SE2 - Chibireco` for this repository:

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

5. Verify Flutter can see the simulator:

   ```bash
   flutter devices
   ```

6. Run the app on the SE2 simulator:

   ```bash
   flutter run -d <UDID>
   ```

7. Wait until Flutter reports that the Dart VM Service is available. That indicates the app launched.
8. If the `flutter run` process must be stopped after launch, stop only that run process and avoid touching unrelated Flutter daemons from editors:

   ```bash
   pgrep -alf flutter
   pkill -f "flutter_tools.snapshot run -d <UDID>"
   ```

9. Confirm the simulator remains booted. If needed, relaunch the installed app by bundle identifier:

   ```bash
   xcrun simctl launch <UDID> <bundle-id>
   ```

## Guardrails

- Prefer an existing iPhone SE 2nd generation simulator over creating duplicates.
- Do not substitute a different screen size unless the SE2 device type is unavailable; explain the mismatch before adapting.
- Use the exact UDID from `simctl` output when running Flutter.
- Commands that access CoreSimulatorService, Simulator.app, Flutter caches, or Xcode state usually require approval outside the workspace sandbox. Request narrow approval for those commands.
- Report the simulator name, UDID, bundle ID when known, and any app runtime exceptions observed after launch.
