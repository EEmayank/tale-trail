import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/badge_chip.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';

/// A card widget representing a story in a horizontal browsing list.
///
/// Features:
/// - Bounce animation (scale 1.0 → 0.95) on tap via [GestureDetector].
/// - [Hero] animation keyed on `'story_cover_${story.id}'`.
/// - Shimmer placeholder while cover image loads.
/// - Premium / Free overlay chip on the cover.
/// - Optional progress bar at the very bottom.
class StoryCard extends StatefulWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.showProgress = false,
    this.progressFraction = 0.0,
  });

  final StorySummary story;
  final VoidCallback onTap;

  /// Whether to show a progress indicator at the bottom.
  final bool showProgress;

  /// Progress value in the range [0, 1]. Only used when [showProgress] is
  /// `true`.
  final double progressFraction;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  Color get _accentColor {
    final accent = widget.story.colorAccent;
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
    final accent = _accentColor;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: 150,
          height: 220,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? TaleColors.warmWhite,
            borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top 65%: cover image area
                SizedBox(
                  height: 220 * 0.65,
                  child: Hero(
                    tag: 'story_cover_${widget.story.id}',
                    child: _CoverArea(
                      story: widget.story,
                      accentColor: accent,
                    ),
                  ),
                ),

                // Bottom 35%: title + badges
                Expanded(
                  child: Container(
                    color: TaleColors.warmWhite,
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.story.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TaleColors.warmGrey900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            BadgeChip.age(widget.story.ageMin, isSmall: true),
                            BadgeChip.duration(
                              widget.story.durationMinutes,
                              isSmall: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Progress bar at very bottom (when enabled)
                if (widget.showProgress)
                  SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: widget.progressFraction.clamp(0.0, 1.0),
                      backgroundColor: TaleColors.warmGrey200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        TaleColors.terracotta,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CoverArea
// ---------------------------------------------------------------------------

class _CoverArea extends StatelessWidget {
  const _CoverArea({
    required this.story,
    required this.accentColor,
  });

  final StorySummary story;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover image or gradient fallback
        if (story.coverUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: story.coverUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => _ShimmerPlaceholder(accentColor: accentColor),
            errorWidget: (_, __, ___) => _GradientFallback(
              title: story.title,
              accentColor: accentColor,
            ),
          )
        else
          _GradientFallback(title: story.title, accentColor: accentColor),

        // Premium chip — top-right
        if (story.isPremium)
          Positioned(
            top: 6,
            right: 6,
            child: _OverlayChip(
              label: 'Premium',
              icon: Icons.star,
              backgroundColor: TaleColors.warmGoldDark,
            ),
          ),

        // FREE chip — top-right (only when not premium)
        if (story.isFree && !story.isPremium)
          Positioned(
            top: 6,
            right: 6,
            child: _OverlayChip(
              label: 'FREE',
              backgroundColor: TaleColors.terracotta,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: accentColor.withAlpha(60),
      highlightColor: accentColor.withAlpha(30),
      child: Container(color: Colors.white),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({
    required this.title,
    required this.accentColor,
  });

  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withAlpha(200),
            accentColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.label,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(TaleDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: Colors.white),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
