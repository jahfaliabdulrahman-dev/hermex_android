# BUG/UX MEGA — Hermex Android v0.1.0-rc2 Post-Release Issues

## IMPORTANT — Read Before Planning
This task contains **5 distinct issues** across multiple files. The Lead Architect MUST:
1. Decompose into separate Kanban cards — one per specialist
2. Plan with experts BEFORE any code is written
3. **Plan → Plan → Plan → then code.** Zero tolerance for direct coding without architectural planning.
4. Run all existing tests before and after changes (currently 478 tests)

---

# Target
Project:  /Users/abdurrahmanjahfali/Projects/hermex_android
Assignee: flutter-lead-architect
Task Type: MULTI — Decompose into 5 sub-tasks

---

# Background
المستخدم قام بتجربة النسخة الجديدة من Hermex Android (v0.1.0-rc2, `latest` tag → `3fffd22`) ووجد 5 مشاكل متبقية من إصدارات سابقة لم تُحل، ومشاكل جديدة ظهرت بعد الإصلاحات. المشاكل تغطي: السمة (Theme)، المهام المجدولة (Cron Jobs)، المرفقات (File Upload)، نسخ الدردشة (Copy)، ومنع تصوير الشاشة (Screenshot Block).

---

# User Problems

المستخدم الحالي يواجه:

1. **السمة (Theme):** لا يتغير عند اختيار الألوان الفاتحة أو الداكنة. الوضع الافتراضي داكن والتباين ضعيف جداً — علامات التحديد لا تكاد تُرى.
2. **صفحة المهام:** يوجد زران لإضافة مهمة — زر عائم (FAB) وزر في منتصف الصفحة. يجب حذف الزر الأوسط. أيضاً، المهام الموجودة في الكمبيوتر لا تُجلب للتطبيق — فقط زر الإنشاء.
3. **المرفقات:** زر المرفقات يعمل ويسمح باختيار ملف، لكن الملف لا يُرفع للسيرفر. الوكيل يستقبل فقط `[Attachment: filename (size)]` كنص ولا يقدر يقرأ محتوى الملف.
4. **نسخ الدردشة:** لا يستطيع المستخدم نسخ كامل رد الوكيل مرة واحدة — فقط فقرة فقرة.
5. **منع التصوير:** ميزة منع تصوير الشاشة (FLAG_SECURE) مزعجة وتحتاج إلغاء.

---

# Required Changes — Decomposed

## ISSUE 1 — Theme System (UX-01)
**Assignee:** flutter-ui-ux-designer
**Files:** `lib/core/theme/`, `lib/features/settings/presentation/settings_screen.dart`, `lib/features/settings/providers/settings_provider.dart`

### What:
- Fix light/dark theme toggle — currently selecting light mode doesn't apply
- Significantly improve dark mode contrast ratios:
  - Selection indicators (checkboxes, switches) — currently nearly invisible
  - Text/background contrast across all elements
  - Active/inactive states must be clearly distinguishable
- Review and rework `HermesColors` palette for WCAG AA compliance (4.5:1 minimum for text)
- Default theme stays dark, but must actually switch when user selects light

### Current State:
- `HermesColors.dark` used as hardcoded background in multiple screens instead of `theme.scaffoldBackgroundColor`
- ThemeMode setter exists in SettingsNotifier but may not propagate correctly

### UX Rules:
- Navy #001F5E + Cyan #32C2FF brand colors MUST be preserved
- Light theme: white/gray backgrounds with navy text/accents
- All interactive elements must have ≥3:1 contrast against their background
- Selection states must use high-visibility indicators

---

## ISSUE 2 — Tasks/Cron Jobs Page (UX-02 + BL-01)
**Assignee:** flutter-state-engineer
**Files:** `lib/features/tasks/presentation/task_list_screen.dart`, `lib/features/tasks/data/task_repository.dart`, `lib/features/tasks/providers/task_provider.dart`

### What:
- **Duplicate button:** Remove `FilledButton.icon` at `task_list_screen.dart:210-214` (inside `_buildEmptyState`). Keep ONLY the `FloatingActionButton.extended` at line 74.
- **Fetch existing jobs:** The app calls `GET /api/cron` (or equivalent) but either the endpoint is wrong or the response parsing fails. Jobs from the Hermes server are never displayed. Verify:
  - API endpoint path is correct: `GET /api/cron` → list all cron jobs
  - Response parsing: `CronJob.fromJson()` handles the actual API response shape
  - Provider flow: `refreshJobs()` → `TaskRepository.getAll()` → `TaskListState.jobs`

