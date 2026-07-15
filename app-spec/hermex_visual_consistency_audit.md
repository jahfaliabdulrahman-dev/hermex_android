# HERMEX-008: Visual-Consistency Audit — Full Design-System Pass

> Phase 1b — UI/UX Design Spec (No Implementation Code)
> Author: flutter-ui-ux-designer
> Date: 2026-07-15
> Source: GOAL_RC6_COMPREHENSIVE_REMEDIATION.md §F.23

---

## §1 Overview

This document is a comprehensive visual-design audit covering all screens in Hermex Android. It identifies inconsistencies in spacing, typography, empty states, and iconography against the design system defined in `app-spec/04_ui_design_system.md`.

### §1.1 Screens Audited

| Screen | File | Screens Visually Inspected |
|---|---|---|
| Chat | `chat_screen.dart` + `message_bubble.dart` + `chat_input.dart` | Yes |
| Sessions | `session_list_screen.dart` | Yes |
| Session Detail | `session_detail_screen.dart` | Yes |
| Tasks | `task_list_screen.dart` | Yes |
| Task Form | `task_form_screen.dart` | Yes |
| Task Detail | `task_detail_screen.dart` | Yes |
| Skills | `skills_screen.dart` | Yes |
| Memory | `memory_screen.dart` | Yes |
| Workspace | `workspace_screen.dart` | Yes |
| Insights | `insights_screen.dart` | Yes |
| Settings | `settings_screen.dart` | Yes |
| Connection | `connection_screen.dart` | Yes |

### §1.2 Design System Reference

Per `app-spec/04_ui_design_system.md`:
- **Spacing**: Multiples of 4dp. `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `2xl=32`, `3xl=48`
- **Typography**: Inter font family. `headlineSmall=24/32`, `titleMedium=16/24`, `bodyLarge=16/24`, `bodyMedium=14/20`, `bodySmall=12/16`, `labelSmall=11/16`
- **Border Radius**: Cards=12, Inputs=4, Bubbles=16, Chips=24, Dialogs=28
- **Icons**: Navigation=24dp, List-leading=24dp, Small-inline=16dp, Empty-state=64dp

---

## §2 Spacing Consistency Audit

### §2.1 Screen-Level Padding

| Screen | Current Padding | Design System | Status |
|---|---|---|---|
| Chat (message list) | `EdgeInsets.only(top: 8, bottom: 8)` — no horizontal | Should be `horizontal: 12` (bubble margin already handles this via individual bubble padding) | OK — bubbles have their own padding |
| Sessions | `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | `lg=16` horizontal, `sm=8` vertical | OK |
| Tasks | `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | `lg=16` horizontal, `sm=8` vertical | OK |
| Skills | `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | OK | OK |
| Memory | `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | OK | OK |
| Workspace | `EdgeInsets.symmetric(vertical: 8)` — NO horizontal padding | Should have `horizontal: 16` | **ISSUE V.1** |
| Insights | `EdgeInsets.all(16)` | `lg=16` | OK |
| Settings | `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | OK | OK |
| Task Form | `EdgeInsets.all(16)` | OK | OK |

**ISSUE V.1 — Workspace missing horizontal padding**: `workspace_screen.dart` uses `ListView.builder(padding: EdgeInsets.symmetric(vertical: 8))` without horizontal padding. List items extend to screen edges. Fix: add `horizontal: 16`.

### §2.2 Card Internal Padding

| Screen | Card Padding | Design System | Status |
|---|---|---|---|
| Sessions (list items) | `EdgeInsets.all(14)` | `md=12` or `lg=16` | **ISSUE V.2** — 14dp is not on the 4dp grid |
| Sessions (loading skeleton) | `EdgeInsets.all(16)` | `lg=16` | OK |
| Tasks (job card) | `EdgeInsets.all(16)` | `lg=16` | OK |
| Skills | `EdgeInsets.all(16)` | `lg=16` | OK |
| Memory | `EdgeInsets.all(16)` | `lg=16` | OK |
| Insights (stat card) | `EdgeInsets.all(16)` | `lg=16` | OK |
| Settings (cards) | `EdgeInsets.all(16)` | `lg=16` | OK |

**ISSUE V.2 — Session card padding off-grid**: `session_list_screen.dart` line 547 uses `EdgeInsets.all(14)`. Should be `EdgeInsets.all(16)` to match all other cards.

