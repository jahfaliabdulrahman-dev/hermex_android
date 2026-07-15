# HERMEX-008: Model + Reasoning-Effort Selector UI Spec

> Phase 1b — UI/UX Design Spec (No Implementation Code)
> Author: flutter-ui-ux-designer
> Date: 2026-07-15
> Source: GOAL_RC6_COMPREHENSIVE_REMEDIATION.md §D, §E

---

## §1 Overview

This spec defines the UI components and behavior for:
1. Model selector in Chat header — bound to `/v1/models` per-profile
2. Reasoning-effort selector — in Chat header AND Profile settings
3. Default model setting in Profile settings — dropdown, NOT free-text

### §1.1 Related Defects (from GOAL_RC6)

| Defect | Description |
|---|---|
| D.14 | `model_selector.dart` — dead code, never instantiated |
| D.15 | Chat always falls back to hardcoded `'hermes-default'` |
| D.16 | `ModelInfo` has no capability or reasoning-effort metadata |
| D.17 | "Default Model" in Settings is free-text, orphaned — never read by chat_provider |
| D.18 | Task form model field is free-text, not bound to `/v1/models` |
| E.19 | Zero `thinking|reasoning|effort` in entire `lib/` |
| E.20 | Server-side reasoning-effort parameter schema must be verified first (Backend/DB Architect) |

### §1.2 Prerequisite

E.19-E.20: The Backend/DB Architect phase (Phase 1a) must verify the exact parameter names the Hermes Agent API Server accepts for reasoning effort. Until verified, the UI spec uses placeholder parameter names: `reasoning_effort` with values `low`/`medium`/`high`.

---

## §2 Component Inventory

| Component ID | Component Name | Location | Binds To |
|---|---|---|---|
| CMP-001 | Model Selector (Chat Header) | Chat AppBar action area | Per-profile `/v1/models` |
| CMP-002 | Reasoning-Effort Selector (Chat Header) | Chat AppBar action area, next to model | Per-profile preference |
| CMP-003 | Default Model Selector (Profile Settings) | Profile form / Settings | Saved in `HermesProfile.defaultModelId` |
| CMP-004 | Reasoning-Effort Selector (Profile Settings) | Profile form / Settings | Saved in `HermesProfile.reasoningEffort` |
| CMP-005 | Model Selector (Task Form) | Task form screen | `/v1/models` list |

---

## §3 CMP-001: Model Selector (Chat Header)

### §3.1 Location

Chat screen AppBar, replacing the current single-line subtitle. Position: right side of AppBar, as a `PopupMenuButton` or tappable chip that opens a bottom sheet.

### §3.2 Visual Design

```
┌──────────────────────────────────┐
│  [H] Session Title    [🤖 ▽]    │
│                        model     │
└──────────────────────────────────┘
```

**Compact mode** (AppBar space is limited):
- Chip/badge: `smart_toy` icon (16dp) + selected model ID (truncated to 20 chars) + `arrow_drop_down` (16dp)
- Background: `colorScheme.surfaceContainerHighest` (subtle surface variant)
- Border radius: 24dp (pill)
- Padding: horizontal 12, vertical 6
- Tap: opens model selector bottom sheet

### §3.3 Model Selector Bottom Sheet

Tapping the model chip opens a modal bottom sheet:

```
┌──────────────────────────────────┐
│  (chat dimmed)                   │
├──────────────────────────────────┤
│  ─── drag handle ───            │
│  Select Model                    │
│                                  │
│  🔍 Search models...             │
│                                  │
│  🟢 deepseek-v4-pro              │
│     deepseek                     │
│     ─────────────────────────    │
│  ⚪ claude-sonnet-4              │
│     anthropic                    │
│     ─────────────────────────    │
│  ⚪ hermes-default               │
│     local                        │
│     ─────────────────────────    │
│  ⚪ gpt-4o                       │
│     openai                       │
│                                  │
└──────────────────────────────────┘
```

**Bottom Sheet Specs**:
- Max height: 50% of screen
- `borderRadius`: top corners 28dp
- `backgroundColor`: `colorScheme.surface`
- Search bar at top (filters model list client-side by model ID or owner)
- Each model row:
  - Leading: radio indicator (`check_circle` filled if selected, `circle_outlined` if not)
  - Primary: model ID (`bodyLarge`)
  - Secondary: owner/provider (`bodySmall`, `colorScheme.onSurfaceVariant`)
  - Selected state: cyan accent for radio + model ID text
