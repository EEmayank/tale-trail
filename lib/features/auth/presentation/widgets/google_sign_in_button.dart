import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// A pill-shaped "Continue with Google" button.
///
/// - White background with a 1 px [TaleColors.warmGrey200] border.
/// - 56 px tall, full-width.
/// - Shows a coloured "G" logo rendered with [RichText] as a placeholder
///   (no external asset required).
/// - Displays an [CircularProgressIndicator] when [isLoading] is `true`.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
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

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
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
              color: isDisabled
                  ? Colors.white.withAlpha(178)
                  : Colors.white,
              borderRadius: const BorderRadius.all(
                Radius.circular(TaleDimensions.radiusFull),
              ),
              border: Border.all(
                color: TaleColors.warmGrey200,
                width: 1,
              ),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TaleColors.warmGrey600,
                        ),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coloured "G" logo rendered via RichText.
                        _GoogleLogo(),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: tt.labelLarge?.copyWith(
                            color: TaleColors.warmGrey800,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                          ),
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

// ---------------------------------------------------------------------------
// _GoogleLogo helper widget
// ---------------------------------------------------------------------------

/// Renders a multi-coloured "G" that approximates the Google brand logo.
///
/// Uses a [CustomPainter] to draw the four-colour segmented G shape so that
/// no external SVG or image asset is needed.
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Outer circle segments (simplified four-colour arc)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    const double gap = 0.08; // radians gap between segments

    // Blue — top-right quadrant
    arcPaint.color = _blue;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      -1.5708 + gap,
      1.5708 - gap * 2,
      false,
      arcPaint,
    );

    // Red — top-left through left
    arcPaint.color = _red;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      3.1416 + gap,
      1.5708 - gap * 2,
      false,
      arcPaint,
    );

    // Yellow — bottom-left
    arcPaint.color = _yellow;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      1.5708 + gap,
      1.5708 - gap * 2,
      false,
      arcPaint,
    );

    // Green — bottom-right
    arcPaint.color = _green;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
      -gap,
      1.5708 - gap * 2,
      false,
      arcPaint,
    );

    // Horizontal bar of the "G"
    final barPaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - 0.05,
          cy - size.height * 0.115,
          r * 0.85,
          size.height * 0.23,
        ),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
