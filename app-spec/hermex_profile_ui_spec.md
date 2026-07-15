# HERMEX-008: Profile Switcher/Management UI Spec

> Phase 1b — UI/UX Design Spec (No Implementation Code)
> Author: flutter-ui-ux-designer
> Date: 2026-07-15
> Source: GOAL_RC6_COMPREHENSIVE_REMEDIATION.md §C

---

## §1 Overview

This spec defines the screens, components, and navigation flows for Hermes Profile management. A "Hermes Profile" is a first-class entity that bundles server connection details + per-profile preferences (default model, reasoning effort). This replaces the flat `ServerConfig` model currently used.

### §1.1 Related PRD Features

| Feature ID | Feature | 
|---|---|
| F-001 | Server Connection — multiple server profiles |
| F-008 | Settings — profile switching, model preference |

### §1.2 Related Defects (from GOAL_RC6)

| Defect | Description |
|---|---|
| C.11 | No first-class "Hermes Profile" entity carrying per-profile default model + reasoning-effort |
| C.12 | Chat does not reactively watch connectionProvider — stale server after profile switch |
| C.13 | `CachedSession.serverId` uses URL instead of ServerConfig.id |

### §1.3 Navigation Shape Confirmation

Per `app-spec/03_user_flows_navigation.md` and `app-spec/01_prd.md`:
- Bottom Navigation: Chat | Sessions | Tasks | Workspace | Settings
- Profile switching: accessible from Settings screen AND Chat header
- Profile management (add/edit): accessible from Settings → Servers/Profiles

---

## §2 Screen Inventory

| Screen ID | Screen Name | Route | Feature ID |
|---|---|---|---|
| SCR-013 | Profile List | `/profiles` (or bottom sheet from Settings/Chat) | F-001, F-008 |
| SCR-014 | Add/Edit Profile | `/profiles/new`, `/profiles/:id/edit` | F-001 |
| SCR-002-mod | Chat Screen (Profile Indicator) | `/chat` (existing, modified) | F-002, F-008 |
| SCR-011-mod | Settings Screen (Profile Section) | `/settings` (existing, modified) | F-008 |

---

## §3 SCR-013: Profile List Screen

### §3.1 Screen Contract

| Field | Value |
|---|---|
| **Screen ID** | `SCR-013` |
| **Screen Name** | Profile List / Switch Profile |
| **Route** | `/profiles` (full screen) OR modal bottom sheet from Chat header |
| **Allowed Roles** | All users (no auth gating) |
| **Feature** | F-001 Server Connection, F-008 Settings |
| **Entry Points** | Chat header → profile avatar/icon tap, Settings → "Switch Profile", Settings → "Manage Profiles" |
| **Exit Points** | Tap profile → connect + navigate back to Chat (profile switch complete), "Add Profile" → `/profiles/new`, tap edit → `/profiles/:id/edit` |
| **Primary Action** | Tap a profile to switch to it |
| **Secondary Actions** | Add new profile, Edit profile, Delete profile (swipe) |

### §3.2 UX Copy (i18n Keys)

| Key | English (en) |
|---|---|
| `profileList.title` | "Profiles" |
| `profileList.switchProfile` | "Switch Profile" |
| `profileList.addProfile` | "Add Profile" |
| `profileList.noProfiles` | "No profiles configured" |
| `profileList.noProfilesSubtitle` | "Add a Hermes server profile to get started." |
| `profileList.activeBadge` | "Active" |
| `profileList.lastConnected` | "Last connected: {time}" |
| `profileList.neverConnected` | "Never connected" |
| `profileList.deleteConfirmTitle` | "Delete Profile" |
| `profileList.deleteConfirmMessage` | "Delete '{name}'? This cannot be undone. API keys and settings for this profile will be permanently removed." |
| `profileList.switchingTo` | "Switching to {name}..." |
| `profileList.switchSuccess` | "Connected to {name}" |
| `profileList.switchFailed` | "Failed to connect to {name}" |

### §3.3 Layout (Success State)

