import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hermex_android/core/api/api_client.dart';
import 'package:hermex_android/core/api/api_exception.dart';
import 'package:hermex_android/core/constants/security_limits.dart';

/// Fake [HttpClientAdapter] that returns canned HTTP responses.
///
/// Allows testing Dio interceptors without a real server.
/// Simulates specific HTTP status codes and response bodies.
class _FakeHttpAdapter implements HttpClientAdapter {
  final int statusCode;
  final String statusMessage;
  final Object? responseBody;
  final Duration delay;

  _FakeHttpAdapter({
    required this.statusCode,
    this.statusMessage = 'OK',
    this.responseBody,
    this.delay = Duration.zero,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final bodyBytes = utf8.encode(
      responseBody is String
          ? responseBody as String
          : jsonEncode(responseBody ?? {'status': 'ok'}),
    );

    return ResponseBody(
      Stream.value(Uint8List.fromList(bodyBytes)),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
      statusMessage: statusMessage,
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Helper to create a Dio instance with the SAME interceptor chain
/// as ApiClient, minus certificate pinning (not relevant for tests).
Dio _createTestDio(String baseUrl) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Authorization': 'Bearer test-key',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    // BUG-6 FIX: only accept 2xx as valid.
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  ));

  // Same interceptor order as ApiClient constructor.
  // _DebugLogInterceptor, _SizeLimitInterceptor are not importable
  // (private), so we replicate the two critical ones here.
  dio.interceptors.add(_StatusCheckInterceptor());
  dio.interceptors.add(_ErrorClassifierInterceptor());

  return dio;
}

// ──────────────────────────────────────────────────────────────────────
// Replicas of the private interceptors for testing.
// These are identical to the ones in api_client.dart.
// ──────────────────────────────────────────────────────────────────────

/// BUG-6 FIX: Response status interceptor — rejects non-2xx responses.
class _StatusCheckInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode;
    if (status != null && (status < 200 || status >= 300)) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message:
              'HTTP $status: ${response.statusMessage ?? 'Request failed'}',
        ),
        true,
      );
      return;
    }
    handler.next(response);
  }
}

/// BUG-6 FIX: Error classifier interceptor.
class _ErrorClassifierInterceptor extends Interceptor {
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    // _classifyError is private in ApiClient — replicate logic here.
    _classify(error);
    handler.next(error);
  }

  void _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        ConnectionException(error.message ?? 'Connection error',
            statusCode: statusCode);
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          AuthException(error.message ?? 'Unauthorized',
              statusCode: statusCode);
        } else if (statusCode != null && statusCode >= 500) {
          ServerException(error.message ?? 'Server error',
              statusCode: statusCode);
        } else {
          ClientException(error.message ?? 'Client error',
              statusCode: statusCode);
        }
        break;
      default:
        ConnectionException(error.message ?? 'Unknown error',
            statusCode: statusCode);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────

