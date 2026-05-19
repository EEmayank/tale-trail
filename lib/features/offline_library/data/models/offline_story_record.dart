import 'package:hive/hive.dart';

part 'offline_story_record.g.dart';

// ---------------------------------------------------------------------------
// DownloadStatus enum
// ---------------------------------------------------------------------------

@HiveType(typeId: 10)
enum DownloadStatus {
  @HiveField(0)
  notDownloaded,

  @HiveField(1)
  downloading,

  @HiveField(2)
  paused,

  @HiveField(3)
  complete,

  @HiveField(4)
  failed,
}

// ---------------------------------------------------------------------------
// OfflineStoryRecord
// ---------------------------------------------------------------------------

/// Persisted record of a downloaded story stored in Hive.
///
/// A record is created when a download begins and updated as files are
/// downloaded. When [downloadStatus] is [DownloadStatus.complete] the story
/// can be played entirely offline.
@HiveType(typeId: 11)
class OfflineStoryRecord extends HiveObject {
  OfflineStoryRecord({
    required this.storyId,
    required this.title,
    required this.coverPath,
    required this.totalSizeBytes,
    required this.downloadStatus,
    required this.downloadProgress,
    required this.version,
    this.downloadedAt,
    this.localTreePath,
    this.localAudioDir,
    this.localIllustrationDir,
  });

  /// Firestore / story identifier.
  @HiveField(0)
  final String storyId;

  /// Human-readable story title.
  @HiveField(1)
  String title;

  /// Absolute path to the locally cached cover image file.
  @HiveField(2)
  String coverPath;

  /// Total size of all downloaded files in bytes.
  @HiveField(3)
  int totalSizeBytes;

  /// Current status of the download pipeline.
  @HiveField(4)
  DownloadStatus downloadStatus;

  /// Fractional progress from 0.0 (not started) to 1.0 (complete).
  @HiveField(5)
  double downloadProgress;

  /// Content version used for cache invalidation — mirrors [StoryTree.version].
  @HiveField(6)
  int version;

  /// When the download completed successfully.
  @HiveField(7)
  DateTime? downloadedAt;

  /// Absolute path to the local `tree.json` file.
  @HiveField(8)
  String? localTreePath;

  /// Absolute path to the directory containing all cached audio files.
  @HiveField(9)
  String? localAudioDir;

  /// Absolute path to the directory containing all cached illustration files.
  @HiveField(10)
  String? localIllustrationDir;

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  /// Total size in megabytes, rounded to one decimal place.
  double get totalSizeMb => totalSizeBytes / (1024 * 1024);

  /// Returns `true` only when the download has fully completed.
  bool get isComplete => downloadStatus == DownloadStatus.complete;

  /// Returns `true` when a download is actively in progress.
  bool get isDownloading => downloadStatus == DownloadStatus.downloading;

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  OfflineStoryRecord copyWith({
    String? storyId,
    String? title,
    String? coverPath,
    int? totalSizeBytes,
    DownloadStatus? downloadStatus,
    double? downloadProgress,
    int? version,
    DateTime? downloadedAt,
    String? localTreePath,
    String? localAudioDir,
    String? localIllustrationDir,
  }) {
    return OfflineStoryRecord(
      storyId: storyId ?? this.storyId,
      title: title ?? this.title,
      coverPath: coverPath ?? this.coverPath,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      version: version ?? this.version,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      localTreePath: localTreePath ?? this.localTreePath,
      localAudioDir: localAudioDir ?? this.localAudioDir,
      localIllustrationDir: localIllustrationDir ?? this.localIllustrationDir,
    );
  }

  @override
  String toString() =>
      'OfflineStoryRecord(storyId: $storyId, status: $downloadStatus, '
      'progress: ${(downloadProgress * 100).toStringAsFixed(0)}%)';
}
