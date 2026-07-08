# MOC Plans — Complex Fixes (Pseudocode)
# hermex_android | 2026-07-08

## MOC-1: API Key Validation + Connection Health Check

**Affected bugs:** BUG-1, BUG-2, BUG-5-Skills  
**Assignee:** flutter-state-engineer  
**Review:** flutter-backend-db-architect (data flow), flutter-zero-trust-auditor (security)

```pseudocode
// FILE: lib/features/connection/providers/connection_provider.dart
// Add to ConnectNotifier:

FUNCTION connectWithHealthCheck(url, apiKey, label):
  // Phase 0: Basic validation
  IF url is empty OR apiKey is empty:
    state.error = "URL and API Key required"
    return
  
  // Phase 1: Connection attempt
  tempClient = ApiClient(baseUrl: url, apiKey: apiKey)
  healthResult = TRY tempClient.healthCheck()
  
  IF healthResult is Failure:
    // Phase 1a: Diagnose 401 separately
    IF healthResult.statusCode == 401:
      state.error = "Authentication failed. Use API_SERVER_KEY from ~/.hermes/.env"
      state.errorAction = "Check API key type"
    ELSE:
      state.error = "Server unreachable: $healthResult"
    return
  
  // Phase 2: Capabilities probe (DISCOVER what endpoints exist)
  capabilities = PROBE:
    - GET /v1/models → {available: bool, models: [...]}
    - GET /v1/skills → {available: bool}  
    - GET /v1/memory → {available: bool}     // ← NEW: probe for existence
    - GET /v1/insights → {available: bool}    // ← NEW: probe for existence
    - GET /v1/workspace → {available: bool}   // ← NEW: probe for existence
  
  // Phase 3: Save connection with capabilities
  serverConfig = ServerConfig(
    id: generateId(),
    url: url,
    label: label,
    capabilities: capabilities,  // ← NEW FIELD
  )
  saveToSecureStorage(serverConfig)
  saveApiKey(serverConfig.id, apiKey)
  
  // Phase 4: Transition to connected
  state.status = connected
  state.activeServer = serverConfig
```

```pseudocode
// FILE: lib/core/providers/api_client_provider.dart
// Add: capabilities provider for feature-gating

FINAL capabilitiesProvider = FutureProvider<ServerCapabilities>:
  apiClient = await resolvedApiClientProvider.future
  IF apiClient IS NULL: return ServerCapabilities.none()
  
  // Parallel probe (fast — all fire simultaneously)
  results = await Future.wait([
    probeEndpoint(apiClient, '/v1/models'),
    probeEndpoint(apiClient, '/v1/skills'),
    probeEndpoint(apiClient, '/v1/memory'),
    probeEndpoint(apiClient, '/v1/insights'),
    probeEndpoint(apiClient, '/v1/workspace'),
  ])
  
  return ServerCapabilities(
    modelsAvailable: results[0] == 200,
    skillsAvailable: results[1] == 200,
    memoryAvailable: results[2] == 200,    // ← Will be false on v0.18.0
    insightsAvailable: results[3] == 200,  // ← Will be false on v0.18.0
    workspaceAvailable: results[4] == 200, // ← Will be false on v0.18.0
  )

FUNCTION probeEndpoint(apiClient, path):
  TRY:
    response = await apiClient.dio.get(path)
    return response.statusCode
  CATCH (DioException e):
    return e.response?.statusCode ?? 0
```

---

## MOC-2: Feature-Gating for Missing Endpoints

**Affected bugs:** BUG-3, BUG-5-Memory, BUG-5-Insights  
**Assignee:** flutter-backend-db-architect  
**Review:** flutter-product-steward (UX decision)

```pseudocode
// FILE: lib/features/settings/presentation/settings_screen.dart
// Change Agent Data section to be capability-aware:

WIDGET _buildAgentDataSection(context, theme):
  capabilities = ref.watch(capabilitiesProvider).valueOrNull
  
  items = []
  
  // Skills — always show (endpoint EXISTS)
  items.add(ListTile(
    title: "Skills",
    subtitle: "View and manage agent skills",
    onTap: () => context.push(RoutePaths.skills),
  ))
  
  // Memory — show only if available, else show "needs dashboard" notice
  IF capabilities?.memoryAvailable == true:
    items.add(ListTile(
      title: "Memory",
      subtitle: "Browse persistent agent memory",
      onTap: () => context.push(RoutePaths.memory),
    ))
  ELSE:
    items.add(ListTile(
      title: "Memory",
      subtitle: "Requires Hermes Workspace dashboard",
      enabled: false,
      trailing: Icon(Icons.lock_outline),
      onTap: () => showDashboardInfoDialog(context),
    ))
  
  // Insights — same pattern as Memory
  IF capabilities?.insightsAvailable == true:
    items.add(ListTile(...))
  ELSE:
    items.add(ListTile(
      title: "Insights", 
      subtitle: "Requires Hermes Workspace dashboard",
      enabled: false,
      onTap: () => showDashboardInfoDialog(context),
    ))
  
  return Card(children: items)
```

```pseudocode
// FILE: lib/core/router/app_router.dart  
// Add route guard for unavailable features:

FUNCTION _redirectGuard(context, state):
  capabilities = container.read(capabilitiesProvider).valueOrNull
  
  location = state.uri.toString()
  
  // Prevent navigation to features that don't exist on this gateway
  IF location == '/memory' AND capabilities?.memoryAvailable != true:
    showSnackBar("Memory requires Hermes Workspace dashboard")
    return previousLocation  // Stay on current page
  
  IF location == '/insights' AND capabilities?.insightsAvailable != true:
    showSnackBar("Insights requires Hermes Workspace dashboard")
    return previousLocation
  
  IF location == '/workspace' AND capabilities?.workspaceAvailable != true:
    showSnackBar("Workspace requires Hermes Workspace dashboard")
    return previousLocation
  
  return null  // Allow navigation
```

