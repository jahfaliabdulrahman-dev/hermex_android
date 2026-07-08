# BUG-002-P1: Switch Server / Disconnect Navigation Fix — Design Specification

## Decision: Option A (Servers Section "Switch Server") + Option C (Danger Zone "Disconnect & Exit")

Both interactions are needed — they serve different user intents. The spec already defined them
in §7.11 SCR-011 (lines 873, 893, 912-913). This spec clarifies behavior and adds missing states.

---

## Interaction 1: "Switch Server" (Servers Section)

### Screen ID
SCR-011 (Settings)

### Trigger
User is connected and wants to switch to a different saved server — or add a new one.

### Entry point
Settings → Servers section → "Manage Servers" link (EXISTING, already navigates to /servers)

### Flow
```
Settings (Servers section)
  → Tap "Manage Servers"
    → /servers (SCR-012 Server List Screen)
      → Tap a saved server
        → selectServer(serverId) — health check
          → SUCCESS: auto-navigate to /chat (via ConnectionScreen provider.listen, line 251)
          → FAILURE: error state on ConnectionScreen, user stays on /connection
      → OR tap "+" (add)
        → context.go('/connection') — new server mode
```

### States

| State | Behavior |
|---|---|
| **Success (Servers)** | Server list rendered with status dots. Active server marked. Tap triggers selectServer. |
| **Loading (Servers)** | Shimmer server items (existing spec). |
| **Empty (Servers)** | "No saved servers." + "Add your first Hermes server." (existing). |
| **Error (Servers)** | "Failed to load server list." Retry. (existing). |
| **Offline (Servers)** | Server list from local storage. Cannot test connectivity. "Add" disabled. (existing). |

### Accessibility
- Server tiles: `Semantics(label: "$name, $url, ${isActive ? 'Active' : 'Inactive'}")`
- "+" FAB: `Semantics(label: "Add server")`

### RTL/LTR
- List tiles mirror: status dot on start, trailing chevron on end
- FAB position mirrors (bottom-start in RTL)

---

## Interaction 2: "Disconnect & Exit" (Danger Zone) — NEW

### Screen ID
SCR-011 (Settings)

### Trigger
User wants to disconnect from the current server and return to /connection
WITHOUT connecting to a different server. Common cases:
- Want to re-enter API key for current server
- Want to add a brand-new server from scratch
- Want to change server URL

### Entry point
Settings → Danger Zone section → "Disconnect & Exit" button

### UX Copy
- Button: `AppStrings.disconnectExit` = "Disconnect & Exit"
- Confirm dialog title: "Disconnect from Server?"
- Confirm dialog body: "You will be returned to the connection screen. Your saved server configurations will be kept."
- Confirm action: "Disconnect" (destructive/red)
- Cancel action: "Cancel" (AppStrings.cancel)

### Flow
```
Settings (Danger Zone)
  → Tap "Disconnect & Exit"
    → Show confirmation dialog
      → Cancel: dismiss dialog, stay on Settings
      → Confirm:
        → ref.read(connectionProvider.notifier).disconnect()
        → context.go('/connection')
```

### States

| State | Behavior |
|---|---|
| **Default** | "Disconnect & Exit" button visible. Styled with warning/amber icon, not error-red (this is not destructive like "Delete All Data"). |
| **Disconnected (no active server)** | Button hidden OR disabled with "Not connected" subtitle. |
| **Disconnecting (busy)** | Button shows spinner. Dialog shows "Disconnecting…" with progress indicator. |
| **Error (disconnect fails)** | Snackbar: "Failed to disconnect. Please try again." Stay on Settings. |
| **Offline** | Button disabled. Subtitle: "Offline — cannot disconnect." |

### Dialog Specification

```
┌──────────────────────────────────┐
│  ┌────────────────────────────┐  │
│  │  ⚠ Disconnect from Server?│  │  ← titleMedium, hermesTextPrimary
│  │                            │  │
│  │  You will be returned to   │  │  ← bodyMedium, hermesTextSecondary
│  │  the connection screen.    │  │
│  │  Your saved server         │  │
│  │  configurations will be    │  │
│  │  kept.                     │  │
│  │                            │  │
│  │         [Cancel]  [Disconnect]│  ← Cancel: TextButton (hermesTextSecondary)
│  └────────────────────────────┘  │     Disconnect: FilledButton (hermesWarning bg, hermesDark fg)
└──────────────────────────────────┘
```

