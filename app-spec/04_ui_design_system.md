# 04 — UI Design System: Hermex Android

> Complete Material 3 design tokens, screen layouts, component specs, and RTL rules.
> Updated: 2026-07-05 | Author: flutter-ui-ux-designer

---

## §1 Design Tokens — Color System

### §1.1 Core Palette

| Token Name | Hex | Description |
|---|---|---|
| `hermesNavy` | `#001F5E` | Primary brand color |
| `hermesCyan` | `#32C2FF` | Accent / interactive elements |
| `hermesDark` | `#0D1117` | Page background (dark theme) |
| `hermesSurface` | `#161B22` | Card/surface background (dark theme) |
| `hermesBorder` | `#30363D` | Separators, borders, text field outlines |
| `hermesTextPrimary` | `#E6EDF3` | Primary text on dark surfaces |
| `hermesTextSecondary` | `#8B949E` | Secondary/muted text (labels, captions) |
| `hermesTextDisabled` | `#484F58` | Disabled text, placeholder hints |
| `hermesWhite` | `#FFFFFF` | High-emphasis text on navy/cyan, icons |

### §1.2 Semantic Colors

| Token Name | Hex | Usage |
|---|---|---|
| `hermesError` | `#F85149` | Errors, destructive actions, delete buttons |
| `hermesSuccess` | `#3FB950` | Success toasts, positive indicators, health OK |
| `hermesWarning` | `#D29922` | Warnings, paused jobs, attention states |
| `hermesInfo` | `#58A6FF` | Info banners, tool progress, neutral status |

### §1.3 Chat-Specific Colors

| Token Name | Hex | Usage |
|---|---|---|
| `hermesUserBubble` | `#32C2FF` | User message bubble fill |
| `hermesUserBubbleText` | `#0D1117` | User message text (on cyan — dark) |
| `hermesAgentBubble` | `#161B22` | Agent message bubble fill |
| `hermesAgentBubbleText` | `#E6EDF3` | Agent message text (on surface) |
| `hermesCodeBlockBg` | `#0D1117` | Code block background (darker than bubble) |
| `hermesCodeBlockBorder` | `#30363D` | Code block left border accent |

### §1.4 Token Naming Convention

All tokens follow pattern: `hermes{Purpose}` (PascalCase for Dart constants).
Never use raw hex values in widget code.
Generated via `material_color_utilities` to produce full `ColorScheme` from `hermesNavy` seed.

---

## §2 Design Tokens — Typography

### §2.1 Font Families

| Role | Font | Weight | Flutter `TextTheme` |
|---|---|---|---|
| Headline Large | Inter | 700 | `headlineLarge` |
| Headline Medium | Inter | 600 | `headlineMedium` |
| Headline Small | Inter | 600 | `headlineSmall` |
| Title Large | Inter | 600 | `titleLarge` |
| Title Medium | Inter | 500 | `titleMedium` |
| Title Small | Inter | 500 | `titleSmall` |
| Body Large | Inter | 400 | `bodyLarge` |
| Body Medium | Inter | 400 | `bodyMedium` |
| Body Small | Inter | 400 | `bodySmall` |
| Label Large | Inter | 500 | `labelLarge` |
| Label Medium | Inter | 500 | `labelMedium` |
| Label Small | Inter | 400 | `labelSmall` |
| Code (monospace) | JetBrains Mono | 400 | Custom: `HermexTextTheme.code` |

### §2.2 Font Sizes (Material 3 scale)

| Token | Size (sp) | Line Height | Letter Spacing |
|---|---|---|---|
| `headlineLarge` | 32 | 40 | -0.5 |
| `headlineMedium` | 28 | 36 | 0 |
| `headlineSmall` | 24 | 32 | 0 |
| `titleLarge` | 22 | 28 | 0 |
| `titleMedium` | 16 | 24 | 0.15 |
| `titleSmall` | 14 | 20 | 0.1 |
| `bodyLarge` | 16 | 24 | 0.5 |
| `bodyMedium` | 14 | 20 | 0.25 |
| `bodySmall` | 12 | 16 | 0.4 |
| `labelLarge` | 14 | 20 | 0.1 |
| `labelMedium` | 12 | 16 | 0.5 |
| `labelSmall` | 11 | 16 | 0.5 |
| `code` | 13 | 20 | 0 |

### §2.3 Bundled Static Fonts

Inter and JetBrains Mono are bundled as static assets in `assets/fonts/`.
No runtime network fetch — fonts work offline and respect user privacy.

---

## §3 Design Tokens — Spacing

Multiples of 4dp. Named constants in `HermesSpacing`:

| Token | Value (dp) | Usage |
|---|---|---|
| `xs` | 4 | Tight icon padding, chip spacing |
| `sm` | 8 | Inside cards, list tile content padding |
| `md` | 12 | Card inner padding, inline gaps |
| `lg` | 16 | Standard screen padding, card margin |
| `xl` | 24 | Section spacing, between card groups |
| `2xl` | 32 | Major section separators |
| `3xl` | 48 | Screen-top padding below AppBar |

---

## §4 Design Tokens — Elevation & Shadows

| Token | Value | Usage |
|---|---|---|
| `elevationCard` | 1 | Standard card |
| `elevationModal` | 8 | Bottom sheets, dialogs |
| `elevationFAB` | 6 | Floating action button |
| `elevationNavBar` | 3 | Bottom navigation bar (Material 3) |
| `elevationAppBar` | 0 | App bar — flat on dark theme (colored surface) |

Dark theme note: Elevation uses surface tint overlay, not drop shadows.
All elevations use `surfaceTintColor: hermesNavy.withOpacity(0.3)`.

---

## §5 Design Tokens — Border Radius

| Token | Value | Usage |
|---|---|---|
| `radiusSharp` | 4 | Input fields, code blocks |
| `radiusCard` | 12 | Cards, list tiles in card containers |
| `radiusPill` | 24 | Chips, status badges, model selector |
| `radiusBubble` | 16 | Chat bubbles (12 top, 12 bottom, 4 on tail side) |
| `radiusDialog` | 28 | Dialogs (Material 3 default) |
| `radiusBottomSheet` | 28 | Bottom sheets (top corners only) |
| `radiusFAB` | 16 | Circular FAB (large: 28) |

### §5.1 Chat Bubble Radius Rules

```
User bubble (right-aligned):
  topLeft:    16, topRight:    16
  bottomLeft: 16, bottomRight:  4  ← tail at bottom-right

Agent bubble (left-aligned):
  topLeft:    16, topRight:    16
  bottomLeft:  4, bottomRight: 16  ← tail at bottom-left
```

---

## §6 Design Tokens — Iconography

Material Icons filled (default), outlined variants for unselected nav.

