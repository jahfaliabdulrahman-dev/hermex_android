# HERMEX-008: Light-Theme Fix Spec — Hardcoded Color Remediation

> Phase 1b — UI/UX Design Spec (No Implementation Code)
> Author: flutter-ui-ux-designer
> Date: 2026-07-15
> Source: GOAL_RC6_COMPREHENSIVE_REMEDIATION.md §F.21-F.22

---

## §1 Overview

This spec documents every hardcoded `HermesColors` token that does NOT adapt to theme brightness, and specifies the exact theme-adaptive replacement for each. When implemented, all these fixes will make the light theme visually correct instead of showing dark-theme colors on light backgrounds.

### §1.1 Current State

The theme infrastructure (`app_theme.dart` + `colors.dart`) is correctly wired for dual-theme support:
- `buildDark()` / `buildLight()` produce complete `ThemeData`
- `ColorScheme` swaps correctly between dark and light tokens
- `_buildBaseTheme()` computes brightness-aware `accentColor` and `hintColor`

However, many widgets bypass the `ColorScheme` and reference `HermesColors` constants directly — these always resolve to dark-theme values regardless of brightness.

### §1.2 Replacement Rules

| Context | Current (Hardcoded) | Replacement (Theme-Adaptive) |
|---|---|---|
| Agent bubble background | `HermesColors.agentBubble` | `Theme.of(context).colorScheme.surfaceContainerHighest` |
| Disabled/muted icon | `HermesColors.textDisabled` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| Disabled/muted text | `HermesColors.textDisabled` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| Hint text in input fields | `TextStyle(color: HermesColors.textDisabled)` | `Theme.of(context).inputDecorationTheme.hintStyle` |
| Empty state icon (muted) | `HermesColors.textDisabled` | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |

### §1.3 Why `withValues(alpha: 0.38)`?

Material 3 spec defines disabled/placeholder content opacity as 38% of `onSurface`. This is the standard M3 approach that auto-adapts to theme brightness:
- Dark theme: 38% of `#E6EDF3` ≈ `#5C6066` (similar to boosted textDisabled)
- Light theme: 38% of `#1F2328` ≈ `#4D5156` (appropriate muted tone on white)

---

## §2 Fix F.21 — Agent Bubble Background

### §2.1 Defect

**File**: `lib/features/chat/presentation/message_bubble.dart`
**Line**: 141
**Code**:
```dart
decoration: BoxDecoration(
  color: HermesColors.agentBubble,  // #161B22 — always dark
  ...
),
```

**Problem**: In light theme, the agent bubble shows as a dark `#161B22` rectangle on a white/light background — the single most user-visible theme defect. Flagged in `UX_SIGNOFF_RC5.md` and still unfixed.

### §2.2 Fix

```dart
decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
  ...
),
```

**Why `colorScheme.surfaceContainerHighest`**:
- Dark theme: `#1B2333` (M3 surfaceContainerHighest on Hermes surface) — a slightly elevated surface tone that creates a distinct bubble against the dark scaffold
- Light theme: `#DCE4ED` (M3 surfaceContainerHighest on Hermes lightSurface) — appropriate elevated card color that contrasts against `colorScheme.surface` scaffold background
- `colorScheme.surface` is already consumed by `scaffoldBackground` in `buildLight()` (app_theme.dart:31), so it would create zero visual separation — the bubble would disappear into the background
- `surfaceContainerHighest` is the correct M3 token for a distinct card-like element sitting on top of the surface — consistent with its usage in `hermex_model_selector_ui_spec.md` CMP-001

### §2.3 Verification

After fix, in light theme:
- Agent bubble: slightly elevated grey-blue `#DCE4ED` (surfaceContainerHighest), visually distinct from the `#F0F6FC` surface scaffold
- User bubble: adapted cyan `#0077A3` (already handled)

**Note**: The user bubble (`HermesColors.userBubble` = `#32C2FF`) is NOT flagged in F.21. However, for full correctness, it should also be theme-adaptive. Per the design system §1.5, on light backgrounds cyan swaps to `#0077A3`. This is a SEPARATE concern — `HermesColors.userBubble` is used on line 75 of message_bubble.dart and ALSO needs the same treatment. The State Engineer should apply the same pattern:

