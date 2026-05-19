import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/features/offline_library/data/models/offline_story_record.dart';
import 'package:kids_stories/features/offline_library/presentation/providers/offline_library_provider.dart';

/// A context-aware download control button for a story card.
///
/// Renders one of three visual states based on the story's [DownloadStatus]:
///
/// - **NOT_DOWNLOADED**: Cloud + download icon with optional size estimate.
///   Tapping shows a confirmation dialog before starting the download.
/// - **DOWNLOADING**: Circular progress indicator with a cancel (X) button.
/// - **COMPLETE**: Green checkmark with the stored size. Tapping shows a
///   "Delete download?" confirmation dialog.
///
/// The button is completely self-contained — it reads and mutates provider
/// state internally.
class DownloadButton extends ConsumerWidget {
  const DownloadButton({
    super.key,
    required this.storyId,
    required this.storyTitle,
    this.estimatedSizeMb,
  });

  final String storyId;
  final String storyTitle;

  /// Optional pre-computed size estimate shown in the confirmation dialog.
  /// When `null` the repository is called to fetch the estimate.
  final double? estimatedSizeMb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(offlineStoriesProvider
        .select((list) => list.where((r) => r.storyId == storyId).firstOrNull));

    final status = record?.downloadStatus ?? DownloadStatus.notDownloaded;

    return switch (status) {
      DownloadStatus.notDownloaded || DownloadStatus.failed => _NotDownloadedButton(
          storyId: storyId,
          storyTitle: storyTitle,
          estimatedSizeMb: estimatedSizeMb,
          hasFailed: status == DownloadStatus.failed,
        ),
      DownloadStatus.downloading || DownloadStatus.paused =>
        _DownloadingButton(storyId: storyId),
      DownloadStatus.complete => _CompleteButton(
          storyId: storyId,
          storyTitle: storyTitle,
          sizeMb: record?.totalSizeMb ?? 0,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// NOT_DOWNLOADED state
// ---------------------------------------------------------------------------

class _NotDownloadedButton extends ConsumerWidget {
  const _NotDownloadedButton({
    required this.storyId,
    required this.storyTitle,
    this.estimatedSizeMb,
    required this.hasFailed,
  });

  final String storyId;
  final String storyTitle;
  final double? estimatedSizeMb;
  final bool hasFailed;

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    double sizeMb = estimatedSizeMb ?? 0;
    if (sizeMb == 0) {
      final sizeBytes =
          await ref.read(downloadRepositoryProvider).estimateSize(storyId);
      sizeMb = sizeBytes / (1024 * 1024);
    }

    if (!context.mounted) return;
    final confirmed = await _showConfirmDialog(context, sizeMb);
    if (confirmed == true && context.mounted) {
      ref.read(downloadNotifierProvider.notifier).start(storyId, storyTitle);
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, double sizeMb) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download for offline use?'),
        content: Text(
          'Size: ~${sizeMb.toStringAsFixed(0)} MB\n\n'
          'This story will be saved to your device so you can read it '
          'without internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TaleColors.terracotta,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: hasFailed ? 'Download failed — tap to retry' : 'Download',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _onTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFailed ? Icons.error_outline : Icons.cloud_download_outlined,
                color: hasFailed ? TaleColors.error : TaleColors.terracotta,
                size: 22,
              ),
              if (estimatedSizeMb != null && estimatedSizeMb! > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${estimatedSizeMb!.toStringAsFixed(0)} MB',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TaleColors.warmGrey600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DOWNLOADING state
// ---------------------------------------------------------------------------

class _DownloadingButton extends ConsumerWidget {
  const _DownloadingButton({required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(downloadProgressProvider(storyId));
    final progress = progressAsync.valueOrNull ?? 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2.5,
            color: TaleColors.terracotta,
            backgroundColor: TaleColors.warmGrey200,
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              ref.read(downloadNotifierProvider.notifier).cancel(storyId),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.close,
              size: 18,
              color: TaleColors.warmGrey600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// COMPLETE state
// ---------------------------------------------------------------------------

class _CompleteButton extends ConsumerWidget {
  const _CompleteButton({
    required this.storyId,
    required this.storyTitle,
    required this.sizeMb,
  });

  final String storyId;
  final String storyTitle;
  final double sizeMb;

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete download?'),
        content: Text(
          '"$storyTitle" will be removed from your device '
          '(${sizeMb.toStringAsFixed(1)} MB freed). '
          'You can re-download it later.',
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
      ref.read(downloadNotifierProvider.notifier).deleteDownload(storyId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _onTap(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: TaleColors.success,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              '${sizeMb.toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TaleColors.warmGrey600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