### §6.1 Navigation Bar Icons

| Tab | Selected (filled) | Unselected (outlined) | Label |
|---|---|---|---|
| Chat | `chat_bubble` | `chat_bubble_outline` | Chat |
| Sessions | `forum` | `forum_outlined` | Sessions |
| Tasks | `schedule` | `schedule_outlined` | Tasks |
| Workspace | `folder` | `folder_outlined` | Workspace |
| Settings | `settings` | `settings_outlined` | Settings |

### §6.2 Action Icons

| Action | Icon |
|---|---|
| Add / Create | `add` |
| Delete | `delete_outline` (red on confirm) |
| Edit | `edit` |
| Search | `search` |
| Close / Dismiss | `close` |
| Back | `arrow_back` (LTR) / `arrow_forward` (RTL) |
| More options | `more_vert` |
| Refresh | `refresh` |
| Copy | `content_copy` |
| Send message | `send` |
| Stop generation | `stop_circle` |
| Server connected | `cloud_done` |
| Server disconnected | `cloud_off` |
| Health check OK | `check_circle` (green) |
| Health check fail | `error_outline` (red) |
| Job paused | `pause_circle` |
| Job running | `play_circle` |
| Job trigger | `play_arrow` |
| File | `description` |
| Folder | `folder` |
| Folder open | `folder_open` |
| Pin | `push_pin` |
| Archive | `archive` |
| Model | `smart_toy` |
| Memory | `memory` |
| Insights | `insights` |
| Skill on | `toggle_on` |
| Skill off | `toggle_off` |
| RTL | `format_textdirection_r_to_l` |

### §6.3 Icon Sizes

| Context | Size (dp) |
|---|---|
| Navigation bar | 24 |
| App bar actions | 24 |
| List tile leading | 24 |
| FAB icon | 24 |
| Small inline icon | 16 |
| Status indicator dot | 12 |
| Empty state illustration placeholder | 64 |

---

## §7 Screen Layouts — Full Specs

Every screen follows the contract:
- Must define: Loading, Success, Empty, Error, Offline states
- No magic strings — all labels use i18n keys
- RTL-aware layout with `Directionality`

---

### §7.1 SCR-001: Connection Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-001` |
| **Screen Name** | Connection |
| **Route** | `/connection` |
| **Feature** | F-001 Server Connection |
| **Entry Points** | App launch (no saved server), Settings → Add Server, auto-redirect on 401 |
| **Exit Points** | Navigate to `/chat` on successful health check |
| **Primary Action** | "Connect" button — validates URL + API key, calls GET /health |
| **Secondary Actions** | "Saved Servers" (opens server list) |

#### Layout (Success / Default State)

```
┌──────────────────────────────┐
│    AppBar: "Hermex"          │
│    action: saved_servers     │
├──────────────────────────────┤
│                              │
│    [Hermes logo / icon]      │
│                              │
│    Headline:                 │
│    "Connect to Hermes"       │
│                              │
│    ┌──────────────────────┐  │
│    │ Server URL           │  │
│    │ http://192.168.1...  │  │
│    └──────────────────────┘  │
│                              │
│    ┌──────────────────────┐  │
│    │ API Key              │  │
│    │ ●●●●●●●●●●●●●●●●    │  │
│    │ [👁 toggle]          │  │
│    └──────────────────────┘  │
│                              │
│    ┌──────────────────────┐  │
│    │ Server Label (opt.)  │  │
│    │ "Home Server"        │  │
│    └──────────────────────┘  │
│                              │
│    ┌──────────────────────┐  │
│    │     CONNECT          │  │
│    └──────────────────────┘  │
│                              │
│    "Saved Servers" link      │
│                              │
└──────────────────────────────┘
```

#### States

| State | Behavior |
|---|---|
| **Loading** | Connect button shows `CircularProgressIndicator` (cyan). Fields disabled. Label: "Connecting…" |
| **Success** | URL + key fields persist. Health indicator: green `check_circle` with "Connected" below. Button becomes "Continue to Chat". |
| **Empty** | Initial state — fields blank, Connect button enabled but shows validation errors if tapped empty. |
| **Error** | Red banner below fields: "Connection failed: [reason]". Retry button. Examples: timeout, 401, DNS failure. |
| **Offline** | System-level offline detected. Banner at top: "No network connection". Connect button disabled. Icon: `cloud_off`. |

---

### §7.2 SCR-002: Chat Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-002` |
| **Screen Name** | Chat |
| **Route** | `/chat` |
| **Feature** | F-002 Chat |
| **Entry Points** | Bottom nav Chat tab, Connection success redirect |
| **Exit Points** | None (primary screen, always accessible via bottom nav) |
| **Primary Action** | Send message (text input + send button) |
| **Secondary Actions** | Stop generation, attach file, select model |

#### Layout (Success / Active Chat)

```
┌──────────────────────────────┐
│  AppBar: "[Session name]"    │
│  action: [model_selector ▽]  │
├──────────────────────────────┤
│                              │
│  ┌─────────────────────┐     │
│  │ Agent message       │     │
│  │ (markdown rendered) │     │
│  │                     │     │
│  │ ```code block```    │     │
│  │                     │     │
│  │ • list items        │     │
│  │                     │     │
│  │ [tool progress]     │     │
│  └─────────────────────┘     │
│                              │
│           ┌─────────────┐    │
│           │ User message│    │
│           │ short text  │    │
│           └─────────────┘    │
│                              │
│  ┌─────────────────────┐     │
│  │ Agent streaming... █│     │
│  └─────────────────────┘     │
│                              │
├──────────────────────────────┤
│ [📎] [___________________] → │
│            input field   send│
└──────────────────────────────┘
```

**Chat input bar** (bottom-anchored):
- Attachment button (left, `attach_file` icon)
- Text field (expanded, outlined, `hermesBorder`, max 6 lines)
- Send button (right, `send` icon, cyan when text is non-empty, disabled grey when empty)
- During streaming: Send button replaced by `stop_circle` (red) — tapping sends cancel request

**Model selector** (AppBar dropdown):
- `PopupMenuButton` showing server's `/v1/models` list
- Current model displayed in AppBar subtitle
- Changes persist in SharedPreferences per server

#### States

| State | Behavior |
|---|---|
| **Loading** | Initial: skeleton placeholders for messages. Subsequent: existing messages visible, streaming indicator on last agent bubble (pulsing cyan dot). |
| **Success** | Full message history rendered. Input enabled. Model selector functional. |
| **Empty** | No messages in session. Centered illustration: Hermes logo. Text: "Start a conversation". Subtitle: "Ask anything — your agent is ready." Input bar visible and active. |
| **Error** | Agent message may show error inline. Red banner if send fails: "Failed to send message". Retry available on last user message (tap to resend). Network errors: "Connection lost — reconnecting…". |
| **Offline** | Messages visible (read-only). Input disabled with hint: "Offline — connect to send". Reconnect button in banner. |

