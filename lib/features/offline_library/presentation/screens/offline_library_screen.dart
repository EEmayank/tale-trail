import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/offline_library/data/models/offline_story_record.dart';
import 'package:kids_stories/features/offline_library/presentation/providers/offline_library_provider.dart';

/// The "My Books" screen showing all downloaded stories.
///
/// Features:
/// - Storage usage chip in the AppBar.
/// - Empty state when no stories are downloaded.
/// - Horizontal story cards for downloaded stories.
/// - Active download banner at the top when a download is in progress.
/// - Pull-to-refresh and Delete All with parental confirmation.
class OfflineLibraryScreen extends ConsumerStatefulWidget {
  const OfflineLibraryScreen({super.key});

  @override
  ConsumerState<OfflineLibraryScreen> createState() =>
      _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends ConsumerState<OfflineLibraryScreen> {
  bool _isRefreshing = false;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM yyyy').format(dt);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    // Invalidate providers to re-read fresh Hive state.
    ref.invalidate(offlineStoriesProvider);
    ref.invalidate(storageUsageProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isRefreshing = false);
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all downloads?'),
        content: const Text(
          'All downloaded stories will be removed from your device. '
          'You can re-download them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TaleColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(downloadNotifierProvider.notifier).deleteAll();
    }
  }