- Divider between rows: `colorScheme.outlineVariant`, 0.5dp
- Tap row → select model + close sheet

### §3.4 States

| State | Behavior |
|---|---|
| **Loading** | Bottom sheet shows 5 shimmer rows (skeleton text). AppBar chip shows spinner (16dp) + "Loading models...". |
| **Success (with models)** | Full model list as described. Selected model highlighted. |
| **Empty (no models)** | Bottom sheet: centered `smart_toy` icon (64dp). Text: "No models available". Subtitle: "Your Hermes server returned an empty model list." "Retry" button. AppBar shows "No models" in dimmed text. |
| **Error** | Bottom sheet: centered `error_outline` icon (48dp). Text: "Failed to load models". Subtitle: error message (truncated 2 lines). "Retry" button. AppBar chip shows "Models unavailable" in dimmed text. Tap re-triggers fetch. |
| **Offline** | AppBar chip disabled (greyed out). Tapping shows snackbar: "Cannot load models while offline". Bottom sheet shows cached model list if available, with offline banner. |

### §3.5 Model Fetch Strategy

1. On Chat screen mount / profile switch: fetch `GET /v1/models` from the active profile's server
2. Cache model list in provider state (does not persist across app restarts — always fetch fresh)
3. On fetch failure: retain last-known model selection, show error state
4. Selected model persisted as part of `ChatState` and sent with each `/v1/chat/completions` request as the `model` field

### §3.6 Replacing Dead Code

The existing `lib/features/chat/presentation/model_selector.dart` (D.14) contains a `ModelSelector` widget that is functionally correct but never instantiated. This spec supersedes it:

- **Keep**: The `ModelSelector` widget structure (list of models, radio selection, bottom sheet)
- **Modify**: Add search bar, loading/empty/error states, wire to `chatProvider`
- **Wire**: Chat AppBar calls `ModelSelector.show(context, ...)` on tap

---

## §4 CMP-002: Reasoning-Effort Selector (Chat Header)

### §4.1 Location

Chat AppBar, adjacent to model selector. Compact chip similar to model selector.

### §4.2 Visual Design

```
┌──────────────────────────────────┐
│  [H] Session Title  [🤖▽] [🧠▽] │
└──────────────────────────────────┘
```

**Chip**:
- Icon: `psychology` (16dp)
- Label: "low" / "med" / "high" (or "fast" / "balanced" / "deep" depending on UX preference)
- Same pill style as model selector chip
- Tap: opens reasoning-effort bottom sheet

### §4.3 Reasoning-Effort Bottom Sheet

