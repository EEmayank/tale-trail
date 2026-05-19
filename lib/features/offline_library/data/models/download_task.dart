import 'package:hive/hive.dart';

part 'download_task.g.dart';

// ---------------------------------------------------------------------------
// DownloadTaskStatus enum
// ---------------------------------------------------------------------------

@HiveType(typeId: 12)
enum DownloadTaskStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  downloading,

  @HiveField(2)
  complete,

  @HiveField(3)
  failed,
}

// ---------------------------------------------------------------------------
// DownloadTask
// ---------------------------------------------------------------------------

/// Represents a single file download operation within a story download pipeline.
///
/// Tasks are persisted in Hive so the queue survives app restarts.
/// The [storyId] groups tasks so all files for a story can be managed together.
@HiveType(typeId: 13)
class DownloadTask extends HiveObject {
  DownloadTask({
    required this.id,
    required this.url,
    required this.localPath,
    required this.fileType,
    required this.storyId,
    required this.status,
    required this.retryCount,
    required this.bytesDownloaded,
    required this.totalBytes,
  });

  /// UUID uniquely identifying this task.
  @HiveField(0)
  final String id;

  /// Remote URL to download from.
  @HiveField(1)
  String url;

  /// Absolute local filesystem path where the file will be saved.
  @HiveField(2)
  String localPath;

  /// Type of asset: `'audio'`, `'illustration'`, `'tree'`, or `'cover'`.
  @HiveField(3)
  String fileType;

  /// Parent story identifier — used to group/cancel related tasks.
  @HiveField(4)
  String storyId;

  /// Current task status.
  @HiveField(5)
  DownloadTaskStatus status;

  /// How many times this task has been retried after failure.
  @HiveField(6)
  int retryCount;

  /// Number of bytes downloaded so far.
  @HiveField(7)
  int bytesDownloaded;

  /// Total file size in bytes (0 if unknown).
  @HiveField(8)
  int totalBytes;

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  /// Fractional download progress for this file (0.0–1.0).
  /// Returns 0.0 when [totalBytes] is 0 to avoid division by zero.
  double get progress =>
      totalBytes > 0 ? (bytesDownloaded / totalBytes).clamp(0.0, 1.0) : 0.0;

  /// Whether this task can be retried (has not exceeded max retries).
  bool get canRetry => retryCount < 2;

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  DownloadTask copyWith({
    String? id,
    String? url,
    String? localPath,
    String? fileType,
    String? storyId,
    DownloadTaskStatus? status,
    int? retryCount,
    int? bytesDownloaded,
    int? totalBytes,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      fileType: fileType ?? this.fileType,
      storyId: storyId ?? this.storyId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  @override
  String toString() =>
      'DownloadTask(id: $id, fileType: $fileType, status: $status, '
      'progress: ${(progress * 100).toStringAsFixed(0)}%)';
}