### §2.3 Section Spacing

| Screen | Between-Section Spacing | Design System | Status |
|---|---|---|---|
| Settings | `SizedBox(height: 24)` between sections, `SizedBox(height: 32)` before Danger/About | `xl=24`, `2xl=32` | OK |
| Insights | `SizedBox(height: 32)` between stat sections | `2xl=32` | OK |
| Task Form | `SizedBox(height: 16)` between fields, `SizedBox(height: 32)` before submit | `lg=16`, `2xl=32` | OK |
| Sessions | `SizedBox(height: 8)` between search and list | `sm=8` | OK |

### §2.4 Input Field Padding Inconsistency

| Screen | Content Padding | Design System | Status |
|---|---|---|---|
| Settings (model input) | `EdgeInsets.symmetric(horizontal: 12, vertical: 10)` | `horizontal: 16, vertical: 12` (from theme) | **ISSUE V.3** |
| Sessions (search) | `EdgeInsets.symmetric(horizontal: 16, vertical: 10)` | `horizontal: 16, vertical: 12` | **ISSUE V.4** |
| Skills (search) | `EdgeInsets.symmetric(vertical: 12)` — NO horizontal | `horizontal: 16, vertical: 12` | **ISSUE V.5** |
| Memory (search) | No `contentPadding` set — inherits theme default | `horizontal: 16, vertical: 12` | OK |
| Task Form (fields) | No `contentPadding` set — inherits theme default | OK | OK |

**ISSUE V.3 — Settings model input off-spec**: `settings_screen.dart:241` uses `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`. Should use theme default or `horizontal: 16, vertical: 12`.

**ISSUE V.4 — Sessions search off-spec**: `session_list_screen.dart:228` uses `EdgeInsets.symmetric(horizontal: 16, vertical: 10)`. Vertical should be `12`.

