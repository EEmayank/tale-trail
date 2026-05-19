import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/features/story_browser/data/models/story_progress.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';

/// A full-width banner that invites the kid to continue an in-progress story.
///
/// Renders a thumbnail, title, percentage label, and a progress bar inside a
/// tappable parchment card.
class ContinueReadingBanner extends StatelessWidget {
  const ContinueReadingBanner({
    super.key,
    required this.story,
    required this.progress,
    required this.onTap,
  });

  final StorySummary story;
  final StoryProgress progress;
  final VoidCallback onTap;

  Color get _accentColor {
    final accent = story.colorAccent;
    if (accent != null) {
      try {
        final hex = accent.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return TaleColors.terracotta;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressFraction = (progress.percentComplete / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: TaleDimensions.paddingMd,
        vertical: TaleDimensions.paddingSm,
      ),
      decoration: BoxDecoration(
        color: TaleColors.parchmentDark,
        borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(TaleDimensions.paddingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(TaleDimensions.radiusSm),
                  child: SizedBox(
                    width: 60,
                    height: 80,
                    child: story.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: story.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _coverPlaceholder(),
                            errorWidget: (_, __, ___) => _coverPlaceholder(),
                          )
                        : _coverPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Continue Reading" label
                      Text(
                        'CONTINUE READING',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: TaleColors.terracotta,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Story title
                      Text(
                        story.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TaleColors.warmGrey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Progress label
                      Text(
                        'You left off ${progress.percentComplete.round()}% through',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: TaleColors.warmGrey500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 6,
                          backgroundColor: TaleColors.warmGrey200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            TaleColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Play icon
                const Icon(
                  Icons.play_circle_filled_rounded,
                  color: TaleColors.terracotta,
                  size: 36,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withAlpha(180),
            _accentColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          story.title.isNotEmpty ? story.title[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