### Technical Notes:
- API endpoint: `GET /api/cron` (verify exact path with Hermes API server)
- Response shape needs verification — check what the Hermes `/api/cron` endpoint actually returns
- `TaskRepository.getAll()` currently uses `getDynamic()` for flexible extraction — may need hardening

---

## ISSUE 3 — File Upload to Server (BL-02 — CRITICAL)
**Assignee:** flutter-backend-db-architect + flutter-state-engineer
**Files:** `lib/features/chat/presentation/chat_screen.dart`, `lib/features/chat/data/chat_repository.dart`, `lib/features/chat/models/attached_file.dart`, `lib/features/chat/providers/chat_provider.dart`

### User-Reported Bug (from Hermes Agent):
> "BUG: Hermex Android — File Attachments Not Accessible by Agent. الـ agent يستقبل فقط reference نصي للملف [Attachment: فاتورة #270805683.pdf (53.1 KB)] — لكن الملف نفسه ما يكون متاح محليا. المسار الكامل ما يوصل للـ agent، فما يقدر يستخدم read_file أو أي أداة لفتح محتواه."

### What:
1. **Upload file to server FIRST** — before sending the chat message:
   - Use `POST /api/upload` (multipart/form-data) to upload the file bytes
   - Get back a file ID/reference from the server
2. **Send file reference in message** — include the server-returned file ID in the SSE message payload so the agent can access it
3. **Handle upload states:** progress, error, retry
4. **Size limits:** Enforce `SecurityLimits.maxFileAttachmentSize` on client side before upload

### Current State:
- `_handleAttach()` picks file via FilePicker correctly ✅
- `AttachedFile` model holds local path, name, size ✅
- BUT: file bytes are NEVER sent to server ❌
- `chat_repository.dart` sends message content with `attachedFile` metadata but no actual file upload

### Required Architecture:
```
User picks file → _handleAttach()
  → Upload file bytes to POST /api/upload (multipart)
  → Server returns { file_id: "abc123", url: "..." }
  → Include file_id in chat message payload
  → Agent can then read file via file_id
```

### Technical Notes:
- Upload endpoint: `POST /api/upload` (verify with Hermes API server — may be `/api/files/upload` or similar)
- Multipart form: field name `file`, binary content
- Response: `{ "id": "abc123", "name": "...", "size": 12345 }`
- The chat message SSE payload must include the uploaded file reference so the agent tools can access it
- Check if Hermes API server has an upload endpoint — if not, this is a BLOCKER that requires server-side work

---

## ISSUE 4 — Copy Entire Agent Response (UX-03)
**Assignee:** flutter-ui-ux-designer
**Files:** `lib/features/chat/presentation/message_bubble.dart`

### What:
- Long-press on agent bubble should copy the ENTIRE response, not just one paragraph
- Currently: `HermesMarkdown` (likely flutter_markdown) renders each paragraph as separate `SelectableText` blocks. Long-press on outer `GestureDetector` is intercepted by markdown's internal text selection
- Fix: Override markdown's selection behavior OR wrap in a copy button/header that copies `message.content` in full

### Current State (message_bubble.dart:25-47):
- `GestureDetector.onLongPress` copies `message.content` via `Clipboard.setData` ✅ (correct logic!)
- BUT: `_AgentBubble` at line 149 uses `HermesMarkdown(data: message.content)` which likely has its own `SelectableText` children that capture long-press
- The outer `GestureDetector` never receives the long-press because markdown's internal selectable text consumes it

### Fix Options:
A. Add a copy icon button in the agent bubble header
B. Set `selectable: false` on markdown and rely on outer GestureDetector
C. Wrap entire agent bubble in a `SelectionArea` with proper behavior

---

## ISSUE 5 — Remove Screenshot Prevention (UX-04)
**Assignee:** flutter-state-engineer
**Files:** `android/app/src/main/kotlin/.../MainActivity.kt`, possibly `android/app/src/main/AndroidManifest.xml`