**ISSUE V.5 — Skills search missing horizontal padding**: `skills_screen.dart:121` uses `EdgeInsets.symmetric(vertical: 12)` without horizontal. Should be `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.

---

## §3 Typography Hierarchy Audit

### §3.1 AppBar Titles

| Screen | AppBar Title Style | Design System | Status |
|---|---|---|---|
| Chat | `titleSmall?.copyWith(fontWeight: w600)` | `headlineSmall` | **ISSUE T.1** |
| Sessions | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Tasks | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Skills | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Memory | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Workspace | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Insights | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Settings | `headlineSmall?.copyWith(fontWeight: bold)` | `headlineSmall` | OK |
| Task Form | `titleMedium?.copyWith(...)` | `titleMedium` | OK (form screens use smaller title) |

**ISSUE T.1 — Chat AppBar uses `titleSmall` instead of `headlineSmall`**: `chat_screen.dart:173` uses `theme.textTheme.titleSmall` for the session title in the AppBar. All other screens use `headlineSmall` for AppBar titles. Chat should use `headlineSmall` for consistency, or use `titleMedium` for a two-line AppBar layout (title + subtitle). The current `titleSmall` makes the session name feel undersized compared to other screens.

**Recommendation**: Use `titleMedium` (16sp/24lh/w600) for Chat AppBar title when showing session context (title + model subtitle). This is consistent with Material 3 two-line AppBar pattern.

### §3.2 Section Headers

| Screen | Header Style | Design System | Status |
|---|---|---|---|
| Settings | `titleSmall?.copyWith(color: cyan, fontWeight: w600)` | `titleSmall` (14sp) | OK |
| Insights | `titleSmall?.copyWith(color: cyan, fontWeight: w600)` | OK | OK |
| Task Form (field labels) | `labelLarge?.copyWith(color: onSurfaceVariant)` | `labelLarge` (14sp) | OK |

### §3.3 Empty State Headlines vs Body

| Screen | Headline Style | Body Style | Design System | Status |
|---|---|---|---|---|
| Chat | `titleMedium` | `bodySmall` for model info | Per spec: `titleMedium` headline + `bodyMedium` body | **ISSUE T.2** |
| Sessions | `titleMedium` | `bodyMedium` for message | OK | OK |
| Tasks | `titleMedium` | `bodyMedium` | OK | OK |
| Skills | `titleMedium` | `bodySmall` for subtitle | Per spec: `titleMedium` + `bodyMedium` | **ISSUE T.3** |
| Memory | `titleMedium` | `bodyMedium` | OK | OK |
| Workspace | `titleMedium` | — (no subtitle) | OK | OK |
| Insights | `titleMedium` | `bodyMedium` | OK | OK |
| Settings (empty servers) | `bodyMedium` (no headline) | — | Should have `titleMedium` headline | **ISSUE T.4** |

**ISSUE T.2 — Chat empty state missing body**: Uses `titleMedium` + `bodySmall` but the design spec calls for `titleMedium` + `bodyMedium`.

**ISSUE T.3 — Skills empty state uses `bodySmall`**: Subtitle in empty state uses `bodySmall` instead of `bodyMedium`.

**ISSUE T.4 — Settings empty servers has no headline**: Settings empty servers state uses `bodyMedium` directly without a `titleMedium` headline.

### §3.4 Font Weight Inconsistency

| Usage | Current | Standard | Status |
|---|---|---|---|
| AppBar titles | `FontWeight.bold` (w700) | `FontWeight.w600` | **ISSUE T.5** |
| Chat empty headline | Not bold | `w600` | **ISSUE T.6** |

**ISSUE T.5 — AppBar titles use `FontWeight.bold`**: Multiple screens (Sessions, Tasks, Skills, Memory, Workspace, Insights, Settings) use `fontWeight: FontWeight.bold` for AppBar titles. The design system specifies `headlineSmall` at w600. `FontWeight.bold` is w700. Fix: change to `fontWeight: FontWeight.w600`.

**ISSUE T.6 — Chat empty state headline not bold**: `chat_screen.dart:247` empty state text does not set fontWeight. Should use `fontWeight: FontWeight.w600` to match other empty states.

---

## §4 Empty-State Consistency Audit

### §4.1 Empty State Comparison

| Screen | Icon | Size | Headline | Subtitle | CTA |
|---|---|---|---|---|---|
| **Design System Spec** | Varies | **64dp** | `titleMedium`, onSurface | `bodyMedium`, onSurfaceVariant | Button if actionable |
| Chat | `chat_bubble_outline` | **64dp** | "Start a conversation..." | "Using {model}" | No CTA (input bar is CTA) |
| Sessions | `forum_outlined` / `archive_outlined` | **64dp** | `titleMedium`, onSurfaceVariant | `bodyMedium`, textDisabled | Button if search |
| Tasks | `schedule_send` | **80dp** | `titleMedium`, onSurface | `bodyMedium`, onSurfaceVariant | No CTA |
| Skills | `extension_outlined` | **48dp** | `titleMedium`, onSurfaceVariant | `bodySmall`, dimmed | No CTA |
| Memory | `psychology_outlined` | **64dp** | `titleMedium`, onSurface | `bodyMedium`, onSurfaceVariant | No CTA |
| Workspace | `folder_open` | **48dp** | `titleMedium`, onSurfaceVariant | — | No CTA |
| Insights | `analytics_outlined` | **64dp** | `titleMedium`, onSurface | `bodyMedium`, onSurfaceVariant | No CTA |
| Settings | `dns_outlined` | **32dp** | — | `bodyMedium`, onSurfaceVariant | OutlinedButton |

### §4.2 Issues Found

| Issue ID | Screen | Problem | Fix |
|---|---|---|---|
| **E.1** | Tasks | Icon 80dp instead of 64dp | Change to 64dp |
| **E.2** | Skills | Icon 48dp instead of 64dp | Change to 64dp |
| **E.3** | Workspace | Icon 48dp instead of 64dp | Change to 64dp |
| **E.4** | Settings (empty servers) | Icon 32dp, no headline | Icon → 64dp, add `titleMedium` headline "No Servers" |
| **E.5** | Tasks | Headline uses `onSurface` but Sessions uses `onSurfaceVariant` | Standardize: all empty headlines `onSurface`, all subtitles `onSurfaceVariant` |
| **E.6** | Skills | Subtitle uses `bodySmall` instead of `bodyMedium` | Change to `bodyMedium` |
| **E.7** | Sessions | Subtitle uses `HermesColors.textDisabled` (hardcoded dark) | Change to `colorScheme.onSurfaceVariant` (also fixes F.22) |
| **E.8** | Settings (empty servers) | Subtitle uses `onSurfaceVariant` — correct | OK |
| **E.9** | Chat | Subtitle uses `HermesColors.textDisabled` (hardcoded dark) | Change to `colorScheme.onSurfaceVariant` (also fixes F.22) |

### §4.3 Standardized Empty State Template

All empty states should follow this pattern:

```dart
Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          <screen-specific-icon>,
          size: 64,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        const SizedBox(height: 16),
        Text(
          <headline>,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          <subtitle>,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        // Optional: CTA button
        if (<has-action>) ...[
          const SizedBox(height: 24),
          <button>,
        ],
      ],
    ),
  ),
)
```

---

## §5 Iconography Audit

### §5.1 Icon Size Consistency

| Context | Design System | Actual Usage | Status |
|---|---|---|---|
| Empty state icon | 64dp | Varies (32-80dp) | **ISSUE I.1** — See §4.2 |
| AppBar action icons | 24dp | 24dp (default) | OK |
| List tile leading | 24dp | 20-24dp mixed | **ISSUE I.2** |
| Small inline icon | 16dp | 12-18dp mixed | **ISSUE I.3** |
| Section header icon | — | 20dp consistently | OK (consistent) |
| FAB icon | 24dp | 24dp (default) | OK |

**ISSUE I.1 — Empty state icon sizes inconsistent**: See §4.2 E.1-E.4.

**ISSUE I.2 — List tile leading icons vary**:
- Settings section headers: `size: 20` (not 24)
- Settings server tiles: `size: 22` (not 24)
- Skills toggle spinner: `width: 20, height: 20` (OK for spinner)
- Session card status dot: `width: 8, height: 8` (OK for dot)

**ISSUE I.3 — Small inline icons vary**:
- Session card push_pin: `size: 14` (OK)
- Session card archive: `size: 14` (OK)
- Session card smart_toy: `size: 12` → should be 14 or 16
- Session card chat_bubble: `size: 12` → should be 14 or 16
- Session card popup menu: `iconSize: 18` → should be 20
- Insights last synced sync: `size: 16` → OK
- Task card schedule/history/arrow: `size: 14` → OK
- Copy button icon: `size: 14` → OK
- Memory card access_time: `size: 14` → OK

### §5.2 Icon Selection Consistency

| Screen | Icon Used | Design System | Status |
|---|---|---|---|
| Chat empty state | `chat_bubble_outline` | Per spec §7.2 | OK |
| Sessions empty | `forum_outlined` | Per spec §7.3 | OK |
| Tasks empty | `schedule_send` | Per spec §7.5: `schedule_outlined` | **ISSUE I.4** |
| Skills empty | `extension_outlined` | Per spec §7.7 | OK |
| Memory empty | `psychology_outlined` | Per spec §7.9: `memory` | **ISSUE I.5** |
| Workspace empty | `folder_open` | Per spec §7.8 | OK |
| Insights empty | `analytics_outlined` | Per spec §7.10 | OK |
| Settings empty | `dns_outlined` | Per spec §7.11 | OK |

**ISSUE I.4 — Tasks empty uses `schedule_send` instead of `schedule_outlined`**: Per the design system §7.5, the empty state icon should be `schedule_outlined`. Currently uses `schedule_send` on line 190. Fix to match spec.

**ISSUE I.5 — Memory empty uses `psychology_outlined` instead of `memory`**: Per the design system §7.9, the icon should be `memory`. Currently uses `psychology_outlined`. This is actually more semantically appropriate (psychology = memory/learning), but should match the spec for consistency.

### §5.3 Navigation/Tab Icons

Per design system §6.1:

| Tab | Spec Icon (Selected) | Spec Icon (Unselected) | Actual | Status |
|---|---|---|---|---|
| Chat | `chat_bubble` | `chat_bubble_outline` | Not yet inspected | — |
| Sessions | `forum` | `forum_outlined` | Not yet inspected | — |
| Tasks | `schedule` | `schedule_outlined` | Not yet inspected | — |
| Workspace | `folder` | `folder_outlined` | Not yet inspected | — |
| Settings | `settings` | `settings_outlined` | Not yet inspected | — |

(These are defined in `app.dart` via `NavigationBar` — not visually inspected as they're generated by the shell route.)

---

## §6 Border Radius Consistency

| Context | Design System | Audit Finding | Status |
|---|---|---|---|
| Cards | 12dp | All screens use 12dp | OK |
| Chat bubbles | 16dp (12 top, 4 tail) | Correct per spec §5.1 | OK |
| Input fields | 4dp (theme) or 12dp (custom) | Mixed: theme=4dp, custom=12dp or 8dp | **ISSUE R.1** |
| Chips | 24dp | Skills chips use default (correct) | OK |
| Bottom sheets | 28dp top | ModelSelector uses 20dp | **ISSUE R.2** |

**ISSUE R.1 — Input field border radius inconsistent**:
- `app_theme.dart`: `borderRadius: 4` (theme default)
- `settings_screen.dart:230-231`: `borderRadius: 8` (model input)
- `session_list_screen.dart:230-231`: `borderRadius: 12` (search bar)
- `skills_screen.dart:122-123`: `borderRadius: 12` (search bar)
- `memory_screen.dart:127-128`: `borderRadius: 12` (search bar)
- `task_form_screen.dart:444-445`: `borderRadius: 12` (form fields)

The theme default is `4dp` (sharp), but most screens override to `12dp` (card-like) for search/input fields. This is actually a reasonable UX choice — search bars look better with rounded corners. However, the theme default of 4dp for standard inputs should be respected for form fields. 

**Recommendation**: 
- Search bars: 12dp (consistent with cards — they're card-like elements)
- Form fields: 4dp (theme default, sharp — for data entry)
- Fix `settings_screen.dart`: change model input from 8dp to 4dp (theme default)

**ISSUE R.2 — ModelSelector bottom sheet uses 20dp**: `model_selector.dart:33` uses `BorderRadius.vertical(top: Radius.circular(20))`. Design system §5 specifies `28dp` for bottom sheets. Fix to 28dp.

---

## §7 Screen-by-Screen Issues Summary

### §7.1 Chat Screen (`chat_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| T.1 | Typography | Medium | AppBar title uses `titleSmall` instead of `titleMedium` |
| T.2 | Typography | Low | Empty state subtitle uses `bodySmall` instead of `bodyMedium` |
| T.6 | Typography | Low | Empty state headline not bold |
| F.22-13 | Color | High | Hardcoded `textDisabled` at line 242 |
| F.22-14 | Color | High | Hardcoded `textDisabled` at line 256 |