---

### §7.3 SCR-003: Session List Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-003` |
| **Screen Name** | Sessions |
| **Route** | `/sessions` |
| **Feature** | F-003 Sessions |
| **Entry Points** | Bottom nav Sessions tab |
| **Exit Points** | Tap session → `/sessions/:id`, FAB → new session → `/chat` |

#### Layout

```
┌──────────────────────────────┐
│  AppBar: "Sessions"          │
│  action: [🔍 search]         │
├──────────────────────────────┤
│   ┌────────────────────────┐ │
│   │ 🔍 Search sessions...  │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Session Card ─────────┐ │
│   │ 📌 Title               │ │
│   │ Preview text...        │ │
│   │ 🕐 2h ago  ·  14 msgs  │ │
│   │               [active] │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Session Card ─────────┐ │
│   │ Title (unpinned)       │ │
│   │ Preview text...        │ │
│   │ 🕐 yesterday · 3 msgs  │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Session Card ─────────┐ │
│   │ 📦 Title (archived)    │ │
│   │ dimmed preview...      │ │
│   │ 🕐 last week · 50 msgs │ │
│   └────────────────────────┘ │
│                              │
│                        [＋]  │
└──────────────────────────────┘
```

**Session card** shows:
- Title (truncated to 1 line, `titleMedium`)
- Preview (last message, truncated to 2 lines, `bodySmall`, `hermesTextSecondary`)
- Timestamp (`bodySmall`, `hermesTextSecondary`)
- Message count badge
- Pin indicator: `📌 push_pin` icon if pinned
- Archive indicator: dimmed card, `📦 archive` icon, no preview
- Status indicator dot: green (active), grey (idle), none (old)
- Long-press: context menu (Pin, Archive, Rename, Delete, Fork)

**FAB** (+): Creates new session, prompts for title, navigates to `/chat`.

#### States

| State | Behavior |
|---|---|
| **Loading** | 3-5 shimmer skeleton cards (surface-colored rectangles). |
| **Success** | Session list with search bar. Pull-to-refresh enabled. |
| **Empty** | Centered: `forum_outlined` icon (64dp). Text: "No sessions yet". Subtitle: "Start a chat to create your first session." FAB visible. |
| **Error** | Red banner: "Failed to load sessions". Retry button. Previously cached sessions shown if available. |
| **Offline** | Cached sessions shown (from Isar). Banner: "Offline — showing cached data". FAB disabled. |

---

### §7.4 SCR-004: Session Detail Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-004` |
| **Screen Name** | Session Detail |
| **Route** | `/sessions/:id` |
| **Feature** | F-003 Sessions |
| **Entry Points** | Tap session card in list |
| **Exit Points** | Back → session list. "Open Chat" → `/chat` with session pre-loaded. |

#### Layout

```
┌──────────────────────────────┐
│  ← AppBar: "Session Title"   │
│  action: [⋮ more]            │
├──────────────────────────────┤
│  Metadata card:              │
│  ┌────────────────────────┐  │
│  │ Status: Active         │  │
│  │ Created: Jul 4, 2026   │  │
│  │ Messages: 142          │  │
│  │ Model: claude-sonnet-4 │  │
│  └────────────────────────┘  │
│                              │
│  Actions:                    │
│  ┌────────────────────────┐  │
│  │ [▶ Open Chat]          │  │
│  │ [✏ Rename]  [📌 Pin]   │  │
│  │ [📦 Archive] [🔀 Fork] │  │
│  │ [🗑 Delete]             │  │
│  └────────────────────────┘  │
│                              │
│  Message Preview (last 10):  │
│  ┌────────────────────────┐  │
│  │ User: message text...  │  │
│  │ Agent: response...     │  │
│  │ (read-only, condensed) │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

#### States

| State | Behavior |
|---|---|
| **Loading** | Skeleton card for metadata + shimmer for message preview. |
| **Success** | Full session detail rendered. All actions available. |
| **Empty** | (Handled via list — cannot reach detail of nonexistent session) |
| **Error** | Red banner: "Session not found or deleted". "Go Back" button returns to list. |
| **Offline** | Cached metadata shown. Actions disabled (no mutations). Banner: "Offline — read only". |

---

### §7.5 SCR-005: Task List Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-005` |
| **Screen Name** | Tasks (Cron Jobs) |
| **Route** | `/tasks` |
| **Feature** | F-004 Tasks |
| **Entry Points** | Bottom nav Tasks tab |
| **Exit Points** | Tap job → `/tasks/:id`, FAB → create job |

#### Layout

```
┌──────────────────────────────┐
│  AppBar: "Cron Jobs"         │
│  action: [🔍 search]         │
├──────────────────────────────┤
│                              │
│   ┌─ Job Card ─────────────┐ │
│   │ ▶ "Daily briefing"     │ │
│   │ ⏱ every day at 09:00   │ │
│   │ ✅ Last: 2h ago (OK)   │ │
│   │ 🔁 Next: in 5h         │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Job Card ─────────────┐ │
│   │ ⏸ "Memory watchdog"   │ │
│   │ ⏱ every 30m           │ │
│   │ ⚠ Last: failed        │ │
│   │ 🔁 Paused              │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Job Card ─────────────┐ │
│   │ ▶ "Disk cleanup"      │ │
│   │ ⏱ daily at 03:00      │ │
│   │ ✅ Last: OK            │ │
│   │ 🔁 Next: tomorrow      │ │
│   └────────────────────────┘ │
│                              │
│                        [＋]  │
└──────────────────────────────┘
```

**Job card** shows:
- Status icon: `▶ play_circle` (active), `⏸ pause_circle` (paused), `⚠ error` (last run failed)
- Job name (`titleMedium`)
- Schedule description (`bodySmall`, `hermesTextSecondary`)
- Last run status + timestamp
- Next run time
- Swipe actions: left → Pause/Resume, right → Delete

**FAB** (+): Opens create job dialog. FAB hidden on scroll-down, shown on scroll-up.

#### States

| State | Behavior |
|---|---|
| **Loading** | 3-5 shimmer job cards. |
| **Success** | Job list rendered. FAB visible. Pull-to-refresh. |
| **Empty** | Centered: `schedule_outlined` (64dp). Text: "No cron jobs". Subtitle: "Create your first scheduled task." FAB visible. |
| **Error** | Red banner: "Failed to load jobs". Retry. |
| **Offline** | Cached jobs shown. Banner: "Offline — read only". FAB disabled. |

---