```
┌──────────────────────────────────┐
│  ← AppBar: "Profiles"            │
│  action: [+ add]                 │
├──────────────────────────────────┤
│                                  │
│  🟢 ┌─────────────────────────┐  │
│     │ H "Home Server"         │  │
│     │   192.168.1.100:8642    │  │
│     │   Model: deepseek-v4    │  │
│     │   ┌────────┐            │  │
│     │   │ Active │            │  │
│     │   └────────┘            │  │
│     └─────────────────────────┘  │
│                                  │
│  ⚪ ┌─────────────────────────┐  │
│     │ H "Office Server"       │  │
│     │   10.0.0.50:8642        │  │
│     │   Model: claude-sonnet  │  │
│     │   Last connected: 3d ago│  │
│     │                    [⋮]  │  │
│     └─────────────────────────┘  │
│                                  │
│  ⚪ ┌─────────────────────────┐  │
│     │ H "VPS Server"          │  │
│     │   hermes.example.com    │  │
│     │   Model: (default)      │  │
│     │   Never connected       │  │
│     │                    [⋮]  │  │
│     └─────────────────────────┘  │
│                                  │
│  + Add Profile                   │
│                                  │
└──────────────────────────────────┘
```

### §3.4 Profile Card Design

Each card displays:
- **Avatar**: CircleAvatar with "H" (first letter of profile name), `hermesNavy` background, `hermesCyan` text
- **Status dot**: `🟢` active (green), `⚪` inactive (grey)
- **Profile name**: `titleMedium`, `colorScheme.onSurface`, weight 600
- **Server URL**: `bodySmall`, `colorScheme.onSurfaceVariant`
- **Default model**: `bodySmall`, `colorScheme.onSurfaceVariant` (shown as chip: `smart_toy` icon + model ID)
- **Last connected**: `labelSmall`, relative time, `colorScheme.onSurface.withValues(alpha: 0.38)`
- **Active badge**: cyan chip ("Active") if this is the currently connected profile
- **Overflow menu** `[⋮]`: Edit, Duplicate, Delete

### §3.5 Bottom Sheet Variant (Chat Header)

When opened from Chat header, the profile list is shown as a modal bottom sheet (not full screen):

```
┌──────────────────────────────────┐
│  (chat visible, dimmed)          │
│                                  │
├──────────────────────────────────┤
│  ─── drag handle ───            │
│  Switch Profile                  │
│                                  │
│  🟢 Home Server   · Active      │
│     deepseek-v4-pro              │
│                                  │
│  ⚪ Office Server                │
│     claude-sonnet-4              │
│                                  │
│  ⚪ VPS Server                   │
│     (default)                    │
│                                  │
│  + Add Profile                   │
│                                  │
│  Manage Profiles...              │
│                                  │
└──────────────────────────────────┘
```

Bottom sheet variant:
- Max height: 60% of screen
- `borderRadius`: top corners 28dp (per design system §5)
- `backgroundColor`: `colorScheme.surface`
- "Manage Profiles..." link navigates to full `/profiles` screen

### §3.6 States

| State | Behavior |
|---|---|
| **Loading** | 2-3 shimmer profile cards. CircleAvatar placeholder + 2 text skeleton lines. |
| **Success** | Profile list with status indicators as shown in layout. |
| **Empty** | Centered: `dns_outlined` icon (64dp). Text: "No profiles configured". Subtitle: "Add a Hermes server profile to get started." FAB/button: "Add Profile". |
| **Error** | Red banner: "Failed to load profiles". Retry button. Profiles are loaded from local storage — this error is rare (Isar read failure). |
| **Offline** | Profiles shown from local storage. Cannot verify connectivity. Status dots show last-known state. Tap to attempt connection — will fail gracefully. |

### §3.7 Switch Behavior (Profile Switch Mid-Chat)

When user taps a different profile (including from bottom sheet in Chat):

1. **Loading indicator**: Profile card shows `CircularProgressIndicator` (cyan, 20dp) replacing status dot
2. **Chat reset**: Chat screen must reactively detect profile switch and:
   - Clear current messages
   - Clear session context
   - Re-initialize with new server's API client
   - Load new server's available models
3. **Session handling**: If user was in a session, show confirmation:
   - "Switching profiles will start a new chat. Current chat will be saved as a session on the previous server."
   - [Cancel] [Switch]
4. **Success**: SnackBar "Connected to {profile name}" (green, `HermesColors.success`)
5. **Failure**: SnackBar "Failed to connect to {profile name}: {reason}" (red, `HermesColors.error`), stay on current profile