---

## MOC-3: Model Selector Recovery UX

**Affected bugs:** BUG-1  
**Assignee:** flutter-state-engineer  
**Review:** flutter-ui-ux-designer

```pseudocode
// FILE: lib/features/chat/presentation/chat_input.dart
// Change _ModelButton to ALWAYS respond:

CLASS _ModelButton:
  BUILD:
    // ALWAYS show tappable button — never dead
    hasModels = models.isNotEmpty
    hasSelectedModel = selectedModelId != null
    
    return Material(
      child: InkWell(
        onTap: () => handleModelTap(context),  // ← ALWAYS tappable
        child: Container(
          child: Row([
            Icon(Icons.psychology_outlined),
            Text(displayName),  // "Select model" or model name
            Icon(hasModels ? Icons.arrow_drop_down : Icons.refresh),
          ])
        )
      )
    )
  
  FUNCTION handleModelTap(context):
    IF models.isNotEmpty:
      // Normal flow: show model picker
      ModelSelector.show(context, models: models, ...)
    ELSE:
      // Recovery flow: show diagnostic bottom sheet
      showModalBottomSheet(
        context: context,
        builder: (_) => ModelDiagnosticSheet(
          onRetry: onRetryLoadModels,
          onManualInput: onManualModelInput,
        )
      )
```

```pseudocode
// FILE: lib/features/chat/presentation/model_diagnostic_sheet.dart
// NEW WIDGET: Recovery bottom sheet when models fail to load

CLASS ModelDiagnosticSheet:
  BUILD:
    return Column([
      Icon(Icons.cloud_off, color: error),
      Text("Couldn't load models"),
      Text("Possible causes:"),
      Text("• Wrong API key (use API_SERVER_KEY)"),
      Text("• Server not running"),
      Text("• Network issue"),
      
      SizedBox(height: 16),
      
      // Manual model input as fallback
      TextField(
        hintText: "Model name (e.g., deepseek-v4-pro)",
        onSubmitted: (name) {
          onManualInput(name);
          Navigator.pop();
        }
      ),
      
      // Retry button
      OutlinedButton(
        onPressed: () {
          onRetry();
          Navigator.pop();
        },
        child: Text("Retry"),
      ),
      
      // Reconnect button
      FilledButton(
        onPressed: () {
          Navigator.pop();
          context.push(RoutePaths.connection);
        },
        child: Text("Reconnect to Server"),
      ),
    ])
```

---

## MOC-4: Dynamic Profile Name

**Affected bugs:** BUG-4  
**Assignee:** flutter-state-engineer

```pseudocode
// FILE: lib/features/settings/presentation/settings_screen.dart
// Replace hardcoded 'flutter-state-engineer' with:

WIDGET _buildProfileSection(theme):
  connectionState = ref.watch(connectionProvider)
  activeServer = connectionState.activeServer
  
  profileName = activeServer?.label ?? activeServer?.url ?? "Not connected"
  profileSubtitle = activeServer != null 
    ? "Connected to ${activeServer.url}"
    : "No server connected"
  
  return Card(
    child: ListTile(
      leading: CircleAvatar(child: Icon(Icons.person)),
      title: Text(profileName),          // ← DYNAMIC, not hardcoded
      subtitle: Text(profileSubtitle),
    )
  )
```

---

## MOC-5: Dialog Text Visibility Fix

**Affected bugs:** BUG-6  
**Assignee:** flutter-ui-ux-designer

```pseudocode
// FILE: lib/core/theme/app_theme.dart
// Fix DialogThemeData:

dialogTheme: DialogThemeData(
  backgroundColor: HermesColors.surface,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  // ADD THESE:
  titleTextStyle: HermesTextTheme.buildTextTheme().headlineSmall?.copyWith(
    color: HermesColors.textPrimary,
  ),
  contentTextStyle: HermesTextTheme.buildTextTheme().bodyMedium?.copyWith(
    color: HermesColors.textSecondary,
  ),
)
```

```pseudocode
// FILE: lib/features/settings/presentation/settings_screen.dart
// Fix all three dialogs to use explicit colors:

FUNCTION _showDeleteConfirmation(context, ref):
  showDialog(
    builder: (ctx) => AlertDialog(
      backgroundColor: HermesColors.surface,
      title: Text(                          // ← REMOVE const
        'Delete All Data?',
        style: TextStyle(                   // ← EXPLICIT color
          color: HermesColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(                        // ← REMOVE const
        'This will permanently remove...',
        style: TextStyle(                   // ← EXPLICIT color
          color: HermesColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(),
          child: Text('Cancel',
            style: TextStyle(color: HermesColors.cyan),  // ← EXPLICIT
          ),
        ),
        FilledButton(
          onPressed: () { Navigator.pop(); deleteData(); },
          style: FilledButton.styleFrom(
            backgroundColor: HermesColors.error,
            foregroundColor: HermesColors.white,  // ← ADD explicit foreground
          ),
          child: Text('Delete Everything'),
        ),
      ],
    ),
  )
```

---

## Verification Checklist

After all fixes:

```bash
# 1. Auth test
flutter test test/features/connection/ --name "health check"

# 2. Model selector test  
flutter test test/features/chat/ --name "model selector"

# 3. Feature gate test
flutter test test/core/providers/ --name "capabilities"

# 4. Full suite
flutter test && flutter analyze

# 5. Device test (Samsung)
flutter run --release
# → Verify: Chat works, Sessions load, Skills load, Memory/Insights show dashboard notice
# → Verify: Danger Zone dialogs readable, Profile shows correct name
```
