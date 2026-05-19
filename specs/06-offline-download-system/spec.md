# Spec 6: Offline Download System

| Field | Value |
|-------|-------|
| **Feature** | Offline Download System |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #11 Offline Story Downloads, #19 Offline-First Architecture, #22 Download Size Estimation |
| **Estimated Effort** | ~53h (7 days) |

---

## Overview

Download complete story packages (audio + SVGs + story data) for offline reading. Critical for the Indian market where connectivity is unreliable. Includes download manager with progress UI, "books on a shelf" library, size estimation, and background download support.

### Acceptance Criteria

1. Download button shows estimated size before starting download.
2. Download package includes: story tree JSON + all audio MP3s + all illustrations + choice icons.
3. Progress indicator during download. "Books on a shelf" library for downloaded stories.
4. Offline playback is identical to online experience. Firestore offline persistence enabled.
5. Background downloads survive app minimization. Individual delete + "Delete All" (gated behind parental PIN).

---

## Architecture

### Local Storage

**Hive Boxes:**
- `offline_stories` — `OfflineStoryRecord`: storyId, title, coverPath, totalSizeBytes, downloadStatus, downloadProgress, version, downloadedAt
- `download_queue` — `DownloadTask`: url, localPath, fileType, status (pending/downloading/complete/failed), retryCount

**File System Layout:**
```
app_documents/
  offline_stories/
    {storyId}/
      tree.json          # Full story tree data
      audio/
        step_1.mp3
        step_2.mp3
        ...
      illustrations/
        step_1.svg
        step_2.png
        ...
      icons/
        choice_1.svg
        ...
```

### Download Flow

1. User taps download → size estimation shown
2. Confirm → story tree fetched and saved as JSON
3. Audio files queued (highest priority)
4. Illustration files queued
5. Choice icon files queued
6. All complete → mark story as available offline
7. Player checks offline storage first, uses local paths

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Hive setup | Register type adapters for OfflineStoryRecord and DownloadTask, initialize boxes | 2h |
| 2 | File datasource | Save/read/delete files in app documents. Directory size calculation. Exists check. | 3h |
| 3 | Size estimation | API provides `totalAssetSizeBytes` per story. Display human-readable (e.g., "12.4 MB"). Heuristic fallback if API field missing. | 2h |
| 4 | Download manager | Queue-based download orchestrator. Max 2 concurrent downloads. Order: tree → audio → illustrations. Resume interrupted downloads. | 10h |
| 5 | Download repository | `startDownload()`, `cancelDownload()`, `retryDownload()` using `dio` with progress callbacks | 6h |
| 6 | Offline storage repository | `getOfflineStory()`, `isDownloaded()`, `deleteDownload()`, `getStorageUsage()`, `listOfflineStories()` | 4h |
| 7 | Download button widget | 3 visual states: cloud icon + size estimate, circular progress indicator, checkmark (complete). Tap toggles start/cancel. | 4h |
| 8 | Offline library screen | "Books on a shelf" UI: illustrated wooden bookshelf SVG, book spine widgets per story, empty shelf state (sleeping fox illustration). | 6h |
| 9 | Download progress indicator | Global indicator in bottom nav: "Downloading: Story Name (67%)" with progress bar | 3h |
| 10 | Player integration | Check offline storage before API fetch. Resolve URLs to local file paths for offline stories. | 4h |
| 11 | Firestore offline config | Enable `persistenceEnabled = true`, set cache size to 100MB | 1h |
| 12 | Background downloads | `workmanager` for background task execution. Completion notification via `flutter_local_notifications`. | 4h |
| 13 | Storage management | Parent settings screen: total storage usage, per-story size, individual delete, "Delete All" (gated behind parental PIN). | 3h |
| 14 | Update detection | On app open, compare local story version with server. Show update badge if newer version available. | 3h |

### Dependencies

`hive`, `hive_flutter`, `dio`, `path_provider`, `connectivity_plus`, `workmanager`, `flutter_local_notifications`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Network loss mid-download | Pause download, auto-resume when connectivity returns. Show "Paused — waiting for network" status. |
| Insufficient disk space | Check available space before download. Show "Not enough storage" with current usage info. |
| Corrupted downloaded file | Integrity check on completion. If corrupt, delete and prompt re-download. |
| Story updated on server | Version check on app open. Show update badge. Re-download replaces old files. |
| Premium story, subscription expired | Block playback of downloaded premium stories. Keep files (in case they resubscribe). Show "Subscription required" message. |
| Very large story (>100MB) | Show Wi-Fi recommendation before download. Allow override. |
| App killed during download | `workmanager` resumes on next app open. Partial files cleaned up. |
| Multiple stories downloading | Queue system with max 2 concurrent. Show queue position for waiting downloads. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Download queue ordering. Size estimation formatting. Offline record CRUD. Version comparison. |
| **Integration** | Full download flow: estimate → download → verify files → play offline. Interrupt → resume flow. |
| **Manual** | Background download with app minimized. Network toggle during download. Storage management UI. |

---

## Effort Estimate

**Total: ~53h (7 days)**