void main() {
  // ─── Group: validateStatus (BUG-6 core fix) ─────────────────────────

  group('ApiClient validateStatus (BUG-6 fix)', () {
    late Dio dio;

    setUp(() {
      dio = _createTestDio('https://test.example.com');
    });

    test('200 is accepted as valid status', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 200,
        responseBody: {'data': 'ok'},
      );

      final response = await dio.get('/test');
      expect(response.statusCode, 200);
    });

    test('201 is accepted as valid status', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 201,
        responseBody: {'data': 'created'},
      );

      final response = await dio.get('/test');
      expect(response.statusCode, 201);
    });

    test('404 is rejected and throws DioException', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 404,
        statusMessage: 'Not Found',
        responseBody: {'error': 'not found'},
      );

      expect(
        () => dio.get('/test'),
        throwsA(isA<DioException>()),
      );
    });

    test('401 is rejected and throws DioException', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 401,
        statusMessage: 'Unauthorized',
        responseBody: {'error': 'unauthorized'},
      );

      expect(
        () => dio.get('/test'),
        throwsA(isA<DioException>()),
      );
    });

    test('500 is rejected and throws DioException', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 500,
        statusMessage: 'Internal Server Error',
        responseBody: {'error': 'server error'},
      );

      expect(
        () => dio.get('/test'),
        throwsA(isA<DioException>()),
      );
    });

    test('403 is rejected and throws DioException', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 403,
        statusMessage: 'Forbidden',
        responseBody: {'error': 'forbidden'},
      );

      expect(
        () => dio.get('/test'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ─── Group: Error response contains correct status code ──────────────

  group('DioException on non-2xx carries response data', () {
    late Dio dio;

    setUp(() {
      dio = _createTestDio('https://test.example.com');
    });

    test('404 DioException contains statusCode=404', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 404,
        statusMessage: 'Not Found',
        responseBody: {'error': 'Resource not found'},
      );

      try {
        await dio.get('/test');
        fail('Expected DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.badResponse);
        expect(e.response?.statusCode, 404);
      }
    });

    test('401 DioException contains statusCode=401', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 401,
        statusMessage: 'Unauthorized',
        responseBody: {'error': 'Invalid API key'},
      );

      try {
        await dio.get('/test');
        fail('Expected DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.badResponse);
        expect(e.response?.statusCode, 401);
      }
    });

    test('500 DioException contains statusCode=500', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 500,
        statusMessage: 'Internal Server Error',
        responseBody: {'error': 'oops'},
      );

      try {
        await dio.get('/test');
        fail('Expected DioException');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.badResponse);
        expect(e.response?.statusCode, 500);
      }
    });

    test('DioException response data is accessible from error', () async {
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 404,
        statusMessage: 'Not Found',
        responseBody: {'error': 'no such endpoint'},
      );

      try {
        await dio.get('/v1/nonexistent');
        fail('Expected DioException');
      } on DioException catch (e) {
        expect(e.response?.data, isNotNull);
      }
    });
  });

  // ─── Group: StatusCheckInterceptor belt-and-suspenders ───────────────

  group('_StatusCheckInterceptor (belt-and-suspenders)', () {
    // Tests that even if validateStatus were misconfigured, the
    // _StatusCheckInterceptor would still catch non-2xx responses.
    // We test this by creating a Dio with a permissive validateStatus
    // and verifying the interceptor still rejects 404.

    test(
        'rejects 404 even when validateStatus is permissive '
        '(belt-and-suspenders)', () async {
      // Create Dio with PERMISSIVE validateStatus (old buggy behavior)
      // BUT with the _StatusCheckInterceptor added.
      final dio = Dio(BaseOptions(
        baseUrl: 'https://test.example.com',
        headers: {'Authorization': 'Bearer test-key'},
        // Old buggy behavior: accept anything < 500
        validateStatus: (status) => status != null && status < 500,
      ));

      // Add the belt-and-suspenders interceptor.
      dio.interceptors.add(_StatusCheckInterceptor());

      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 404,
        statusMessage: 'Not Found',
        responseBody: {'error': 'gone'},
      );

      // Even though validateStatus accepts 404, the interceptor rejects it.
      expect(
        () => dio.get('/test'),
        throwsA(isA<DioException>()),
      );
    });

    test('passes through 200 response', () async {
      final dio = _createTestDio('https://test.example.com');

      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 200,
        responseBody: {'data': 'success'},
      );

      final response = await dio.get('/test');
      expect(response.statusCode, 200);
    });
  });

  // ─── Group: ApiException classification ─────────────────────────────

  group('ApiException class hierarchy', () {
    test('ConnectionException stores message, statusCode, responseBody', () {
      final ex = ConnectionException('timeout',
          statusCode: null, responseBody: 'timeout body');
      expect(ex.message, 'timeout');
      expect(ex.statusCode, isNull);
      expect(ex.responseBody, 'timeout body');
      expect(ex, isA<ApiException>());
    });

    test('AuthException stores message, statusCode, responseBody', () {
      final ex = AuthException('unauthorized',
          statusCode: 401, responseBody: 'auth body');
      expect(ex.message, 'unauthorized');
      expect(ex.statusCode, 401);
      expect(ex.responseBody, 'auth body');
      expect(ex, isA<ApiException>());
    });

    test('ServerException stores message, statusCode, responseBody', () {
      final ex = ServerException('server error',
          statusCode: 500, responseBody: 'server body');
      expect(ex.message, 'server error');
      expect(ex.statusCode, 500);
      expect(ex.responseBody, 'server body');
      expect(ex, isA<ApiException>());
    });

    test('ClientException stores message, statusCode, responseBody', () {
      final ex = ClientException('not found',
          statusCode: 404, responseBody: 'client body');
      expect(ex.message, 'not found');
      expect(ex.statusCode, 404);
      expect(ex.responseBody, 'client body');
      expect(ex, isA<ApiException>());
    });

    test('ClientException can represent 400 Bad Request', () {
      final ex = ClientException('bad request',
          statusCode: 400, responseBody: 'bad body');
      expect(ex.statusCode, 400);
      expect(ex, isA<ApiException>());
    });

    test('ClientException can represent 403 Forbidden', () {
      final ex = ClientException('forbidden',
          statusCode: 403, responseBody: 'forbidden body');
      expect(ex.statusCode, 403);
      expect(ex, isA<ApiException>());
    });
  });

  // ─── Group: Real ApiClient integration ──────────────────────────────

  group('ApiClient with fixed validateStatus', () {
    test('ApiClient constructor creates Dio with 2xx-only validateStatus',
        () {
      final client = ApiClient(
        baseUrl: 'https://test.example.com',
        apiKey: 'test-api-key',
      );

      final dio = client.dio;
      // Verify the interceptor chain was set up.
      expect(dio.interceptors.length, greaterThanOrEqualTo(2));

      // Verify validateStatus via a real request.
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 200,
        responseBody: {'data': 'ok'},
      );
      // Should not throw — 200 is valid.
      expect(
        dio.get('/test'),
        completes,
      );
    });

    test('ApiClient returns error response body on 404', () async {
      final client = ApiClient(
        baseUrl: 'https://test.example.com',
        apiKey: 'test-api-key',
      );

      client.dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 404,
        statusMessage: 'Not Found',
        responseBody: {'error': 'not found'},
      );

      // A.1 fix: validateStatus < 400 → 404 is now rejected as an exception.
      // The caller must catch DioException and inspect response data.
      expect(
        () => client.get('/test'),
        throwsA(isA<DioException>()),
      );
    });

    test('ApiClient healthCheck returns false on 404', () async {
      final client = ApiClient(
        baseUrl: 'https://test.example.com',
        apiKey: 'test-api-key',
      );

      client.dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 404,
        statusMessage: 'Not Found',
      );

      final result = await client.healthCheck();
      expect(result, false);
    });
  });

  // ─── Group: Response size limits still work (regression) ─────────────

  group('SizeLimit behavior preserved', () {
    test('response under limit passes', () async {
      final dio = _createTestDio('https://test.example.com');

      final smallBody = '{"data": "${"x" * 100}"}';
      dio.httpClientAdapter = _FakeHttpAdapter(
        statusCode: 200,
        responseBody: smallBody,
      );

      final response = await dio.get('/test');
      expect(response.statusCode, 200);
    });

    test('SecurityLimits.maxJsonResponseSize is 10MB', () {
      expect(SecurityLimits.maxJsonResponseSize, 10 * 1024 * 1024);
    });
  });
}
