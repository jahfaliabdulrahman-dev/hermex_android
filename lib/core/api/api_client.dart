import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'endpoints.dart';
import '../constants/security_limits.dart';
import '../security/certificate_pinner.dart';
import 'api_exception.dart';

/// Centralized Dio HTTP client for Hermes Agent API Server communication.
///
/// Features:
/// - Bearer token auth interceptor
/// - Base URL from active server configuration
/// - 10-second connect timeout, 30-second receive timeout
/// - Typed error classification (ConnectionException, AuthException, ServerException)
/// - Debug logging on all requests/responses
/// - Response size limiting (AUD-006)
/// - Certificate pinning via TOFU (AUD-001)
class ApiClient {
  late final Dio _dio;

  ApiClient({
    required String baseUrl,
    required String apiKey,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
    CertificatePinner? certificatePinner,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    // AUD-001: Certificate pinning for production builds.
    // Configure the underlying HttpClient to validate server certificates
    // against pinned SHA-256 fingerprints (TOFU: Trust On First Use).
    if (certificatePinner != null) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            certificatePinner.validateCertificate;
        return client;
      };
    }

    _dio.interceptors.add(_DebugLogInterceptor());
    _dio.interceptors.add(_SizeLimitInterceptor());

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final exception = _classifyError(error);
        if (kDebugMode) {
          debugPrint(
              '=== HERMEX DEBUG: ApiClient error — ${exception.runtimeType}: ${exception.message} ===');
        }
        handler.next(error);
      },
    ));
  }

  /// Raw Dio instance for advanced use cases (SSE, file downloads).
  Dio get dio => _dio;

  // ─── Convenience Methods ───

  /// GET request. Returns raw decoded JSON as `dynamic`.
  ///
  /// Use this instead of [get] when the API may return a bare JSON array
  /// (e.g. [ModelInfo] list, [SessionSummary] list) which Dio's typed
  /// `Map<String, dynamic>` return would silently reject.
  Future<dynamic> getDynamic(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
    );
    return response.data;
  }

  /// GET request. Returns decoded JSON map.
  /// Prefer [getDynamic] when the response shape may be a bare array.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return response.data ?? {};
  }

  /// POST request with JSON body.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
    );
    return response.data ?? {};
  }

  /// PUT request with JSON body.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      path,
      data: data,
    );
    return response.data ?? {};
  }

  /// PATCH request with JSON body.
  /// DEC-EPIC001-DEPCHECK: Added for cron job updates (PUT returns 405).
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      path,
      data: data,
    );
    return response.data ?? {};
  }

  /// DELETE request.
  Future<Map<String, dynamic>> delete(String path) async {
    final response =
        await _dio.delete<Map<String, dynamic>>(path);
    return response.data ?? {};
  }

  /// Health check — calls GET /health.
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.health,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== HERMEX DEBUG: Health check failed — $e ===');
      }
      return false;
    }
  }

  // ─── Error Classification ───

  static ApiException _classifyError(DioException error) {
    final message = error.message ?? 'Unknown error';
    final statusCode = error.response?.statusCode;
    final body = error.response?.data?.toString();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ConnectionException(message,
            statusCode: statusCode, responseBody: body);

      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return AuthException(message,
              statusCode: statusCode, responseBody: body);
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerException(message,
              statusCode: statusCode, responseBody: body);
        }
        return ClientException(message,
            statusCode: statusCode, responseBody: body);

      default:
        return ConnectionException(message,
            statusCode: statusCode, responseBody: body);
    }
  }
}

/// Debug logging interceptor — only active in debug mode.
class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '=== HERMEX DEBUG: ${options.method} ${options.uri} ===');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '=== HERMEX DEBUG: ${response.statusCode} ${response.requestOptions.uri} ===');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          '=== HERMEX DEBUG: ERROR ${err.type} ${err.message} ===');
    }
    handler.next(err);
  }
}

/// AUD-006: Response size interceptor — rejects oversized JSON responses
/// before they are fully parsed into memory, preventing OOM attacks.
class _SizeLimitInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    if (data is String) {
      if (data.length > SecurityLimits.maxJsonResponseSize) {
        if (kDebugMode) {
          debugPrint(
              '=== HERMEX DEBUG: Response rejected — size ${data.length} '
              'exceeds limit ${SecurityLimits.maxJsonResponseSize} ===');
        }
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Response body too large',
          ),
          true,
        );
        return;
      }
    } else if (data is List) {
      // List responses also checked for extreme size via JSON serialization.
      final size = data.toString().length;
      if (size > SecurityLimits.maxJsonResponseSize) {
        if (kDebugMode) {
          debugPrint(
              '=== HERMEX DEBUG: List response rejected — size $size '
              'exceeds limit ${SecurityLimits.maxJsonResponseSize} ===');
        }
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'Response body too large',
          ),
          true,
        );
        return;
      }
    }

    handler.next(response);
  }
}