### §7.2 Sessions List (`session_list_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| V.2 | Spacing | Medium | Card padding 14dp (off-grid) |
| V.4 | Spacing | Low | Search input vertical padding 10dp instead of 12dp |
| E.7 | Empty State | Medium | Subtitle uses hardcoded `textDisabled` |
| T.5 | Typography | Low | AppBar title uses `FontWeight.bold` (w700) instead of w600 |
| F.22-7 | Color | High | Hardcoded `textDisabled` hintStyle |
| F.22-8 | Color | High | Hardcoded `textDisabled` icon |
| F.22-9 | Color | High | Hardcoded `textDisabled` text |
| F.22-10 | Color | High | Hardcoded `textDisabled` icon |
| F.22-11 | Color | High | Hardcoded `textDisabled` icon |
| F.22-12 | Color | High | Hardcoded `textDisabled` text |

### §7.3 Tasks List (`task_list_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| E.1 | Empty State | Low | Icon 80dp instead of 64dp |
| E.5 | Empty State | Low | Headline color inconsistent with standard |
| I.4 | Iconography | Low | Empty uses `schedule_send` instead of `schedule_outlined` |
| T.5 | Typography | Low | AppBar title uses `FontWeight.bold` instead of w600 |

### §7.4 Task Form (`task_form_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| R.1 (partial) | Radius | Low | Form fields use 12dp radius (theme default is 4dp) — acceptable for modern UX |

