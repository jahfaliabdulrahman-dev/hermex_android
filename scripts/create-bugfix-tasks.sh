#!/bin/bash
# Kanban task creation for BUG-001 and BUG-002
# Run: bash scripts/create-bugfix-tasks.sh
set -e

PROJECT="/Users/abdurrahmanjahfali/Projects/hermex_android"
cd "$PROJECT"

echo "=== Creating Bug Fix Kanban Tasks ==="

# BUG-001 tasks (Tailscale IP validation)
echo "--- BUG-001 tasks ---"

hermes kanban create \
  "BUG-001-P1: Verify isLocalNetwork Tailscale fix with full rebuild" \
  --assignee flutter-backend-db-architect \
  --body "BUG 1 — Verification Step

PROBLEM: Tailscale IP addresses (100.64.0.0/10 range) trigger 'HTTP is only allowed on local networks' error in ConnectionScreen.

ATTEMPTED FIX: Added _isTailscaleOrCGNAT() at server_repository.dart:375-388, called from isLocalNetwork() at line 352-353.

TASK:
1. Run 'flutter clean' (this is CRITICAL — static method changes need full rebuild)
2. Run 'flutter pub get'
3. Run 'flutter run' (NOT hot reload)
4. Enter a Tailscale IP (100.x.x.x:8642) in ConnectionScreen
5. Verify the Connect button works (no red error border)
6. Verify 'Local network detected' hint appears

KEY FILES:
- lib/features/connection/data/server_repository.dart:341-388 (isLocalNetwork + _isTailscaleOrCGNAT)
- lib/features/connection/presentation/connection_screen.dart:97 (calls ServerRepository.isLocalNetwork)

IF FIX STILL FAILS: Report exact error message. The duplicated _validateUrl methods (connection_screen.dart:70 and server_repository.dart:255) may be out of sync."

echo "  BUG-001-P1 created"

hermes kanban create \
  "BUG-001-P2: Add unit tests for Tailscale/CGNAT IP ranges" \
  --assignee flutter-qa-tester \
  --body "BUG 1 — Test Coverage

Add the following test cases to test/features/connection/data/server_repository_test.dart (in the 'local network detection' group around line 92):

1. Tailscale IP: http://100.64.0.1:8642 → should return true
2. Tailscale IP: http://100.100.100.100:8642 → should return true
3. Tailscale IP: http://100.127.255.255 → should return true
4. Non-Tailscale 100.x: http://100.63.255.255 → should return false (outside 100.64/10)
5. Non-Tailscale 100.x: http://100.128.0.1 → should return false (outside 100.64/10)

Also add to test/features/connection/providers/connection_provider_test.dart (around line 138):
- detectLocalNetwork('http://100.64.0.1:8642') → true
- detectLocalNetwork('http://100.127.255.255:8642') → true

Verify all 7 new tests pass. No code changes needed — just test additions."

echo "  BUG-001-P2 created"

hermes kanban create \
  "BUG-001-P3: Consolidate duplicated _validateUrl methods" \
  --assignee flutter-state-engineer \
  --body "BUG 1 — Code Quality Fix

TWO DUPLICATED _validateUrl methods exist:
- connection_screen.dart:70-102 (UI layer — form validator)
- server_repository.dart:255-297 (data layer — health check pre-validation)

Both check the same conditions and call the same isLocalNetwork(). This duplication means any fix must be applied TWICE and future drift is likely.

TASK:
1. Make ServerRepository._validateUrl() public: rename to validateUrl() and keep static
2. Have ConnectionScreen._validateUrl() delegate to ServerRepository.validateUrl()
3. Remove the duplicated logic from connection_screen.dart
4. Ensure form validation still shows correct error messages (AppStrings.invalidUrlHttpRemote, etc.)
5. Run existing tests to verify no regressions

CHANGED FILES:
- lib/features/connection/data/server_repository.dart (make _validateUrl public)
- lib/features/connection/presentation/connection_screen.dart (delegate, remove duplicate)"

echo "  BUG-001-P3 created"

hermes kanban create \
  "BUG-001-P4: Security audit of isLocalNetwork changes" \
  --assignee flutter-zero-trust-auditor \
  --body "BUG 1 — Security Review

Verify the isLocalNetwork() changes do not introduce security regressions:

1. Confirm 100.64.0.0/10 (Tailscale/CGNAT) is the only new range added
2. Verify non-local 100.x.x.x IPs (100.0.0.0-100.63.255.255 and 100.128.0.0-100.255.255.255) are still rejected for HTTP
3. Check that HTTPS enforcement for truly remote IPs remains intact
4. Verify network_security_config.xml (android/app/src/main/res/xml/) allows cleartext (LL-027)
5. Confirm no other IP ranges were accidentally affected

FILES TO AUDIT:
- lib/features/connection/data/server_repository.dart (isLocalNetwork, _isPrivate172, _isTailscaleOrCGNAT)
- lib/features/connection/presentation/connection_screen.dart (_validateUrl)
- android/app/src/main/res/xml/network_security_config.xml"

echo "  BUG-001-P4 created"

