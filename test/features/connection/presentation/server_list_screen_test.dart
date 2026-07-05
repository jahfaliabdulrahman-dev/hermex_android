import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/features/connection/presentation/server_list_screen.dart';
import 'package:hermex_android/features/connection/providers/connection_provider.dart';
import 'package:hermex_android/models/server_config.dart';

/// Wraps a widget in ProviderScope and MaterialApp for testing.
Widget testableWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Test notifier that provides a pre-configured state.
class TestConnectionNotifier extends ConnectionNotifier {
  final List<ServerConfig> _servers;
  final ServerConfig? _active;

  TestConnectionNotifier(this._servers, this._active);

  @override
  ServerConnectionState build() {
    return ServerConnectionState(
      servers: _servers,
      status:
          _active != null ? ConnectionStatus.connected : ConnectionStatus.idle,
      activeServer: _active,
    );
  }
}

void main() {
  group('ServerListScreen — rendering', () {
    testWidgets('shows empty state when no servers', (tester) async {
      await tester.pumpWidget(testableWidget(const ServerListScreen()));

      // Should show empty state text
      expect(find.text('No saved servers'), findsOneWidget);
      expect(find.text('Add your first Hermes server'), findsOneWidget);
    });

    testWidgets('shows add server button in empty state', (tester) async {
      await tester.pumpWidget(testableWidget(const ServerListScreen()));

      expect(find.text('Add Server'), findsOneWidget);
    });

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(testableWidget(const ServerListScreen()));

      expect(find.text('Saved Servers'), findsOneWidget);
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(testableWidget(const ServerListScreen()));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('ServerListScreen — with servers', () {
    testWidgets('shows server cards when servers exist', (tester) async {
      final servers = [
        ServerConfig(
          id: '1',
          name: 'Test Server',
          url: 'http://192.168.1.100:8642',
          isDefault: true,
          createdAt: DateTime.now(),
          lastConnected: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionProvider.overrideWith(
              () => TestConnectionNotifier(servers, servers.first),
            ),
          ],
          child: const MaterialApp(
            home: ServerListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show server name
      expect(find.text('Test Server'), findsOneWidget);

      // Should show server URL
      expect(find.text('http://192.168.1.100:8642'), findsOneWidget);

      // Should show connected indicator
      expect(find.text('Connected'), findsOneWidget);
    });
  });
}
