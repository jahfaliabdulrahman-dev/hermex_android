/// ServerConfig model — in-memory representation of a Hermes Agent API Server connection.
///
/// Persisted via flutter_secure_storage (NOT Isar) because it contains
/// connection details including API key references. The API key itself
/// is stored separately in OS-encrypted storage and NEVER held in memory
/// longer than necessary.
///
/// This model is plain Dart (no Isar @collection, no Freezed) because
/// it lives in secure storage, not the local database.
class ServerConfig {
  final String id;
  final String name;
  final String url;
  final bool isDefault;
  final DateTime? lastConnected;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const ServerConfig({
    required this.id,
    required this.name,
    required this.url,
    this.isDefault = false,
    this.lastConnected,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  // ─── JSON Serialization (for secure storage persistence) ───

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isDefault': isDefault,
        'lastConnected': lastConnected?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
        lastConnected: json['lastConnected'] != null
            ? DateTime.parse(json['lastConnected'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
      );

  // ─── Copy With ───

  ServerConfig copyWith({
    String? id,
    String? name,
    String? url,
    bool? isDefault,
    DateTime? lastConnected,
    DateTime? createdAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) =>
      ServerConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
        isDefault: isDefault ?? this.isDefault,
        lastConnected: lastConnected ?? this.lastConnected,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  // ─── Equality ───

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerConfig &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ServerConfig(id: $id, name: $name, url: $url, isDefault: $isDefault, '
      'isDeleted: $isDeleted)';
  // NOTE: API key deliberately excluded from toString() — never logged.
}