### §7.6 SCR-006: Task Detail Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-006` |
| **Screen Name** | Task Detail |
| **Route** | `/tasks/:id` |
| **Feature** | F-004 Tasks |
| **Entry Points** | Tap job card |
| **Exit Points** | Back → task list |

#### Layout

```
┌──────────────────────────────┐
│  ← AppBar: "Job Name"        │
│  action: [⋮ edit/delete]     │
├──────────────────────────────┤
│  Status banner:              │
│  ┌────────────────────────┐  │
│  │ ▶ Active · Next: 5h    │  │
│  └────────────────────────┘  │
│                              │
│  ┌─ Details ───────────────┐ │
│  │ Schedule: 0 9 * * *    │ │
│  │ Created: Jul 1, 2026   │ │
│  │ Last Run: 2h ago       │ │
│  │ Deliver: telegram      │ │
│  │ Skills: [tag1] [tag2]  │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ Prompt Preview ────────┐ │
│  │ Daily briefing with    │ │
│  │ latest news and agent  │ │
│  │ activity summary...    │ │
│  └────────────────────────┘  │
│                              │
│  Actions:                    │
│  ┌────────────────────────┐  │
│  │ [▶ Run Now]  [⏸ Pause] │  │
│  │ [✏ Edit]     [🗑 Delete]│  │
│  └────────────────────────┘  │
│                              │
│  Run History:                │
│  ┌────────────────────────┐  │
│  │ ✅ Jul 5, 09:00  OK    │  │
│  │ ✅ Jul 4, 09:00  OK    │  │
│  │ ⚠ Jul 3, 09:00  Error │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

#### Sub-screens (dialogs)

| Dialog | Trigger | Content |
|---|---|---|
| **Create Job** | FAB | Schedule picker (cron or interval), prompt text field, deliver target, skills picker, name, [Create] [Cancel] |
| **Edit Job** | ⋮ → Edit | Same fields pre-filled. [Save] [Cancel] |
| **Delete Confirm** | ⋮ → Delete | "Delete '[name]'? This cannot be undone." [Cancel] [Delete] |
| **Run Output** | Tap history item | Full output text in scrollable view. [Copy] [Close] |

#### States

| State | Behavior |
|---|---|
| **Loading** | Skeleton card for details. |
| **Success** | Full detail rendered. Actions based on current status (Pause/Resume toggle). |
| **Empty** | (N/A — cannot reach detail of nonexistent job) |
| **Error** | "Job not found or deleted." Back to list. 404 from server. |
| **Offline** | Cached details shown. All mutation actions disabled. |

---

### §7.7 SCR-007: Skills Browser Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-007` |
| **Screen Name** | Skills |
| **Route** | `/skills` |
| **Feature** | F-005 Skills Browser |
| **Entry Points** | Settings → Skills |
| **Exit Points** | Back → Settings |

#### Layout

```
┌──────────────────────────────┐
│  ← AppBar: "Skills"          │
│  action: [🔍 search]         │
├──────────────────────────────┤
│   ┌────────────────────────┐ │
│   │ 🔍 Search skills...    │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Skill Card ───────────┐ │
│   │ [🟢] git-workflows    │ │
│   │ Automate git branch,  │ │
│   │ merge, and PR work... │ │
│   │ 12 snippets · High    │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Skill Card ───────────┐ │
│   │ [⚫] translation       │ │
│   │ Translate content     │ │
│   │ across languages...   │ │
│   │ Disabled              │ │
│   └────────────────────────┘ │
└──────────────────────────────┘
```

**Skill card** shows:
- Status toggle: `🟢 toggle_on` (enabled) / `⚫ toggle_off` (disabled)
- Skill name (`titleMedium`, JetBrains Mono style)
- Description (2 lines, `bodySmall`, `hermesTextSecondary`)
- Metadata: snippet count, source reputation
- Tap: expand to full skill content (embedded markdown view, secondary)
- Toggle: tap the toggle icon — sends PUT to server

#### States

| State | Behavior |
|---|---|
| **Loading** | 4-6 shimmer skill cards. |
| **Success** | Skills list with toggle functionality. Search filters in real-time. |
| **Empty** | Centered: `extension_outlined` (64dp). Text: "No skills installed". Subtitle: "Install skills on your Hermes server to see them here." |
| **Error** | "Failed to load skills". Retry. |
| **Offline** | Cached skill list shown. Toggles disabled. Banner: "Offline — cannot modify skills". |

---

### §7.8 SCR-008: Workspace Browser Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-008` |
| **Screen Name** | Workspace |
| **Route** | `/workspace` |
| **Feature** | F-006 Workspace Browser |
| **Entry Points** | Bottom nav Workspace tab |
| **Exit Points** | None (primary screen, always accessible) |

#### Layout

```
┌──────────────────────────────┐
│  AppBar: "/home/agent"       │
│  (breadcrumb path, tappable) │
├──────────────────────────────┤
│                              │
│   📁 📂 projects/            │
│   📁 📂 .hermes/             │
│   📁 📂 app-spec/            │
│   📄 📄 README.md    4.2 KB │
│   📄 📄 pubspec.yaml  1.8 KB│
│                              │
│   Tap folder → navigate in   │
│   Tap file → preview         │
│                              │
└──────────────────────────────┘
```

**List items**:
- Folder: `📁 folder` icon, name (`bodyLarge`), tap to navigate into folder
- File: `📄 description` icon, name (`bodyLarge`), size (`bodySmall`, `hermesTextSecondary`), tap to preview

**Breadcrumb AppBar**: Each path segment is tappable to jump to that level.

#### States

| State | Behavior |
|---|---|
| **Loading** | Shimmer list items (5-8 rows). |
| **Success** | Directory listing rendered. |
| **Empty** | "This directory is empty." |
| **Error** | "Failed to load directory". Retry. (Common: permission denied on server.) |
| **Offline** | Banner: "Offline — workspace unavailable". List area empty/greyed. |

#### File Preview (bottom sheet)

Triggered by tapping a file. Shows file content in a modal bottom sheet:
- Text/code files: Syntax-highlighted (read-only, JetBrains Mono, dark code bg)
- Images: Rendered inline
- Other: "Cannot preview this file type" with file metadata (size, modified date)
- Actions: [Copy content] [Close]

---

### §7.9 SCR-009: Memory Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-009` |
| **Screen Name** | Memory |
| **Route** | `/memory` |
| **Feature** | F-007 Memory & Insights |
| **Entry Points** | Settings → Memory |
| **Exit Points** | Back → Settings |

#### Layout

