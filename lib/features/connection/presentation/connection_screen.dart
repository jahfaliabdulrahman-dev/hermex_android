import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/colors.dart';
import '../data/server_repository.dart';
import '../providers/connection_provider.dart';

/// First screen users see — connect to Hermes Agent API Server.
///
/// States handled:
/// - Idle: shows URL + API key inputs, connect button
/// - Connecting: shows spinner, disables inputs
/// - Error: shows error banner with retry
/// - Connected: auto-navigates to /chat
///
/// Edge cases handled:
/// - Invalid URL format → validation error
/// - Server unreachable → error state with retry
/// - Wrong API key → auth error
/// - Server returns non-200 → error
/// - URL with trailing slash → normalized before save
/// - Local network detection → hint shown
class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _labelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureApiKey = true;
  bool _hasAttemptedConnection = false;

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill from active server if one exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(connectionProvider);
      if (state.activeServer != null) {
        _urlController.text = state.activeServer!.url;
        _labelController.text = state.activeServer!.name;
      }
    });
  }

  // ─── URL Validation ───

  /// Validates the server URL against the same security rules as
  /// [ServerRepository._validateUrl]:
  /// 1. Not empty.
  /// 2. Parseable absolute URI with a host.
  /// 3. Must use http:// or https:// scheme.
  /// 4. No userinfo (prevents host injection like evil.com@host).
  /// 5. HTTP only on RFC 1918 private networks.
  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server URL is required.';
    }

    final trimmed = value.trim();

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority) {
      return AppStrings.invalidUrlNotAbsolute;
    }

    // RFC 3986: reject userinfo (host injection via @).
    if (uri.userInfo.isNotEmpty) {
      return AppStrings.invalidUrlHostInjection;
    }

    if (uri.host.isEmpty) {
      return AppStrings.invalidUrlNotAbsolute;
    }

    final scheme = uri.scheme;
    if (scheme != 'http' && scheme != 'https') {
      return AppStrings.invalidUrlNoScheme;
    }

    // HTTP only allowed on local/RFC 1918 networks.
    if (scheme == 'http' && !ServerRepository.isLocalNetwork(trimmed)) {
      return AppStrings.invalidUrlHttpRemote;
    }

    return null;
  }

  // ─── API Key Validation ───

  String? _validateApiKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API key is required.';
    }
    if (value.trim().length < 4) {
      return 'API key seems too short.';
    }
    return null;
  }

  // ─── Connect Action ───

  /// Handles the Connect button tap.
  ///
  /// Flow:
  /// 1. Validate form fields.
  /// 2. Unfocus keyboard.
  /// 3. If this server URL has never been connected before, show a
  ///    confirmation dialog asking "Is this your Hermes Agent server?"
  ///    with the full URL displayed.
  /// 4. On confirm (or if server is already known), proceed with
  ///    the health check and save.
  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final url = _urlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final label = _labelController.text.trim();

    // Normalize URL for comparison with stored servers.
    final normalizedUrl = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;

    // Check if this server is already known (has been connected before).
    final connectionState = ref.read(connectionProvider);
    final isNewServer =
        !connectionState.servers.any((s) => s.url == normalizedUrl);

    // Show confirmation dialog for first-time connections.
    if (isNewServer && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: HermesColors.surface,
          title: const Text(
            AppStrings.confirmServerTitle,
            style: TextStyle(color: HermesColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.confirmServerMessage,
                style: TextStyle(color: HermesColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HermesColors.dark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HermesColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.urlLabel,
                      style: TextStyle(
                        color: HermesColors.textDisabled,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      normalizedUrl,
                      style: const TextStyle(
                        color: HermesColors.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                AppStrings.cancel,
                style: TextStyle(color: HermesColors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: HermesColors.cyan,
                foregroundColor: HermesColors.dark,
              ),
              child: const Text(AppStrings.confirmConnect),
            ),
          ],
        ),
      );

      if (confirmed != true) return; // User cancelled the dialog.
    }

    _hasAttemptedConnection = true;

    final success = await ref.read(connectionProvider.notifier).connect(
          url: url,
          apiKey: apiKey,
          label: label,
        );

    if (success && mounted) {
      context.go(RoutePaths.chat);
    }
  }

  void _handleRetry() {
    ref.read(connectionProvider.notifier).clearError();
  }

  void _navigateToServers() {
    context.push(RoutePaths.servers);
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);
    final theme = Theme.of(context);

    // Auto-navigate to chat if connected and we just connected.
    ref.listen<ServerConnectionState>(connectionProvider, (prev, next) {
      if (next.status == ConnectionStatus.connected && _hasAttemptedConnection) {
        _hasAttemptedConnection = false;
        context.go(RoutePaths.chat);
      }
    });

    return Scaffold(
      backgroundColor: HermesColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.connectToHermes,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: HermesColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header ───
                _buildHeader(theme),

                const SizedBox(height: 32),

                // ─── URL Input ───
                _buildUrlField(theme, connectionState),

                const SizedBox(height: 20),

                // ─── API Key Input ───
                _buildApiKeyField(theme, connectionState),

                const SizedBox(height: 20),

                // ─── Label Input (optional) ───
                _buildLabelField(theme),

                const SizedBox(height: 12),

                // ─── Local Network Hint ───
                if (connectionState.isLocalNetwork) _buildLocalNetworkHint(theme),

                const SizedBox(height: 24),

                // ─── Error Message ───
                if (connectionState.status == ConnectionStatus.error)
                  _buildErrorBanner(connectionState, theme),

                const SizedBox(height: 24),

                // ─── Connect Button ───
                _buildConnectButton(theme, connectionState),

                const SizedBox(height: 16),

                // ─── Saved Servers Link ───
                _buildSavedServersLink(theme, connectionState),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widget Builders ───

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.cloud_outlined,
          size: 64,
          color: HermesColors.cyan.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.appTagline,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: HermesColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUrlField(ThemeData theme, ServerConnectionState state) {
    final isDisabled = state.status == ConnectionStatus.connecting || state.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.serverUrl,
          style: theme.textTheme.labelLarge?.copyWith(
            color: HermesColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _urlController,
          enabled: !isDisabled,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: TextStyle(color: HermesColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'http://192.168.1.100:8642',
            hintStyle: TextStyle(color: HermesColors.textDisabled),
            prefixIcon: Icon(
              Icons.dns_outlined,
              color: HermesColors.cyan,
            ),
            filled: true,
            fillColor: HermesColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.cyan, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.error),
            ),
          ),
          validator: _validateUrl,
        ),
      ],
    );
  }

  Widget _buildApiKeyField(ThemeData theme, ServerConnectionState state) {
    final isDisabled = state.status == ConnectionStatus.connecting || state.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.apiKey,
          style: theme.textTheme.labelLarge?.copyWith(
            color: HermesColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _apiKeyController,
          enabled: !isDisabled,
          obscureText: _obscureApiKey,
          autocorrect: false,
          style: TextStyle(color: HermesColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'sk-...',
            hintStyle: TextStyle(color: HermesColors.textDisabled),
            prefixIcon: Icon(
              Icons.vpn_key_outlined,
              color: HermesColors.cyan,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                color: HermesColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscureApiKey = !_obscureApiKey;
                });
              },
            ),
            filled: true,
            fillColor: HermesColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.cyan, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.error),
            ),
          ),
          validator: _validateApiKey,
        ),
      ],
    );
  }

  Widget _buildLabelField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.serverLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: HermesColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _labelController,
          keyboardType: TextInputType.text,
          autocorrect: false,
          style: TextStyle(color: HermesColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Home Server',
            hintStyle: TextStyle(color: HermesColors.textDisabled),
            prefixIcon: Icon(
              Icons.label_outline,
              color: HermesColors.cyan,
            ),
            filled: true,
            fillColor: HermesColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: HermesColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: HermesColors.cyan, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalNetworkHint(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HermesColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HermesColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: HermesColors.info, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Local network detected. HTTP is allowed on local networks.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: HermesColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ServerConnectionState state, ThemeData theme) {
    final isAuthError = state.errorMessage?.contains('Authentication') == true ||
        state.errorMessage?.contains('API_SERVER_KEY') == true ||
        state.errorMessage?.contains('401') == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HermesColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HermesColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: HermesColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorTitle(state.errorMessage, isAuthError),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: HermesColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: HermesColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _handleRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton(ThemeData theme, ServerConnectionState state) {
    final isConnecting = state.status == ConnectionStatus.connecting || state.isBusy;

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: isConnecting ? null : _handleConnect,
        icon: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: HermesColors.dark,
                ),
              )
            : const Icon(Icons.power_settings_new),
        label: Text(
          isConnecting ? AppStrings.connecting : AppStrings.connect,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: HermesColors.cyan,
          foregroundColor: HermesColors.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedServersLink(ThemeData theme, ServerConnectionState state) {
    final hasServers = state.servers.isNotEmpty;

    return TextButton.icon(
      onPressed: _navigateToServers,
      icon: Icon(
        Icons.storage_outlined,
        size: 18,
        color: hasServers ? HermesColors.cyan : HermesColors.textDisabled,
      ),
      label: Text(
        hasServers
            ? '${AppStrings.savedServers} (${state.servers.length})'
            : AppStrings.noSavedServers,
        style: TextStyle(
          color: hasServers ? HermesColors.cyan : HermesColors.textDisabled,
        ),
      ),
    );
  }

  // ─── Helpers ───

  String _errorTitle(String? message, bool isAuthError) {
    if (isAuthError) return AppStrings.authFailed;
    if (message == null) return AppStrings.connectionFailed;
    if (message.contains('timed out')) return AppStrings.timeout;
    if (message.contains('reach')) return AppStrings.serverUnreachable;
    return AppStrings.connectionFailed;
  }
}
