# 09 — Testing & Acceptance

## Test Layers
1. **Unit tests** — Providers, repositories, API parsing
2. **Widget tests** — UI components, screen states
3. **Integration tests** — Full flow (connect → chat → sessions)

## Coverage Targets
- Core API layer: 90%+
- Feature providers: 80%+
- UI widgets: 70%+

## Acceptance Criteria
Per feature, Gherkin format. See 01_prd.md for feature list.

## Test Data
- Mock API server responses for all endpoints
- SSE stream simulation

---

## Gherkin Acceptance Scenarios

### F-001: Server Connection

#### AC-F001-01: Connect with valid URL and API key

```
Scenario: User connects to a Hermes Agent API Server with valid credentials
  Given the user is on the "Connect to Server" screen
  When the user enters a valid server URL "http://192.168.1.100:8642"
  And the user enters a valid API key "sk-abc123..."
  And the user taps "Connect"
  Then a health check is sent to "GET /health"
  And the health check returns 200 OK
  And the server configuration is saved to encrypted local storage
  And the user is redirected to the Chat screen
  And the bottom navigation bar shows Chat, Sessions, Tasks, Workspace, Settings
```

#### AC-F001-02: Health check failure — invalid API key

```
Scenario: User attempts to connect with an invalid API key
  Given the user is on the "Connect to Server" screen
  When the user enters a valid server URL "http://192.168.1.100:8642"
  And the user enters an invalid API key "bad-key"
  And the user taps "Connect"
  Then the health check returns 401 Unauthorized
  And an error message "Authentication failed. Please check your API key." is displayed
  And the user remains on the "Connect to Server" screen
```

#### AC-F001-03: Connection failure — server unreachable

```
Scenario: User attempts to connect to an unreachable server
  Given the user is on the "Connect to Server" screen
  When the user enters an unreachable server URL "http://10.0.0.99:8642"
  And the user enters any API key
  And the user taps "Connect"
  Then the connection attempt times out after 10 seconds
  And an error message "Server unreachable. Check the URL and ensure Hermes Agent is running." is displayed
  And the user remains on the "Connect to Server" screen
```

#### AC-F001-04: Connection failure — SSL error on remote

```
Scenario: User attempts to connect to a remote server with invalid SSL certificate
  Given the user is on the "Connect to Server" screen
  When the user enters a remote HTTPS URL "https://my-server.example.com:8642"
  And the server has an invalid or self-signed SSL certificate
  And the user taps "Connect"
  Then a TLS handshake error occurs
  And an error message "Secure connection failed" is displayed
  And the user is offered an option to proceed with HTTP (insecure) if on local network
```

#### AC-F001-05: Create multiple server profiles

```
Scenario: User adds a second server profile
  Given the user is connected to "Home Server"
  When the user navigates to Settings > Server Management
  And the user taps "Add Server"
  And the user enters a new server URL "http://192.168.1.200:8642"
  And the user enters a valid API key
  And the user taps "Save"
  Then the new server profile "Server (2)" is saved
  And the server list shows both "Home Server" and "Server (2)"
```

#### AC-F001-06: Switch between server profiles

```
Scenario: User switches from one server profile to another
  Given the user has two server profiles: "Home Server" and "Work Server"
  And the user is currently connected to "Home Server"
  When the user navigates to Settings > Server Management
  And the user selects "Work Server"
  And the user taps "Switch to This Server"
  Then a health check is performed against "Work Server"
  And the active server changes to "Work Server"
  And all data screens refresh to reflect the new server's state
```

#### AC-F001-07: Remove a server profile

```
Scenario: User removes a non-default server profile
  Given the user has two server profiles
  And "Home Server" is set as the default
  When the user navigates to Settings > Server Management
  And the user swipes left on "Work Server" to delete
  And the user confirms deletion
  Then "Work Server" is removed from local storage
  And only "Home Server" remains in the server list
```

#### AC-F001-08: Empty URL validation

```
Scenario: User submits an empty server URL
  Given the user is on the "Connect to Server" screen
  When the user leaves the server URL field empty
  And the user enters any API key
  And the user taps "Connect"
  Then a validation error "Server URL is required" is displayed
  And no network request is made
```

#### AC-F001-09: Invalid URL format

```
Scenario: User enters a malformed server URL
  Given the user is on the "Connect to Server" screen
  When the user enters "not-a-valid-url" in the server URL field
  And the user taps "Connect"
  Then a validation error "Please enter a valid URL" is displayed
  And no network request is made
```

#### AC-F001-10: HTTP allowed on local network only

```
Scenario: User attempts HTTP connection to remote IP
  Given the user is on the "Connect to Server" screen
  When the user enters "http://203.0.113.1:8642" (non-private IP)
  And the user taps "Connect"
  Then a warning "HTTP is only allowed on local networks. Use HTTPS for remote servers." is displayed
  And the connection is blocked
```

