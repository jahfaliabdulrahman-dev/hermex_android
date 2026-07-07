/// Centralized string constants for the entire application.
/// No hardcoded strings in widgets, controllers, or repositories.
abstract class AppStrings {
  AppStrings._();

  // ─── App ───
  static const appName = 'Hermex';
  static const appTagline = 'Your AI Agent, in your pocket';

  // ─── Connection ───
  static const connectToHermes = 'Connect to Hermes';
  static const serverUrl = 'Server URL';
  static const apiKey = 'API Key';
  static const serverLabel = 'Server Label (optional)';
  static const connect = 'Connect';
  static const connecting = 'Connecting…';
  static const continueToChat = 'Continue to Chat';
  static const connected = 'Connected';
  static const savedServers = 'Saved Servers';
  static const noSavedServers = 'No saved servers';
  static const addYourFirstServer = 'Add your first Hermes server';

  // ─── Server Validation (Security) ───
  static const invalidUrlHttpRemote =
      'HTTP is only allowed on local networks. Use HTTPS for remote servers.';
  static const invalidUrlHostInjection =
      'Invalid URL: user credentials in URL are not allowed.';
  static const invalidUrlNotAbsolute =
      'Invalid URL format. Please enter a valid server address.';
  static const invalidUrlNoScheme =
      'Server URL must start with http:// or https://.';

  // ─── First-Connect Confirmation ───
  static const confirmServerTitle = 'Confirm Server';
  static const confirmServerMessage =
      'Is this your Hermes Agent server?';
  static const confirmConnect = 'Yes, Connect';
  static const urlLabel = 'URL';

  // ─── Errors ───
  static const connectionFailed = 'Connection failed';
  static const serverUnreachable =
      'Server unreachable. Check the URL and ensure Hermes Agent is running.';
  static const authFailed =
      'Authentication failed. Please check your API key.';
  static const sslError =
      'Secure connection failed. The server may have an invalid certificate.';
  static const timeout = 'Connection timed out';
  static const failedToLoadSessions = 'Failed to load sessions';
  static const failedToLoadJobs = 'Failed to load jobs';
  static const failedToLoadSkills = 'Failed to load skills';
  static const failedToLoadMemory = 'Failed to load memory';
  static const failedToLoadInsights = 'Failed to load insights';
  static const failedToLoadServerInfo = 'Failed to load server info';
  static const failedToSendMessage = 'Failed to send message';
  static const sessionNotFound = 'Session not found or deleted';
  static const jobNotFound = 'Job not found or deleted';

  // ─── Offline ───
  static const offlineBanner = 'No network connection';
  static const offlineReadOnly = 'Offline — read only';
  static const offlineCachedData = 'Offline — showing cached data';
  static const offlineConnectToSend = 'Offline — connect to send';
  static const offlineSkillsCantModify = 'Offline — cannot modify skills';
  static const offlineWorkspaceUnavailable = 'Offline — workspace unavailable';

  // ─── Chat ───
  static const startConversation = 'Start a conversation';
  static const askAnything = 'Ask anything — your agent is ready.';
  static const typeMessage = 'Type a message…';
  static const connectionLostReconnecting = 'Connection lost — reconnecting…';
  static const modelSelectorHint = 'Select model';

  // ─── Sessions ───
  static const sessions = 'Sessions';
  static const noSessionsYet = 'No sessions yet';
  static const startChatForFirstSession =
      'Start a chat to create your first session.';
  static const searchSessions = 'Search sessions...';
  static const openChat = 'Open Chat';
  static const rename = 'Rename';
  static const pin = 'Pin';
  static const archive = 'Archive';
  static const fork = 'Fork';
  static const deleteSession = 'Delete Session';
  static const deleteSessionConfirm =
      'Are you sure you want to delete this session? This cannot be undone.';

  // ─── Tasks / Cron ───
  static const cronJobs = 'Cron Jobs';
  static const noCronJobs = 'No cron jobs';
  static const createFirstCronJob = 'Create your first scheduled task.';
  static const runNow = 'Run Now';
  static const pause = 'Pause';
  static const resume = 'Resume';
  static const editJob = 'Edit Job';
  static const deleteJob = 'Delete Job';
  static const deleteJobConfirm =
      'Are you sure you want to delete this job? This cannot be undone.';
  static const createJob = 'Create Job';
  static const jobDetails = 'Job Details';
  static const schedule = 'Schedule';
  static const lastRun = 'Last Run';
  static const nextRun = 'Next Run';
  static const deliverTarget = 'Deliver';
  static const prompt = 'Prompt';
  static const runHistory = 'Run History';