Dialog properties (per §8.8):
- Shape: RoundedRectangleBorder, radius 28dp
- Fill: hermesSurface
- Padding: 24dp
- Backdrop: Colors.black54
- Close: tap outside, back button, Cancel button

### Icon
- `Icons.logout` (not `Icons.warning_amber_outlined` — this is navigation, not destruction)

### Placement in Danger Zone
The Danger Zone currently has:
1. "Delete All Local Data" (error/red)
2. "Reset to Defaults" (warning/amber)

"Disconnect & Exit" should be placed BELOW "Reset to Defaults" in the Danger Zone,
using `Icons.logout` with `HermesColors.warning` tint. This groups it with "reset-like"
actions (reversible, not destructive) rather than destructive ones.

Alternative considered: placing it in Servers section. Rejected because:
- Servers section already has "Manage Servers" for switching
- Disconnect without reconnecting is a different intent
- Danger Zone (alongside Reset) is the right mental model: "I want to exit/undo my current state"

---

## GoRouter Navigation Note

/connection is OUTSIDE the ShellRoute. Use `context.go('/connection')` — NOT `context.push()`.
This replaces the entire navigation stack, which is correct because after disconnecting,
the bottom-nav ShellRoute should not be in the stack.

---

## Existing Constants Used

| Constant | Value | Location |
|---|---|---|
| `AppStrings.switchServer` | "Switch Server" | app_strings.dart:144 |
| `AppStrings.disconnectExit` | "Disconnect & Exit" | app_strings.dart:154 |
| `AppStrings.cancel` | "Cancel" | app_strings.dart:158 |
| `RoutePaths.connection` | "/connection" | route_paths.dart:7 |
| `RoutePaths.servers` | "/servers" | route_paths.dart:18 |

---

## Implementation Checklist

- [ ] Settings Danger Zone: Add "Disconnect & Exit" ListTile below "Reset to Defaults"
  - Icon: `Icons.logout`, color: `HermesColors.warning`
  - Title: `AppStrings.disconnectExit`
  - Subtitle: "Return to server connection screen"
  - onTap: show confirm dialog
- [ ] Confirm dialog: title, body, Cancel/Disconnect buttons
- [ ] Disconnect action: `disconnect()` → `context.go('/connection')`
- [ ] Guard: hide/disable button when `activeServer == null`
- [ ] Guard: disable button when offline
- [ ] Busy state: show spinner while disconnecting
- [ ] Error state: SnackBar on disconnect failure

---

## MVP Compliance Check

This is a BUG FIX, not a new feature. The Settings screen (F-008) is MVP.
"Server management (add/remove/switch)" is already listed in PRD §F-008.
This fix enables existing MVP functionality that was inaccessible.

- [x] Within existing feature scope (F-008 Settings)
- [x] No premium/auth features
- [x] No backend-dependent features
- [x] No features not in app-spec/01_prd.md

---

## Output Validation

- Source files read:
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/app-spec/01_prd.md`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/app-spec/03_user_flows_navigation.md`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/app-spec/04_ui_design_system.md` (§7.11, §8.8, §9)
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/lib/core/router/app_router.dart`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/lib/core/constants/app_strings.dart`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/lib/core/constants/route_paths.dart`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/lib/features/settings/presentation/settings_screen.dart`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/lib/features/connection/providers/connection_provider.dart`
  - `/Users/abdurrahmanjahfali/Projects/hermex_android/lib/features/connection/presentation/connection_screen.dart`
- MVP features referenced: F-008 Settings, F-001 Server Connection
- Features NOT in MVP that were excluded: None
- Conflicts found with existing specs: Minor — existing §7.11 spec says "Switch Server" → server list bottom sheet, but implementation uses full-screen /servers route. This spec defers to the existing implementation path (/servers) for the "Manage Servers" link, and adds the "Disconnect & Exit" as the navigation path back to /connection.
