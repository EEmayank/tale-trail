import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';

/// A centred empty-state widget that can show a Lottie animation or SVG
/// illustration alongside a title, optional subtitle, and an optional
/// action widget (e.g. a [TaleButton]).
///
/// Provide either [lottieAsset] or [svgAsset] — if both are given, the Lottie
/// animation takes precedence. If neither is provided only the text is shown.
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.svgAsset,
    this.lottieAsset,
    this.action,
  });

  /// Primary heading shown below the illustration.
  final String title;

  /// Optional supporting text shown below [title].
  final String? subtitle;

  /// Path to an SVG asset (e.g. `'assets/svg/empty_library.svg'`).
  final String? svgAsset;

  /// Path to a Lottie JSON asset (e.g. `'assets/animations/empty.json'`).
  ///
  /// Takes precedence over [svgAsset] when both are supplied.
  final String? lottieAsset;

  /// Optional widget (e.g. a button) rendered below the subtitle.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            if (lottieAsset != null)
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  lottieAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 200),
                ),
              )
            else if (svgAsset != null)
              SizedBox(
                height: 200,
                child: SvgPicture.asset(
                  svgAsset!,
                  fit: BoxFit.contain,
                ),
              ),

            if (lottieAsset != null || svgAsset != null)
              const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: TaleColors.warmGrey500,
                ),
              ),
            ],

            // Action
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