#### AC-F001-11: Offline — no cached server config

```
Scenario: User opens app with no network and no server configuration cached
  Given the app is launched with no network connectivity
  And no server configuration is stored in local cache
  When the app finishes loading
  Then the "Connect to Server" screen is displayed
  And an offline message "No network connection. Connect to Wi-Fi or mobile data to continue." is shown
  And the Connect button is disabled
  When network connectivity is restored
  Then the offline message disappears
  And the Connect button becomes enabled
```

#### AC-F001-12: Offline — cached server exists, fallback mode

```
Scenario: User opens app with no network but has cached server config
  Given the app is launched with no network connectivity
  And a server configuration "Home Server" is cached in encrypted local storage
  When the app finishes loading
  Then an offline banner "You are offline — showing cached data" is displayed at the top of all screens
  And previously cached data from the last successful connection is displayed where available
  And all mutation actions (send message, create session, etc.) are disabled
  And a health check retry is queued to run automatically when connectivity returns
  When connectivity is restored
  Then the offline banner disappears
  And the app transitions to online mode without requiring manual reconnection
```

#### AC-F001-13: Loading state on connect

```
Scenario: User taps Connect and sees loading indicator during health check
  Given the user is on the "Connect to Server" screen
  When the user enters a valid server URL and API key
  And the user taps "Connect"
  Then the Connect button shows a loading spinner and becomes disabled
  And a label "Checking connection..." appears below the button
  And the URL and API key fields become non-editable
  When the health check completes (success or failure)
  Then the loading state resolves to either the Chat screen or an error message
```

#### AC-F001-14: URL trailing-slash normalization

```
Scenario: User enters server URL with trailing slash
  Given the user is on the "Connect to Server" screen
  When the user enters "http://192.168.1.100:8642/" with a trailing slash
  And the user taps "Connect"
  Then the URL is normalized to "http://192.168.1.100:8642" before the health check is sent
  And the health check proceeds with the normalized URL
```

---

### F-002: Chat (SSE Streaming)

#### AC-F002-01: Send message and receive streaming response

```
Scenario: User sends a chat message and receives a real-time streaming response
  Given the user is connected to a server
  And the user is on the Chat screen with an active session
  When the user types "Hello, what models do you support?"
  And the user taps the send button
  Then the user message appears as a right-aligned chat bubble with cyan tint
  And a loading indicator appears on the left side
  And text chunks begin streaming in as SSE text delta events
  And the response bubble updates in real-time as text arrives
  And when the stream ends, the loading indicator is replaced with a complete assistant response
  And the response is left-aligned on a surface-colored background
```

#### AC-F002-02: Markdown rendering — code blocks

```
Scenario: Agent response contains a code block
  Given the user is on the Chat screen
  When the user sends "Write a simple Flutter widget"
  And the agent response includes a code block surrounded by ```dart ... ```
  Then the code block is rendered with a dark background (#161B22)
  And the code is displayed in JetBrains Mono font
  And syntax highlighting is applied for Dart
  And the user can long-press the code block to copy its contents
```

#### AC-F002-03: Markdown rendering — tables and images

```
Scenario: Agent response contains markdown table and inline image
  Given the user is on the Chat screen
  When the agent response includes a markdown table
  Then the table is rendered with proper column alignment and row borders
  When the agent response includes an inline image ![alt](url)
  Then the image is loaded and displayed inline within the message
  And a loading placeholder is shown while the image loads
  And a broken-image placeholder is shown if the image fails to load
```

#### AC-F002-04: Model selection

```
Scenario: User selects a different model for chat
  Given the user is on the Chat screen
  When the user taps the model selector (showing current model name)
  Then a list of available models from "GET /v1/models" is displayed
  When the user selects "deepseek-v4-pro"
  Then the model selector updates to show "deepseek-v4-pro"
  And subsequent messages are sent using the selected model
```

#### AC-F002-05: Stop / interrupt running agent turn

```
Scenario: User interrupts a streaming response
  Given the user is on the Chat screen
  And the agent is currently streaming a long response
  When the user taps the stop button (appears in place of send button)
  Then the SSE connection is cancelled
  And the streaming stops immediately
  And the partial response so far remains visible with an indicator "(interrupted)"
  And the send button returns to its normal state
```

#### AC-F002-06: Tool progress visibility

```
Scenario: Agent invokes a tool during response generation
  Given the user is on the Chat screen
  When the agent begins a tool call (e.g., web_search)
  Then a tool progress indicator appears showing:
    - Tool name: "web_search"
    - Status: "Running..."
    - A spinner or progress animation
  When the tool call completes
  Then the indicator updates to show "web_search — Done"
  And the tool result is displayed (collapsible) within the conversation
```

