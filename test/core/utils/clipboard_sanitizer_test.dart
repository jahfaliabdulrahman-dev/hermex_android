import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/utils/clipboard_sanitizer.dart';

/// Tests for [ClipboardSanitizer] — AUD-CLIP-002.
void main() {
  group('ClipboardSanitizer — normal text passthrough', () {
    test('plain text passes through unchanged', () {
      const input = 'Hello, world!';
      expect(ClipboardSanitizer.sanitize(input), equals(input));
    });

    test('markdown text without URLs passes through', () {
      const input = '**bold** and *italic* text';
      expect(ClipboardSanitizer.sanitize(input), equals(input));
    });

    test('empty string returns empty', () {
      expect(ClipboardSanitizer.sanitize(''), equals(''));
    });

    test('whitespace-only returns unchanged', () {
      const input = '   \n  ';
      expect(ClipboardSanitizer.sanitize(input), equals(input));
    });
  });

  group('ClipboardSanitizer — API key redaction', () {
    test('sk- prefixed key is redacted', () {
      const input = 'My key is sk-abcdefghij1234567890 in the code';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, isNot(contains('sk-')));
      expect(output, contains('[API KEY REDACTED]'));
    });

    test('hk- prefixed key is redacted', () {
      const input = 'hk-abcdef1234567890abcdef1234567890abcdef12';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, isNot(contains('hk-')));
      expect(output, contains('[API KEY REDACTED]'));
    });

    test('api_key=VALUE is redacted', () {
      const input = 'Set api_key=abc123def456ghi789jkl';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[API KEY REDACTED]'));
      expect(output, isNot(contains('abc123def')));
    });

    test('SECRET=longvalue is redacted (case insensitive)', () {
      const input = 'export SECRET=superduperlongsecretvalue123';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[API KEY REDACTED]'));
    });

    test('TOKEN: longvalue is redacted', () {
      const input = 'Authorization: TOKEN: abcdef1234567890abcdef';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[API KEY REDACTED]'));
    });

    test('short value after key= is NOT falsely redacted', () {
      const input = 'The api_key=short should survive';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });

    test('sk- with too few chars is NOT redacted', () {
      const input = 'Prefix sk-abcde should pass';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });
  });

  group('ClipboardSanitizer — Bearer token redaction', () {
    test('Bearer token is redacted keeping "Bearer"', () {
      const input = 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.token.here';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('Bearer [REDACTED]'));
      expect(output, isNot(contains('eyJhbGci')));
    });

    test('Bearer with short token is redacted', () {
      const input = 'Header: Bearer abc123def456ghi78901';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('Bearer [REDACTED]'));
    });

    test('word "Bearer" without token is NOT affected', () {
      const input = 'The word Bearer appears alone';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });
  });

  group('ClipboardSanitizer — URL redaction', () {
    test('plain https URL is redacted', () {
      const input = 'Visit https://example.com/path?q=1 for more info';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[URL REDACTED]'));
      expect(output, isNot(contains('example.com')));
      expect(output, contains('Visit'));
      expect(output, contains('for more info'));
    });

    test('plain http URL is redacted', () {
      const input = 'Check http://server.local:8080/admin';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[URL REDACTED]'));
      expect(output, isNot(contains('http://')));
    });

    test('multiple URLs are each redacted', () {
      const input = 'URLs: https://a.com and https://b.com/path';
      final output = ClipboardSanitizer.sanitize(input);
      final matches = '[URL REDACTED]'.allMatches(output);
      expect(matches.length, equals(2));
    });
  });

  group('ClipboardSanitizer — Markdown link handling', () {
    test('markdown link label is preserved, URL is redacted', () {
      const input = 'Click [here](https://evil.com/malware) for details';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[here]'));
      expect(output, contains('([URL REDACTED])'));
      expect(output, isNot(contains('evil.com')));
      expect(output, isNot(contains('https://')));
    });

    test('markdown link with empty label', () {
      const input = 'See [](https://tracker.io/beacon) for more';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[]([URL REDACTED])'));
    });

    test('markdown link + plain URL both redacted', () {
      const input = 'Link [docs](https://docs.example.com) and https://other.com';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[docs]([URL REDACTED])'));
      final urlMatches = '[URL REDACTED]'.allMatches(output);
      expect(urlMatches.length, equals(2));
    });

    test('array bracket text not confused with markdown link', () {
      const input = 'Array access: arr[0] and function() is called';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });
  });

  group('ClipboardSanitizer — IP address redaction', () {
    test('IPv4 address is redacted', () {
      const input = 'Connect to address 10.20.30.40 for API';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[IP REDACTED]'));
      expect(output, isNot(contains('10.20.30.40')));
    });

    test('IP with port is redacted', () {
      const input = 'Server at 172.16.0.1:8443 is running';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[IP REDACTED]'));
      expect(output, isNot(contains('172.16.0.1')));
    });

    test('version-like v1.2.3.4 is NOT redacted', () {
      const input = 'Using version v1.2.3.4 of the library';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });
  });

  group('ClipboardSanitizer — long token redaction', () {
    test('40-char alphanumeric in quotes is redacted', () {
      const token = 'aB3dEfGhIjKlMnOpQrStUvWxYz0123456789abcd';
      expect(token.length, equals(40));
      final input = 'Token: "$token"';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[TOKEN REDACTED]'));
      expect(output, isNot(contains(token)));
    });

    test('54-char JWT-like token is redacted', () {
      const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0';
      expect(token.length, greaterThanOrEqualTo(40));
      final input = 'JWTs: $token end';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[TOKEN REDACTED]'));
    });

    test('39-char string is NOT redacted', () {
      const token = 'abcdefghijklmnopqrstuvwxyz0123456789abc';
      expect(token.length, equals(39));
      final input = 'Short: "$token"';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });

    test('embedded 40-char without delimiter NOT redacted', () {
      const embedded = 'Thisabcdefghijklmnopqrstuvwxyz0123456789abcdThat';
      final output = ClipboardSanitizer.sanitize(embedded);
      expect(output, equals(embedded));
    });

    test('normal sentence with 40+ chars NOT redacted', () {
      const input = 'This is a normal sentence with exactly forty char';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, equals(input));
    });
  });

  group('ClipboardSanitizer — combined scenarios', () {
    test('multiple sensitive patterns in one string', () {
      const input = 'API key sk-abcdefghij1234567890. '
          'Use Bearer eyJhbGciOiJIUzI1NiJ9.token at https://api.example.com/v1 '
          'via proxy 10.20.30.40:8080.';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, contains('[API KEY REDACTED]'));
      expect(output, contains('Bearer [REDACTED]'));
      expect(output, contains('[URL REDACTED]'));
      expect(output, contains('[IP REDACTED]'));
      expect(output, isNot(contains('sk-')));
      expect(output, isNot(contains('eyJhbGci')));
      expect(output, isNot(contains('api.example.com')));
      expect(output, isNot(contains('10.20.30.40')));
    });

    test('agent-like response with code blocks survives', () {
      const input = 'Here is how:\n\n'
          '```bash\n'
          'export API_KEY=sk-abcdefghij1234567890\n'
          '```\n\n'
          'Then call https://api.example.com/v1';
      final output = ClipboardSanitizer.sanitize(input);
      expect(output, isNot(contains('sk-abcdefghij')));
      expect(output, contains('[API KEY REDACTED]'));
      expect(output, isNot(contains('api.example.com')));
      expect(output, contains('[URL REDACTED]'));
      expect(output, contains('```'));
      expect(output, contains('export'));
    });
  });
}
