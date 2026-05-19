# Tasks: Offline Download System

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 14 |
| **Total Estimated Effort** | ~53h |
| **Phase** | MVP |
| **Sprint** | 7-8 |
| **Status** | 🚧 Mostly Complete (4 tasks pending) |

---

## Phase 1: Storage Foundation (~7h)

- [x] **Task 1:** Hive setup — `offline_story_record.dart` + `.g.dart` (Hive @HiveType, `DownloadStatus` enum). `download_task.dart` + `.g.dart` (`DownloadTaskStatus` enum). Boxes `offline_stories`, `download_queue`, `story_progress`, `app_cache` opened in `hive_setup.dart`. Run `dart run build_runner build` to regenerate adapters. *(2h)*
- [x] **Task 2:** File datasource — `offline_storage_repository.dart`: `isDownloaded()`, `getOfflineStory()`, `listOfflineStories()`, `deleteDownload()` (files + Hive), `deleteAllDownloads()`, `getStorageUsageBytes()`, `updateRecord()`, `getLocalAssetPath()`, `verifyIntegrity()`. *(3h)*
- [x] **Task 3:** Size estimation — `download_repository.dart`: `estimateSize()` reads `totalAssetSizeBytes` from story metadata, formats as human-readable string (e.g. "12.4 MB"). Heuristic fallback based on step count. *(2h)*

## Phase 2: Download Engine (~20h)

- [x] **Task 4:** Download manager — Queue-based orchestrator in `download_repository.dart`. Max 2 concurrent downloads via `Semaphore`. Sequential ordering: tree JSON → audio files → illustrations → icons. `resumeInterruptedDownloads()` on app start. *(10h)*
- [x] **Task 5:** Download repository — `startDownload()` (fetches tree → queues all assets → processes with semaphore), `cancelDownload()`, `retryDownload()`, `_downloadFile()` (Dio + progress callbacks + 2x retry on failure). *(6h)*
- [x] **Task 6:** Offline storage repository — `getOfflineStory()`, `isDownloaded()`, `deleteDownload()`, `getStorageUsageBytes()`, `listOfflineStories()` all implemented in `offline_storage_repository.dart`. *(4h)*

## Phase 3: UI Components (~13h)

- [x] **Task 7:** Download button widget — `download_button.dart`: 3 visual states: cloud icon + size estimate (idle), `CircularProgressIndicator` + percentage (downloading), checkmark (complete). Tap toggles start/cancel. Size-estimate confirm dialog. *(4h)*
- [x] **Task 8:** Offline library screen — `offline_library_screen.dart` (562 lines): storage usage chip, `ListView` of downloaded stories with play/delete buttons, active download banner, "Delete All" gated behind parental PIN. *(6h)*
- [ ] **Task 9:** Download progress indicator — Global indicator visible in bottom navigation area: "Downloading: Story Name (67%)" with animated progress bar. *(3h)* — **Partial:** download banner shown inside offline library screen only; global bottom-nav overlay not implemented yet.

## Phase 4: Integration & Background (~9h)

- [x] **Task 10:** Player integration — `player_repository.dart` checks Hive/local files before API fetch. Resolves asset URLs to `localAudioPath` / `localIllustrationPath` for offline-available steps. Seamless online/offline switching. *(4h)*
- [ ] **Task 11:** Firestore offline config — Enable `persistenceEnabled = true` in Firestore settings. Set cache size to 100MB. *(1h)* — **Not implemented yet.**
- [ ] **Task 12:** Background downloads — `workmanager` background download tasks surviving app minimization. `flutter_local_notifications` completion notification. *(4h)* — **Package added to pubspec; implementation pending.**

## Phase 5: Management & Updates (~6h)

- [x] **Task 13:** Storage management screen — Total storage usage chip in `offline_library_screen.dart`, per-story size, individual story delete, "Delete All" button gated behind parental PIN confirmation dialog. *(3h)*
- [ ] **Task 14:** Update detection — Compare local story version with server version on app open. Show update badge on outdated stories. Trigger re-download on user action. *(3h)* — **Not implemented yet.**