---

## §4 SCR-014: Add/Edit Profile Screen

### §4.1 Screen Contract

| Field | Value |
|---|---|
| **Screen ID** | `SCR-014` |
| **Screen Name** | Add Profile / Edit Profile |
| **Route** | `/profiles/new` (create), `/profiles/:id/edit` (edit) |
| **Allowed Roles** | All users |
| **Feature** | F-001 Server Connection |
| **Entry Points** | Profile List → "Add Profile", Profile List → [⋮] → Edit, Connection screen → "Save as Profile" |
| **Exit Points** | Save → back to Profile List. Cancel → back without saving. |
| **Primary Action** | "Save Profile" button |
| **Secondary Actions** | "Test Connection", "Delete Profile" (edit mode only) |

### §4.2 UX Copy (i18n Keys)

| Key | English (en) |
|---|---|
| `profileForm.titleNew` | "Add Profile" |
| `profileForm.titleEdit` | "Edit Profile" |
| `profileForm.nameLabel` | "Profile Name" |
| `profileForm.nameHint` | "e.g., Home Server" |
| `profileForm.urlLabel` | "Server URL" |
| `profileForm.urlHint` | "http://192.168.1.100:8642" |
| `profileForm.apiKeyLabel` | "API Key" |
| `profileForm.apiKeyHint` | "Enter your Hermes API key" |
| `profileForm.defaultModelLabel` | "Default Model" |
| `profileForm.defaultModelHint` | "Select a model (fetched from server)" |
| `profileForm.reasoningEffortLabel` | "Reasoning Effort" |
| `profileForm.save` | "Save Profile" |
| `profileForm.testConnection` | "Test Connection" |
| `profileForm.testingConnection` | "Testing connection..." |
| `profileForm.connectionSuccess` | "Connected successfully" |
| `profileForm.connectionFailed` | "Connection failed: {reason}" |
| `profileForm.validation.nameRequired` | "Profile name is required" |
| `profileForm.validation.urlRequired` | "Server URL is required" |
| `profileForm.validation.urlInvalid` | "Enter a valid URL (e.g., http://host:8642)" |
| `profileForm.validation.apiKeyRequired` | "API key is required" |
| `profileForm.deleteProfile` | "Delete Profile" |

### §4.3 Layout

```
┌──────────────────────────────────┐
│  ← AppBar: "Add Profile"         │
│   (or "Edit Profile" in edit)    │
├──────────────────────────────────┤
│                                  │
│  Profile Name *                  │
│  ┌────────────────────────────┐  │
│  │ 🏷 Home Server             │  │
│  └────────────────────────────┘  │
│                                  │
│  Server URL *                    │
│  ┌────────────────────────────┐  │
│  │ 🌐 http://192.168.1...     │  │
│  └────────────────────────────┘  │
│                                  │
│  API Key *                       │
│  ┌────────────────────────────┐  │
│  │ 🔑 ●●●●●●●●●●●●●●●●  [👁] │  │
│  └────────────────────────────┘  │
│                                  │
│  ── Advanced (collapsible) ──    │
│                                  │
│  Default Model                   │
│  ┌────────────────────────────┐  │
│  │ 🤖 Select model...     [▽] │  │
│  │    (fetched after connect) │  │
│  └────────────────────────────┘  │
│                                  │
│  Reasoning Effort                │
│  ┌────────────────────────────┐  │
│  │ low  ○───●───○  high      │  │
│  │       medium               │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │      TEST CONNECTION       │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │       SAVE PROFILE         │  │
│  └────────────────────────────┘  │
│                                  │
│  (edit mode only:)               │
│  ┌────────────────────────────┐  │
│  │    DELETE PROFILE          │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

### §4.4 Form Fields Detail

#### Profile Name
- `TextFormField`, single line
- Leading icon: `badge` or `label_outline`
- Required. Validation: non-empty, max 64 chars
- RTL-aware text input

#### Server URL
- `TextFormField`, single line
- Leading icon: `dns_outlined`
- Required. Validation: non-empty, valid URL format (starts with `http://` or `https://`)
- Keyboard type: `TextInputType.url`
- Auto-correct: off

#### API Key
- `TextFormField`, single line
- Leading icon: `vpn_key_outlined`
- Required. Validation: non-empty
- Obscured by default (`obscureText: true`)
- Suffix icon: visibility toggle (`visibility` / `visibility_off`)
- Auto-correct: off

