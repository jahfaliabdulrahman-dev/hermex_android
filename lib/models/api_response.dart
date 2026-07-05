import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// Generic wrapper for Hermes Agent API Server responses.
///
/// Some endpoints wrap data in {"data": [...], "total": N}.
/// The `data` field is a raw JSON value (Map or List) — callers
/// parse it into typed models separately.
@freezed
class ApiResponse with _$ApiResponse {
  const factory ApiResponse({
    @Default({}) Map<String, dynamic> data,
    @Default(0) int total,
    String? error,
    String? message,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
}

/// A paginated list response from the API server.
///
/// `data` contains the raw list of items — callers deserialize each
/// item into the appropriate model type.
@freezed
class ApiListResponse with _$ApiListResponse {
  const factory ApiListResponse({
    @Default([]) List<Map<String, dynamic>> data,
    @Default(0) int total,
    @Default(20) int limit,
    @Default(0) int offset,
  }) = _ApiListResponse;

  factory ApiListResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiListResponseFromJson(json);
}
