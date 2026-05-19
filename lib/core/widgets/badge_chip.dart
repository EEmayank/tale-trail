import 'package:flutter/material.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';

/// A compact pill-shaped chip used for metadata badges (age rating, duration,
/// subscription tier, etc.).
///
/// Named constructors cover the most common variants:
/// - [BadgeChip.age]      — e.g. "Ages 4–6"
/// - [BadgeChip.duration] — e.g. "12 min"
/// - [BadgeChip.free]     — "Free" badge
/// - [BadgeChip.premium]  — "Premium" badge with gold colour
class BadgeChip extends StatelessWidget {
  const BadgeChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.isSmall = false,
  });

  // ---------------------------------------------------------------------------
  // Named constructors
  // ---------------------------------------------------------------------------

  /// Shows the child's target age range: "Ages [age]–[age+2]".
  factory BadgeChip.age(int age, {bool isSmall = false}) => BadgeChip(
        label: 'Ages $age–${age + 2}',
        color: TaleColors.forestGreen,
        icon: const Icon(Icons.child_care, size: 12),
        isSmall: isSmall,
      );

  /// Shows a reading duration: "[minutes] min".
  factory BadgeChip.duration(int minutes, {bool isSmall = false}) => BadgeChip(
        label: '$minutes min',
        color: TaleColors.oceanBlue,
        icon: const Icon(Icons.schedule, size: 12),
        isSmall: isSmall,
      );

  /// "Free" tier indicator.
  factory BadgeChip.free({bool isSmall = false}) => BadgeChip(
        label: 'Free',
        color: TaleColors.success,
        isSmall: isSmall,
      );

  /// "Premium" tier indicator.
  factory BadgeChip.premium({bool isSmall = false}) => BadgeChip(
        label: 'Premium',
        color: TaleColors.warmGoldDark,
        icon: const Icon(Icons.star, size: 12),
        isSmall: isSmall,
      );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Text displayed inside the chip.
  final String label;

  /// Background colour (defaults to warmGrey300 when null).
  final Color? color;

  /// Optional leading icon widget.
  final Widget? icon;

  /// When `true` reduces padding for use in dense lists.
  final bool isSmall;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? TaleColors.warmGrey300).withAlpha(30);
    final fg = color ?? TaleColors.warmGrey700;
    final hPad = isSmall ? 6.0 : 10.0;
    final vPad = isSmall ? 2.0 : 4.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
        border: Border.all(color: fg.withAlpha(80), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(color: fg, size: isSmall ? 10 : 12),
                child: icon!,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontSize: isSmall ? 10 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