#### AC-F002-07: File / image attachment

```
Scenario: User attaches an image to a chat message
  Given the user is on the Chat screen
  When the user taps the attachment button
  And the user selects an image from the device gallery
  Then a thumbnail preview of the image appears above the input field
  When the user types a message and taps send
  Then the message is sent with the image attachment
  And the image is displayed inline in the user's chat bubble
```

#### AC-F002-08: Send empty message — blocked

```
Scenario: User attempts to send an empty message
  Given the user is on the Chat screen
  When the user taps the send button with an empty input field and no attachment
  Then the send action is blocked
  And no network request is made
```

#### AC-F002-09: Streaming error — server disconnects mid-stream

```
Scenario: Server disconnects during streaming
  Given the user is on the Chat screen
  And a response is currently streaming
  When the server connection drops unexpectedly
  Then an error message "Connection lost. Tap to retry." is displayed
  And a retry button appears
  And the partial response so far remains visible with an error indicator
```

#### AC-F002-10: Chat history loads from session

```
Scenario: User opens an existing session and sees message history
  Given the user is on the Sessions screen
  When the user opens a session with 15 messages
  Then the Chat screen loads and displays all 15 messages in chronological order
  And the oldest messages are at the top (scrollable)
  And the input field is ready at the bottom for a new message
```

#### AC-F002-11: Offline — chat unavailable

```
Scenario: User opens Chat tab with no network connection
  Given the user was previously connected to a server with an active session
  And the device has no network connectivity
  When the user navigates to the Chat tab
  Then an offline banner "You are offline" is displayed at the top
  And previously loaded messages from cache are displayed (if any)
  And the message input field is disabled with hint text "Chat unavailable while offline"
  And the send button and attachment button are disabled
  And the model selector is disabled
  When connectivity is restored
  Then the offline banner disappears
  And the input field and all controls become enabled
```

#### AC-F002-12: Very large attachment rejected

```
Scenario: User attempts to attach a file exceeding the maximum size
  Given the user is on the Chat screen
  When the user taps the attachment button
  And the user selects a file larger than 50 MB
  Then an error message "File too large. Maximum size is 50 MB." is displayed
  And the file is not attached to the message
```

#### AC-F002-13: Rapid double-send prevented

```
Scenario: User rapidly taps send button twice
  Given the user is on the Chat screen
  And the user has typed a message "Hello"
  When the user rapidly taps the send button twice in quick succession
  Then only one message "Hello" is sent
  And the send button is disabled immediately after the first tap until the message is sent
  And no duplicate message appears
```

---

### F-003: Sessions

#### AC-F003-01: List sessions — populated

```
Scenario: User views list of existing sessions
  Given the user is connected to a server with 8 sessions
  When the user navigates to the Sessions tab
  Then 8 session cards are displayed
  And each card shows: session title, last activity time, message count, model name
  And sessions are sorted by last activity (newest first)
  And pinned sessions appear at the top regardless of last activity
```

#### AC-F003-02: List sessions — empty

```
Scenario: User opens sessions with no sessions on server
  Given the user is connected to a server with 0 sessions
  When the user navigates to the Sessions tab
  Then an empty state is displayed with a message "No sessions yet. Start chatting to create one."
  And a "New Chat" button is offered
```

#### AC-F003-03: Search sessions

```
Scenario: User searches for a session by title
  Given the user is on the Sessions screen with 12 sessions
  When the user types "api" in the search bar
  Then only sessions whose titles contain "api" (case-insensitive) are displayed
  And the search is performed on the client side (filtered from cached list)
  When the user clears the search bar
  Then all 12 sessions are displayed again
```

#### AC-F003-04: Create new session

```
Scenario: User creates a new chat session
  Given the user is on the Sessions screen
  When the user taps the "New Chat" FAB (cyan accent)
  Then a new session is created on the server
  And the user is navigated to the Chat screen for that new session
  And the session title defaults to "New Chat" (or untitled)
```

#### AC-F003-05: Rename session

```
Scenario: User renames an existing session
  Given the user is on the Sessions screen
  When the user long-presses a session card titled "New Chat"
  And the user selects "Rename"
  Then an inline text field appears with "New Chat" pre-filled
  When the user types "API Design Discussion" and confirms
  Then the session title updates to "API Design Discussion" on the server
  And the session card updates to show the new title
```

#### AC-F003-06: Delete session

```
Scenario: User deletes a session
  Given the user is on the Sessions screen
  When the user swipes left on a session card
  And the user taps the red "Delete" button
  And the user confirms deletion in the dialog
  Then the session is deleted on the server
  And the session card is removed from the list
```

#### AC-F003-07: Fork session