```
┌──────────────────────────────┐
│  ← AppBar: "Memory"          │
├──────────────────────────────┤
│   Memory usage bar:          │
│   ┌────────────────────────┐ │
│   │ ████████░░ 78% (1020B) │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Memory Entry ─────────┐ │
│   │ "User prefers concise  │ │
│   │  responses"            │ │
│   │ Priority: P1           │ │
│   └────────────────────────┘ │
│                              │
│   ┌─ Memory Entry ─────────┐ │
│   │ "Project uses Riverpod │ │
│   │  with GoRouter"        │ │
│   │ Priority: P2           │ │
│   └────────────────────────┘ │
│                              │
│   Read-only — managed by    │
│   the agent on server       │
└──────────────────────────────┘
```

**Memory entry card**:
- Memory content (`bodyMedium`)
- Priority badge (P1/P2/P3, colored pill)
- No edit/delete (read-only, server-managed)

#### States

| State | Behavior |
|---|---|
| **Loading** | Shimmer cards + skeleton memory bar. |
| **Success** | Memory entries with usage bar. |
| **Empty** | Centered: `memory` icon (64dp). Text: "No memories stored". Subtitle: "The agent will save facts as it learns about you." |
| **Error** | "Failed to load memory". Retry. |
| **Offline** | Cached memory shown. Banner: "Offline — cached data". |

---

### §7.10 SCR-010: Insights Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-010` |
| **Screen Name** | Insights |
| **Route** | `/insights` |
| **Feature** | F-007 Memory & Insights |
| **Entry Points** | Settings → Insights |
| **Exit Points** | Back → Settings |

#### Layout

```
┌──────────────────────────────┐
│  ← AppBar: "Insights"        │
├──────────────────────────────┤
│                              │
│  ┌─ Stats Card ────────────┐ │
│  │ Tokens This Month       │ │
│  │        245,832          │ │
│  │  ▲ 12% from last month  │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ Stats Card ────────────┐ │
│  │ Active Sessions         │ │
│  │          47             │ │
│  │  Last 30 days           │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ Stats Card ────────────┐ │
│  │ Top Model               │ │
│  │  deepseek-v4-pro        │ │
│  │  68% of all requests    │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ Stats Card ────────────┐ │
│  │ Total Cron Runs         │ │
│  │        1,203            │ │
│  │  98.2% success rate     │ │
│  └────────────────────────┘  │
│                              │
│  Last synced: 5 min ago      │
└──────────────────────────────┘
```

**Stats card**: Icon → large number → description → trend arrow + percentage.

#### States

| State | Behavior |
|---|---|
| **Loading** | 4 shimmer stat cards with skeleton numbers. |
| **Success** | Stats cards with data. Pull-to-refresh updates. |
| **Empty** | "No insights available yet." Subtitle: "Start using the agent to generate data." |
| **Error** | "Failed to load insights". Retry. |
| **Offline** | Cached stats shown. "Last synced: [timestamp]" banner. |

---

### §7.11 SCR-011: Settings Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-011` |
| **Screen Name** | Settings |
| **Route** | `/settings` |
| **Feature** | F-008 Settings |
| **Entry Points** | Bottom nav Settings tab |
| **Exit Points** | Sub-navigation: tap item → Skills/Memory/Insights/Server management |

#### Layout

```
┌──────────────────────────────┐
│  AppBar: "Settings"          │
├──────────────────────────────┤
│                              │
│  ┌─ Server ────────────────┐ │
│  │ Connected: Home Server  │ │
│  │ 192.168.1.100:8642     │ │
│  │ [Switch Server] [Add]  │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ Agent ─────────────────┐ │
│  │ Skills                 > │ │
│  │ Memory                 > │ │
│  │ Insights               > │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ Preferences ───────────┐ │
│  │ Default Model      ▽   > │ │
│  │ Theme: Dark / Light     │ │
│  └────────────────────────┘  │
│                              │
│  ┌─ About ─────────────────┐ │
│  │ Version: 0.1.0          │ │
│  │ Hermes Agent: v2.x      │ │
│  │ License: MIT           > │ │
│  └────────────────────────┘  │
│                              │
│  [Disconnect & Exit]         │
│                              │
└──────────────────────────────┘
```

**Settings sections** (Material 3 `ListTile` groups with subheaders):
1. **Server**: Current connection info, switch/add server buttons
2. **Agent**: Navigation to Skills, Memory, Insights (chevron →)
3. **Preferences**: Model picker dropdown, theme toggle
4. **About**: Version, license, credits
5. **Danger zone**: Disconnect button (red outline, at bottom)

#### Sub-navigation

| Item | Route |
|---|---|
| Skills | → `/skills` |
| Memory | → `/memory` |
| Insights | → `/insights` |
| Switch Server | → server list bottom sheet |
| Add Server | → `/connection` (new server mode) |
| Theme Toggle | Toggle switch (immediate, no navigation) |
| Model Selector | Bottom sheet with radio list |
| License | → `/settings/license` (text page) |

#### States (all sub-screens inherit)

| State | Behavior |
|---|---|
| **Loading** | Settings skeleton. |
| **Success** | All settings rendered, values populated from preferences. |
| **Empty** | (N/A — settings always have defaults) |
| **Error** | "Failed to load server info". Retry. Model list may fail independently. |
| **Offline** | Most settings available. Server info shows last-known state. Model selector disabled. |

---

### §7.12 SCR-012: Server List Screen

| Field | Value |
|---|---|
| **Screen ID** | `SCR-012` |
| **Screen Name** | Server List |
| **Route** | `/servers` (or bottom sheet from Settings) |
| **Feature** | F-001 Server Connection, F-008 Settings |
| **Entry Points** | Settings → Switch Server, Connection screen → Saved Servers |
| **Exit Points** | Tap server → connect + navigate to Chat |

#### Layout

```
┌──────────────────────────────┐
│  ← AppBar: "Servers"         │
│  action: [＋ add]            │
├──────────────────────────────┤
│                              │
│  🟢 Home Server              │
│     192.168.1.100:8642      │
│     Active · 2 sessions     │
│                              │
│  ⚪ Office Server            │
│     10.0.0.50:8642          │
│     Last connected: 3d ago  │
│                              │
│  ⚪ VPS Server               │
│     hermes.example.com      │
│     Last connected: never   │
│                              │
└──────────────────────────────┘
```

**Server list item**:
- Status dot: `🟢` active, `⚪` inactive
- Server label + URL (`titleMedium`)
- Last connected / session count (`bodySmall`, `hermesTextSecondary`)
- Swipe to delete (with confirmation dialog)
- Tap to connect (switches active server)

#### States

| State | Behavior |
|---|---|
| **Loading** | Shimmer server items. |
| **Success** | Server list with status indicators. |
| **Empty** | "No saved servers." Subtitle: "Add your first Hermes server." FAB visible. |
| **Error** | "Failed to load server list". Retry. (Local storage error.) |
| **Offline** | Server list loaded from local storage. Cannot test connectivity. |