  // ─── Skills ───
  static const skills = 'Skills';
  static const noSkillsInstalled = 'No skills installed';
  static const installSkillsOnServer =
      'Install skills on your Hermes server to see them here.';
  static const searchSkills = 'Search skills...';
  static const skillsSubtitle = 'View and manage agent skills';
  // ─── Skills error diagnostics (BUG-5) ───
  static const skillAuthErrorTitle = 'API Key Invalid';
  static const skillAuthErrorMessage =
      'The stored API key was rejected. You may have entered the wrong '
      'key type. Use API_SERVER_KEY from ~/.hermes/.env.';
  static const skillNetworkErrorTitle = 'Cannot Reach Server';
  static const skillNetworkErrorMessage =
      'Could not connect to the server. Check your network connection '
      'and server status.';
  static const skillLoadErrorTitle = 'Failed to Load Skills';
  static const reconnectWithCorrectApiKey = 'Reconnect with Correct API Key';

  // ─── Workspace ───
  static const workspace = 'Workspace';
  static const emptyDirectory = 'This directory is empty.';
  static const failedToLoadDirectory = 'Failed to load directory';
  static const cannotPreviewFileType = 'Cannot preview this file type';

  // ─── Memory ───
  static const memory = 'Memory';
  static const noMemoriesStored = 'No memories stored';
  static const agentLearnsOverTime =
      'The agent will save facts as it learns about you.';
  static const memorySubtitle = 'Browse persistent agent memory';
  static const memoryRequiresDashboard =
      'Memory requires the Hermes Workspace dashboard (port 9119).\n'
      'Start the dashboard to access persistent agent memory.';

  // ─── Insights ───
  static const insights = 'Insights';
  static const noInsightsAvailable = 'No insights available yet';
  static const startUsingAgentForData =
      'Start using the agent to generate data.';
  static const lastSynced = 'Last synced';
  static const insightsSubtitle = 'Usage analytics and insights';
  static const insightsRequiresDashboard =
      'Insights requires the Hermes Workspace dashboard (port 9119).\n'
      'Start the dashboard to access usage analytics.';

  // ─── Settings ───
  static const settings = 'Settings';
  static const server = 'Server';
  static const agent = 'Agent';
  static const preferences = 'Preferences';
  static const about = 'About';
  static const switchServer = 'Switch Server';
  static const addServer = 'Add Server';
  static const defaultModel = 'Default Model';
  static const theme = 'Theme';
  static const dark = 'Dark';
  static const light = 'Light';
  static const system = 'System';
  static const version = 'Version';
  static const hermesAgentVersion = 'Hermes Agent';
  static const license = 'License';
  static const disconnectExit = 'Disconnect & Exit';
  static const noServerConnected = 'Not connected';
  static const activeServerLabel = 'Active Server';

  // ─── Settings Danger Zone (BUG-006) ───
  static const settingsDangerZoneDeleteTitle = 'Delete All Data?';
  static const settingsDangerZoneDeleteMessage =
      'This will permanently remove all server configurations, '
      'API keys, preferences, and cached data. This action cannot be undone.';
  static const settingsDangerZoneDeleteAction = 'Delete Everything';
  static const settingsDangerZoneResetTitle = 'Reset Preferences?';
  static const settingsDangerZoneResetMessage =
      'This will reset theme, default model, and other preferences '
      'to their defaults. Server configurations will be kept.';
  static const settingsDangerZoneResetAction = 'Reset';
  static const settingsDangerZoneDisconnectTitle = 'Disconnect from Server?';
  static const settingsDangerZoneDisconnectMessage =
      'You will be returned to the connection screen. '
      'Your saved server configurations will be kept.';
  static const settingsDangerZoneDisconnectAction = 'Disconnect';

  // ─── Generic ───
  static const retry = 'Retry';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const copy = 'Copy';
  static const close = 'Close';
  static const search = 'Search';
  static const back = 'Back';
  static const goBack = 'Go Back';
  static const ok = 'OK';
  static const yes = 'Yes';
  static const no = 'No';
  static const confirm = 'Confirm';
  static const loading = 'Loading…';
  static const refreshing = 'Refreshing…';
}