```
Scenario: User forks a session to create a branch
  Given the user is on the Sessions screen
  And a session "Debugging Session" exists with 20 messages
  When the user long-presses the session card
  And the user selects "Fork"
  Then a new session "Debugging Session (fork)" is created on the server
  And the new session contains a copy of all 20 messages from the original
  And the new session appears in the sessions list
```

#### AC-F003-08: Archive / unarchive session

```
Scenario: User archives a session
  Given the user is on the Sessions screen
  When the user long-presses a session card
  And the user selects "Archive"
  Then the session is marked as archived (isArchived = true) on the server
  And the session card is hidden from the default list
  And a filter/toggle "Show Archived" becomes available
  When the user taps "Show Archived" and unarchives the session
  Then the session reappears in the main list
```

#### AC-F003-09: Pin / unpin session

```
Scenario: User pins a session to the top
  Given the user is on the Sessions screen
  When the user long-presses a session card
  And the user selects "Pin"
  Then the session is marked as pinned (isPinned = true) on the server
  And the session card moves to the top of the list with a pin icon indicator
  When the user unpins the session
  Then the session returns to its normal position based on last activity
```

#### AC-F003-10: Session status indicators

```
Scenario: Session shows active/running status
  Given the user is on the Sessions screen
  When a session currently has a running agent turn
  Then that session card shows a pulsing green dot indicator
  And the status text shows "Active" or "Running"
  When the turn completes
  Then the indicator disappears
```

#### AC-F003-11: Session list error state

```
Scenario: Server returns an error when fetching sessions
  Given the user is on the Sessions screen
  When "GET /api/sessions" returns 500 Internal Server Error
  Then an error message "Failed to load sessions" is displayed
  And a "Retry" button is offered
  And previously cached sessions (if any) are still visible with a "cached" indicator
```

#### AC-F003-12: Offline — cached sessions visible, mutations disabled

```
Scenario: User opens Sessions tab with no network connection
  Given the user was previously connected to a server
  And the device has no network connectivity
  When the user navigates to the Sessions tab
  Then an offline banner "You are offline — showing cached sessions" is displayed
  And previously cached sessions are displayed (if any)
  And each cached session shows a "cached" indicator badge
  And the "New Chat" FAB is disabled
  And long-press actions (rename, delete, fork, archive, pin) are all disabled
  When connectivity is restored
  Then the offline banner disappears
  And the FAB and all actions become enabled
```

#### AC-F003-13: Delete last remaining session

```
Scenario: User deletes the only session on the server
  Given the user is on the Sessions screen with exactly 1 session "My Chat"
  When the user deletes that session
  Then the session is removed from the list and the server
  And the empty state "No sessions yet. Start chatting to create one." is displayed
  And the "New Chat" button is offered
```

#### AC-F003-14: Very long session title truncated in list

```
Scenario: Session with an extremely long title is displayed
  Given the user has a session with a title of 200 characters
  When the user views the Sessions list
  Then the session title is truncated to 80 characters with an ellipsis "…" appended
  And the full title is visible when viewing the session detail
```

---

### F-004: Tasks (Cron Jobs)

#### AC-F004-01: List cron jobs — populated

```
Scenario: User views list of scheduled cron jobs
  Given the user is connected to a server with 5 cron jobs
  When the user navigates to the Tasks tab
  Then 5 job cards are displayed
  And each card shows: prompt preview, schedule, status, last run time
  And jobs are sorted by next run time (soonest first)
```

#### AC-F004-02: List cron jobs — empty

```
Scenario: User opens tasks with no jobs on server
  Given the user is connected to a server with 0 cron jobs
  When the user navigates to the Tasks tab
  Then an empty state is displayed with "No scheduled tasks. Create one to automate your agent."
  And a "Create Task" FAB is offered
```

#### AC-F004-03: View job details

```
Scenario: User views full details of a cron job
  Given the user is on the Tasks screen
  When the user taps a job card for "Daily Briefing"
  Then a detail screen opens showing:
    - Full prompt text
    - Schedule expression (e.g., "0 9 * * *")
    - Human-readable schedule ("Every day at 9:00 AM")
    - Current status (active/paused)
    - Last run timestamp and result
    - Next scheduled run
    - Assigned skills list
    - Model provider and model name
```

#### AC-F004-04: Create cron job

```
Scenario: User creates a new cron job
  Given the user is on the Tasks screen
  When the user taps the "Create Task" FAB
  Then a form appears with fields: prompt, schedule, skills (optional), model (optional)
  When the user enters:
    - Prompt: "Summarize today's activity"
    - Schedule: "0 9 * * *"
    - Skills: news, summarizer
  And the user taps "Save"
  Then "POST /api/jobs" is called with the job data
  And on success, the new job appears in the tasks list
  And a success toast "Task created" is shown
```

#### AC-F004-05: Edit cron job

