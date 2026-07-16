# UX Sign-Off Report — RC5 Light Theme + Screen Validation

**Date:** 2026-07-11
**Project:** Hermex Android
**Branch:** epic/rc4-polish (HEAD: 4998d31)
**Reviewer:** flutter-ui-ux-designer
**Task:** t_f8ded1ca

---

## VERDICT: FAIL (Light Theme)

The dark theme remains solid. The light theme infrastructure (app_theme.dart, colors.dart) is correctly wired with WCAG-AA contrast tokens. However, **most screens bypass the theme system entirely** by using hardcoded `HermesColors.*` constants that assume dark backgrounds. In light mode, these screens range from partially broken to completely unusable.

---

## 1. LIGHT THEME — Is It REAL?

### 1.1 Text Contrast (WCAG AA 4.5:1)

| Token | Hex | Light BG Contrast | Pass AA? | Used Where |
|-------|-----|-------------------|----------|------------|
| `textPrimary` | #E6EDF3 | ~2.0:1 on white | **NO** | Settings, Insights, Sessions, Chat empty states |
| `textSecondary` | #8B949E | ~2.6:1 on white | **NO** | Settings subtitles, Insights labels, Session cards |
| `textDisabled` | #6E7681 | ~3.8:1 on white | **NO** | Empty state icons, disabled text everywhere |
| `surface` | #161B22 | N/A (dark block) | **NO** | Loading inputs, dialogs, stat cards |
| `border` | #30363D | Visible but harsh | Borderline | Dividers, input borders |

