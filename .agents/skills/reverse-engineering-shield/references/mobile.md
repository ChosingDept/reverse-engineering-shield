# Mobile apps

APKs and IPAs are archives. JavaScript bundles, Dart snapshots and Java/Kotlin bytecode
can all be decompiled.

## React Native / Expo

- Keep **Hermes** enabled (default in recent Expo/React Native). The bundle becomes
  bytecode, much more expensive to read than plain JS. The audit script checks the magic
  bytes of `index.android.bundle` / `main.jsbundle`.
- `EXPO_PUBLIC_*` values and `app.json` → `extra` are shipped in clear text. No secrets.
- Android release: enable R8/ProGuard (with Expo: `expo-build-properties` →
  `android.enableProguardInReleaseBuilds: true`).
- Do not ship source maps inside the app; upload them to your error tracker only.

## Native Android

- `minifyEnabled true` and `shrinkResources true` in release builds.
- Keep secrets out of `strings.xml`, `BuildConfig` and assets.
- Use Play Integrity on sensitive endpoints (server verifies the token).

## Native iOS

- Strip debug symbols from the release binary; keep dSYMs only in your crash reporter.
- Keep secrets out of `Info.plist` and bundled JSON.
- Use App Attest / DeviceCheck on sensitive endpoints (server verifies).

## Flutter

- Build with `--obfuscate --split-debug-info=<dir>` and keep the symbol files private.

## Optional hardening (delays, does not stop)

- Certificate pinning for apps that move money or run automations.
- Root/jailbreak and debugger detection, reported to the server rather than only
  blocking locally.

## Verify

```bash
scripts/audit.sh app-release.apk
scripts/audit.sh App.ipa
```