---

## §8 Component Specifications

### §8.1 Chat Bubble — User Variant

```
┌──────────────────────────────┐
│ Properties                   │
├──────────────────────────────┤
│ Alignment       right        │
│ Fill            hermesCyan   │
│ Text color      hermesDark   │
│ Max width       75% of screen│
│ Radius          TL:16 TR:16  │
│                 BL:16 BR:4   │
│ Padding         12/16        │
│ Typography      bodyLarge    │
├──────────────────────────────┤
│ States                       │
│ - Default: as above          │
│ - Sending: opacity 0.6,      │
│   pending indicator (clock)  │
│ - Failed: red border         │
│   (0.5dp), retry icon on tap │
│ - Selected: slightly         │
│   elevated background        │
└──────────────────────────────┘
```

### §8.2 Chat Bubble — Agent Variant

```
┌──────────────────────────────┐
│ Properties                   │
├──────────────────────────────┤
│ Alignment       left         │
│ Fill            hermesSurface│
│ Text color      hermesText   │
│                 Primary      │
│ Max width       85% of screen│
│ Radius          TL:16 TR:16  │
│                 BL:4  BR:16  │
│ Padding         12/16        │
│ Typography      bodyLarge    │
├──────────────────────────────┤
│ States                       │
│ - Default: as above          │
│ - Streaming: shows cursor    │
│   (blinking cyan █) at end   │
│ - Tool progress: embedded    │
│   chip with spinner + label  │
│ - Errored: inline red text   │
│   "Generation interrupted"   │
│ - Thinking: pulsing dots     │
│   "●●●" (indeterminate)     │
└──────────────────────────────┘
```

### §8.3 Code Block (inside Agent Bubble)

```
┌──────────────────────────────┐
│ Properties                   │
├──────────────────────────────┤
│ Background      hermesCodeBg │
│                 (#0D1117)    │
│ Border left     3dp          │
│                 hermesCyan   │
│ Font            JetBrains    │
│                 Mono 13sp    │
│ Padding         12/16dp      │
│ Radius          radiusSharp  │
│                 (4dp)        │
├──────────────────────────────┤
│ Features                     │
│ - Copy button (top-right)    │
│ - Language label (top-left)  │
│   extracted from fence info  │
│ - Horizontal scroll for long │
│   lines                      │
│ - Max height: 300dp, then    │
│   internal vertical scroll   │
└──────────────────────────────┘
```

### §8.4 Markdown Rendering Rules

Rendered via `flutter_markdown` with custom `MarkdownStyleSheet`:

| Element | Style |
|---|---|
| `# Heading 1` | `headlineSmall`, `hermesTextPrimary` |
| `## Heading 2` | `titleLarge`, `hermesTextPrimary` |
| `### Heading 3` | `titleMedium`, `hermesTextPrimary` |
| `**bold**` | `bodyLarge` w/ `FontWeight.w700` |
| `*italic*` | `bodyLarge` w/ `FontStyle.italic` |
| `` `inline code` `` | JetBrains Mono, `hermesCyan` color, `hermesSurface` bg, 2dp radius, 2dp h-padding |
| ```` ```block``` ```` | Custom code block widget (see §8.3) |
| `- list item` | `bodyLarge`, 8dp indent, `hermesCyan` bullet |
| `1. numbered` | `bodyLarge`, 8dp indent |
| `> blockquote` | Left border 3dp `hermesBorder`, 8dp padding, `hermesTextSecondary` italic |
| `[link](url)` | `hermesCyan`, underline on tap, opens in browser |
| `![image](url)` | Rounded 8dp, max width 100%, tap to fullscreen |
| `--- hr` | 1dp `hermesBorder` line, 8dp vertical margin |
| Table | `hermesBorder` separators, alternating row bg, horizontal scroll |

### §8.5 Bottom Navigation Bar

```
┌──────────────────────────────┐
│ Properties                   │
├──────────────────────────────┤
│ Widget     NavigationBar     │
│            (Material 3)      │
│ Height     80dp              │
│ Fill       hermesSurface     │
│ Elevation  elevationNavBar(3)│
│ Indicator  hermesCyan pill   │
│            with navy icon    │
├──────────────────────────────┤
│ Destinations:                │
│ [Chat] [Sessions] [Tasks]    │
│ [Workspace] [Settings]       │
├──────────────────────────────┤
│ Behavior:                    │
│ - Selected: filled icon +    │
│   label (labelLarge)         │
│ - Unselected: outlined icon  │
│   + label (labelMedium,      │
│   hermesTextSecondary)       │
│ - Indicator: pill-shaped     │
│   (radius 16), hermesCyan    │
│   40% opacity background     │
│ - 5 destinations max (M3)    │
└──────────────────────────────┘
```

### §8.6 Floating Action Button (FAB)

```
┌──────────────────────────────┐
│ Properties                   │
├──────────────────────────────┤
│ Shape      Circle (small)    │
│            or StadiumBorder  │
│            (extended)        │
│ Fill       hermesCyan        │
│ Icon       add (white)       │
│ Elevation  elevationFAB (6)  │
│ Position   bottom-end        │
│            margin 16dp       │
│            above nav bar     │
├──────────────────────────────┤
│ Behavior:                    │
│ - Sessions list: create      │
│   session                    │
│ - Tasks list: create job     │
│ - Not on: Chat, Settings,    │
│   Workspace, sub-screens     │
│ - Hides on scroll-down       │
│   (standard M3 behavior)     │
└──────────────────────────────┘
```

### §8.7 Card Component

```
┌──────────────────────────────┐
│ Properties                   │
├──────────────────────────────┤
│ Fill       hermesSurface     │
│ Radius     radiusCard (12dp) │
│ Elevation  elevationCard (1) │
│ Padding    16dp (all sides)  │
│ Margin     8dp horizontal    │
│            4dp vertical      │
├──────────────────────────────┤
│ Variants:                    │
│ - Default: as above          │
│ - Tappable: InkWell wrapper, │
│   surface color shifts on    │
│   press (splash: hermesCyan  │
│   at 10% opacity)            │
│ - Dismissible: swipe-to-     │
│   dismiss background shows   │
│   action icon + label        │
│ - Selected: 1dp hermesCyan   │
│   border                     │
└──────────────────────────────┘
```

### §8.8 Dialog & Bottom Sheet