**Root cause:** Not a bug in `app_theme.dart` — the theme correctly maps `colorScheme.onSurface` → `lightOnSurface` (#1F2328, ~14:1 contrast). The problem is that **screen widget code uses `HermesColors.textPrimary` (#E6EDF3) instead of `Theme.of(context).colorScheme.onSurface`**.

### 1.2 Screen-by-Screen Severity

#### 🔴 CRITICAL — Settings Screen (`settings_screen.dart`)
**30+ hardcoded `HermesColors.textPrimary/textSecondary/textDisabled/surface/border` references.** Every label, subtitle, icon, divider, dialog background, and text field uses dark-only tokens. This screen will render as **mostly invisible text on a white background**. The settings screen is the cornerstone of user trust — unusable in light mode is a critical failure.

Specific breakages:
- AppBar title (L46): `HermesColors.textPrimary` → invisible on light
- All section headers (L115, L120): Hardcoded `HermesColors.cyan`
- All body text/sublabels: `HermesColors.textPrimary/textSecondary` → invisible
- All text field text: `HermesColors.textPrimary` → invisible
- All dialogs (L420, L460): `HermesColors.surface` (#161B22) → dark dialog on light screen
- All dialog text: `HermesColors.textPrimary/textSecondary` → invisible on dark surface
- Danger zone disconnect button (L446-447): `HermesColors.cyan` → `HermesColors.dark` text is correct on dark surface but dialog background is dark

#### 🔴 CRITICAL — Insights Screen (`insights_screen.dart`)
**20+ hardcoded dark tokens.** Identical pattern to settings. All text, icons, stat card backgrounds, and empty state are hardcoded to dark-only values. Unusable in light mode.

#### 🔴 CRITICAL — Session List Screen (`session_list_screen.dart`)
**25+ hardcoded dark tokens.** AppBar title, search bar, session cards, empty state, error state, popup menus — all use `HermesColors.textPrimary/textSecondary/textDisabled/surface/border`. Unusable.

#### 🟡 MAJOR — Chat Screen (`chat_screen.dart`)
- Loading input placeholder (L330-360): `HermesColors.surface` — dark block on light screen
- Empty state icon/text (L250-267): `HermesColors.textDisabled`, `HermesColors.textSecondary` — very low contrast
- Scroll-to-bottom FAB (L166): `HermesColors.surface` — dark button on light screen
- Loading spinners (L230, L237): `HermesColors.cyan` — semantically should use `lightSecondary`

#### 🟡 MAJOR — Agent Message Bubbles (`message_bubble.dart`)
- Agent bubble background (L138): `HermesColors.agentBubble` (#161B22) — **DARK BOX ON WHITE BACKGROUND**. This is the most user-visible issue — every AI response appears as a dark navy box in light mode.
- Agent avatar (L121): `HermesColors.navy` — acceptable as brand element
- User bubble (L75): `HermesColors.userBubble` (#32C2FF) — acceptable, cyan works on both themes
- User bubble text (L89): `HermesColors.userBubbleText` (#0D1117) — dark on cyan = OK
- Typing dots (L387): `HermesColors.cyan` — OK, visible on both
- Tool name badge (L248-255): `HermesColors.navy`, `HermesColors.cyan` — dark badge on light = visible but semantically wrong

#### 🟢 MINOR — Task List, Task Detail, Task Form
Mostly theme-aware. Hardcoded accent/semantic colors (`HermesColors.cyan`, `.success`, `.error`, `.warning`) are used for status indicators, which is acceptable as these are brand/semantic constants. The FAB background (L78 task_list) uses `HermesColors.cyan` which should use `lightSecondary` in light mode but is visually acceptable (good contrast on white).

#### 🟢 CLEAN — Memory Screen
Almost entirely uses `Theme.of(context).colorScheme.*`. Only loading spinner uses `HermesColors.cyan` directly. **Best-in-class example.**

#### 🟢 CLEAN — Session Detail Screen
Nearly entirely theme-aware. Only accent colors for action buttons use `HermesColors.*` (acceptable).

#### 🟢 CLEAN — Workspace Screen
Nearly entirely theme-aware. Minor hardcoded `HermesColors.cyan` in breadcrumbs and loading state.

#### 🟡 MINOR — Skills Screen
- Category chip active state (L181): `HermesColors.cyan` — acceptable
- Loading spinner (L236): `HermesColors.cyan` — acceptable
- Error state (L256, 261): `HermesColors.error` — semantic color, acceptable
- Focused border (L132): `HermesColors.cyan` — acceptable

#### 🟡 MINOR — Server List
- Loading spinner (L58): `HermesColors.cyan`
- Active server indicator (L224-231): `HermesColors.cyan` — acceptable
- Active badge (L306-312): `HermesColors.cyan` — acceptable
- Empty state CTA button (L137): `HermesColors.cyan` — OK

#### 🟡 MINOR — Connection Screen
- Connect button (L613): `HermesColors.cyan`
- Saved servers link (L631, 638): `HermesColors.cyan`
- Acceptable for primary actions in both themes

### 1.3 Chat Input (`chat_input.dart`)
Mostly theme-aware. The send button (L123, L130-131) uses `HermesColors.cyan` and `colorScheme.onSecondary`. The stop button (L105-106, L111) uses `HermesColors.error` and `HermesColors.white`. These are acceptable as they're action indicators visible in both themes. The input field itself uses `colorScheme.*` throughout. ✅

---

## 2. DARK THEME — No Regression

| Screen | Dark Mode | Notes |
|--------|-----------|-------|
| Chat | ✅ | No regression in dark mode from RC4 |
| Task List | ✅ | Status badges, FAB all correct |
| Task Detail | ✅ | Action buttons, status display correct |
| Task Form | ✅ | Form fields, validation correct |
| Sessions List | ✅ | Card contrast, popup menu correct |
| Session Detail | ✅ | Header, action buttons correct |
| Settings | ✅ | Correct (uses hardcoded dark tokens → looks right in dark) |
| Memory | ✅ | Theme-aware, correct |
| Insights | ✅ | Correct (hardcoded dark tokens → looks right in dark) |
| Workspace | ✅ | Breadcrumbs, file list correct |
| Skills | ✅ | Correct |
| Connection | ✅ | Correct |
| Server List | ✅ | Correct |

**Dark theme verdict: PASS.** No regressions. All screens look correct because the hardcoded `HermesColors.*` constants are the original dark-theme tokens.

---

## 3. PRODUCT PRINCIPLES VALIDATION

| Principle | Status | Evidence |
|-----------|--------|----------|
| No dead buttons (attachment icon removed) | ✅ PASS | Verified in t_66dd2cd7 — `Icons.attach_file` removed from chat_input.dart |
| All tasks visible (not just 2) | ✅ PASS | TaskListScreen uses ListView.builder with pull-to-refresh |
| Chat shows history + session context in AppBar | ✅ PASS | chat_screen.dart L173-223 shows session title + model name |
| Error messages are user-friendly (no raw server data) | ✅ PASS | REG-4 fix restored `_sanitizeError()`, confirmed in t_5ae2e66 |

---

## 4. SUMMARY BY SCREEN

| Screen | Light Theme | Dark Theme | Hardcoded Dark Tokens |
|--------|------------|------------|----------------------|
| Chat | 🟡 Major issues | ✅ OK | 12 |
| Task List | 🟢 Minor | ✅ OK | 9 (semantic) |
| Task Detail | 🟢 Minor | ✅ OK | 10 (semantic) |
| Task Form | 🟢 Minor | ✅ OK | 6 (semantic) |
| Sessions List | 🔴 Critical | ✅ OK | 25+ |
| Session Detail | 🟢 Clean | ✅ OK | 2 |
| Settings | 🔴 Critical | ✅ OK | 30+ |
| Memory | 🟢 Clean | ✅ OK | 1 |
| Insights | 🔴 Critical | ✅ OK | 20+ |
| Workspace | 🟢 Clean | ✅ OK | 4 |
| Skills | 🟡 Minor | ✅ OK | 4 |
| Connection | 🟡 Minor | ✅ OK | 4 |
| Server List | 🟡 Minor | ✅ OK | 6 |

---

## 5. ROOT CAUSE ANALYSIS

The theme infrastructure (app_theme.dart + colors.dart) is **correct**. `_buildBaseTheme()` is brightness-aware. The `HermesColors` class has properly defined light-mode tokens with WCAG AA contrast.

The problem is **widget-level bypass**: Screen code imports `colors.dart` and uses `HermesColors.textPrimary` (#E6EDF3, a dark-theme text color) instead of `Theme.of(context).colorScheme.onSurface` (which correctly resolves to #1F2328 in light and #E6EDF3 in dark).

This is a **systemic adoption gap**, not a theme bug. The RC4 → RC5 migration wired light tokens into the theme infrastructure but did not update screen widgets to use `Theme.of(context).colorScheme` instead of `HermesColors.*` constants.

---

## 6. RECOMMENDED FIX APPROACH

### Priority 1 (Blocking — screens unusable in light mode):
- **settings_screen.dart**: Replace all `HermesColors.textPrimary` → `Theme.of(context).colorScheme.onSurface`, `HermesColors.textSecondary` → `colorScheme.onSurfaceVariant`, `HermesColors.textDisabled` → `colorScheme.onSurface.withValues(alpha:0.38)`, `HermesColors.surface` → `colorScheme.surface`, `HermesColors.border` → `colorScheme.outlineVariant`, `HermesColors.cyan` (for text/icons) → `colorScheme.secondary`
- **insights_screen.dart**: Same replacements
- **session_list_screen.dart**: Same replacements

### Priority 2 (User-visible degradation):
- **chat_screen.dart**: Fix loading input, empty state, FAB colors
- **message_bubble.dart**: Agent bubble background → use `colorScheme.primaryContainer` (or define a light-mode agent bubble token)

### Priority 3 (Polishing):
- All remaining screens: Replace `HermesColors.cyan` (where used for non-brand accent) → `colorScheme.secondary`
- Any `HermesColors.textPrimary/textSecondary/textDisabled` → corresponding `colorScheme.*` tokens

---

## 7. ACCEPTANCE CRITERIA STATUS

| Criterion | Status |
|-----------|--------|
| Light theme passes UX bar — looks like a REAL light mode app | ❌ FAIL |
| Dark theme: no regressions | ✅ PASS |
| All screens reviewed in both themes | ✅ DONE |
| PASS or FAIL with specific screen/issue | ❌ FAIL (documented above) |

---

## 8. OFFICIAL VERDICT

**FAIL — Light theme is not production-ready.**

- **3 screens are completely unusable** (settings, insights, session list) due to invisible text on light backgrounds
- **Agent message bubbles** render as dark boxes on white — the most visible user-facing issue
- **Chat loading/empty states** have low contrast
- **Dark theme: no regressions** — all screens remain correct
- **Theme infrastructure: correct** — the fix is widget-level adoption, not theme redesign
- **Product principles: all 4 pass**
