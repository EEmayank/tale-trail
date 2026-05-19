import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// A pill-shaped elevated button used throughout TaleTrail.
///
/// Features:
/// - **Full-width** by default, 56 px tall.
/// - **Bounce animation** — scales down to 0.96 on tap, back to 1.0 on release.
/// - Three mutually exclusive visual variants:
///   - [isPrimary] (default) — terracotta background, white text.
///   - [isDestructive]       — error-red background, white text.
///   - Neither               — secondary/outlined style using the theme's
///                             secondary colour.
/// - [isLoading]             — replaces the label with [CircularProgressIndicator.adaptive].
class TaleButton extends StatefulWidget {
  const TaleButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isPrimary = true,
    this.isDestructive = false,
  });

  /// Callback invoked when the button is tapped (ignored while [isLoading]).
  final VoidCallback? onPressed;

  /// Button label text.
  final String label;

  /// Optional leading icon widget.
  final Widget? icon;

  /// When `true` a loading spinner replaces the label and the button is
  /// non-interactive.
  final bool isLoading;

  /// Primary style — terracotta background.
  final bool isPrimary;

  /// Destructive style — error-red background.
  final bool isDestructive;

  @override
  State<TaleButton> createState() => _TaleButtonState();
}

class _TaleButtonState extends State<TaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gesture callbacks
  // ---------------------------------------------------------------------------

  void _onTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onPressed == null) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    if (!widget.isLoading && widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  void _onTapCancel() => _controller.reverse();

  // ---------------------------------------------------------------------------
  // Styling helpers
  // ---------------------------------------------------------------------------

  Color _resolveBackgroundColor(BuildContext context) {
    if (widget.isDestructive) return TaleColors.error;
    if (widget.isPrimary) return TaleColors.terracotta;
    return Theme.of(context).colorScheme.secondary;
  }

  Color _resolveForegroundColor(BuildContext context) {
    if (widget.isDestructive || widget.isPrimary) return Colors.white;
    return Theme.of(context).colorScheme.onSecondary;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bgColor = _resolveBackgroundColor(context);
    final fgColor = _resolveForegroundColor(context);
    final isDisabled = widget.isLoading || widget.onPressed == null;

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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDisabled ? bgColor.withAlpha(153) : bgColor,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          IconTheme(
                            data: IconThemeData(color: fgColor, size: 20),
                            child: widget.icon!,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: fgColor),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
