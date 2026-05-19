import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/features/story_player/data/models/story_choice.dart';

/// A pill-shaped choice button with an optional SVG icon and debounce
/// protection to prevent accidental double-taps.
///
/// - Unselected: [TaleColors.warmGold] background, [TaleColors.terracottaLight] border.
/// - Selected: [TaleColors.terracotta] solid background, white text.
/// - Height: 56 px; border radius: 100 (full pill).
/// - Haptic feedback: [HapticFeedback.lightImpact] on each accepted tap.
/// - Debounce: taps within 600 ms of the previous accepted tap are ignored.
class IllustratedChoiceButton extends StatefulWidget {
  const IllustratedChoiceButton({
    super.key,
    required this.choice,
    required this.onTap,
    this.isSelected = false,
  });

  /// The choice data this button represents.
  final StoryChoice choice;

  /// Called when the button is tapped (subject to debounce).
  final VoidCallback onTap;

  /// When `true` the button renders in its selected / confirmed visual state.
  final bool isSelected;

  @override
  State<IllustratedChoiceButton> createState() =>
      _IllustratedChoiceButtonState();
}

class _IllustratedChoiceButtonState extends State<IllustratedChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  DateTime? _lastTapTime;
  static const Duration _debounceDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 130),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gesture callbacks
  // ---------------------------------------------------------------------------

  void _handleTapDown(TapDownDetails _) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _scaleController.reverse();
    _tryInvoke();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  void _tryInvoke() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _debounceDuration) {
      return; // Debounced — ignore.
    }
    _lastTapTime = now;
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    final backgroundColor =
        isSelected ? TaleColors.terracotta : TaleColors.warmGold;
    final borderColor =
        isSelected ? TaleColors.terracotta : TaleColors.terracottaLight;
    final labelColor =
        isSelected ? Colors.white : TaleColors.warmGrey800;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: TaleColors.terracotta.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Optional icon ──────────────────────────────────────────
              if (widget.choice.iconUrl != null) ...[
                _ChoiceIcon(
                  url: widget.choice.iconUrl!,
                  localPath: widget.choice.localIconPath,
                  color: labelColor,
                ),
                const SizedBox(width: 10),
              ],

              // ── Label ─────────────────────────────────────────────────
              Flexible(
                child: Text(
                  widget.choice.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: labelColor,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChoiceIcon
// ---------------------------------------------------------------------------

class _ChoiceIcon extends StatelessWidget {
  const _ChoiceIcon({
    required this.url,
    required this.color,
    this.localPath,
  });

  final String url;
  final String? localPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;

    if (localPath != null) {
      return SvgPicture.asset(
        localPath!,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return SvgPicture.network(
      url,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.star_rounded, size: size, color: color),
      ),
    );
  }
}