### What:
- Remove any `FLAG_SECURE` or window flag that prevents screenshots
- Check:
  - `MainActivity.kt` for `window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)`
  - `AndroidManifest.xml` for any secure flag attributes
  - Flutter's `SystemChrome` calls in Dart code

### Why:
- User finds it frustrating — cannot screenshot for debugging/reference
- No security requirement for this app (personal AI assistant)

---

# Acceptance Criteria (Per-Issue)

## ISSUE 1 — Theme
- [ ] `flutter analyze` — 0 issues
- [ ] Theme toggle switches between light/dark correctly
- [ ] Dark mode: all selection indicators clearly visible
- [ ] Light mode: readable with proper contrast
- [ ] All screens follow theme (not hardcoded `HermesColors.dark`)

## ISSUE 2 — Tasks/Cron
- [ ] Only ONE "Add" button (FAB only, no center button in empty state)
- [ ] Existing cron jobs from server are fetched and displayed
- [ ] `refreshJobs()` populates the list from `GET /api/cron`

## ISSUE 3 — File Upload
- [ ] File is uploaded to server BEFORE message is sent
- [ ] Server returns a file reference ID
- [ ] File reference is included in the SSE chat message
- [ ] Agent tools can read the file content on the server side
- [ ] Upload progress indicator shown to user
- [ ] Error handling: upload failure shows clear error, doesn't block message send

## ISSUE 4 — Copy
- [ ] Long-press on agent bubble copies ENTIRE response text
- [ ] Or: visible copy button that copies full response
- [ ] SnackBar confirmation: "Copied to clipboard"

## ISSUE 5 — Screenshot
- [ ] `FLAG_SECURE` removed from all locations
- [ ] User can take screenshots of the app
- [ ] No security regression (none expected — personal app)

---

# Verification Scenarios

## Scenario 1 — Theme Toggle
Given: User is on Settings screen, dark mode active
When:  User selects "Light" theme
Then:  All screens switch to light backgrounds with dark text. Navigation bar, input bar, bubbles all update.

## Scenario 2 — Fetch Cron Jobs
Given: Hermes API server has 3 active cron jobs
When:  User opens Tasks tab
Then:  3 job cards are displayed with name, schedule, and status badges. Empty state is NOT shown.

## Scenario 3 — File Upload
Given: User taps attachment button and selects invoice.pdf (53KB)
When:  File is picked and upload completes
Then:  Upload progress is shown. Chat message is sent with file reference. Agent responds acknowledging it can read the file content.

## Scenario 4 — Copy Full Response
Given: Agent responded with a 5-paragraph answer
When:  User long-presses the agent bubble (or taps copy icon)
Then:  All 5 paragraphs are copied to clipboard. User pastes and sees complete text.

## Scenario 5 — Screenshot Allowed
Given: App is open on any screen
When:  User takes a screenshot (Power+Volume Down)
Then:  Screenshot is saved successfully. No "Can't take screenshot due to security policy" message.

---

# Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Hermes API server has no file upload endpoint | HIGH | Verify `/api/upload` or `/api/files` exists BEFORE coding. If not → BLOCK and report. |
| Theme propagation breaks existing hardcoded colors | MED | Audit all screens for `HermesColors.dark` and replace with `theme.scaffoldBackgroundColor` |
| Cron job API response shape differs from model | MED | Fetch actual API response first; update `CronJob.fromJson()` as needed |
| `flutter_markdown` doesn't support disabling internal selection | LOW | Fallback to copy icon button in agent bubble header |
| Removing FLAG_SECURE may have been intentional for security | LOW | Confirm with user: no security requirement for screenshot blocking |

---

# Product Principles
- User experience over premature security
- Dark theme first (default), light theme must work
- No dead UI elements — every button must work
- Files must be truly accessible by the agent, not just metadata
- Plan before code — architecture decisions documented in DEC format

---

# Completion Gate
Lead Architect MUST:
1. Decompose this task into 5 separate Kanban cards
2. Assign each to the correct specialist profile
3. Hold a planning session with all assigned experts before any code is written
4. Ensure each specialist creates a DEC (Decision Record) for their approach
5. Run full test suite (478 tests) after all changes
6. Mark this parent task complete with links to all 5 sub-tasks