# BUG-002 tasks (Navigation dead-end)
echo "--- BUG-002 tasks ---"

hermes kanban create \
  "BUG-002-P1: Add disconnect/switch-server navigation path" \
  --assignee flutter-ui-ux-designer \
  --body "BUG 2 — Navigation UX Fix

PROBLEM: Once connected and navigated to /chat, there is NO way back to /connection to change servers. Only fix is clearing all app data.

ROOT CAUSE: GoRouter config at app_router.dart:37-40 puts /connection OUTSIDE the ShellRoute. All main screens (/chat, /sessions, etc.) are inside ShellRoute. No navigation path crosses this boundary.

TASK:
1. Add a 'Disconnect' or 'Switch Server' entry point. Options:
   - Option A: Add to Settings screen (Servers section) — a 'Switch Server' button that disconnects and navigates to /connection
   - Option B: Add to bottom nav as a reconnect action
   - Option C: Add to Settings danger zone as 'Disconnect & Exit'
2. Design the UI flow: confirm dialog → disconnect → navigate to /connection
3. Use existing AppStrings.switchServer and AppStrings.disconnectExit constants

KEY FILES:
- lib/core/router/app_router.dart (ShellRoute + /connection route)
- lib/features/settings/presentation/settings_screen.dart (add switch server button)
- lib/core/constants/app_strings.dart (lines 144, 154 — existing string constants)
- lib/features/connection/providers/connection_provider.dart (disconnect method at line 342)

DESIGN NOTE: ConnectionScreen already handles re-entry correctly via initState (line 49-58) which pre-fills from activeServer. The provider.listen at line 251 auto-navigates on connect, so return navigation must use context.go('/connection')."

echo "  BUG-002-P1 created"

hermes kanban create \
  "BUG-002-P2: Add GoRouter redirect guard for connection state" \
  --assignee flutter-state-engineer \
  --body "BUG 2 — Router Guard Fix

Add a GoRouter redirect that watches ConnectionStatus and navigates back to /connection when the user disconnects.

TASK:
1. In app_router.dart, add a redirect callback to the GoRouter constructor
2. Watch connectionProvider for ConnectionStatus.idle
3. When status transitions from connected→idle, redirect to RoutePaths.connection
4. Handle edge case: don't redirect if already on /connection (prevent loops)
5. Handle edge case: don't redirect if user is on a non-ShellRoute page (like /servers or /skills)

PSEUDO-CODE:
redirect: (context, state) {
  final connState = ref.read(connectionProvider);
  final location = state.uri.toString();
  if (connState.status == ConnectionStatus.idle && 
      location != RoutePaths.connection &&
      location.startsWith('/chat') || shellRoutePaths.contains(location)) {
    return RoutePaths.connection;
  }
  return null;
}

KEY FILES:
- lib/core/router/app_router.dart (add redirect)
- lib/features/connection/providers/connection_provider.dart (disconnect method)

NOTE: This must work with Riverpod — GoRouter can access providers via ProviderScope.containerOf(context)."

echo "  BUG-002-P2 created"

hermes kanban create \
  "BUG-002-P3: Ensure ConnectionScreen state is correct on re-entry" \
  --assignee flutter-state-engineer \
  --body "BUG 2 — State Integrity on Re-entry

When user disconnects and returns to /connection, verify the screen shows correct state:

1. URL/API key fields should be empty (or pre-filled from last used server)
2. 'Local network detected' hint should not appear (isLocalNetwork should be false)
3. Error state should be cleared
4. The auto-navigate listener (connection_screen.dart:251-256) should not fire spuriously

TASK:
1. Add a test: connect → disconnect → verify ConnectionScreen state is idle
2. Add a test: disconnect while on /chat → verify navigation to /connection
3. Verify existing tests for connection_screen_test.dart still pass

KEY FILES:
- lib/features/connection/presentation/connection_screen.dart (initState, listeners)
- lib/features/connection/providers/connection_provider.dart (disconnect at line 342)
- test/features/connection/presentation/connection_screen_test.dart"

echo "  BUG-002-P3 created"

hermes kanban create \
  "BUG-002-P4: Integration test — connect → disconnect → reconnect" \
  --assignee flutter-qa-tester \
  --body "BUG 2 — End-to-End Validation

Create an integration test that validates the full connect-disconnect-reconnect flow:

1. Start at /connection
2. Enter server URL + API key
3. Tap Connect → verify navigation to /chat
4. Navigate to Settings → tap Switch Server / Disconnect
5. Verify navigation back to /connection
6. Verify ConnectionScreen shows idle state (not error, not connected)
7. Enter different server URL → verify can connect to new server
8. Verify the old server is still in saved servers list

KEY FILES:
- test/ (add new integration test file)
- lib/core/router/app_router.dart (verify routes)
- lib/features/connection/presentation/connection_screen.dart

NOTE: This test validates both BUG-001 (Tailscale IP acceptance) and BUG-002 (navigation round-trip)."

echo "  BUG-002-P4 created"

echo ""
echo "=== All tasks created ==="
echo "Run: hermes kanban list to view all tasks"
