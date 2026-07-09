/// Model representing a user-selected file attachment in chat input.
///
/// Holds the local file path, display metadata, and provides
/// formatted size and type detection helpers.
class AttachedFile {
  final String path;
  final String name;
  final int size;
  final String? mimeType;

  const AttachedFile({
    required this.path,
    required this.name,
    required this.size,
    this.mimeType,
  });

  /// Human-readable file size string (e.g., "1.2 MB").
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Whether this is likely an image file.
  bool get isImage => mimeType != null && mimeType!.startsWith('image/');
}
