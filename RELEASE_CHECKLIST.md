# RELEASE_CHECKLIST.md — Hermex Android

Version: 0.1.0 (build 1) | Date: 2026-07-05

## Release Gates

- [ ] **All tests pass** — `flutter test` (unit + widget tests)
- [ ] **Zero-trust audit clean** — no secrets, no hardcoded keys, secure storage used
- [ ] **APK size < 30MB** (per-ABI) — arm64: ~20MB, fat: ~53MB
- [ ] **API server connectivity verified** — health check against Hermes Agent API Server (port 8642)
- [ ] **No debug logging in release build** — `debugPrint` stripped, `kDebugMode` false
- [ ] **No ProGuard/R8 missing class errors** — R8 passes with dontwarn for Play Core
- [ ] **Crash reporting configured** — (future: Firebase Crashlytics or Sentry)
- [ ] **Release APK signed** — currently debug-signed; production keystore needed
- [ ] **AndroidManifest secure** — allowBackup=false, cleartext localhost only

## Build Artifacts

| Artifact | Path | Size |
|----------|------|------|
| Debug APK (fat) | `build/app/outputs/flutter-apk/app-debug.apk` | ~155 MB |
| Release APK (fat) | `build/app/outputs/flutter-apk/app-release.apk` | ~53 MB |
| Release APK (arm64) | `build/app/outputs/flutter-apk/app-release.apk` | ~20 MB |

## Configuration Summary

| Setting | Value |
|---------|-------|
| Application ID | `com.jahfali.hermex_android` |
| Version Name | `0.1.0` |
| Version Code | `1` |
| Min SDK | 26 (Android 8.0) |
| Target SDK | 34 (Android 14) |
| Compile SDK | 36 |
| Kotlin | 2.2.20 |
| AGP | 8.11.1 |
| Gradle | 8.14 |
| iOS Min | 16.0 |

## Known Issues (Non-blocking)

- Kotlin daemon connection warnings (non-fatal, falls back to non-daemon mode)
- `isar_flutter_libs` verifyReleaseResources disabled (AGP 8.11+ compat, no impact on runtime)
- Release APK signed with debug keystore (production keystore needed before store submission)
- `shrinkResources` disabled temporarily due to isar lStar issue
- `google_fonts` bundles all font assets (can be optimized with `--no-tree-shake-icons` already active)

## Rollback Plan

1. Revert to previous APK from build artifacts
2. Version stays at 0.1.0 until next build
3. No database migrations in this version (no rollback needed for data)

## Sign-off

- [ ] DevOps Release Engineer
- [ ] Lead Architect
- [ ] Zero-Trust Auditor
