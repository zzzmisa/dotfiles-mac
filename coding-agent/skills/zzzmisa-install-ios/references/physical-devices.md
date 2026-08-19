# Physical iOS Devices

## Targets

| Purpose | Device name |
| --- | --- |
| Phone verification | `MisaのiPhone` |
| iPad verification | `ミサのiPad` |

Use the exact device name throughout the build and install workflow.

## Flutter

1. Build the Release app:

   ```bash
   flutter build ios --release
   ```

2. After a successful build, install it:

   ```bash
   flutter install -d "<device-name>" --release
   ```

## Swift/Xcode

1. Identify the project/workspace and scheme. Use `xcodebuild -list` when unknown.
2. Build Release for the selected device. Use `-workspace` instead of `-project` when applicable:

   ```bash
   xcodebuild build -project <Name>.xcodeproj -scheme <Scheme> \
     -configuration Release -destination "platform=iOS,name=<device-name>" \
     -derivedDataPath build/DerivedData
   ```

3. After a successful build, install the app:

   ```bash
   xcrun devicectl device install app --device "<device-name>" \
     build/DerivedData/Build/Products/Release-iphoneos/<AppName>.app
   ```

If a UUID is required, resolve it with `xcrun devicectl list devices`; do not guess it.