| Property | Dialog | Bottom Sheet |
|---|---|---|
| Shape | `RoundedRectangleBorder` radius 28dp | Top corners radius 28dp |
| Fill | `hermesSurface` | `hermesSurface` |
| Padding | 24dp | 16dp vertical, 16dp horizontal |
| Title | `titleLarge`, centered | `titleMedium`, left-aligned |
| Actions | Row: [Cancel] [Confirm] (end-aligned) | Full-width buttons at bottom |
| Backdrop | `Colors.black54` | `Colors.black54` (drag handle visible) |
| Drag handle | N/A | 4dp × 32dp `hermesBorder` pill, centered top |
| Close | Tap outside, back button, Cancel button | Swipe down, drag handle, back button |

### §8.9 Common State Widgets

#### Loading (Shimmer/Skeleton)

Pattern: Use `shimmer` package or manual animation.
- Cards: Surface-colored rounded rectangles (12dp radius), pulsing opacity 0.3 ↔ 0.6
- Text lines: Surface-colored rectangles (6dp radius), varying widths (60%, 80%, 40%)
- Lists: 3-6 skeleton items with slight stagger animation
- Never use `CircularProgressIndicator` alone for full-page loads — use skeletons for structured content

#### Empty State

Pattern: Centered column.
```
┌──────────────────────────────┐
│                              │
│          [icon 64dp]         │
│        (hermesTextDisabled)  │
│                              │
│       Title text             │
│    (titleMedium, center)     │
│                              │
│    Subtitle text             │
│  (bodySmall, center,         │
│   hermesTextSecondary)       │
│                              │
│    [Optional action button]  │
│                              │
└──────────────────────────────┘
```

#### Error State

Pattern: Banner + retry.
```
┌──────────────────────────────┐
│ ⚠ Error message      [RETRY]│  ← MaterialBanner or SnackBar
└──────────────────────────────┘
```
- Error type icons: `error_outline` (red), `cloud_off` (offline), `wifi_off` (network)
- Retry button: text button, hermesCyan
- Network errors: auto-retry with exponential backoff (1s, 2s, 4s, 8s) shown as countdown

#### Offline State

Pattern: Persistent banner at top.
```
┌──────────────────────────────┐
│ ⚡ Offline — [feature]       │
│    unavailable               │
└──────────────────────────────┘
```
- Yellow/amber background (`hermesWarning` at 10% opacity)
- Content below banner: read-only, cached, or greyed out
- Auto-dismisses when connectivity restored
- Non-destructive: user can still browse cached content

---

## §9 Navigation Specification

### §9.1 Bottom Navigation Bar

| Index | Label | Icon (Filled) | Icon (Outlined) | Route | Feature |
|---|---|---|---|---|---|
| 0 | Chat | `chat_bubble` | `chat_bubble_outline` | `/chat` | F-002 |
| 1 | Sessions | `forum` | `forum_outlined` | `/sessions` | F-003 |
| 2 | Tasks | `schedule` | `schedule_outlined` | `/tasks` | F-004 |
| 3 | Workspace | `folder` | `folder_outlined` | `/workspace` | F-006 |
| 4 | Settings | `settings` | `settings_outlined` | `/settings` | F-008 |

### §9.2 GoRouter Route Table

```
/                          → Redirect to /connection or /chat
/connection                → SCR-001 Connection Screen
/chat                      → SCR-002 Chat Screen (ShellRoute, part of bottom nav)
/sessions                  → SCR-003 Session List (ShellRoute)
/sessions/:id              → SCR-004 Session Detail
/tasks                     → SCR-005 Task List (ShellRoute)
/tasks/:id                 → SCR-006 Task Detail
/tasks/create              → Create Job dialog (pushed as route)
/skills                    → SCR-007 Skills Browser
/workspace                 → SCR-008 Workspace Browser (ShellRoute)
/memory                    → SCR-009 Memory
/insights                  → SCR-010 Insights
/settings                  → SCR-011 Settings (ShellRoute)
/servers                   → SCR-012 Server List
```

### §9.3 Shell Route

Bottom tabs use `StatefulShellRoute.indexedStack` to preserve tab state:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return ScaffoldWithNavBar(navigationShell: navigationShell);
  },
  branches: [
    // Branch 0: Chat
    StatefulShellBranch(routes: [GoRoute(path: '/chat', ...)]),
    // Branch 1: Sessions
    StatefulShellBranch(routes: [
      GoRoute(path: '/sessions', ...),
      GoRoute(path: '/sessions/:id', ...),
    ]),
    // Branch 2: Tasks
    StatefulShellBranch(routes: [
      GoRoute(path: '/tasks', ...),
      GoRoute(path: '/tasks/:id', ...),
    ]),
    // Branch 3: Workspace
    StatefulShellBranch(routes: [GoRoute(path: '/workspace', ...)]),
    // Branch 4: Settings
    StatefulShellBranch(routes: [
      GoRoute(path: '/settings', ...),
      GoRoute(path: '/skills', ...),
      GoRoute(path: '/memory', ...),
      GoRoute(path: '/insights', ...),
    ]),
  ],
)
```

### §9.4 Initial Route Logic

```
if (hasSavedServer && healthCheckPasses)
  → /chat (active session or new)
else if (hasSavedServer && healthCheckFails)
  → /connection (retry connection)
else
  → /connection (first launch)
```

### §9.5 Navigation Behavior

| Context | Behavior |
|---|---|
| Tab switch | Preserves scroll position and state (IndexedStack) |
| Back from sub-screen | Pops to parent shell tab |
| Back from tab root | Android back exits app (after confirm on Chat tab to avoid accidental exit) |
| Deep link | `hermex://chat?session=xyz` → opens Chat with session pre-loaded |
| Connection loss during navigation | Stays on current screen, shows offline banner |

---

## §10 RTL (Right-to-Left) Specification

### §10.1 Activation

RTL activates when device locale is Arabic (`ar`) or any RTL language.
Detected via `Directionality.of(context)` — no manual flipping required if widgets use `start`/`end` instead of `left`/`right`.

### §10.2 Layout Mirroring Rules

| Element | LTR | RTL |
|---|---|---|
| **Bottom nav order** | Chat → Sessions → Tasks → Workspace → Settings | Same order (icons mirror, not tab order) |
| **Back button** | `arrow_back` | `arrow_forward` (auto-handled by M3) |
| **List tile trailing icon** | Right edge | Left edge |
| **FAB position** | Bottom-end (right) | Bottom-start (left) |
| **Card swipe actions** | Swipe left → delete, swipe right → archive | Swipe right → delete, swipe left → archive |
| **Text alignment** | Left | Right (auto via `TextDirection`) |
| **Input text** | Left-aligned | Right-aligned (auto) |
| **Drawer** | Opens from left | Opens from right |

### §10.3 Chat Bubble RTL

User/agent alignment does NOT mirror — it always follows message sender:

| Element | LTR | RTL |
|---|---|---|
| **User bubble** | Right-aligned | Right-aligned (unchanged) |
| **Agent bubble** | Left-aligned | Left-aligned (unchanged) |
| **Bubble tail** | Bottom-right (user), Bottom-left (agent) | Bottom-right (user), Bottom-left (agent) — unchanged, tails stay on their respective edges |

### §10.4 Bidirectional (Bidi) Text in Chat

Chat messages may contain mixed Arabic + English + code. Rules:

1. **Message-level**: Each chat bubble respects the `TextDirection` of its content via `Bidi.stripHtmlIfNeeded` or `TextDirection` heuristic.
2. **Arabic-first messages**: If first strong character is Arabic, bubble text alignment is RTL. Text flows RTL. Embedded Latin runs LTR inline.
3. **English-first messages**: If first strong character is Latin, bubble text alignment remains LTR.
4. **Code blocks**: Always LTR — code does not mirror.
5. **Markdown**: `flutter_markdown` respects `TextDirection` of parent. Tables, lists, and mixed content handled natively.
6. **Numbers**: Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) rendered per locale; Latin digits (0123…) in code blocks preserved.

### §10.5 RTL-Specific Spacing Adjustments

| Token | LTR Value | RTL Adjustment |
|---|---|---|
| `listTileContentPadding` | `EdgeInsets.only(left: 16, right: 24)` | `EdgeInsets.only(left: 24, right: 16)` |
| `messageTailOffset` | Bottom-right corner reduced | Bottom-left corner reduced (same — handled by `BorderRadius` directional) |
| `inputPrefixIcon` | Padding right: 8 | Padding left: 8 |
| `cardActionAlignment` | `MainAxisAlignment.end` | `MainAxisAlignment.start` |

### §10.6 RTL Testing Checklist

- [ ] All screens render with `Directionality` set to RTL
- [ ] Bottom nav icons and labels positioned correctly
- [ ] Chat bubbles: user on right, agent on left (unchanged)
- [ ] Mixed Arabic + English text renders inline correctly
- [ ] Code blocks remain LTR regardless of surrounding text direction
- [ ] Settings chevrons flip to left edge
- [ ] FAB moves to left side
- [ ] Swipe actions reverse
- [ ] Numbers and dates use correct locale format

---

## §11 Accessibility Requirements

| Requirement | Implementation |
|---|---|
| **Semantic labels** | All icons have `Semantics(label: ...)` |
| **Contrast ratio** | All text meets WCAG AA (4.5:1 for body, 3:1 for large) |
| **Touch targets** | Minimum 48×48dp for all interactive elements |
| **Screen reader** | All screens navigable via TalkBack/VoiceOver |
| **Focus order** | Logical tab order (top-left to bottom-right or RTL equivalent) |
| **Error announcements** | Errors announced via `SemanticsService.announce()` |
| **Dynamic text** | All text scales with system font size (no hardcoded sizes) |
| **Reduce motion** | `MediaQuery.of(context).disableAnimations` respected for shimmer/spinner |

---

## §12 UX Copy Rules

- All user-facing strings use i18n keys (never hardcoded).
- English and Arabic translations in `app_en.arb` / `app_ar.arb`.
- Tone: neutral, professional, concise. No marketing-speak.
- Error messages: state what happened + what user can do.
- Empty states: describe what goes here + how to create it (actionable).

---

## §13 Animation & Motion

| Element | Animation | Duration | Curve |
|---|---|---|---|
| **Screen transition** | `FadeTransition` + slight slide | 200ms | `easeOut` |
| **Nav bar indicator** | Material 3 built-in pill animation | 300ms | `easeInOut` |
| **FAB show/hide** | `ScaleTransition` | 200ms | `easeOutBack` |
| **Streaming cursor** | Blinking opacity 1 ↔ 0 | 800ms | `linear` |
| **Swipe dismiss** | `Dismissible` default slide | 300ms | `easeIn` |
| **Card tap splash** | M3 `InkWell` ripple | 400ms | `easeInOut` |
| **Dialog entry** | `ScaleTransition` 0.9 → 1.0 | 250ms | `easeOutBack` |
| **Shimmer** | Gradient slide left → right | 1500ms | `linear` (looping) |

---

## §14 MVP Compliance Check

- ✅ 5-tab bottom navigation only (Chat | Sessions | Tasks | Workspace | Settings)
- ✅ No premium/auth features (free/OSS, self-hosted)
- ✅ All features in app-spec/01_prd.md §Feature List (MVP): F-001 through F-008
- ✅ No notifications, voice, TTS, widgets, or multi-account
- ✅ Dark theme default, Material 3
- ✅ RTL support for Arabic locale
- ✅ Every screen defines all 5 required states

---

## §15 Output Validation Checklist

- **Source files read**: `app-spec/00_project_context.md`, `app-spec/01_prd.md`, `app-spec/03_user_flows_navigation.md`, `app-spec/04_ui_design_system.md` (original), `app-spec/07_flutter_architecture.md`, `app-spec/06_api_contract.md`, `app-spec/00_active_capabilities.md`, `app-spec/00_project_overrides.md`, `app-spec/02_monetization_entitlements.md`
- **MVP features referenced**: F-001 (Connection), F-002 (Chat), F-003 (Sessions), F-004 (Tasks), F-005 (Skills), F-006 (Workspace), F-007 (Memory & Insights), F-008 (Settings)
- **Features NOT in MVP that were excluded**: Voice input, TTS output, Widget, Notifications, Offline session cache, Multi-account support
- **Conflicts found with existing specs**: None. All spec files aligned. Original 04_ui_design_system.md was a minimal 23-line stub — no conflicts to resolve.

---

## §16 Handoff Notes

1. **Token dart file**: `lib/core/theme/colors.dart` should define all §1 tokens as `const Color` constants.
2. **Typography dart file**: `lib/core/theme/typography.dart` should produce `HermexTextTheme` using `GoogleFonts.interTextTheme()` and `GoogleFonts.jetBrainsMono()`.
3. **App theme**: `lib/core/theme/app_theme.dart` should combine `ColorScheme.fromSeed(seedColor: hermesNavy, brightness: Brightness.dark)` with custom `TextTheme` and component themes.
4. **Router**: `lib/core/router/app_router.dart` should implement §9.3 with `StatefulShellRoute.indexedStack`.
5. **RTL**: No special code needed beyond using `start`/`end` instead of `left`/`right` in `EdgeInsets` and `Alignment`. Flutter M3 handles the rest.
6. **i18n**: All screen labels, empty states, error messages, toast text must be in `.arb` files — `app_en.arb` and `app_ar.arb` — with keys matching pattern `screen_component_state` (e.g., `chat_empty_title`, `tasks_error_retry`).