```
Scenario: User edits an existing cron job
  Given the user is viewing job details for "Daily Briefing"
  When the user taps "Edit"
  Then the job form is shown pre-filled with current values
  When the user changes the schedule to "0 8 * * *"
  And the user taps "Save"
  Then the job is updated on the server
  And the detail screen reflects the new schedule
```

#### AC-F004-06: Delete cron job

```
Scenario: User deletes a cron job
  Given the user is viewing job details for an old job
  When the user taps the "Delete" button
  And the user confirms deletion in the dialog
  Then the job is deleted from the server
  And the user is returned to the Tasks list
  And the deleted job no longer appears
```

#### AC-F004-07: Pause / resume job

```
Scenario: User pauses an active cron job
  Given the user is on the Tasks screen
  And a job "Hourly Check" is currently active (status: "active")
  When the user long-presses the job card
  And the user selects "Pause"
  Then the job status changes to "paused" on the server
  And the job card shows a paused indicator
  When the user long-presses again and selects "Resume"
  Then the job status changes back to "active"
```

#### AC-F004-08: Run job immediately

```
Scenario: User triggers an immediate run of a cron job
  Given the user is on the Tasks screen
  And a job "Daily Briefing" is scheduled for 9:00 AM
  When the user long-presses the job card
  And the user selects "Run Now"
  Then the job executes immediately on the server
  And a progress indicator appears on the job card
  When the run completes
  Then the "last run" timestamp updates
  And the job output becomes viewable
```

#### AC-F004-09: View job output

```
Scenario: User views the output of a completed job run
  Given the user is viewing job details for "Daily Briefing"
  And the job has a completed run
  When the user taps "View Last Output"
  Then the last run's output text is displayed in a scrollable view
  And the output is rendered as plain text (no markdown processing)
```

#### AC-F004-10: Create job — validation errors

```
Scenario: User submits an invalid cron job form
  Given the user is on the Create Task form
  When the user leaves the prompt field empty
  And the user enters an invalid schedule "every tuesday maybe"
  And the user taps "Save"
  Then a validation error "Prompt is required" is shown below the prompt field
  And a validation error "Invalid schedule format. Use cron syntax." is shown below the schedule field
  And no network request is made
```

#### AC-F004-11: Tasks error state

```
Scenario: Server returns an error when fetching cron jobs
  Given the user is on the Tasks screen
  When "GET /api/jobs" returns 500 Internal Server Error
  Then an error message "Failed to load tasks" is displayed
  And a "Retry" button is offered
```

#### AC-F004-12: Offline — cached tasks visible, mutations disabled

```
Scenario: User opens Tasks tab with no network connection
  Given the user was previously connected to a server
  And the device has no network connectivity
  When the user navigates to the Tasks tab
  Then an offline banner "You are offline — showing cached tasks" is displayed
  And previously cached jobs are displayed (if any)
  And each cached job shows a "cached" indicator badge
  And the "Create Task" FAB is disabled
  And all actions (edit, delete, pause, resume, run now, view output) are disabled
  When connectivity is restored
  Then the offline banner disappears
  And the FAB and all actions become enabled
```

#### AC-F004-13: Loading state on tasks list fetch

```
Scenario: User sees loading state while tasks are being fetched
  Given the user is connected to a server
  When the user navigates to the Tasks tab
  Then skeleton loading placeholders are shown for each expected job card (3-5 skeleton rows)
  And a loading spinner is visible at the center of the screen
  When the job data arrives from the server
  Then the skeleton placeholders are replaced with actual job cards
  And the loading spinner disappears
```

#### AC-F004-14: Run now on already-running job

```
Scenario: User triggers Run Now on a job that is currently executing
  Given the user is on the Tasks screen
  And a job "Data Sync" is currently running (status: "running")
  When the user long-presses the job card
  And the user selects "Run Now"
  Then a warning "This job is already running. Wait for it to complete." is displayed
  And no duplicate execution is triggered
```

---

### F-005: Skills Browser

#### AC-F005-01: List skills

```
Scenario: User views list of installed skills
  Given the user is connected to a server with 15 skills
  When the user navigates to Settings > Skills Browser
  Then 15 skill cards are displayed
  And each card shows: skill name, description, category badge, enabled/disabled toggle
  And skills are sorted alphabetically by name
```

#### AC-F005-02: Search skills

```
Scenario: User searches for a skill by name
  Given the user is on the Skills Browser screen with 15 skills
  When the user types "flutter" in the search bar
  Then only skills whose name or description contains "flutter" are displayed
  And the search is case-insensitive
  When the user clears the search bar
  Then all 15 skills are displayed again
```

#### AC-F005-03: Filter by category

```
Scenario: User filters skills by category
  Given the user is on the Skills Browser screen
  When the user selects the "Flutter" category chip
  Then only skills with category "flutter" are displayed
  When the user selects "All" category
  Then all skills are displayed again
```