```
┌──────────────────────────────────┐
│  (chat dimmed)                   │
├──────────────────────────────────┤
│  ─── drag handle ───            │
│  Reasoning Effort                │
│                                  │
│  How much thinking should the    │
│  model do before responding?     │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🏎  Low                    │  │
│  │    Faster responses, less  │  │
│  │    reasoning. Good for     │  │
│  │    simple questions.       │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ ⚖  Medium  ●  (selected)  │  │
│  │    Balanced speed and      │  │
│  │    depth. Default for most │  │
│  │    tasks.                  │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🧠  High                   │  │
│  │    Maximum reasoning. Best │  │
│  │    for complex analysis.   │  │
│  │    Slower responses.       │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

### §4.4 Specs

- Three options with descriptions
- Selected option: highlighted card with cyan accent border + checkmark
- `low` = `speed` icon, "Fast"
- `medium` = `balance` icon, "Balanced" (DEFAULT)
- `high` = `psychology` icon, "Deep"
- Tap → select + close sheet + update AppBar chip label

### §4.5 States

| State | Behavior |
|---|---|
| **Loading** | N/A — effort is a local preference, no server fetch needed |
| **Success** | Three options shown, current selection highlighted |
| **Error** | N/A — no server dependency |
| **Empty** | N/A |
| **Offline** | Fully functional — effort is stored locally |

---

## §5 CMP-003: Default Model Selector (Profile Settings)

### §5.1 Location

Add/Edit Profile screen (SCR-014) and Settings → Preferences section.

### §5.2 Current Problem (D.17)

In `settings_screen.dart:217-245`, "Default Model" is a free-text `TextFormField` bound to `defaultModelProvider` — but `chat_provider.dart` NEVER reads this value. It's completely orphaned.

### §5.3 Replacement

Replace the free-text field with a proper `DropdownButtonFormField`:

```
┌──────────────────────────────────┐
│  Default Model                   │
│  ┌────────────────────────────┐  │
│  │ 🤖 deepseek-v4-pro    [▽] │  │
│  └────────────────────────────┘  │
│  Fetched from connected server   │
└──────────────────────────────────┘
```

**Specs**:
- Dropdown, NOT free text
- Items: populated from `/v1/models` of the active server
- Shows `model.id` as primary label, `model.ownedBy` as secondary (if available in dropdown items via `DropdownMenuItem` with `child` that shows both)
- If no server connected: disabled with hint "Connect to a server first"
- If server connected but models not loaded: shows spinner
- If server connected but no models: "No models available"
- Default value: saved to `HermesProfile.defaultModelId`
- When profile is active: Chat uses this model unless overridden in Chat header

### §5.4 States

| State | Behavior |
|---|---|
| **Loading models** | Dropdown shows spinner, disabled |
| **Models loaded** | Dropdown populated, functional |
| **No server connected** | Disabled, hint: "Connect to a server to load models" |
| **Server error** | Disabled, hint: "Failed to load models — tap to retry" |
| **Offline** | Disabled, shows last-known model if cached |
| **Empty (no models)** | Disabled, hint: "No models available on server" |

---

## §6 CMP-004: Reasoning-Effort Selector (Profile Settings)

### §6.1 Location

Add/Edit Profile screen (SCR-014) and Settings → Preferences section.

### §6.2 Visual Design

Three-segment control:

```
┌──────────────────────────────────┐
│  Default Reasoning Effort        │
│                                  │
│  ┌────────┬────────┬────────┐   │
│  │  Low   │ Medium │  High  │   │
│  │  🏎    │   ⚖    │   🧠   │   │
│  └────────┴────────┴────────┘   │
│         ▲ selected               │
│                                  │
│  Medium: Balanced speed and      │
│  depth. Best for most tasks.     │
└──────────────────────────────────┘
```

**Specs**:
- Material 3 `SegmentedButton<String>` with three segments
- Each segment: icon + short label
- Selected segment: `hermesNavy` background, white text
- Unselected segment: transparent, `colorScheme.onSurfaceVariant` text
- Below control: description of selected effort level (dynamic text)
- Saved to `HermesProfile.reasoningEffort`
- When profile is active: Chat uses this effort unless overridden in Chat header

### §6.3 Reasoning-Effort Values

| Value | Label | Icon | Description |
|---|---|---|---|
| `low` | Low | `speed` | Faster responses, less reasoning. Good for simple questions. |
| `medium` | Medium | `balance` | Balanced speed and depth. Default for most tasks. |
| `high` | High | `psychology` | Maximum reasoning. Best for complex analysis. Slower. |

### §6.4 States

| State | Behavior |
|---|---|
| **Default** | "Medium" selected by default |
| **User changed** | User selection persisted |
| **Offline** | Fully functional (local preference) |

---

## §7 CMP-005: Model Selector (Task Form)

### §7.1 Current Problem (D.18)

`task_form_screen.dart:41,313-320` — task model field is free-text (`_modelNameController`), not bound to the server's `/v1/models` list.

### §7.2 Replacement

Replace the free-text model field with a dropdown matching CMP-003 (default model selector):

```
┌──────────────────────────────────┐
│  Model (optional)                │
│  ┌────────────────────────────┐  │
│  │ 🤖 deepseek-v4-pro    [▽] │  │
│  └────────────────────────────┘  │
│  Leave blank to use profile      │
│  default                         │
└──────────────────────────────────┘
```

**Specs**:
- Same dropdown behavior as CMP-003
- Optional field (can be left unselected → uses profile default)
- Dropdown includes a "Use profile default" option at top (selected by default)
- Items populated from the active server's `/v1/models`
- Saved as `modelName` in the cron job's API payload

---

## §8 UX Copy (i18n Keys)

| Key | English (en) |
|---|---|
| `modelSelector.title` | "Select Model" |
| `modelSelector.searchHint` | "Search models..." |
| `modelSelector.noModels` | "No models available" |
| `modelSelector.noModelsSubtitle` | "Your Hermes server returned an empty model list." |
| `modelSelector.loadingModels` | "Loading models..." |
| `modelSelector.loadFailed` | "Failed to load models" |
| `modelSelector.offlineHint` | "Cannot load models while offline" |
| `modelSelector.useDefault` | "Use profile default" |
| `modelSelector.connectFirst` | "Connect to a server to load models" |
| `reasoningEffort.title` | "Reasoning Effort" |
| `reasoningEffort.description` | "How much thinking should the model do before responding?" |
| `reasoningEffort.low` | "Low" |
| `reasoningEffort.lowDescription` | "Faster responses, less reasoning. Good for simple questions." |
| `reasoningEffort.medium` | "Medium" |
| `reasoningEffort.mediumDescription` | "Balanced speed and depth. Default for most tasks." |
| `reasoningEffort.high` | "High" |
| `reasoningEffort.highDescription` | "Maximum reasoning. Best for complex analysis. Slower responses." |
| `reasoningEffort.chipLabel.low` | "fast" |
| `reasoningEffort.chipLabel.medium` | "balanced" |
| `reasoningEffort.chipLabel.high` | "deep" |

---

## §9 Behavior Contract for State Engineer

### §9.1 Chat Header Wiring

```
ChatScreen AppBar
  ├─ Row of action chips:
  │   ├─ [ModelChip] ← tapping opens CMP-001 bottom sheet
  │   └─ [EffortChip] ← tapping opens CMP-002 bottom sheet
  │
  └─ Both chips read from chatProvider
      ├─ selectedModelId → model chip label
      └─ reasoningEffort → effort chip label
