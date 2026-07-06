#!/bin/bash
# android-preflight.sh — MoA-Audited Android Build Verification Gate
# LL-024, LL-025 enforcement — 2026-07-06
#
# Run before EVERY flutter build apk.
# Exit code 0 = all gates passed. Non-zero = blocked.
#
# Usage:
#   bash scripts/android-preflight.sh && flutter build apk --release

set -euo pipefail
PASS=0
FAIL=0

echo "=============================================="
echo " Android Preflight Verification"
echo " Gate: LL-024 (namespace) + LL-025 (Isar/ProGuard)"
echo "=============================================="

# Helper: extract value from gradle property
# Usage: gradle_prop "namespace" android/app/build.gradle.kts
gradle_prop() {
    grep "$1" "$2" 2>/dev/null | head -1 | sed 's/.*'"$1"' *= *"\([^"]*\)".*/\1/'
}

# ──────────────────────────────────────────────
# Gate 1: namespace in build.gradle.kts == MainActivity.kt package
# ──────────────────────────────────────────────
echo ""
echo "── Gate 1: Namespace vs MainActivity Package ──"

NS=$(gradle_prop "namespace" android/app/build.gradle.kts)
PKG=$(find android/app/src/main/kotlin -name "*.kt" -exec grep '^package' {} \; 2>/dev/null | head -1 | sed 's/package //' | tr -d '[:space:]')

if [ -z "$NS" ]; then
    echo "❌  FAILED: Cannot extract namespace from build.gradle.kts"
    ((FAIL++))
elif [ -z "$PKG" ]; then
    echo "❌  FAILED: Cannot find MainActivity.kt or extract package"
    ((FAIL++))
elif [ "$NS" != "$PKG" ]; then
    echo "❌  FAILED"
    echo "   namespace  = '$NS'  (in build.gradle.kts)"
    echo "   package    = '$PKG'  (in MainActivity.kt)"
    echo "   Fix: Make them identical. See: /android/flutter-android-build-system §1"
    ((FAIL++))
else
    echo "✅  PASSED: namespace == package ($NS)"
    ((PASS++))
fi

# ──────────────────────────────────────────────
# Gate 2: Isar + isMinifyEnabled compatibility
# ──────────────────────────────────────────────
echo ""
echo "── Gate 2: Isar + ProGuard/R8 Compatibility ──"

if grep -q 'isar:' pubspec.yaml 2>/dev/null; then
    echo "   Isar detected in pubspec.yaml"
    if grep -q 'isMinifyEnabled *= *true' android/app/build.gradle.kts 2>/dev/null; then
        echo "❌  FAILED: isMinifyEnabled=true with Isar dependency"
        echo "   R8 strips Isar adapter classes (loaded reflectively) → IsarError crash."
        echo "   Fix: Set isMinifyEnabled=false, or add -keep rules from /android/flutter-android-build-system §2"
        ((FAIL++))
    else
        echo "✅  PASSED: isMinifyEnabled is false (or not set)"
        ((PASS++))
    fi
else
    echo "✅  PASSED: Isar not detected — no conflict possible"
    ((PASS++))
fi

# ──────────────────────────────────────────────
# Gate 3: applicationId consistency
# ──────────────────────────────────────────────
echo ""
echo "── Gate 3: applicationId Consistency ──"

APP_ID=$(gradle_prop "applicationId" android/app/build.gradle.kts)
if [ -n "$APP_ID" ] && [ -n "$NS" ] && [ "$APP_ID" != "$NS" ]; then
    echo "⚠️   WARNING: applicationId='$APP_ID' ≠ namespace='$NS'"
    echo "   Valid but unusual. Verify intent."
    ((PASS++))
elif [ -n "$APP_ID" ]; then
    echo "✅  PASSED: applicationId == namespace ($APP_ID)"
    ((PASS++))
else
    echo "⚠️   WARNING: Could not extract applicationId"
    ((PASS++))
fi

# ──────────────────────────────────────────────
# Gate 4: isar_flutter_libs + AGP 8.8+ compatibility hook
# ──────────────────────────────────────────────
echo ""
echo "── Gate 4: isar_flutter_libs + AGP 8.8+ Compat ──"

if grep -q 'isar_flutter_libs' pubspec.yaml 2>/dev/null; then
    echo "   isar_flutter_libs detected in pubspec.yaml"
    if grep -q 'gradle.projectsEvaluated' android/build.gradle.kts 2>/dev/null; then
        echo "✅  PASSED: AGP compat hook present"
        ((PASS++))
    else
        echo "❌  FAILED: isar_flutter_libs detected but no AGP 8.8+ compat hook"
        echo "   isar_flutter_libs carries package attribute → rejected by AGP 8.8+"
        echo "   Fix: Add gradle.projectsEvaluated block. See /android/flutter-android-build-system §3"
        ((FAIL++))
    fi
else
    echo "✅  PASSED: isar_flutter_libs not detected"
    ((PASS++))
fi

# ──────────────────────────────────────────────
# Gate 5: network_security_config.xml — cleartext traffic (LL-027)
# ──────────────────────────────────────────────
echo ""
echo "── Gate 5: Android Cleartext HTTP (LL-027) ──"

NSC_FILE="android/app/src/main/res/xml/network_security_config.xml"
if [ -f "$NSC_FILE" ]; then
    if grep -q 'base-config.*cleartextTrafficPermitted="false"' "$NSC_FILE" 2>/dev/null; then
        echo "❌  FAILED: network_security_config blocks cleartext HTTP globally"
        echo "   Android will silently drop HTTP connections to IPs not in the whitelist."
        echo "   Fix: Set base-config cleartextTrafficPermitted=\"true\" (LL-027)"
        ((FAIL++))
    else
        echo "✅  PASSED: cleartext traffic not globally blocked"
        ((PASS++))
    fi
else
    echo "⚠️   WARNING: network_security_config.xml not found"
    ((PASS++))
fi

# ──────────────────────────────────────────────
# Verdict
# ──────────────────────────────────────────────
echo ""
echo "=============================================="
echo " VERDICT: $PASS passed, $FAIL failed"
echo "=============================================="

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "🛑  BUILD BLOCKED — $FAIL gate(s) failed."
    echo "   Fix the issues above, then re-run:"
    echo "   bash scripts/android-preflight.sh"
    exit 1
else
    echo ""
    echo "✅  ALL GATES PASSED — Safe to build."
    echo "   Run: flutter build apk --release"
    exit 0
fi