#### Default Model (Dropdown)
- `DropdownButtonFormField` — NOT free text
- Items populated from `/v1/models` endpoint AFTER a successful Test Connection
- If models haven't been loaded: disabled state with hint "Connect first to load models"
- If connected but no models: "No models available"
- Loading models: spinner in dropdown
- Shows `model.id` as primary text, `model.ownedBy` as secondary if available

#### Reasoning Effort (Segmented Control / Slider)
- Three options: `low`, `medium`, `high`
- Default: `medium`
- Visual: Material 3 `SegmentedButton` or custom slider
- Each option has icon + label:
  - `low`: `speed` icon, "Fast"
  - `medium`: `balance` icon, "Balanced"  
  - `high`: `psychology` icon, "Deep"

### §4.5 Test Connection Flow

1. User taps "Test Connection"
2. Button shows spinner: "Testing connection..."
3. Sends `GET /health` to the entered URL + API key
4. **Success**: Green checkmark with "Connected successfully". Model dropdown becomes enabled and auto-fetches `/v1/models`.
5. **Failure**: Red banner with specific reason:
   - Timeout: "Connection timed out. Check the URL and ensure the server is running."
   - 401: "Invalid API key. Check your key and try again."
   - DNS/Network: "Could not reach server. Check the URL and your network connection."
   - Other: "Connection failed: {status_code} {message}"

### §4.6 States

| State | Behavior |
|---|---|
| **Loading (edit mode)** | Form skeleton with shimmer fields if loading existing profile data. |
| **Form Idle** | All fields enabled. Save button active. |
| **Testing Connection** | Test button shows spinner. Other fields remain enabled. Save button disabled during test. |
| **Connection Success** | Green indicator. Model dropdown enabled. |
| **Connection Failed** | Red banner below URL field. Retry available. |
| **Submitting** | Save button shows spinner. All fields disabled. "Saving..." |
| **Success** | Navigate back. SnackBar: "Profile saved." |
| **Error** | Banner: "Failed to save profile: {reason}". Form remains editable. |
| **Offline** | Cannot test connection. Save still works (local storage). Banner: "Offline — cannot test connection. Profile will be saved locally." |

---

## §5 Active Profile Indicator

### §5.1 Chat Header Indicator

The Chat screen's AppBar must show the current active profile:

```
┌──────────────────────────────────┐
│  [H] Session Title          [▽]  │
│      deepseek-v4-pro · Home      │
│  ────────────────────────────── │
```

- **Profile avatar**: CircleAvatar (radius 14) with first letter of profile name, `hermesNavy` bg, `hermesCyan` text
- **Tapping the avatar or profile area**: Opens the profile switcher bottom sheet (SCR-013 bottom sheet variant)
- **Subtitle row**: Model name · Profile name, `bodySmall`, `colorScheme.onSurfaceVariant`
- **Dropdown chevron** `[▽]`: Tapping also opens the profile switcher

When no profile is connected:
- Avatar shows `?` or `cloud_off` icon
- Subtitle: "Not connected"
- Tapping navigates to Connection screen

### §5.2 Settings Screen Profile Section

In Settings (SCR-011), the "Profile" section shows:

```
┌──────────────────────────────────┐
│  Profile                         │
│  ┌────────────────────────────┐  │
│  │ [H] Home Server            │  │
│  │     192.168.1.100:8642    >│  │
│  │     Model: deepseek-v4-pro  │  │
│  │     Effort: medium          │  │
│  └────────────────────────────┘  │
│                                  │
│  Switch Profile                  │
│  Manage Profiles                 │
└──────────────────────────────────┘
```

- **"Switch Profile"**: Opens profile list bottom sheet
- **"Manage Profiles"**: Navigates to `/profiles`

---

## §6 Profile Data Model (Reference — Backend/DB Architect owns)

The `HermesProfile` entity replaces the flat `ServerConfig`. For UI spec purposes:

