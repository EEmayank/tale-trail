import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// A horizontal row of dots connected by lines that visualises story progress.
///
/// - Completed dots: 8 px, [TaleColors.warmGold].
/// - Current dot: 12 px, [TaleColors.terracotta], with a soft glow shadow.
/// - Future dots: 8 px, [TaleColors.warmGrey300].
/// - Connecting lines: 2 px, colour matches the left-hand dot.
/// - When [hasBranches] is `true`, a fork icon is rendered at every other
///   step position to hint at branching paths.
/// - Scrollable horizontally when step count exceeds visible width.
/// - Fixed height of 24 px.
class ProgressTrail extends StatelessWidget {
  const ProgressTrail({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.hasBranches = false,
  });

  /// Total number of steps in the story (all branches included).
  final int totalSteps;

  /// Zero-based index of the step currently being shown.
  /// A value of 0 means the reader is on the first step.
  final int currentStep;

  /// When `true`, branch fork icons are shown at intermediate positions.
  final bool hasBranches;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Guard against degenerate inputs.
    final clampedTotal = totalSteps.clamp(1, 100);
    final clampedCurrent = currentStep.clamp(0, clampedTotal - 1);

    return SizedBox(
      height: 24,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildDots(clampedTotal, clampedCurrent),
        ),
      ),
    );
  }

  List<Widget> _buildDots(int total, int current) {
    final items = <Widget>[];

    for (int i = 0; i < total; i++) {
      final isCurrent = i == current;
      final isCompleted = i < current;

      // ── Dot ──────────────────────────────────────────────────────────────
      items.add(_StepDot(
        isCurrent: isCurrent,
        isCompleted: isCompleted,
        hasBranches: hasBranches,
        stepIndex: i,
        totalSteps: total,
      ));

      // ── Connecting line (not after the last dot) ──────────────────────────
      if (i < total - 1) {
        final lineColor =
            isCompleted ? TaleColors.warmGold : TaleColors.warmGrey300;
        items.add(_ConnectingLine(color: lineColor));
      }
    }

    return items;
  }
}

// ---------------------------------------------------------------------------
// _StepDot
// ---------------------------------------------------------------------------

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.isCurrent,
    required this.isCompleted,
    required this.hasBranches,
    required this.stepIndex,
    required this.totalSteps,
  });

  final bool isCurrent;
  final bool isCompleted;
  final bool hasBranches;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    // Branch point: render at every even intermediate step when hasBranches.
    final isBranchPoint = hasBranches &&
        stepIndex > 0 &&
        stepIndex < totalSteps - 1 &&
        stepIndex % 2 == 0;

    if (isBranchPoint && !isCurrent) {
      return _ForkIcon(isCompleted: isCompleted);
    }

    final size = isCurrent ? 12.0 : 8.0;
    final Color color;
    if (isCompleted) {
      color = TaleColors.warmGold;
    } else if (isCurrent) {
      color = TaleColors.terracotta;
    } else {
      color = TaleColors.warmGrey300;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: TaleColors.terracotta.withAlpha(102),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ConnectingLine
// ---------------------------------------------------------------------------

class _ConnectingLine extends StatelessWidget {
  const _ConnectingLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 2,
      color: color,
    );
  }
}

// ---------------------------------------------------------------------------
// _ForkIcon
// ---------------------------------------------------------------------------

class _ForkIcon extends StatelessWidget {
  const _ForkIcon({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted ? TaleColors.warmGoldDark : TaleColors.warmGrey400;

    return Icon(
      Icons.call_split_rounded,
      size: 14,
      color: color,
    );
  }
}
