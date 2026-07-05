/// All Hermes Agent API Server endpoint paths — from 06_api_contract.md.
///
/// Centralized path constants. Import this file instead of hardcoding paths
/// in API calls.
abstract class ApiEndpoints {
  ApiEndpoints._();

  // ─── Base ───
  static const String apiPrefix = '/api';
  static const String v1Prefix = '/v1';

  // ─── Health ───
  static const String health = '/health';

  // ─── Chat Completions (OpenAI-compatible) ───
  static const String chatCompletions = '/v1/chat/completions';

  // ─── Responses API (stateful) ───
  static const String responses = '/v1/responses';

  // ─── Models ───
  static const String models = '/v1/models';

  // ─── Sessions ───
  static const String sessions = '/api/sessions';
  static String sessionById(String id) => '/api/sessions/$id';
  static String sessionMessages(String id) => '/api/sessions/$id/messages';
  static String sessionChatStream(String id) =>
      '/api/sessions/$id/chat/stream';

  // ─── Jobs / Cron ───
  static const String jobs = '/api/jobs';
  static String jobById(String id) => '/api/jobs/$id';

  // ─── Skills ───
  static const String skills = '/v1/skills';

  // ─── Capabilities ───
  static const String capabilities = '/v1/capabilities';

  // ─── Memory ───
  static const String memory = '/v1/memory';

  // ─── Insights ───
  static const String insights = '/v1/insights';

  // ─── Workspace ───
  static const String workspace = '/v1/workspace';
  static String workspacePath(String path) => '/v1/workspace/$path';
}
