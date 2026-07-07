# MisaのiPhone — Device Info & Debugging Tips

## Device

- Model: iPhone 17, device name `MisaのiPhone`
- `xcodebuild` / `devicectl` / `flutter` all accept the device name; when a UUID is required, look it up with:

  ```bash
  xcrun devicectl list devices
  ```

## Debugging Tips

- To capture `print` output from the app running on the physical device, add diagnostic code triggered by a launch argument and launch with console attached:

  ```bash
  xcrun devicectl device process launch --console --device "MisaのiPhone" <bundle-id>
  ```

  (`log collect --device` requires sudo, so prefer the `--console` approach.)

- iOS never re-prompts a permission dialog once the user has denied it. When a feature fails silently on the device (e.g. saving to the photo library), check the permission state in the Settings app first, and make sure the app offers an "open Settings" path for the denied state.
