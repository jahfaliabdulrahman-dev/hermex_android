import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_entry.freezed.dart';
part 'workspace_entry.g.dart';

/// A file or directory entry returned by the workspace API.
/// From GET /v1/workspace and GET /v1/workspace/{path}.
@freezed
class WorkspaceEntry with _$WorkspaceEntry {
  const factory WorkspaceEntry({
    required String name,
    @Default('file') String type, // 'file' | 'directory'
    @Default(0) int size,
    @JsonKey(name: 'modified_at') String? modifiedAt,
    @JsonKey(name: 'is_binary') @Default(false) bool isBinary,
  }) = _WorkspaceEntry;

  factory WorkspaceEntry.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceEntryFromJson(json);
}