```

### §9.2 Profile Settings Wiring

```
SettingsScreen → Model Section
  └─ DropdownButtonFormField (CMP-003)
      └─ Reads models from resolvedApiClientProvider → /v1/models
      └─ Writes to HermesProfile.defaultModelId

SettingsScreen → Preferences / Profile Form
  └─ SegmentedButton (CMP-004)
      └─ Reads/writes HermesProfile.reasoningEffort
```

### §9.3 Task Form Wiring

```
TaskFormScreen → Model Field
  └─ DropdownButtonFormField (CMP-005)
      └─ Reads models from resolvedApiClientProvider → /v1/models
      └─ Includes "Use profile default" as first option
```

### §9.4 API Payload Contract (E.20 — pending Backend verification)

The following fields are sent with chat completion requests:

```json
{
  "model": "<selected model ID>",
  "reasoning_effort": "low|medium|high"
}
```

**IMPORTANT**: The exact parameter name (`reasoning_effort`, `thinking_budget`, etc.) and value format MUST be verified against the live Hermes Agent API Server by the Backend/DB Architect in Phase 1a. This spec uses placeholder names that the State Engineer must update after Phase 1a confirmation.

---

## §10 Accessibility Notes

- Model selector chip: `Semantics` label = "Select model, currently {model name}"
- Effort selector chip: `Semantics` label = "Reasoning effort, currently {effort level}"
- Bottom sheet: trap focus, dismiss on Escape/back
- Dropdown items: each `Semantics` label includes selection state
- Search field: `Semantics` label = "Search models"
- Radio indicators in model list: announce "selected" / "not selected"
- Minimum touch target: 48x48dp for all interactive elements

## §11 RTL/LTR Notes

- Model names and provider names: LTR (Latin characters)
- Chip layout in AppBar: stays in the `actions` area (right side in both LTR and RTL)
- Bottom sheet: layout unaffected, text alignment follows locale
- Dropdown menu items: text alignment matches locale
- Icons: `arrow_drop_down` mirrors automatically in RTL

---

## §12 MVP Compliance Check

```
☑ Navigation shape: Model/effort selectors are AppBar chips + bottom sheets — no new navigation screens
☑ No premium/auth features — this project has no monetization
☑ Features match PRD: F-002 (model selection), F-008 (model preference in settings)
☑ No features not in app-spec/01_prd.md §Feature List (MVP)
☑ E.20 acknowledged: reasoning-effort param name pending Backend verification
```

---

## §13 Output Validation

- **Source files read**:
  - `app-spec/GOAL_RC6_COMPREHENSIVE_REMEDIATION.md`
  - `app-spec/01_prd.md`
  - `app-spec/04_ui_design_system.md`
  - `lib/features/chat/presentation/model_selector.dart`
  - `lib/features/chat/presentation/chat_screen.dart`
  - `lib/features/settings/presentation/settings_screen.dart`
  - `lib/features/tasks/presentation/task_form_screen.dart`
  - `lib/core/theme/colors.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/models/model_info.dart`
- **MVP features referenced**: F-002 (Chat), F-004 (Tasks), F-008 (Settings)
- **Features NOT in MVP that were excluded**: Voice input, TTS, notifications
- **Conflicts found with existing specs**: None — this spec replaces dead code (D.14) and orphaned settings (D.17-D.18) per GOAL_RC6 directives
