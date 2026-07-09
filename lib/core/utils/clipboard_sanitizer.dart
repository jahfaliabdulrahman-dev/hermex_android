/// Sanitizes text before copying to system clipboard.
///
/// Redacts sensitive patterns that could leak via Android/iOS system clipboard:
/// - API keys (sk-…, hk-…, etc.)
/// - Bearer / authorization tokens
/// - URLs (http://, https://)
/// - IP addresses with optional ports
/// - Long token-like strings (40+ chars of base64/JWT-like characters)
///
/// Markdown link text is preserved while the URL target is redacted.
///
/// [AUD-CLIP-002] — unfiltered clipboard copy vector.
class ClipboardSanitizer {
  ClipboardSanitizer._();

  /// Returns a sanitized version of [text] safe for system clipboard copy.
  static String sanitize(String text) {
    var result = text;
    result = _redactMarkdownLinks(result);
    result = _redactPlainUrls(result);
    result = _redactApiKeys(result);
    result = _redactBearerTokens(result);
    result = _redactIpAddresses(result);
    result = _redactLongTokens(result);
    return result;
  }

  // ─── Markdown links: keep label, drop URL ────────────────────────────

  /// Transforms `[label](https://…)` → `[label]([URL REDACTED])`.
  static String _redactMarkdownLinks(String text) {
    // Match inline markdown links: [text](url) where url is http(s).
    // Character class excludes whitespace, ), ", <, > — common URL terminators.
    final inlineLink = RegExp(
      r'\[([^\]]*)\]\((https?://[^\s)"><]+)\)',
      multiLine: true,
    );
    return text.replaceAllMapped(inlineLink, (m) {
      final label = m.group(1)!;
      return '[$label]([URL REDACTED])';
    });
  }

  // ─── Plain URLs ──────────────────────────────────────────────────────

  /// Redacts bare `http://` / `https://` URLs not already inside a markdown link.
  static String _redactPlainUrls(String text) {
    // Negative lookbehind for "](" — avoids double-redacting markdown links.
    final plainUrl = RegExp(
      r'(?<!\]\()https?://[^\s)"><]+',
      multiLine: true,
    );
    return text.replaceAll(plainUrl, '[URL REDACTED]');
  }

  // ─── API keys ────────────────────────────────────────────────────────

  /// Redacts common API key patterns: sk-…, hk-…, key=…, api_key=…, etc.
  static String _redactApiKeys(String text) {
    // OpenAI keys: sk-proj-…, sk-…
    // Anthropic keys: sk-ant-…
    // Hermes keys: hk-…
    // Generic KEY=VALUE where value is 16+ non-whitespace, non-quote chars
    final apiKeyPatterns = <RegExp>[
      // sk- / hk- prefixed keys (OpenAI, Anthropic, Hermes)
      RegExp(r'\b(sk|hk)-[A-Za-z0-9_-]{20,}\b'),
      // env-style: KEY= or KEY: long value (exclude quoted values)
      RegExp(
        r'(?<![A-Za-z0-9])(api[_-]?key|secret|token|password|credential)s?\s*[=:]\s*[^\s"<>]{16,}',
        caseSensitive: false,
      ),
    ];
    for (final pattern in apiKeyPatterns) {
      text = text.replaceAll(pattern, '[API KEY REDACTED]');
    }
    return text;
  }

  // ─── Bearer tokens ───────────────────────────────────────────────────

  /// Redacts `Bearer <token>` patterns while preserving the word "Bearer".
  static String _redactBearerTokens(String text) {
    final bearer = RegExp(
      r'Bearer\s+[A-Za-z0-9\-._~+/]{20,}={0,2}',
      multiLine: true,
    );
    return text.replaceAll(bearer, 'Bearer [REDACTED]');
  }

  // ─── IP addresses ────────────────────────────────────────────────────

  /// Redacts IPv4 addresses with optional port numbers.
  /// Avoids redacting version numbers (e.g. "v1.2.3.4") by checking the
  /// preceding character.
  static String _redactIpAddresses(String text) {
    final ip = RegExp(
      r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?::\d{2,5})?\b',
    );
    return text.replaceAllMapped(ip, (m) {
      final before = m.start > 0 ? text[m.start - 1] : '';
      // Skip if preceded by a letter or digit — likely a version string
      if (RegExp(r'[A-Za-z0-9]').hasMatch(before)) {
        return m.group(0)!;
      }
      return '[IP REDACTED]';
    });
  }

  // ─── Long token-like strings ─────────────────────────────────────────

  /// Redacts strings of 40+ base64/JWT-like characters (alphanumeric, `-`, `_`,
  /// `+`, `/`, `=`) that likely represent tokens.
  ///
  /// Conservative: only matches when the string forms a standalone token
  /// (delimited by whitespace, double-quote, or string boundaries).
  static String _redactLongTokens(String text) {
    // Matches 40+ chars of base64-url-safe alphabet as standalone token.
    // Requires mixed case + digits to avoid matching normal text.
    final longToken = RegExp(
      r'(?<=[\s"]|^)(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[A-Za-z0-9_\-+=./]{40,}(?=[\s"]|\$)',
      multiLine: true,
    );
    return text.replaceAll(longToken, '[TOKEN REDACTED]');
  }
}
