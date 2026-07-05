import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../models/skill.dart';

/// Repository for fetching skills from the Hermes Agent API Server.
///
/// Endpoint: GET /v1/skills
/// Returns a list of [Skill] objects.
/// Repository owns its own transaction boundaries — no nested writeTxn (DEC-034 rule 7).
class SkillsRepository {
  final ApiClient? _apiClient;

  SkillsRepository({ApiClient? apiClient}) : _apiClient = apiClient;

  /// Fetch all installed skills from the server.
  ///
  /// Returns an empty list if no ApiClient is available (no server connected).
  /// Throws [ApiException] on network/auth/server errors.
  Future<List<Skill>> getSkills() async {
    final client = _apiClient;
    if (client == null) {
      return [];
    }

    final json = await client.get(ApiEndpoints.skills);

    final skillsList = json['data'] as List<dynamic>?;
    if (skillsList == null || skillsList.isEmpty) {
      return [];
    }

    return skillsList
        .map((s) => Skill.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}
