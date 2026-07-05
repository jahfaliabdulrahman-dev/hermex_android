import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Certificate pinning via TOFU (Trust On First Use) for Dio HttpClient.
///
/// ## How it works
///
/// 1. On **first successful** TLS handshake with a host:port, the server's
///    certificate SHA-256 fingerprint is stored in SharedPreferences.
/// 2. On **subsequent** connections to the same host:port, the presented
///    certificate is validated against the pinned fingerprint.
/// 3. If the fingerprints don't match → the connection is **rejected**
///    (potential MITM or server cert rotation).
///
/// ## Behaviour by build mode
///
/// | Mode      | Pinning enforcement | First-connection handling          |
/// |-----------|---------------------|-------------------------------------|
/// | debug     | Warn only           | Always allow (dev flexibility)      |
/// | profile   | Warn only           | Always allow                        |
/// | release   | **Enforce**         | TOFU — pin on first connect         |
///
/// ## Storage
///
/// Pinned fingerprints are stored in SharedPreferences keyed by `host:port`
/// with prefix `cert_pin_`. Cert fingerprints are NOT secrets (they are
/// SHA-256 hashes of public certificates), so SharedPreferences is appropriate.
///
/// ## Spec compliance
///
/// - app-spec/08_security_privacy.md §Network Security:
///   "Certificate pinning for production builds"
/// - AUD-001: MITM Protection
class CertificatePinner {
  static const _keyPrefix = 'cert_pin_';

  SharedPreferences? _prefs;
  final Map<String, String> _pinCache = {};

  /// Initialize the pinner by loading SharedPreferences.
  /// Call once before any network requests — typically during app init
  /// or before creating the ApiClient.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPinsFromStorage();
    debugPrint(
        '=== HERMEX DEBUG: CertificatePinner.init — '
        'loaded ${_pinCache.length} pinned certificates ===');
  }

  /// Synchronous certificate validation callback for use with
  /// `HttpClient.badCertificateCallback`.
  ///
  /// Returns `true` to allow the connection, `false` to reject.
  bool validateCertificate(X509Certificate cert, String host, int port) {
    final fingerprint = _sha256Hex(cert.der);
    final hostKey = '$host:$port';

    // Non-release: warn only, always allow.
    if (!kReleaseMode) {
      debugPrint(
          '=== HERMEX DEBUG: CertificatePinner — '
          'non-release: allowing $hostKey (SHA-256: $fingerprint) ===');
      return true;
    }

    // Release mode: enforce pinning.
    final pinned = _pinCache[hostKey];
    if (pinned == null) {
      // TOFU: no pin yet — accept and store for future.
      debugPrint(
          '=== HERMEX DEBUG: CertificatePinner — '
          'TOFU: pinning $hostKey → $fingerprint ===');
      _pinCache[hostKey] = fingerprint;
      _persistPinAsync(hostKey, fingerprint);
      return true;
    }

    if (pinned == fingerprint) {
      return true; // Match — trusted.
    }

    // Mismatch — potential MITM or server cert rotation.
    debugPrint(
        '=== HERMEX DEBUG: CertificatePinner — '
        'REJECTED: $hostKey fingerprint mismatch. '
        'Pinned: $pinned, Got: $fingerprint ===');
    return false;
  }

  /// Clear all pinned certificates.
  Future<void> clearAll() async {
    debugPrint('=== HERMEX DEBUG: CertificatePinner.clearAll ===');
    // Remove from SharedPreferences
    final keysToRemove = _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix));
    if (keysToRemove != null) {
      for (final key in keysToRemove) {
        await _prefs?.remove(key);
      }
    }
    _pinCache.clear();
  }

  /// Clear pin for a specific host:port.
  Future<void> clearPin(String host, int port) async {
    final storageKey = '$_keyPrefix$host:$port';
    await _prefs?.remove(storageKey);
    _pinCache.remove('$host:$port');
  }

  /// Manually pin a certificate fingerprint.
  Future<void> pinManually(
      String host, int port, String sha256Fingerprint) async {
    final hostKey = '$host:$port';
    _pinCache[hostKey] = sha256Fingerprint;
    await _persistPinAsync(hostKey, sha256Fingerprint);
  }

  // ─── Private ───

  void _loadPinsFromStorage() {
    if (_prefs == null) return;
    _pinCache.clear();
    for (final key in _prefs!.getKeys()) {
      if (key.startsWith(_keyPrefix)) {
        final hostKey = key.substring(_keyPrefix.length);
        final fingerprint = _prefs!.getString(key);
        if (fingerprint != null) {
          _pinCache[hostKey] = fingerprint;
        }
      }
    }
  }

  Future<void> _persistPinAsync(String hostKey, String fingerprint) async {
    try {
      await _prefs?.setString('$_keyPrefix$hostKey', fingerprint);
    } catch (e) {
      debugPrint(
          '=== HERMEX DEBUG: CertificatePinner — '
          'failed to persist pin for $hostKey: $e ===');
    }
  }

  /// SHA-256 hex digest of binary data.
  /// Uses a pure-Dart implementation (zero external dependencies).
  static String _sha256Hex(List<int> data) {
    return _pureDartSha256Hex(data);
  }

  /// Pure-Dart SHA-256 (RFC 6234) — zero-dependency fallback.
  static String _pureDartSha256Hex(List<int> data) {
    final k = <int>[
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
      0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
      0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
      0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
      0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
      0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
      0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
      0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
      0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];

    var h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    var h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;

    final msgBytes = List<int>.from(data);
    final msgBitLen = msgBytes.length * 8;
    msgBytes.add(0x80);
    while ((msgBytes.length * 8) % 512 != 448) {
      msgBytes.add(0x00);
    }
    for (var i = 7; i >= 0; i--) {
      msgBytes.add((msgBitLen >> (i * 8)) & 0xff);
    }

    for (var chunkStart = 0; chunkStart < msgBytes.length; chunkStart += 64) {
      final w = List<int>.filled(64, 0);
      for (var i = 0; i < 16; i++) {
        final offset = chunkStart + i * 4;
        w[i] = (msgBytes[offset] << 24) |
            (msgBytes[offset + 1] << 16) |
            (msgBytes[offset + 2] << 8) |
            msgBytes[offset + 3];
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr32(w[i - 15], 7) ^
            _rotr32(w[i - 15], 18) ^
            (w[i - 15] >> 3);
        final s1 = _rotr32(w[i - 2], 17) ^
            _rotr32(w[i - 2], 19) ^
            (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      var a = h0, b = h1, c = h2, d = h3;
      var e = h4, f = h5, g = h6, h = h7;

      for (var i = 0; i < 64; i++) {
        final s1 = _rotr32(e, 6) ^ _rotr32(e, 11) ^ _rotr32(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = (h + s1 + ch + k[i] + w[i]) & 0xffffffff;
        final s0 = _rotr32(a, 2) ^ _rotr32(a, 13) ^ _rotr32(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + h) & 0xffffffff;
    }

    final digest = StringBuffer();
    for (final val in [h0, h1, h2, h3, h4, h5, h6, h7]) {
      digest.write(val.toRadixString(16).padLeft(8, '0'));
    }
    return digest.toString();
  }

  static int _rotr32(int x, int n) =>
      ((x >> n) | (x << (32 - n))) & 0xffffffff;
}
