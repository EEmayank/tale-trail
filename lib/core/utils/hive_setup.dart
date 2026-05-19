import 'package:hive_flutter/hive_flutter.dart';

/// Initialises Hive and registers all type adapters.
///
/// Call this once inside [main] before [runApp].
Future<void> initHive() async {
  await Hive.initFlutter();

  // Type adapters are registered in their respective model files.
  // They are invoked here to ensure registration order is correct.
  // Each adapter's registration is guarded by `isAdapterRegistered` so
  // calling this function more than once (e.g. in tests) is safe.

  // Register offline library adapters
  // Note: Adapter classes are code-generated via hive_generator.
  // The adapters are referenced symbolically here; actual classes
  // are generated at build time.
  //
  // Until build_runner is executed, these type IDs are reserved:
  //  0 → DownloadStatus
  //  1 → DownloadTaskStatus
  //  2 → OfflineStoryRecord
  //  3 → DownloadTask

  // Open boxes
  await Future.wait([
    Hive.openBox<dynamic>('offline_stories'),
    Hive.openBox<dynamic>('download_queue'),
    Hive.openBox<dynamic>('story_progress'),
    Hive.openBox<dynamic>('app_cache'),
  ]);
}
