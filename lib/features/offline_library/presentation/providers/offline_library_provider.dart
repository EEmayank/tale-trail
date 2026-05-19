import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kids_stories/features/offline_library/data/models/offline_story_record.dart';
import 'package:kids_stories/features/offline_library/data/repositories/download_repository.dart';
import 'package:kids_stories/features/offline_library/data/repositories/offline_storage_repository.dart';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

/// Singleton [OfflineStorageRepository] provider.
final offlineStorageRepositoryProvider = Provider<OfflineStorageRepository>(
  (ref) => OfflineStorageRepository(),
  name: 'offlineStorageRepositoryProvider',
);

/// Singleton [DownloadRepository] provider.
final downloadRepositoryProvider = Provider<DownloadRepository>(
  (ref) {
    final storage = ref.watch(offlineStorageRepositoryProvider);
    final repo = DownloadRepository(storageRepository: storage);
    ref.onDispose(repo.dispose);
    return repo;
  },
  name: 'downloadRepositoryProvider',
);

// ---------------------------------------------------------------------------
// Offline stories list — reactive via Hive ValueListenable
// ---------------------------------------------------------------------------

/// Provides the current list of all [OfflineStoryRecord]s from Hive.
///
/// Re-reads the Hive box on every watch. For full reactivity, invalidate this
/// provider after any Hive mutation by calling
/// `ref.invalidate(offlineStoriesProvider)`.
final offlineStoriesProvider = Provider<List<OfflineStoryRecord>>(
  (ref) {
    final storage = ref.watch(offlineStorageRepositoryProvider);
    return storage.listOfflineStories();
  },
  name: 'offlineStoriesProvider',
);

// ---------------------------------------------------------------------------
// Download progress stream — per storyId
// ---------------------------------------------------------------------------

/// A [StreamProvider.family] that emits progress values (0.0–1.0) for a
/// given [storyId] as its download proceeds.
final downloadProgressProvider =
    StreamProvider.family<double, String>((ref, storyId) {
  final repo = ref.watch(downloadRepositoryProvider);
  // Seed with the current persisted progress.
  final storage = ref.watch(offlineStorageRepositoryProvider);
  final record = storage.getOfflineStory(storyId);
  final seedProgress = record?.downloadProgress ?? 0.0;

  final controller = StreamController<double>();
  controller.add(seedProgress);

  final sub = repo.progressStream(storyId).listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
}, name: 'downloadProgressProvider');

// ---------------------------------------------------------------------------
// Derived convenience providers
// ---------------------------------------------------------------------------

/// Returns `true` when the story with [storyId] is fully downloaded.
final isDownloadedProvider = Provider.family<bool, String>((ref, storyId) {
  final storage = ref.watch(offlineStorageRepositoryProvider);
  return storage.isDownloaded(storyId);
}, name: 'isDownloadedProvider');

/// Total bytes used by all downloaded stories.
final storageUsageProvider = Provider<int>((ref) {
  final storage = ref.watch(offlineStorageRepositoryProvider);
  return storage.getStorageUsageBytes();
}, name: 'storageUsageProvider');

/// Stories that are currently being downloaded.
final activeDownloadsProvider = Provider<List<OfflineStoryRecord>>((ref) {
  final stories = ref.watch(offlineStoriesProvider);
  return stories
      .where((s) => s.downloadStatus == DownloadStatus.downloading)
      .toList();
}, name: 'activeDownloadsProvider');

// ---------------------------------------------------------------------------
// DownloadNotifier
// ---------------------------------------------------------------------------

/// Manages download operations and keeps provider state consistent after
/// each mutation by invalidating dependent providers.
class DownloadNotifier extends StateNotifier<void> {
  DownloadNotifier(this._ref) : super(null);

  final Ref _ref;

  DownloadRepository get _downloadRepo =>
      _ref.read(downloadRepositoryProvider);
  OfflineStorageRepository get _storageRepo =>
      _ref.read(offlineStorageRepositoryProvider);

  void _invalidate() {
    _ref.invalidate(offlineStoriesProvider);
    _ref.invalidate(storageUsageProvider);
    _ref.invalidate(activeDownloadsProvider);
  }

  /// Starts downloading the story identified by [storyId].
  Future<void> start(String storyId, String title) async {
    try {
      await _downloadRepo.startDownload(storyId, title);
    } finally {
      _invalidate();
    }
  }

  /// Cancels the in-progress download for [storyId].
  Future<void> cancel(String storyId) async {
    await _downloadRepo.cancelDownload(storyId);
    _invalidate();
  }

  /// Retries a failed download for [storyId].
  Future<void> retry(String storyId) async {
    try {
      await _downloadRepo.retryDownload(storyId);
    } finally {
      _invalidate();
    }
  }

  /// Deletes local assets and metadata for [storyId].
  Future<void> deleteDownload(String storyId) async {
    await _storageRepo.deleteDownload(storyId);
    _invalidate();
  }

  /// Deletes all downloaded stories.
  Future<void> deleteAll() async {
    await _storageRepo.deleteAllDownloads();
    _invalidate();
  }
}

/// [StateNotifierProvider] for [DownloadNotifier].
final downloadNotifierProvider = StateNotifierProvider<DownloadNotifier, void>(
  (ref) => DownloadNotifier(ref),
  name: 'downloadNotifierProvider',
);
