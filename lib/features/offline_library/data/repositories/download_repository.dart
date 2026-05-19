import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:kids_stories/features/offline_library/data/models/download_task.dart';
import 'package:kids_stories/features/offline_library/data/models/offline_story_record.dart';
import 'package:kids_stories/features/offline_library/data/repositories/offline_storage_repository.dart';
import 'package:kids_stories/features/story_player/data/models/story_tree.dart';

// ---------------------------------------------------------------------------
// _Semaphore — limits concurrent downloads
// ---------------------------------------------------------------------------

class _Semaphore {
  _Semaphore(this._maxCount) : _count = _maxCount;

  final int _maxCount;
  int _count;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() async {
    if (_count > 0) {
      _count--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next.complete();
    } else {
      _count++;
    }
  }
}

// ---------------------------------------------------------------------------
// DownloadRepository
// ---------------------------------------------------------------------------

/// Orchestrates story asset downloads using Dio.
///
/// Persists the download queue in the `'download_queue'` Hive box and
/// limits concurrency to 2 simultaneous file transfers via a semaphore.
/// [OfflineStorageRepository] is used for all metadata persistence.
class DownloadRepository {
  DownloadRepository({
    required this.storageRepository,
    Dio? dio,
    FirebaseFirestore? firestore,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 10),
                sendTimeout: const Duration(seconds: 30),
              ),
            ),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final OfflineStorageRepository storageRepository;
  final Dio _dio;
  final FirebaseFirestore _firestore;

  static const String _queueBoxName = 'download_queue';
  static const int _maxConcurrent = 2;
  static const int _maxRetries = 2;
  static const int _defaultSizeBytes = 15 * 1024 * 1024; // 15 MB

  final _semaphore = _Semaphore(_maxConcurrent);

  // Active cancel tokens keyed by storyId.
  final _cancelTokens = <String, List<CancelToken>>{};

  // Progress stream controllers keyed by storyId.
  final _progressControllers = <String, StreamController<double>>{};

  // ---------------------------------------------------------------------------
  // Box access
  // ---------------------------------------------------------------------------

  Box<DownloadTask> get _queueBox => Hive.box<DownloadTask>(_queueBoxName);

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_queueBoxName)) {
      await Hive.openBox<DownloadTask>(_queueBoxName);
    }
  }

  // ---------------------------------------------------------------------------
  // Progress stream
  // ---------------------------------------------------------------------------

  /// Returns a broadcast stream of progress values (0.0–1.0) for [storyId].
  Stream<double> progressStream(String storyId) {
    _progressControllers.putIfAbsent(
      storyId,
      () => StreamController<double>.broadcast(),
    );
    return _progressControllers[storyId]!.stream;
  }

  void _emitProgress(String storyId, double progress) {
    _progressControllers[storyId]?.add(progress.clamp(0.0, 1.0));
  }

  // ---------------------------------------------------------------------------
  // Size estimation
  // ---------------------------------------------------------------------------

  /// Fetches the estimated download size for [storyId] from Firestore.
  /// Falls back to [_defaultSizeBytes] if the field is absent or an error
  /// occurs.
  Future<int> estimateSize(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();
      final data = doc.data();
      if (data == null) return _defaultSizeBytes;
      final sizeBytes = (data['offlineSizeBytes'] as num?)?.toInt();
      return sizeBytes ?? _defaultSizeBytes;
    } catch (_) {
      return _defaultSizeBytes;
    }
  }

  // ---------------------------------------------------------------------------
  // Start download
  // ---------------------------------------------------------------------------

  /// Initiates a full story download for [storyId].
  ///
  /// Steps:
  /// 1. Create initial [OfflineStoryRecord] with [DownloadStatus.downloading].
  /// 2. Fetch the `tree.json` from Firestore, save to local storage.
  /// 3. Parse the tree to discover all audio + illustration URLs.
  /// 4. Queue each file as a [DownloadTask] in Hive.
  /// 5. Process the queue (max 2 concurrent via semaphore).
  Future<void> startDownload(String storyId, String storyTitle) async {
    // Prevent duplicate downloads.
    final existing = storageRepository.getOfflineStory(storyId);
    if (existing != null &&
        existing.downloadStatus == DownloadStatus.downloading) {
      return;
    }

    await storageRepository.ensureDirectories(storyId);

    final treePath = await storageRepository.getLocalAssetPath(
      storyId,
      'meta',
      'tree.json',
    );
    final audioDir = await storageRepository.getStoryDirectory(storyId) +
        '/audio';
    final illustrationDir =
        await storageRepository.getStoryDirectory(storyId) + '/illustrations';

    final record = OfflineStoryRecord(
      storyId: storyId,
      title: storyTitle,
      coverPath: '',
      totalSizeBytes: 0,
      downloadStatus: DownloadStatus.downloading,
      downloadProgress: 0.0,
      version: 1,
      localTreePath: treePath,
      localAudioDir: audioDir,
      localIllustrationDir: illustrationDir,
    );
    await storageRepository.updateRecord(record);
    _emitProgress(storyId, 0.0);

    try {
      // Step 1: Fetch and save tree.json from Firestore.
      final treeData = await _fetchStoryTree(storyId);
      await _saveJsonFile(treePath, treeData);

      final tree = StoryTree.fromJson(treeData);

      // Update record version from tree.
      final updatedRecord = storageRepository.getOfflineStory(storyId)!;
      updatedRecord.version = tree.version;
      await storageRepository.updateRecord(updatedRecord);

      // Step 2: Collect all asset URLs from the tree.
      final tasks = <DownloadTask>[];
      final uuid = const Uuid();

      for (final step in tree.steps.values) {
        // Audio file
        if (step.audioUrl.isNotEmpty) {
          final filename = _filenameFromUrl(step.audioUrl);
          final localPath = '$audioDir/$filename';
          tasks.add(DownloadTask(
            id: uuid.v4(),
            url: step.audioUrl,
            localPath: localPath,
            fileType: 'audio',
            storyId: storyId,
            status: DownloadTaskStatus.pending,
            retryCount: 0,
            bytesDownloaded: 0,
            totalBytes: 0,
          ));
        }

        // Illustration file
        if (step.illustrationUrl.isNotEmpty) {
          final filename = _filenameFromUrl(step.illustrationUrl);
          final localPath = '$illustrationDir/$filename';
          tasks.add(DownloadTask(
            id: uuid.v4(),
            url: step.illustrationUrl,
            localPath: localPath,
            fileType: 'illustration',
            storyId: storyId,
            status: DownloadTaskStatus.pending,
            retryCount: 0,
            bytesDownloaded: 0,
            totalBytes: 0,
          ));
        }
      }

      // Cover image — fetch URL from Firestore story document.
      final coverTask = await _buildCoverTask(storyId, uuid);
      if (coverTask != null) tasks.add(coverTask);

      // Persist all tasks in Hive.
      for (final task in tasks) {
        await _queueBox.put(task.id, task);
      }

      // Step 3: Process queue concurrently.
      await _processQueue(storyId, tasks.length);
    } catch (e) {
      final failedRecord = storageRepository.getOfflineStory(storyId);
      if (failedRecord != null) {
        failedRecord.downloadStatus = DownloadStatus.failed;
        await storageRepository.updateRecord(failedRecord);
      }
      _emitProgress(storyId, 0.0);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  /// Cancels an in-progress download for [storyId].
  Future<void> cancelDownload(String storyId) async {
    final tokens = _cancelTokens[storyId] ?? [];
    for (final token in tokens) {
      token.cancel('User cancelled download');
    }
    _cancelTokens.remove(storyId);

    // Remove pending/downloading tasks from queue.
    final toRemove = _queueBox.values
        .where((t) =>
            t.storyId == storyId &&
            (t.status == DownloadTaskStatus.pending ||
                t.status == DownloadTaskStatus.downloading))
        .map((t) => t.id)
        .toList();
    await _queueBox.deleteAll(toRemove);

    final record = storageRepository.getOfflineStory(storyId);
    if (record != null) {
      record.downloadStatus = DownloadStatus.notDownloaded;
      record.downloadProgress = 0.0;
      await storageRepository.updateRecord(record);
    }
    _emitProgress(storyId, 0.0);
  }

  // ---------------------------------------------------------------------------
  // Retry
  // ---------------------------------------------------------------------------

  /// Retries a failed download for [storyId] from the beginning.
  Future<void> retryDownload(String storyId) async {
    final record = storageRepository.getOfflineStory(storyId);
    if (record == null) return;

    // Clean up failed tasks.
    final toRemove = _queueBox.values
        .where((t) => t.storyId == storyId)
        .map((t) => t.id)
        .toList();
    await _queueBox.deleteAll(toRemove);

    await startDownload(storyId, record.title);
  }

  // ---------------------------------------------------------------------------
  // Resume interrupted downloads
  // ---------------------------------------------------------------------------

  /// Resumes any downloads that were interrupted by an app restart.
  /// Call this once during app initialization.
  Future<void> resumeInterruptedDownloads() async {
    final interruptedRecords = storageRepository
        .listOfflineStories()
        .where((r) => r.downloadStatus == DownloadStatus.downloading)
        .toList();

    for (final record in interruptedRecords) {
      // Mark as failed first; caller can retry manually via UI.
      record.downloadStatus = DownloadStatus.failed;
      record.downloadProgress = 0.0;
      await storageRepository.updateRecord(record);

      // Clean up stale queue tasks.
      final toRemove = _queueBox.values
          .where((t) => t.storyId == record.storyId)
          .map((t) => t.id)
          .toList();
      await _queueBox.deleteAll(toRemove);
    }
  }

  // ---------------------------------------------------------------------------
  // Private: queue processing
  // ---------------------------------------------------------------------------

  Future<void> _processQueue(String storyId, int totalTasks) async {
    if (totalTasks == 0) {
      await _finaliseDownload(storyId);
      return;
    }

    int completedTasks = 0;
    final pendingTasks = _queueBox.values
        .where((t) =>
            t.storyId == storyId && t.status == DownloadTaskStatus.pending)
        .toList();

    final futures = pendingTasks.map((task) async {
      await _semaphore.acquire();
      try {
        await _downloadFile(task);
      } finally {
        _semaphore.release();
        completedTasks++;
        _emitProgress(storyId, completedTasks / totalTasks);
        final record = storageRepository.getOfflineStory(storyId);
        if (record != null) {
          record.downloadProgress = completedTasks / totalTasks;
          await storageRepository.updateRecord(record);
        }
      }
    });

    await Future.wait(futures);

    // Check if all tasks completed successfully.
    final failed = _queueBox.values
        .where((t) =>
            t.storyId == storyId && t.status == DownloadTaskStatus.failed)
        .toList();

    if (failed.isEmpty) {
      await _finaliseDownload(storyId);
    } else {
      final record = storageRepository.getOfflineStory(storyId);
      if (record != null) {
        record.downloadStatus = DownloadStatus.failed;
        await storageRepository.updateRecord(record);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Private: single file download
  // ---------------------------------------------------------------------------

  Future<void> _downloadFile(DownloadTask task) async {
    // Skip if already downloaded (e.g. file exists from a previous partial run).
    if (File(task.localPath).existsSync() &&
        File(task.localPath).lengthSync() > 0) {
      task.status = DownloadTaskStatus.complete;
      await _queueBox.put(task.id, task);
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens.putIfAbsent(task.storyId, () => []).add(cancelToken);

    task.status = DownloadTaskStatus.downloading;
    await _queueBox.put(task.id, task);

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        // Ensure parent directory exists.
        final dir = Directory(task.localPath).parent;
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }

        await _dio.download(
          task.url,
          task.localPath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            task.bytesDownloaded = received;
            task.totalBytes = total > 0 ? total : 0;
            _queueBox.put(task.id, task);
          },
        );

        task.status = DownloadTaskStatus.complete;
        await _queueBox.put(task.id, task);
        return;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          task.status = DownloadTaskStatus.failed;
          await _queueBox.put(task.id, task);
          return;
        }
        if (attempt < _maxRetries) {
          task.retryCount++;
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        } else {
          task.status = DownloadTaskStatus.failed;
          await _queueBox.put(task.id, task);
          return;
        }
      } catch (_) {
        if (attempt >= _maxRetries) {
          task.status = DownloadTaskStatus.failed;
          await _queueBox.put(task.id, task);
          return;
        }
        task.retryCount++;
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Private: finalisation
  // ---------------------------------------------------------------------------

  Future<void> _finaliseDownload(String storyId) async {
    // Calculate total size from completed files.
    int totalBytes = 0;
    final tasks = _queueBox.values
        .where((t) =>
            t.storyId == storyId && t.status == DownloadTaskStatus.complete)
        .toList();
    for (final task in tasks) {
      try {
        final f = File(task.localPath);
        if (f.existsSync()) totalBytes += f.lengthSync();
      } catch (_) {}
    }

    // Find cover path from completed cover task.
    final coverTask = tasks.where((t) => t.fileType == 'cover').firstOrNull;

    final record = storageRepository.getOfflineStory(storyId);
    if (record != null) {
      record.downloadStatus = DownloadStatus.complete;
      record.downloadProgress = 1.0;
      record.totalSizeBytes = totalBytes;
      record.downloadedAt = DateTime.now();
      if (coverTask != null) record.coverPath = coverTask.localPath;
      await storageRepository.updateRecord(record);
    }

    // Clean up cancel tokens.
    _cancelTokens.remove(storyId);
    _emitProgress(storyId, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Private: helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchStoryTree(String storyId) async {
    final doc = await _firestore.collection('stories').doc(storyId).get();
    final data = doc.data();
    if (data == null) throw Exception('Story $storyId not found in Firestore');
    // The tree may be stored inline or as a subcollection document.
    if (data.containsKey('tree')) {
      return data['tree'] as Map<String, dynamic>;
    }
    // Fallback: fetch from tree subcollection.
    final treeDoc = await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('tree')
        .doc('v1')
        .get();
    final treeData = treeDoc.data();
    if (treeData == null) throw Exception('Tree not found for story $storyId');
    return treeData;
  }

  Future<void> _saveJsonFile(String path, Map<String, dynamic> data) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  String _filenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        // Strip query params from filename.
        return Uri.decodeComponent(segments.last).replaceAll('/', '_');
      }
    } catch (_) {}
    // Fallback: hash the URL.
    return url.hashCode.abs().toString();
  }

  Future<DownloadTask?> _buildCoverTask(String storyId, Uuid uuid) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();
      final data = doc.data();
      if (data == null) return null;
      final coverUrl = data['coverUrl'] as String?;
      if (coverUrl == null || coverUrl.isEmpty) return null;
      final filename = _filenameFromUrl(coverUrl);
      final localPath = await storageRepository.getLocalAssetPath(
        storyId,
        'meta',
        'cover_$filename',
      );
      return DownloadTask(
        id: uuid.v4(),
        url: coverUrl,
        localPath: localPath,
        fileType: 'cover',
        storyId: storyId,
        status: DownloadTaskStatus.pending,
        retryCount: 0,
        bytesDownloaded: 0,
        totalBytes: 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}