```dart
// User bubble background — theme-adaptive
color: Theme.of(context).brightness == Brightness.light
    ? HermesColors.lightSecondary   // #0077A3 (WCAG AA on white)
    : HermesColors.userBubble,      // #32C2FF
```

Similarly for `HermesColors.userBubbleText` (line 92) and `HermesColors.agentBubbleText` — though `agentBubbleText` (#E6EDF3 on dark) would need `colorScheme.onSurface` on light.

---

## §3 Fix F.22 — Hardcoded `textDisabled` Instances

### §3.1 File: `settings_screen.dart` (3 instances)

| # | Line | Current Code | Context | Replacement |
|---|---|---|---|---|
| 1 | 136 | `Icon(Icons.dns_outlined, color: HermesColors.textDisabled, size: 32)` | Empty servers icon | `color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 2 | 227 | `hintStyle: TextStyle(color: HermesColors.textDisabled)` | Model input hint text | `hintStyle: Theme.of(context).inputDecorationTheme.hintStyle` |
| 3 | 643 | `color: isActive ? HermesColors.success : HermesColors.textDisabled` | Inactive server icon | `color: isActive ? HermesColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |

**Line 136 — Detail**:
```dart
// BEFORE
Icon(Icons.dns_outlined, color: HermesColors.textDisabled, size: 32),

// AFTER
Icon(Icons.dns_outlined,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  size: 32),
```

**Line 227 — Detail**:
```dart
// BEFORE
decoration: InputDecoration(
  hintText: 'e.g., deepseek-v4-pro',
  hintStyle: TextStyle(color: HermesColors.textDisabled),
  ...
)

// AFTER
decoration: InputDecoration(
  hintText: 'e.g., deepseek-v4-pro',
  // hintStyle: inherits from Theme.of(context).inputDecorationTheme.hintStyle
  // which is already brightness-aware per app_theme.dart:_buildBaseTheme()
  ...
)
```
Note: Simply remove the `hintStyle` line — the theme already provides the correct hint style. If you prefer explicit:
```dart
hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
```

**Line 643 — Detail**:
```dart
// BEFORE
Icon(
  isActive ? Icons.check_circle : Icons.circle_outlined,
  color: isActive ? HermesColors.success : HermesColors.textDisabled,
  size: 22,
)

// AFTER
Icon(
  isActive ? Icons.check_circle : Icons.circle_outlined,
  color: isActive
      ? HermesColors.success
      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  size: 22,
)
```

### §3.2 File: `insights_screen.dart` (3 instances)

| # | Line | Current Code | Context | Replacement |
|---|---|---|---|---|
| 4 | 183 | `Icon(Icons.sync, size: 16, color: HermesColors.textDisabled)` | Last synced icon | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 5 | 188 | `style: ...copyWith(color: HermesColors.textDisabled)` | Last synced text | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 6 | 208 | `Icon(..., color: HermesColors.textDisabled)` | Empty state icon | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |

**Line 183 — Detail**:
```dart
// BEFORE
Icon(Icons.sync, size: 16, color: HermesColors.textDisabled),

// AFTER
Icon(Icons.sync,
  size: 16,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
```

**Line 188 — Detail**:
```dart
// BEFORE
Text(
  '${AppStrings.lastSynced}: ${_formatDateTime(data.lastSynced!)}',
  style: theme.textTheme.labelSmall?.copyWith(
    color: HermesColors.textDisabled,
  ),
)

// AFTER
Text(
  '${AppStrings.lastSynced}: ${_formatDateTime(data.lastSynced!)}',
  style: theme.textTheme.labelSmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  ),
)
```

**Line 208 — Detail**:
```dart
// BEFORE
Icon(
  Icons.analytics_outlined,
  size: 64,
  color: HermesColors.textDisabled,
),

// AFTER
Icon(
  Icons.analytics_outlined,
  size: 64,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
),
```

### §3.3 File: `session_list_screen.dart` (6 instances)

| # | Line | Current Code | Context | Replacement |
|---|---|---|---|---|
| 7 | 210 | `hintStyle: TextStyle(color: HermesColors.textDisabled)` | Search hint text | `Theme.of(context).inputDecorationTheme.hintStyle` |
| 8 | 360 | `color: HermesColors.textDisabled` | Empty state icon | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 9 | 376 | `color: HermesColors.textDisabled` | Empty state message text | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 10 | 609 | `color: HermesColors.textDisabled` | Session card model icon | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 11 | 623 | `color: HermesColors.textDisabled` | Session card message count icon | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 12 | 646 | `color: HermesColors.textDisabled` | Session card relative time text | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |

**Line 210 — Detail**:
```dart
// BEFORE
decoration: InputDecoration(
  hintText: AppStrings.searchSessions,
  hintStyle: TextStyle(color: HermesColors.textDisabled),
  ...
)

// AFTER
decoration: InputDecoration(
  hintText: AppStrings.searchSessions,
  // hintStyle: inherits from theme — remove the hardcoded line
  ...
)
```

**Lines 360, 376 — Detail** (empty state):
```dart
// BEFORE (line ~360)
Icon(
  uiState.showArchived ? Icons.archive_outlined : Icons.forum_outlined,
  size: 64,
  color: HermesColors.textDisabled,
)

// AFTER
Icon(
  uiState.showArchived ? Icons.archive_outlined : Icons.forum_outlined,
  size: 64,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
)

// BEFORE (line ~376)
Text(
  message,
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: HermesColors.textDisabled,
  ),
  ...
)

// AFTER
Text(
  message,
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  ),
  ...
)
```

**Lines 609, 623, 646 — Detail** (session card metadata):
```dart
// Line 609 — BEFORE
Icon(Icons.smart_toy_outlined, size: 12, color: HermesColors.textDisabled),
// AFTER
Icon(Icons.smart_toy_outlined, size: 12,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),

// Line 623 — BEFORE
Icon(Icons.chat_bubble_outline, size: 12, color: HermesColors.textDisabled),
// AFTER
Icon(Icons.chat_bubble_outline, size: 12,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),

// Line 646 — BEFORE
Text(
  DateFormatter.relativeTime(session.lastActivity!),
  style: theme.textTheme.bodySmall?.copyWith(
    color: HermesColors.textDisabled,
  ),
),
// AFTER
Text(
  DateFormatter.relativeTime(session.lastActivity!),
  style: theme.textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  ),
),
```

### §3.4 File: `chat_screen.dart` (2 instances)

| # | Line | Current Code | Context | Replacement |
|---|---|---|---|---|
| 13 | 242 | `HermesColors.textDisabled.withValues(alpha: 0.5)` | Empty state icon | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |
| 14 | 256 | `color: HermesColors.textDisabled` | Empty state model description | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)` |

**Line 242 — Detail**:
```dart
// BEFORE
Icon(
  Icons.chat_bubble_outline,
  size: 64,
  color: HermesColors.textDisabled.withValues(alpha: 0.5),
),