#### AC-F005-04: View skill content

```
Scenario: User views the full content of a skill
  Given the user is on the Skills Browser screen
  When the user taps on a skill card "flutter-patterns"
  Then a detail screen opens showing:
    - Skill name and description
    - Full SKILL.md content (rendered as Markdown)
    - Category and other metadata
    - Enabled/disabled status
```

#### AC-F005-05: Toggle skill on/off

```
Scenario: User toggles a skill off
  Given the user is on the Skills Browser screen
  And a skill "news" is currently enabled
  When the user toggles the switch on the "news" skill card to off
  Then the skill is disabled on the server
  And the toggle shows the off state
  And a toast "news disabled" is shown
  When the user toggles it back on
  Then the skill is re-enabled on the server
```

#### AC-F005-06: Empty skills state

```
Scenario: No skills installed on server
  Given the user is connected to a server with 0 skills
  When the user navigates to the Skills Browser
  Then an empty state is displayed: "No skills installed"
```

#### AC-F005-07: Skills error state

```
Scenario: Server returns an error when fetching skills
  Given the user is on the Skills Browser screen
  When "GET /v1/skills" returns a network error
  Then an error message "Failed to load skills" is displayed
  And a "Retry" button is offered
```

#### AC-F005-08: Offline — cached skills visible

```
Scenario: User opens Skills Browser with no network connection
  Given the user was previously connected to a server
  And the device has no network connectivity
  When the user navigates to Settings > Skills Browser
  Then an offline banner "You are offline — showing cached skills" is displayed
  And previously cached skills are displayed (if any)
  And each cached skill shows a "cached" indicator badge
  And the enable/disable toggle on each skill is disabled
  And the search bar is disabled
  When connectivity is restored
  Then the offline banner disappears
  And the toggles and search become enabled
```

#### AC-F005-09: Loading state on skills list fetch

```
Scenario: User sees loading state while skills are being fetched
  Given the user is connected to a server
  When the user navigates to Settings > Skills Browser
  Then skeleton loading placeholders are shown for expected skill cards (5-8 skeleton rows)
  And a loading spinner is visible at the center of the screen
  When the skills data arrives from the server
  Then the skeleton placeholders are replaced with actual skill cards
  And the loading spinner disappears
```

---

### F-006: Workspace Browser

#### AC-F006-01: Directory listing — root

```
Scenario: User browses the workspace root directory
  Given the user is connected to a server
  When the user navigates to the Workspace tab
  Then the root directory contents are listed
  And each item shows: name, type icon (folder/file), size, modified date
  And folders are listed before files
  And items are sorted alphabetically within each group
```

#### AC-F006-02: Navigate into subdirectory

```
Scenario: User navigates into a subdirectory
  Given the user is on the Workspace screen viewing the root directory
  When the user taps on a folder "projects/"
  Then the view navigates into "projects/"
  And a breadcrumb path shows "root > projects"
  And the contents of "projects/" are listed
```

#### AC-F006-03: Navigate up to parent directory

```
Scenario: User navigates back to parent directory
  Given the user is viewing "root > projects > hermex_android"
  When the user taps the "Up" button or back button
  Then the view returns to "root > projects"
  And the contents of "projects" are listed
```

#### AC-F006-04: File content preview

```
Scenario: User previews a text file
  Given the user is viewing a directory containing "README.md"
  When the user taps on "README.md"
  Then a preview screen opens showing the file contents with syntax highlighting
  And the file content is displayed as read-only
  And large files show only the first 500 lines with a "Load more" option
```

#### AC-F006-05: Empty directory

```
Scenario: User views an empty directory
  Given the user navigates to an empty directory
  Then an empty state is displayed: "This directory is empty"
```

#### AC-F006-06: File metadata display

```
Scenario: User views file metadata
  Given the user is viewing a directory listing
  When the user long-presses a file "config.yaml"
  Then a bottom sheet appears showing metadata:
    - Full path
    - File size (human-readable, e.g., "2.3 KB")
    - Last modified date
    - Permissions (readable format)
```

#### AC-F006-07: Workspace error state

```
Scenario: Server returns an error when listing workspace directory
  Given the user is on the Workspace screen
  When the directory listing API returns an error
  Then an error message "Failed to load directory" is displayed
  And a "Retry" button is offered
```

#### AC-F006-08: Binary file preview blocked

```
Scenario: User attempts to preview a binary file
  Given the user is viewing a directory containing "app.apk"
  When the user taps on "app.apk"
  Then a message "Binary file — preview not available" is displayed
  And file metadata (size, modified date) is still shown
```

#### AC-F006-09: Offline — cached workspace visible

