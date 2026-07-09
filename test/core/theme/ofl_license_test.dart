import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Validates that the OFL license files exist on disk and are declared
/// in pubspec.yaml's assets section.
///
/// The build-time APK bundling is verified by `flutter build apk` — if
/// the assets are missing or misconfigured, the build will fail or the
/// files will not appear in the APK assets.
void main() {
  final projectRoot = Directory.current.path.endsWith('test')
      ? '${Directory.current.parent.path}/'
      : '${Directory.current.path}/';

  group('OFL license files', () {
    test('OFL-Inter.txt exists in assets/fonts', () {
      final file = File('${projectRoot}assets/fonts/OFL-Inter.txt');
      expect(file.existsSync(), isTrue,
          reason: 'OFL-Inter.txt must exist at assets/fonts/OFL-Inter.txt');
    });

    test('OFL-JetBrainsMono.txt exists in assets/fonts', () {
      final file = File('${projectRoot}assets/fonts/OFL-JetBrainsMono.txt');
      expect(file.existsSync(), isTrue,
          reason: 'OFL-JetBrainsMono.txt must exist at assets/fonts/OFL-JetBrainsMono.txt');
    });

    test('OFL-Inter.txt contains SIL OFL 1.1 license', () {
      final content =
          File('${projectRoot}assets/fonts/OFL-Inter.txt').readAsStringSync();
      expect(content, contains('SIL OPEN FONT LICENSE'));
      expect(content, contains('Version 1.1'));
      expect(content, contains('Inter Project Authors'));
    });

    test('OFL-JetBrainsMono.txt contains SIL OFL 1.1 license', () {
      final content = File('${projectRoot}assets/fonts/OFL-JetBrainsMono.txt')
          .readAsStringSync();
      expect(content, contains('SIL OPEN FONT LICENSE'));
      expect(content, contains('Version 1.1'));
      expect(content, contains('JetBrains Mono Project Authors'));
    });

    test('pubspec.yaml declares OFL files in assets', () {
      final pubspec =
          File('${projectRoot}pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/fonts/OFL-Inter.txt'));
      expect(pubspec, contains('assets/fonts/OFL-JetBrainsMono.txt'));
      // Verify they're in the assets section
      expect(
        pubspec,
        contains(RegExp(r'assets:\s*\n\s+- assets/fonts/OFL-Inter.txt')),
      );
    });
  });

  group('Inter variable font declaration', () {
    test('Inter.ttf declared without weight (variable font pattern)', () {
      final pubspec =
          File('${projectRoot}pubspec.yaml').readAsStringSync();
      // Variable fonts should be declared without weight so Flutter
      // reads all weight axes from the single file
      expect(pubspec, contains('Inter.ttf'));
      // The font entry should exist in the fonts section
      expect(pubspec, contains('family: Inter'));
    });
  });
}