// AFTER
Icon(
  Icons.chat_bubble_outline,
  size: 64,
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
),
```

**Line 256 — Detail**:
```dart
// BEFORE
Text(
  'Using ${state.selectedModelId ?? "default model"}',
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: HermesColors.textDisabled,
  ),
),

// AFTER
Text(
  'Using ${state.selectedModelId ?? "default model"}',
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  ),
),
```

---

## §4 Summary Table — All Fixes

| Fix # | Defect | File | Line | Change |
|---|---|---|---|---|
| F.21 | agentBubble hardcoded | `message_bubble.dart` | 141 | `HermesColors.agentBubble` → `Theme.of(context).colorScheme.surfaceContainerHighest` |
| F.22-1 | textDisabled icon | `settings_screen.dart` | 136 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-2 | textDisabled hintStyle | `settings_screen.dart` | 227 | → `Theme.of(context).inputDecorationTheme.hintStyle` |
| F.22-3 | textDisabled icon | `settings_screen.dart` | 643 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-4 | textDisabled icon | `insights_screen.dart` | 183 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-5 | textDisabled text | `insights_screen.dart` | 188 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-6 | textDisabled icon | `insights_screen.dart` | 208 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-7 | textDisabled hintStyle | `session_list_screen.dart` | 210 | → `Theme.of(context).inputDecorationTheme.hintStyle` |
| F.22-8 | textDisabled icon | `session_list_screen.dart` | 360 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-9 | textDisabled text | `session_list_screen.dart` | 376 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-10 | textDisabled icon | `session_list_screen.dart` | 609 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-11 | textDisabled icon | `session_list_screen.dart` | 623 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-12 | textDisabled text | `session_list_screen.dart` | 646 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-13 | textDisabled icon | `chat_screen.dart` | 242 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |
| F.22-14 | textDisabled text | `chat_screen.dart` | 256 | → `colorScheme.onSurface.withValues(alpha: 0.38)` |

**Total**: 15 fixes across 4 files.

---

## §5 Additional: `HermesColors.cyan` Hardcoded Uses

While auditing, I found extensive direct use of `HermesColors.cyan` (#32C2FF) that should also be theme-adaptive. On light backgrounds, `#32C2FF` has ~2.5:1 contrast (fails WCAG AA). The design system specifies `#0077A3` as the adapted cyan for light mode.