### §7.5 Skills (`skills_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| V.5 | Spacing | Medium | Search bar contentPadding missing horizontal |
| E.2 | Empty State | Low | Icon 48dp instead of 64dp |
| E.6 | Empty State | Low | Subtitle uses `bodySmall` instead of `bodyMedium` |
| T.3 | Typography | Low | Empty state subtitle uses `bodySmall` |
| T.5 | Typography | Low | AppBar title uses `FontWeight.bold` instead of w600 |

### §7.6 Memory (`memory_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| I.5 | Iconography | Low | Empty uses `psychology_outlined` instead of `memory` |
| T.5 | Typography | Low | AppBar title uses `FontWeight.bold` instead of w600 |

### §7.7 Workspace (`workspace_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| V.1 | Spacing | Medium | ListView missing horizontal padding |
| E.3 | Empty State | Low | Icon 48dp instead of 64dp |
| T.5 | Typography | Low | AppBar title uses `FontWeight.bold` instead of w600 |
| T.5 | Typography | Low | AppBar `centerTitle: true` — inconsistent with all other screens (centerTitle: false) |

### §7.8 Insights (`insights_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| T.5 | Typography | Low | AppBar title uses `FontWeight.bold` instead of w600 |
| F.22-4 | Color | High | Hardcoded `textDisabled` icon |
| F.22-5 | Color | High | Hardcoded `textDisabled` text |
| F.22-6 | Color | High | Hardcoded `textDisabled` icon |

