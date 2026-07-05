import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../models/workspace_entry.dart';

/// Repository for browsing workspace files from the Hermes Agent API Server.
///
/// Endpoints:
/// - GET /v1/workspace → root directory listing
/// - GET /v1/workspace/{path} → subdirectory listing or file content
///
/// Repository owns its own transaction boundaries — no nested writeTxn (DEC-034 rule 7).
class WorkspaceRepository {
  final ApiClient? _apiClient;

  WorkspaceRepository({ApiClient? apiClient}) : _apiClient = apiClient;

  /// Get directory listing for [path].
  /// Pass an empty string or '/' for root.
  /// Returns a list of [WorkspaceEntry] objects.
  /// Returns empty list if no ApiClient is available.
  Future<List<WorkspaceEntry>> getDirectoryContents(String path) async {
    final client = _apiClient;
    if (client == null) {
      return [];
    }

    final cleanPath = _cleanPath(path);

    final endpoint = cleanPath.isEmpty
        ? ApiEndpoints.workspace
        : ApiEndpoints.workspacePath(cleanPath);

    final json = await client.get(endpoint);

    final entries = json['data'] as List<dynamic>?;
    if (entries == null || entries.isEmpty) {
      return [];
    }

    return entries
        .map((e) => WorkspaceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the content of a file at [path].
  /// Returns the raw content as a String for text files.
  /// Throws for binary files or permission errors.
  Future<String> getFileContent(String path) async {
    final client = _apiClient;
    if (client == null) {
      throw ConnectionException('No server connected');
    }

    final cleanPath = _cleanPath(path);

    final endpoint = ApiEndpoints.workspacePath(cleanPath);
    final json = await client.get(endpoint);

    // The content may be in 'data' as a string, or in a 'content' field.
    if (json['data'] is String) {
      return json['data'] as String;
    }
    if (json['content'] is String) {
      return json['content'] as String;
    }

    // If the response contains entries (it's a directory), that's an error.
    if (json['data'] is List) {
      throw ClientException('Path is a directory, not a file');
    }

    return json.toString();
  }

  /// Clean a path — remove leading/trailing slashes, collapse duplicates.
  String _cleanPath(String path) {
    var cleaned = path.trim();
    while (cleaned.startsWith('/')) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
