# Simulator Debugging Tips

## Controlling permission (TCC) state for testing

Simulator permission state can be scripted, which makes permission-denied scenarios reproducible (unlike physical devices, where iOS never re-prompts after a denial):

```bash
xcrun simctl privacy <UDID> grant photos-add <bundle-id>
xcrun simctl privacy <UDID> revoke photos-add <bundle-id>
xcrun simctl privacy <UDID> reset photos-add <bundle-id>
```

Other services (`photos`, `camera`, `microphone`, `location`, etc.) work the same way. Use `reset` to make the permission dialog appear again on next access.