### §7.9 Settings (`settings_screen.dart`)

| Issue | Type | Severity | Description |
|---|---|---|---|
| V.3 | Spacing | Low | Model input contentPadding off-spec |
| E.4 | Empty State | Medium | Empty servers: icon 32dp, no headline |
| R.1 (partial) | Radius | Low | Model input border radius 8dp (should be 4dp) |
| F.22-1 | Color | High | Hardcoded `textDisabled` icon |
| F.22-2 | Color | High | Hardcoded `textDisabled` hintStyle |
| F.22-3 | Color | High | Hardcoded `textDisabled` icon |

---

## §8 Consolidated Fix Priority

### Priority 1 — High (User-Visible Theme Bugs)
These are covered in `hermex_light_theme_fix_spec.md`:
- F.21: Agent bubble background
- F.22: All 14 `textDisabled` instances

### Priority 2 — Medium (Visible Inconsistencies)
| Issue | Fix |
|---|---|
| V.1 | Workspace: add horizontal padding to ListView |
| V.2 | Sessions: card padding 14→16 |
| V.5 | Skills: search contentPadding add horizontal |
| E.4 | Settings: empty servers — 64dp icon, add headline |
| T.1 | Chat: AppBar title `titleSmall`→`titleMedium` |
| T.5 | All screens: AppBar fontWeight bold→w600 |
| R.2 | ModelSelector: bottom sheet radius 20→28 |

### Priority 3 — Low (Polish)
| Issue | Fix |
|---|---|
| V.3, V.4 | Input field padding to match spec |
| E.1-E.3 | Empty state icon sizes to 64dp |
| E.5-E.9 | Empty state typography standardization |
| I.1-I.5 | Icon size/selection to match spec |
| T.2, T.3, T.4, T.6 | Typography hierarchy fixes |
| R.1 | Border radius consistency |
| Workspace appBar | centerTitle: false |

---

## §9 MVP Compliance Check

```
☑ All screens audited against design system in 04_ui_design_system.md
☑ No premium/auth features affected
☑ All issues are within existing screens — no new screens needed
☑ No features not in app-spec/01_prd.md
```

---

## §10 Output Validation

- **Source files read** (all 12 screens + design system):
  - `app-spec/04_ui_design_system.md` (complete)
  - `lib/features/chat/presentation/chat_screen.dart`
  - `lib/features/chat/presentation/message_bubble.dart`
  - `lib/features/sessions/presentation/session_list_screen.dart`
  - `lib/features/tasks/presentation/task_list_screen.dart`
  - `lib/features/tasks/presentation/task_form_screen.dart`
  - `lib/features/skills/presentation/skills_screen.dart`
  - `lib/features/memory/presentation/memory_screen.dart`
  - `lib/features/workspace/presentation/workspace_screen.dart`
  - `lib/features/insights/presentation/insights_screen.dart`
  - `lib/features/settings/presentation/settings_screen.dart`
  - `lib/core/theme/colors.dart`
  - `lib/core/theme/app_theme.dart`
- **MVP features referenced**: F-002 through F-008 (all screens)
- **Features NOT in MVP that were excluded**: N/A — visual consistency pass
- **Conflicts found with existing specs**: None
