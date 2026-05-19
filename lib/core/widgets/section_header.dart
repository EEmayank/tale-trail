import 'package:flutter/material.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';

/// A horizontal section header with a [title] on the left and an optional
/// "See All" [TextButton] (or custom [trailing] widget) on the right.
///
/// Usage:
/// ```dart
/// SectionHeader(
///   title: 'New This Week',
///   onSeeAll: () => context.push(AppRoutes.newThisWeek),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.trailing,
  });

  /// Section heading text.
  final String title;

  /// If provided, a "See All" [TextButton] is rendered on the right that
  /// calls this callback when tapped.
  final VoidCallback? onSeeAll;

  /// Fully custom trailing widget. Takes precedence over [onSeeAll] when
  /// both are provided.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? trailingWidget = trailing;

    if (trailingWidget == null && onSeeAll != null) {
      trailingWidget = TextButton(
        onPressed: onSeeAll,
        style: TextButton.styleFrom(
          foregroundColor: TaleColors.terracotta,
          textStyle: theme.textTheme.labelMedium,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('See All'),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: 8),
          trailingWidget,
        ],
      ],
    );
  }
}