```
Scenario: User opens Workspace tab with no network connection
  Given the user was previously connected to a server
  And the device has no network connectivity
  When the user navigates to the Workspace tab
  Then an offline banner "You are offline — showing cached directory" is displayed
  And the previously cached directory listing is displayed (if any)
  And each item shows a "cached" indicator
  And tapping on folders or files is disabled
  When connectivity is restored
  Then the offline banner disappears
  And folder/file navigation becomes enabled
```

#### AC-F006-10: Loading state on directory listing fetch

```
Scenario: User sees loading state while workspace directory is being fetched
  Given the user is connected to a server
  When the user navigates to the Workspace tab
  Then skeleton loading placeholders are shown for expected items (5-8 rows)
  And a loading spinner is visible at the center of the screen
  When the directory data arrives from the server
  Then the skeleton placeholders are replaced with actual file/folder items
  And the loading spinner disappears
```

#### AC-F006-11: Large directory with 1000+ files — paginated

```
Scenario: User views a directory with over 1000 files
  Given the user navigates to a directory containing 1200 files
  When the directory listing loads
  Then only the first 100 files are displayed initially
  And a "Load more (1100 remaining)" button is shown at the bottom
  When the user taps "Load more"
  Then the next 100 files are appended to the list
  And the button updates to "Load more (1000 remaining)"
```

---

### F-007: Memory & Insights

#### AC-F007-01: Read-only memory view

```
Scenario: User views stored memory entries
  Given the user is connected to a server
  When the user navigates to Settings > Memory
  Then memory entries are displayed as read-only cards
  And each entry shows: key/type, content preview, last updated timestamp
  And entries cannot be edited or deleted
  And a "Read-only — manage memory on the server" indicator is shown
```

#### AC-F007-02: Stats dashboard — tokens

```
Scenario: User views token usage statistics
  Given the user is on the Insights screen
  When the user views the tokens section
  Then a summary card shows:
    - Total tokens used (lifetime)
    - Tokens used today
    - Tokens used this week
    - Average tokens per session
  And a simple bar chart or sparkline shows daily token usage for the past 7 days
```

#### AC-F007-03: Stats dashboard — sessions and active time

```
Scenario: User views session statistics
  Given the user is on the Insights screen
  When the user views the sessions section
  Then a summary card shows:
    - Total session count
    - Active sessions (this week)
    - Total active time across all sessions
    - Average session duration
```

#### AC-F007-04: Empty memory state

```
Scenario: No memory entries exist on server
  Given the user is connected to a server with 0 memory entries
  When the user navigates to Settings > Memory
  Then an empty state is displayed: "No memory entries stored"
```

#### AC-F007-05: Insights loading state

```
Scenario: Insights data is being fetched
  Given the user navigates to the Insights screen
  When the stats data is loading from the server
  Then skeleton loading placeholders are shown for each stat card
  And a loading spinner is visible
  When the data arrives
  Then the placeholders are replaced with actual values
```

#### AC-F007-06: Memory & insights error state

```
Scenario: Server returns an error when fetching memory or insights
  Given the user is on the Memory or Insights screen
  When the API call fails
  Then an error message "Failed to load data" is displayed
  And a "Retry" button is offered
```

#### AC-F007-07: Offline — cached memory and insights

```
Scenario: User opens Memory or Insights screen with no network connection
  Given the user was previously connected to a server
  And the device has no network connectivity
  When the user navigates to Settings > Memory or Settings > Insights
  Then an offline banner "You are offline — showing cached data" is displayed
  And previously cached memory entries or stats are displayed (if any)
  And each entry shows a "cached" indicator badge
  When connectivity is restored
  Then the offline banner disappears
  And fresh data is fetched from the server
```

---

### F-008: Settings

#### AC-F008-01: Server management — add server

```
Scenario: User adds a new server from Settings
  Given the user is on the Settings screen
  When the user taps "Server Management"
  And the user taps "Add Server"
  And the user enters a valid URL and API key
  And the user taps "Test Connection"
  Then a health check is performed
  And a success message "Connection successful" is shown
  When the user taps "Save"
  Then the new server is added to the server list
```

#### AC-F008-02: Server management — switch server

```
Scenario: User switches the active server
  Given the user is on the Server Management screen
  And "Home Server" is currently active (shown with a checkmark)
  When the user taps on "Work Server"
  Then a connection check is performed against "Work Server"
  And on success, "Work Server" becomes the active server
  And all data screens refresh
  And on failure, an error is shown and the active server does not change
```

#### AC-F008-03: Server management — remove server

```
Scenario: User removes a server profile
  Given the user is on the Server Management screen with 3 servers
  When the user swipes left on a server to delete
  And the user confirms
  Then the server is removed from local storage
  And if it was the active server, the default server becomes active
  And if it was the only server, the user is prompted to add a new one
```

#### AC-F008-04: Theme toggle

