# 10 — DevOps, Release & Observability

> **MoA Audit:** 2026-07-06 — Expanded from 19 lines to full Android build specification.
> **Drives:** flutter-devops-release-engineer SOUL §12, flutter-lead-architect SOUL §14.

---

## 1. Build Commands

```bash
# Android
flutter build apk --release          # Single APK
flutter build apk --split-per-abi    # Per-ABI APKs (smaller)
flutter build appbundle              # Play Store bundle

# iOS
flutter build ipa                    # Requires Xcode + signing
```

---

## 2. Android Build Configuration

### 2.1 Namespace (LL-024 — CRITICAL)

**Rule:** `namespace` in `build.gradle.kts` MUST equal the `package` declaration in `MainActivity.kt`.

```kotlin
// android/app/build.gradle.kts
android {
    namespace = "com.jahfali.hermex_android"  // ← This!
}

// android/app/src/main/kotlin/com/jahfali/hermex_android/MainActivity.kt
package com.jahfali.hermex_android  // ← Must match!
```

**Why:** AndroidManifest resolves `android:name=".MainActivity"` relative to namespace.
Mismatch → `ClassNotFoundException` → app crashes before splash screen.

### 2.2 Isar + ProGuard/R8 (LL-025 — CRITICAL)

**Rule:** If `isar:` in `pubspec.yaml`, `isMinifyEnabled` MUST be `false`.

```kotlin
buildTypes {
    release {
        isMinifyEnabled = false  // REQUIRED for Isar
        isShrinkResources = false
    }
}
```

**Why:** R8 strips classes not directly referenced in Java/Kotlin. Isar adapter classes are loaded reflectively → stripped → `IsarError` crash.

**If minification is required:** Add explicit `-keep` rules from isar.dev:
```proguard
-keep class io.isar.** { *; }
-keep class * extends io.isar.IsarCollectionSchema { *; }
-keepclassmembers class * { @io.isar.annotations.** <fields>; }
```

### 2.3 AGP + isar_flutter_libs Compatibility

**Rule:** If `isar_flutter_libs` in `pubspec.yaml`, add AGP 8.8+ compat hook in `android/build.gradle.kts`.

```kotlin
gradle.projectsEvaluated {
    subprojects {
        if (name == "isar_flutter_libs") {
            tasks.matching { it.name.contains("verifyReleaseResources") }.configureEach {
                enabled = false
            }
            tasks.matching { it.name.startsWith("process") && it.name.contains("Manifest") }.configureEach {
                doFirst {
                    val mf = file("${project.projectDir}/src/main/AndroidManifest.xml")
                    if (mf.exists() && mf.readText().contains("package=")) {
                        mf.writeText(mf.readText().replace(Regex("""package="[^"]*"\s*"""), ""))
                    }
                }
            }
        }
    }
}
```

---

## 3. Android Preflight Gate (LL-024, LL-025 Enforcement)

**Before EVERY `flutter build apk`:**
```bash
bash scripts/android-preflight.sh
```

The script checks:
| Gate | Check | Failure |
|------|-------|---------|
| 1 | `namespace` == `MainActivity.kt` package | ClassNotFoundException |
| 2 | Isar + `isMinifyEnabled` compatibility | IsarError crash |
| 3 | `applicationId` consistency | Install conflicts |
| 4 | `isar_flutter_libs` + AGP compat hook | Build failure |

**Exit code 0 = all gates passed.** Non-zero = BLOCKED.

---

## 4. CI/CD — GitHub Actions

### Workflow Template
```yaml
name: Build & Release APK
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Android Preflight Check
        run: bash scripts/android-preflight.sh
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.6'
          channel: 'stable'
          cache: true
      
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
      
      - name: Publish to Releases
        uses: softprops/action-gh-release@v2
        with:
          tag_name: latest
          name: "Latest APK Build"
          files: build/app/outputs/flutter-apk/app-release.apk
          make_latest: true
```

### CI Environment Drift Prevention
- `flutter-version` in CI MUST match local `flutter --version`
- AGP on `ubuntu-latest` is ALWAYS newer than local Mac's bundled AGP
- Never trust "works on my machine" — test in CI

---

## 5. ProGuard/R8 — Complete Rules

```proguard
# ─── Flutter Engine ───
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }

# ─── Isar (LL-025) ───
-keep class io.isar.** { *; }
-keep class * extends io.isar.IsarCollectionSchema { *; }
-keepclassmembers class * { @io.isar.annotations.** <fields>; }

# ─── Dio / OkHttp ───
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ─── Flutter Secure Storage ───
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── App Code ───
-keep class com.jahfali.hermex_android.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ─── Google Play Core (unused, suppress warnings) ───
-dontwarn com.google.android.play.core.**
```

---

## 6. Release Gates

| Gate | Check | Blocker? |
|------|-------|:--------:|
| Android Preflight | All 4 gates passed | 🔴 BLOCK if fail |
| flutter analyze | 0 errors | 🔴 BLOCK if fail |
| flutter test | All pass, count ≥ previous | 🔴 BLOCK if fail |
| Zero-Trust Audit | Clean for critical features | 🔴 BLOCK if fail |
| Device Test | APK installed on real device, app opens | 🔴 BLOCK if crash |
| APK Size | < 80MB (with Isar native libs) | 🟡 WARNING |
| API Connectivity | Server reachable on port 8642 | 🟡 WARNING |

---

## 7. Versioning

Semantic versioning: `MAJOR.MINOR.PATCH`

```yaml
# pubspec.yaml
version: 0.1.0+1
#        ^ ^ ^ ^
#        | | | build number (integer, must increase each release)
#        | | patch
#        | minor
#        major
```

---

## 8. Mandatory Skills for DevOps Engineer

Before any release task, the DevOps Engineer MUST load:
- `/android/flutter-android-build-system` — Complete Android build reference
- `/android/android-preflight-verification` — Machine-enforceable verification gate

---

## 9. Knowledge Sources (MoA-Verified)

| Source | Content | Verified |
|--------|---------|:--------:|
| developer.android.com/build | AGP, namespace, ProGuard/R8, build types | ✅ |
| isar.dev | Isar ProGuard keep rules | ✅ |
| docs.flutter.dev/deployment/android | Flutter Android deployment | ✅ |
| github.com/android/skills | ❌ NOT for build config (app code only) | ❌ |

---

## 10. Evolution

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07-04 | Initial — 19 lines |
| 2.0 | 2026-07-06 | MoA audit — expanded to full Android build spec + preflight gate |
