# iOS Debugging

## Simulator permissions

Script TCC state to reproduce permission paths:

```bash
xcrun simctl privacy <UDID> grant photos-add <bundle-id>
xcrun simctl privacy <UDID> revoke photos-add <bundle-id>
xcrun simctl privacy <UDID> reset photos-add <bundle-id>
```

Services such as `photos`, `camera`, `microphone`, and `location` follow the same form. Use `reset` to make the permission prompt appear again.

## Physical-device console

`MisaのiPhone` is an iPhone 17. Launch an installed app with its console attached when diagnostic output is needed:

```bash
xcrun devicectl device process launch --console --device "MisaのiPhone" <bundle-id>
```

Prefer this to `log collect --device`, which requires `sudo`.

On a physical device, iOS does not show a permission prompt again after denial. Check Settings first and verify that the app provides an Open Settings path for denied permissions.
