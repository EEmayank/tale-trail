import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kids_stories/features/offline_library/data/models/offline_story_record.dart';

/// Manages all read/write operations for locally stored offline stories.
///
/// Combines a Hive box for metadata with the device filesystem for asset files.
/// All public methods are safe to call from any isolate context.
class OfflineStorageRepository {
  static const String _boxName = 'offline_stories';

  // ---------------------------------------------------------------------------
  // Box access
  // ---------------------------------------------------------------------------

  Box<OfflineStoryRecord> get _box => Hive.box<OfflineStoryRecord>(_boxName);

  /// Opens the Hive box. Must be called once during app initialisation before
  /// any repository methods are used.
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<OfflineStoryRecord>(_boxName);
    }
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns `true` when the story with [storyId] has been fully downloaded
  /// and its tree file still exists on disk.
  bool isDownloaded(String storyId) {
    final record = _box.get(storyId);
    if (record == null) return false;
    if (record.downloadStatus != DownloadStatus.complete) return false;
    final treePath = record.localTreePath;
    if (treePath == null) return false;
    return File(treePath).existsSync();
  }

  /// Returns the [OfflineStoryRecord] for [storyId], or `null` if not found.
  OfflineStoryRecord? getOfflineStory(String storyId) => _box.get(storyId);

  /// Returns all persisted offline story records.
  List<OfflineStoryRecord> listOfflineStories() => _box.values.toList();

  /// Returns the total number of bytes consumed by all downloaded stories.
  int getStorageUsageBytes() {
    return _box.values.fold<int>(0, (sum, r) => sum + r.totalSizeBytes);
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Persists or updates [record] in the Hive box.
  /// Uses [OfflineStoryRecord.storyId] as the box key.
  Future<void> updateRecord(OfflineStoryRecord record) async {
    await _box.put(record.storyId, record);
  }

  /// Deletes all local asset files and removes the Hive record for [storyId].
  Future<void> deleteDownload(String storyId) async {
    final record = _box.get(storyId);
    if (record != null) {
      await _deleteStoryDirectory(storyId);
    }
    await _box.delete(storyId);
  }

  /// Deletes all downloaded stories and clears the Hive box.
  Future<void> deleteAllDownloads() async {
    final storyIds = _box.keys.toList();
    for (final id in storyIds) {
      await _deleteStoryDirectory(id as String);
    }
    await _box.clear();
  }

  // ---------------------------------------------------------------------------
  // Path helpers
  // ---------------------------------------------------------------------------

  /// Returns the absolute local path for an asset file.
  ///
  /// Path format: `<app_documents>/offline_stories/<storyId>/<assetType>/<filename>`
  Future<String> getLocalAssetPath(
    String storyId,
    String assetType,
    String filename,
  ) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/offline_stories/$storyId/$assetType/$filename';
  }

  /// Returns the root directory for a story's downloaded assets.
  Future<String> getStoryDirectory(String storyId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/offline_stories/$storyId';
  }

  /// Ensures all required subdirectories for [storyId] exist.
  Future<void> ensureDirectories(String storyId) async {
    final base = await getStoryDirectory(storyId);
    for (final sub in ['audio', 'illustrations', 'meta']) {
      await Directory('$base/$sub').create(recursive: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Integrity check
  // ---------------------------------------------------------------------------

  /// Returns `true` when the story's tree.json and at least some asset files
  /// exist on disk. Used to detect incomplete / corrupted downloads.
  Future<bool> verifyIntegrity(String storyId) async {
    final record = _box.get(storyId);
    if (record == null) return false;

    final treePath = record.localTreePath;
    if (treePath == null || !File(treePath).existsSync()) return false;

    // Check audio directory has at least one file.
    final audioDir = record.localAudioDir;
    if (audioDir != null) {
      final dir = Directory(audioDir);
      if (dir.existsSync()) {
        final files = dir.listSync();
        if (files.isEmpty) return false;
      } else {
        return false;
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _deleteStoryDirectory(String storyId) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final storyDir = Directory('${docsDir.path}/offline_stories/$storyId');
      if (storyDir.existsSync()) {
        await storyDir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort deletion — do not throw on partial failure.
    }
  }
}