```
Scenario: User toggles between dark and light theme
  Given the user is on the Settings screen
  And the current theme is Dark (default)
  When the user taps the "Theme" toggle to Light
  Then the entire app switches to light theme:
    - Background: #F8F9FA
    - Surface: #FFFFFF
    - Chat bubbles update to light mode variants
  And the preference is persisted to SharedPreferences
  When the user toggles back to Dark
  Then the app returns to dark theme with navy #001F5E accents
```

#### AC-F008-05: Model preference

```
Scenario: User sets a default model preference
  Given the user is on the Settings screen
  When the user taps "Default Model"
  Then a list of available models from the server is displayed
  When the user selects "deepseek-v4-pro"
  Then the preference is saved
  And all new chat sessions default to this model
  And the model selector in Chat shows this as the pre-selected model
```

#### AC-F008-06: About / version info

```
Scenario: User views app version and information
  Given the user is on the Settings screen
  When the user taps "About"
  Then a screen displays:
    - App name: "Hermex Android"
    - Version: (from pubspec.yaml)
    - Build number
    - "Your server. Your phone. No middleman." tagline
    - Open-source license link
```

#### AC-F008-07: Settings — all screens accessible from Settings

```
Scenario: User navigates to all settings sub-screens
  Given the user is on the Settings screen
  Then the following menu items are available:
    - Server Management
    - Default Model
    - Theme
    - Skills Browser
    - Memory
    - Insights
    - About
```

#### AC-F008-08: Switch Hermes Agent profile (work ↔ personal on same server)

```
Scenario: User switches between Hermes Agent profiles on the same server
  Given the user is connected to a server with two Hermes Agent profiles: "work" and "personal"
  And the currently active profile is "work"
  When the user navigates to Settings
  And the user taps "Agent Profile"
  Then a list of available profiles on the server is displayed with "work" checked
  When the user selects "personal"
  Then the active profile switches to "personal"
  And the profile name is displayed in the Settings screen
  And all data screens refresh to reflect the "personal" profile's sessions, tasks, and memory
  And the profile preference is persisted locally for the current server
```

#### AC-F008-09: Profile switching — profile not found on server

```
Scenario: Saved profile preference no longer exists on server
  Given the user's local preference is set to profile "dev"
  And the server no longer has a profile named "dev"
  When the user connects to the server
  Then the app falls back to the server's default profile
  And a toast "Profile 'dev' not found. Using default profile." is shown
  And all data screens reflect the default profile
```

#### AC-F008-10: Offline — settings accessible, server-dependent options disabled

```
Scenario: User opens Settings with no network connection
  Given the user was previously connected to a server
  And the device has no network connectivity
  When the user navigates to the Settings tab
  Then all settings menu items are visible
  And server-dependent items (Server Management, Default Model, Agent Profile) show a "Requires connection" hint
  And local-only settings (Theme, About) remain fully functional
  And the current server name and profile are displayed from cache
```

#### AC-F008-11: About — license link opens browser

```
Scenario: User taps the open-source license link in About
  Given the user is on the Settings > About screen
  When the user taps the "MIT License" link
  Then the device's default browser opens to the Hermex Android license URL
  And the app remains in its current state (backgrounded, not closed)
```

---

## Coverage Summary

| Feature | Gherkin Scenarios | Key States Covered |
|---------|-------------------|-------------------|
| F-001 Server Connection | 14 | Success, Auth Fail, Unreachable, SSL Error, Multi-Profile, Validation, Security Policy, Offline (no cache), Offline (cached fallback), Loading, URL Normalization |
| F-002 Chat (SSE) | 13 | Streaming, Markdown, Model Select, Stop, Tool Progress, Attachment, Error, History, Offline, Large File Rejection, Double-Send Prevention |
| F-003 Sessions | 14 | List Empty/Populated, Search, CRUD, Fork, Archive, Pin, Status, Error, Offline, Last-Session Delete, Long-Title Truncation |
| F-004 Tasks/Cron | 14 | List Empty/Populated, CRUD, Pause/Resume, Run Now, Output, Validation, Error, Offline, Loading, Already-Running Guard |
| F-005 Skills Browser | 9 | List, Search, Filter, View, Toggle, Empty, Error, Offline, Loading |
| F-006 Workspace Browser | 11 | List, Navigate, Preview, Empty Dir, Metadata, Binary, Error, Offline, Loading, Pagination (1000+ files) |
| F-007 Memory & Insights | 7 | Memory View, Stats, Tokens, Sessions, Loading, Empty, Error, Offline |
| F-008 Settings | 11 | Server Mgmt, Theme, Model, About, Navigation, Add/Switch/Remove, Profile Switching (Hermes Agent profiles), Profile Fallback, Offline, License Link |
| **Total** | **93** | All five screen states (Loading, Empty, Error, Success, Offline) covered across all features |
