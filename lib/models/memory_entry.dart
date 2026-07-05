/// A single memory entry returned by the Hermes Agent API (GET /v1/memory).
///
/// This is a read-only API model — not persisted locally.
class MemoryEntry {
  /// Unique memory identifier.
  final String id;

  /// Short title / key for this memory.
  final String title;

  /// Full description or value of the memory entry.
  final String? description;

  /// When this memory was created on the server.
  final DateTime? createdAt;

  /// When this memory was last updated on the server.
  final DateTime? updatedAt;

  const MemoryEntry({
    required this.id,
    required this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  // ─── JSON Parsing (safe — handles malformed payloads) ───

  factory MemoryEntry.fromJson(Map<String, dynamic> json) {
    return MemoryEntry(
      id: (json['id'] ?? json['key'] ?? '').toString(),
      title: (json['title'] ?? json['key'] ?? json['name'] ?? 'Untitled')
          .toString(),
      description: json['description']?.toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Parse a list from the API response.
  /// The API may return a map like {"memories": [...]} or a direct list.
  static List<MemoryEntry> parseList(dynamic body) {
    if (body == null) return [];
    if (body is List) {
      return body
          .map((e) => MemoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final list = body['memories'] ?? body['data'] ?? body['results'];
      if (list is List) {
        return list
            .map((e) => MemoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  // ─── Equality ───

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MemoryEntry(id: $id, title: $title)';
}
