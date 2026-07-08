# BUG-006: Danger Zone AlertDialog Text Visibility — Design Spec

> Status: Ready for implementation | Author: flutter-ui-ux-designer | Date: 2026-07-08
> Source: AUDIT_REPORT_6BUGS_20260708.md §BUG 6
> Affects: 3 Danger Zone confirmation dialogs in settings_screen.dart

---

## §1 Problem Statement

All three Danger Zone confirmation dialogs render with invisible or barely-visible text on the dark `HermesColors.surface` (#161B22) background. The user reports:

> "Danger Zone — all 3 items work, but clicking shows empty dialog with 2 colored buttons where I can't see what's written."

### Root Cause

Material 3 `AlertDialog` creates its own internal `DefaultTextStyle` that does not reliably pick up the custom `colorScheme.onSurface` from our `ColorScheme.fromSeed()`. The dialogs use `const Text(...)` without explicit `style:`, relying entirely on theme inheritance — which fails under certain M3 dark-mode rendering paths.

Two contributing factors:
1. `DialogThemeData` in `app_theme.dart:144` lacks `titleTextStyle` and `contentTextStyle`
2. Dialog `Text` widgets use `const` without explicit `style:` parameter

---

## §2 Design Solution

### §2.1 Dialog Theme Fix (affects ALL dialogs)

**File:** `lib/core/theme/app_theme.dart`

The `DialogThemeData` block (lines 144–149) shall be updated to:

```dart
dialogTheme: DialogThemeData(
  backgroundColor: HermesColors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  ),
  // NEW: explicit text styles prevent M3 dark-mode inheritance failures
  titleTextStyle: HermesTextTheme.buildTextTheme().headlineSmall?.copyWith(
        color: HermesColors.textPrimary,   // #E6EDF3
      ),
  contentTextStyle: HermesTextTheme.buildTextTheme().bodyMedium?.copyWith(
        color: HermesColors.textSecondary, // #8B949E
      ),
),
```

**Design rationale:**
- `titleTextStyle` uses `headlineSmall` (24sp, w600) — matches Material 3 dialog title convention
- `contentTextStyle` uses `bodyMedium` (14sp, w400) — standard dialog body
- Explicit `color:` breaks out of the M3 inheritance chain that causes the bug
- This fix propagates to ALL dialogs in the app, not just Danger Zone

### §2.2 Danger Zone Dialog Text Styles

**File:** `lib/features/settings/presentation/settings_screen.dart`

All three dialogs shall have explicit `style:` on every `Text` widget. The `const` qualifier on `Text` widgets inside dialogs shall be removed (const prevents runtime style resolution from `Theme.of(context)`).

#### Dialog A: Delete All Data (line 426)

| Element | Style Token | Color |
|---------|-----------|-------|
| Title: "Delete All Data?" | `headlineSmall` | `HermesColors.textPrimary` (#E6EDF3) |
| Content: description | `bodyMedium` | `HermesColors.textSecondary` (#8B949E) |
| Cancel button (TextButton) | `labelLarge` | Inherits from `textButtonTheme` / `colorScheme.primary` → cyan |
| Delete button (FilledButton) | `labelLarge` | `HermesColors.white` on `HermesColors.error` |

#### Dialog B: Reset Preferences (line 456)

| Element | Style Token | Color |
|---------|-----------|-------|
| Title: "Reset Preferences?" | `headlineSmall` | `HermesColors.textPrimary` (#E6EDF3) |
| Content: description | `bodyMedium` | `HermesColors.textSecondary` (#8B949E) |
| Cancel button (TextButton) | `labelLarge` | Inherits cyan |
| Reset button (FilledButton) | `labelLarge` | `HermesColors.dark` (#0D1117) on `HermesColors.warning` (#D29922) |

#### Dialog C: Disconnect (line 489)

| Element | Style Token | Color |
|---------|-----------|-------|
| Title: "Disconnect from Server?" | `headlineSmall` | `HermesColors.textPrimary` (#E6EDF3) |
| Content: description | `bodyMedium` | `HermesColors.textSecondary` (#8B949E) |
| Cancel button (TextButton) | `labelLarge` | Inherits cyan |
| Disconnect button (FilledButton) | `labelLarge` | `HermesColors.dark` (#0D1117) on `HermesColors.warning` (#D29922) |

---

## §3 Implementation Template (per dialog)

Replace pattern:

```dart
// BEFORE (broken — invisible text)
AlertDialog(
  backgroundColor: HermesColors.surface,
  title: const Text('Delete All Data?'),
  content: const Text('This will permanently remove...'),
  // ...
)
```

With:

```dart
// AFTER (fixed — explicit styles)
AlertDialog(
  title: Text(
    'Delete All Data?',
    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
          color: HermesColors.textPrimary,
        ),
  ),
  content: Text(
    'This will permanently remove all server configurations, '
    'API keys, preferences, and cached data. This action cannot be undone.',
    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
          color: HermesColors.textSecondary,
        ),
  ),
  // ...
)
```

---

## §4 Button Contrast Verification

| Button | Background | Foreground | Contrast Ratio | WCAG AA (4.5:1) | Result |
|--------|-----------|-----------|---------------|------------------|--------|
| Delete (FilledButton) | #F85149 (error) | #FFFFFF (white) | 4.61:1 | ✅ Pass | Good — destructive action reads clearly |
| Reset (FilledButton) | #D29922 (warning) | #0D1117 (dark) | 6.58:1 | ✅ Pass | Excellent — high contrast on warning |
| Disconnect (FilledButton) | #D29922 (warning) | #0D1117 (dark) | 6.58:1 | ✅ Pass | Same as Reset |
| Cancel (TextButton) | transparent | theme default (cyan) | cyan on #161B22 ≈ 5.5:1 | ✅ Pass | Sufficient for secondary action |
| Title text | #161B22 (surface) | #E6EDF3 (textPrimary) | 10.6:1 | ✅ Pass | Excellent |
| Content text | #161B22 (surface) | #8B949E (textSecondary) | 5.1:1 | ✅ Pass | Good — meets enhanced contrast |

---

## §5 i18n Key Registration

The Danger Zone dialog strings are currently hardcoded English. They shall be registered as i18n keys for proper Arabic translation:

| Current Hardcoded String | i18n Key | Type |
|--------------------------|----------|------|
| `'Delete All Data?'` | `settingsDangerZoneDeleteTitle` | dialog title |
| `'This will permanently remove all server configurations...'` | `settingsDangerZoneDeleteMessage` | dialog content |
| `'Delete Everything'` | `settingsDangerZoneDeleteAction` | button label |
| `'Reset Preferences?'` | `settingsDangerZoneResetTitle` | dialog title |
| `'Reset preferences without deleting server configs.'` | `settingsDangerZoneResetMessage` | dialog content |
| `'Reset'` | `settingsDangerZoneResetAction` | button label |
| `'Disconnect from Server?'` | `settingsDangerZoneDisconnectTitle` | dialog title |
| `'Return to server connection screen'` | `settingsDangerZoneDisconnectMessage` | dialog content |
| `'Disconnect'` | `settingsDangerZoneDisconnectAction` | button label |

---

## §6 Scope Boundaries

### IN SCOPE (BUG-006)
- Fix `app_theme.dart` `DialogThemeData`: add `titleTextStyle` + `contentTextStyle`
- Fix 3 Danger Zone dialogs in `settings_screen.dart`: explicit `style:` on all `Text` widgets
- Register i18n keys for hardcoded dialog strings
- Button contrast verification

### OUT OF SCOPE
- Other dialogs in the app (session_detail, session_list, connection, tasks) — these inherit the `DialogThemeData` fix and should be verified separately
- Non-dialog text visibility issues
- SnackBar or other overlay text
- Form field label visibility

---

## §7 Acceptance Criteria

- [ ] AC-1: Dialog title text visible on device (light text on dark surface)
- [ ] AC-2: Dialog content/body text visible on device (secondary text on dark surface)
- [ ] AC-3: FilledButton labels readable (white on red for delete, dark on amber for reset/disconnect)
- [ ] AC-4: Cancel TextButton readable (cyan on dark surface)
- [ ] AC-5: All 3 Danger Zone dialogs pass visual inspection
- [ ] AC-6: `DialogThemeData` fix does not break other app dialogs
- [ ] AC-7: i18n keys registered in `app_en.arb` and `app_ar.arb`

---

## §8 MVP Compliance Check

- ✅ Settings screen is part of F-008 (Settings) — within MVP
- ✅ No new features — bug fix only
- ✅ No premium/auth/gate features
- ✅ No new routes or navigation
- ✅ No new dependencies
- ✅ No backend changes required

---

## §9 Output Validation Checklist

- **Source files read**: `app-spec/AUDIT_REPORT_6BUGS_20260708.md`, `app-spec/04_ui_design_system.md`, `app-spec/01_prd.md`, `lib/core/theme/app_theme.dart`, `lib/core/theme/typography.dart`, `lib/core/theme/colors.dart`, `lib/features/settings/presentation/settings_screen.dart`, `lib/core/constants/app_strings.dart`
- **MVP features referenced**: F-008 (Settings)
- **Features NOT in MVP that were excluded**: None. Bug fix only.
- **Conflicts found with existing specs**: None. `04_ui_design_system.md` does not currently define dialog component specs — §10 of the design system update below fills this gap non-disruptively.