| Field | Type | Description |
|---|---|---|
| `id` | String (UUID) | Unique profile identifier |
| `name` | String | Human-readable profile name |
| `serverUrl` | String | Hermes Agent API Server URL |
| `apiKey` | String | Encrypted API key (never displayed in full) |
| `defaultModelId` | String? | Default model ID for this profile |
| `reasoningEffort` | String | "low" / "medium" / "high" |
| `isActive` | bool | Currently connected profile |
| `lastConnected` | DateTime? | Last successful connection timestamp |
| `createdAt` | DateTime | Profile creation timestamp |

---

## §7 Navigation Flow

```
Chat Screen (SCR-002)
  │
  ├─ Tap profile avatar in AppBar
  │   └─ Profile Switcher Bottom Sheet (SCR-013, bottom sheet variant)
  │       ├─ Tap profile → switch + close sheet
  │       ├─ Tap "Manage Profiles" → /profiles (full screen)
  │       └─ Tap "Add Profile" → /profiles/new (SCR-014, create mode)
  │
Settings Screen (SCR-011)
  │
  ├─ "Switch Profile"
  │   └─ Profile Switcher Bottom Sheet (same as above)
  │
  └─ "Manage Profiles"
      └─ /profiles (SCR-013, full screen)
          ├─ Tap profile → switch + navigate back
          ├─ Tap [⋮] → Edit → /profiles/:id/edit (SCR-014, edit mode)
          ├─ Tap [⋮] → Delete → confirmation dialog
          └─ Tap "+" FAB → /profiles/new (SCR-014, create mode)

Connection Screen (SCR-001)
  │
  └─ After successful connect, option: "Save as Profile"
      └─ /profiles/new (pre-filled with URL + API key)
```

### §7.1 Profile Switch State Reset Contract

When profile switch occurs:
1. `connectionProvider` updates `activeServer`/`activeProfile`
2. Chat provider's `initialize()` must react — clear messages, re-init API client
3. `chat_provider.dart` must reactively watch `connectionProvider` (mirror `resolvedApiClientProvider` pattern)
4. If current chat has unsaved messages in a session: prompt to save before switching
5. After switch: Chat screen shows empty state for new profile ("Start a conversation with Hermes")

---

## §8 Accessibility Notes

- Profile cards: `Semantics` label = "{profile name}, {active/inactive}, last connected {time}"
- Status dots: `Semantics` label = "Active" or "Inactive" (not just colored dot)
- API key field: `Semantics` label = "API key, {obscured/visible}"
- Toggle visibility button: `Semantics` label = "Show API key" / "Hide API key"
- Test Connection result: announce via `SemanticsService.announce`
- Delete confirmation: focus trap in dialog
- All interactive elements: minimum 48x48dp touch target

## §9 RTL/LTR Notes

- Arabic is the primary RTL language for this project (per PRD targeting Abdulrahman)
- Form labels and inputs: LTR for URLs, RTL for profile names
- Server URL remains LTR (Latin characters)
- Profile list layout mirrors: avatar stays left, status dot stays left
- Back navigation: `arrow_forward` in RTL (already handled by Material)
- Bottom sheet handle: centered, unaffected

---

## §10 MVP Compliance Check

```
☑ Navigation shape matches this project's PRD/design-system spec:
  Bottom Navigation: Chat | Sessions | Tasks | Workspace | Settings (03_user_flows_navigation.md)
  Profile management accessible from Settings and Chat header
☑ No premium/auth features — this project has no monetization/entitlements
☑ No backend-dependent features beyond what PRD scopes (F-001, F-008)
☑ No features not in app-spec/01_prd.md §Feature List (MVP)
```

---

## §11 Output Validation

- **Source files read**: 
  - `app-spec/GOAL_RC6_COMPREHENSIVE_REMEDIATION.md`
  - `app-spec/01_prd.md`
  - `app-spec/03_user_flows_navigation.md`
  - `app-spec/04_ui_design_system.md`
  - `lib/core/theme/colors.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/core/constants/route_paths.dart`
  - `lib/features/settings/presentation/settings_screen.dart`
  - `lib/features/chat/presentation/chat_screen.dart`
- **MVP features referenced**: F-001 (Server Connection), F-002 (Chat), F-008 (Settings)
- **Features NOT in MVP that were excluded**: Multi-account, offline session cache, notifications, voice/TTS, widgets
- **Conflicts found with existing specs**: None — this spec extends existing SCR-002 (Chat) and SCR-011 (Settings) with new profile functionality as scoped by GOAL_RC6