The `app_theme.dart` already computes a brightness-aware `accentColor`:
```dart
final Color accentColor = isLight ? HermesColors.lightSecondary : HermesColors.cyan;
```

These files use `HermesColors.cyan` directly (should use `Theme.of(context).colorScheme.secondary` instead, since `secondary` is swapped per theme):

| File | Approx Count | Pattern |
|---|---|---|
| `settings_screen.dart` | ~12 uses | Section headers, icons, buttons |
| `insights_screen.dart` | ~4 uses | Progress indicator, stat card colors, section header |
| `chat_screen.dart` | ~4 uses | Progress indicators |
| `session_list_screen.dart` | ~8 uses | Active states, refresh indicator, focused borders |
| `skills_screen.dart` | ~6 uses | Active states, toggles, chips |
| `memory_screen.dart` | ~2 uses | Search icon, refresh indicator |
| `workspace_screen.dart` | ~4 uses | Breadcrumbs, navigation icons, buttons |
| `task_list_screen.dart` | ~4 uses | FAB, refresh indicator, progress indicator |
| `task_form_screen.dart` | ~4 uses | Icons, button, focused border |

However, many of these are CORRECT as "accent color" usage — they should simply use `Theme.of(context).colorScheme.secondary` instead of `HermesColors.cyan`. The `ColorScheme.secondary` is already set to `HermesColors.cyan` in dark and `HermesColors.lightSecondary` in light (per `app_theme.dart:42,59`).

**Recommendation**: The State Engineer should NOT replace all cyan uses (most are semantically correct as accent uses). Instead:
1. Where `HermesColors.cyan` is used as an accent color (section headers, active states, icons): replace with `Theme.of(context).colorScheme.secondary`
2. Where `HermesColors.cyan` is used as a progress indicator color: already handled by `progressIndicatorTheme` in `app_theme.dart` — use `Theme.of(context).progressIndicatorTheme.color`
3. Where `HermesColors.cyan` is used as a semantic color (info, tool status): keep as-is (these are brand-consistent, not theme-dependent)

**This is a Phase 2 judgment call** for the State Engineer. The critical defects (F.21, F.22) must be fixed first.

---

## §6 Verification Command (for QA Phase 3)

```bash
# After fixes, these greps should return ZERO non-brand matches:
grep -rn "HermesColors\.textDisabled" lib/
grep -rn "HermesColors\.agentBubble" lib/
```

Expected: 0 results (all references replaced with theme-adaptive equivalents).

The only remaining `HermesColors.agentBubble` reference should be in `colors.dart` (the definition itself).

---

## §7 MVP Compliance Check

```
☑ All fixes are within existing screens — no new screens needed
☑ No premium/auth features affected
☑ Theme infrastructure (app_theme.dart) already supports these replacements
☑ No features not in app-spec/01_prd.md
```

---

## §8 Output Validation

- **Source files read**:
  - `lib/features/chat/presentation/message_bubble.dart` (full file)
  - `lib/features/settings/presentation/settings_screen.dart` (full file)
  - `lib/features/insights/presentation/insights_screen.dart` (full file)
  - `lib/features/sessions/presentation/session_list_screen.dart` (full file)
  - `lib/features/chat/presentation/chat_screen.dart` (full file)
  - `lib/core/theme/colors.dart` (full file)
  - `lib/core/theme/app_theme.dart` (full file)
  - `app-spec/04_ui_design_system.md` (§1)
- **MVP features referenced**: F-002 (Chat), F-003 (Sessions), F-007 (Insights), F-008 (Settings)
- **Features NOT in MVP that were excluded**: N/A — this is a bugfix, not a feature
- **Conflicts found with existing specs**: None — these are direct remediations of documented defects F.21-F.22