  Future<void> _confirmDeleteSingle(
    BuildContext context,
    OfflineStoryRecord story,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete download?'),
        content: Text(
          '"${story.title}" will be removed from your device '
          '(${_formatBytes(story.totalSizeBytes)} freed).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TaleColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref
          .read(downloadNotifierProvider.notifier)
          .deleteDownload(story.storyId);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(offlineStoriesProvider);
    final usageBytes = ref.watch(storageUsageProvider);
    final activeDownloads = ref.watch(activeDownloadsProvider);

    // Show only complete + failed (not actively downloading ones in list).
    final displayStories = stories
        .where((s) =>
            s.downloadStatus == DownloadStatus.complete ||
            s.downloadStatus == DownloadStatus.failed)
        .toList();

    return Scaffold(
      backgroundColor: TaleColors.warmWhite,
      appBar: _buildAppBar(context, usageBytes),
      body: Column(
        children: [
          // Active downloads banner.
          if (activeDownloads.isNotEmpty)
            _ActiveDownloadBanner(downloads: activeDownloads),

          // Main content.
          Expanded(
            child: displayStories.isEmpty
                ? _buildEmptyState(context)
                : _buildStoryList(context, displayStories, usageBytes),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, int usageBytes) {
    return AppBar(
      backgroundColor: TaleColors.warmWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'My Books',
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w700,
          color: TaleColors.warmGrey900,
        ),
      ),
      actions: [
        if (usageBytes > 0)
          Padding(
            padding: const EdgeInsets.only(right: TaleDimensions.paddingMd),
            child: _StorageChip(bytes: usageBytes),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return IllustratedEmptyState(
      title: 'Your bookshelf is empty',
      subtitle: 'Download stories to read without internet',
      action: SizedBox(
        width: 200,
        child: TaleButton(
          label: 'Browse Stories',
          onPressed: () => context.go('/home'),
        ),
      ),
    );
  }

  Widget _buildStoryList(
    BuildContext context,
    List<OfflineStoryRecord> stories,
    int usageBytes,
  ) {
    return RefreshIndicator(
      color: TaleColors.terracotta,
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(TaleDimensions.paddingMd),
        children: [
          ...stories.map((story) => _StoryCard(
                key: ValueKey(story.storyId),
                story: story,
                formatDate: _formatDate,
                onPlay: () =>
                    context.push('/stories/${story.storyId}/play'),
                onDelete: () => _confirmDeleteSingle(context, story),
              )),
          const SizedBox(height: TaleDimensions.paddingXl),
          if (stories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingMd),
              child: TaleButton(
                label: 'Delete All Downloads',
                isDestructive: true,
                onPressed: () => _confirmDeleteAll(context),
              ),
            ),
          const SizedBox(height: TaleDimensions.paddingLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active download banner
// ---------------------------------------------------------------------------

class _ActiveDownloadBanner extends ConsumerWidget {
  const _ActiveDownloadBanner({required this.downloads});

  final List<OfflineStoryRecord> downloads;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = downloads.first;
    final progressAsync =
        ref.watch(downloadProgressProvider(primary.storyId));
    final progress = progressAsync.valueOrNull ?? primary.downloadProgress;
    final percent = (progress * 100).toStringAsFixed(0);

    return Container(
      color: TaleColors.terracotta.withAlpha(13),
      padding: const EdgeInsets.symmetric(
        horizontal: TaleDimensions.paddingMd,
        vertical: TaleDimensions.paddingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.downloading,
                color: TaleColors.terracotta,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Downloading ${primary.title} ($percent%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TaleColors.terracotta,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (downloads.length > 1)
                Text(
                  '+${downloads.length - 1} more',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TaleColors.warmGrey600,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: TaleColors.warmGrey200,
            color: TaleColors.terracotta,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Story card
// ---------------------------------------------------------------------------

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    super.key,
    required this.story,
    required this.formatDate,
    required this.onPlay,
    required this.onDelete,
  });

  final OfflineStoryRecord story;
  final String Function(DateTime?) formatDate;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFailed = story.downloadStatus == DownloadStatus.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: TaleDimensions.paddingMd),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
        side: isFailed
            ? const BorderSide(color: TaleColors.error, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TaleDimensions.paddingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover thumbnail.
            _CoverThumbnail(coverPath: story.coverPath),

            const SizedBox(width: TaleDimensions.paddingMd),

            // Story info.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          story.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Delete button.
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: TaleColors.error,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Delete download',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (!isFailed && story.downloadedAt != null) ...[
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: TaleColors.warmGrey500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(story.downloadedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: TaleColors.warmGrey500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!isFailed)
                        _SizeBadge(bytes: story.totalSizeBytes),
                      if (isFailed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TaleColors.error.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Download failed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: TaleColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: TaleDimensions.paddingMd),
                  // Play button.
                  if (!isFailed)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaleColors.terracotta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusFull),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: TaleDimensions.paddingMd),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Play'),
                        onPressed: onPlay,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cover thumbnail
// ---------------------------------------------------------------------------

class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({required this.coverPath});

  final String coverPath;

  @override
  Widget build(BuildContext context) {
    final hasFile = coverPath.isNotEmpty && File(coverPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TaleDimensions.radiusSm),
      child: SizedBox(
        width: 80,
        height: 100,
        child: hasFile
            ? Image.file(
                File(coverPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: TaleColors.warmGrey200,
      child: const Center(
        child: Icon(
          Icons.auto_stories,
          color: TaleColors.warmGrey400,
          size: 32,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Size badge
// ---------------------------------------------------------------------------

class _SizeBadge extends StatelessWidget {
  const _SizeBadge({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    final label = bytes < 1024 * 1024
        ? '${(bytes / 1024).toStringAsFixed(0)} KB'
        : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TaleColors.warmGrey100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: TaleColors.warmGrey600,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Storage chip
// ---------------------------------------------------------------------------

class _StorageChip extends StatelessWidget {
  const _StorageChip({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    final label = bytes < 1024 * 1024
        ? '${(bytes / 1024).toStringAsFixed(0)} KB used'
        : '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB used';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TaleColors.warmGrey100,
        borderRadius: BorderRadius.circular(TaleDimensions.radiusFull),
        border: Border.all(color: TaleColors.warmGrey300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storage_outlined,
            size: 12,
            color: TaleColors.warmGrey600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TaleColors.warmGrey700,
                ),
          ),
        ],
      ),
    );
  }
}
