import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// Three staggered bouncing dots that indicate narration audio is playing.
///
/// Each dot animates vertically from 0 → −8 px → 0 with a 150 ms stagger
/// between dots. The animation runs indefinitely while [isPlaying] is `true`
/// and fades out (with [AnimatedOpacity]) when audio stops.
class SpeakingIndicator extends StatefulWidget {
  const SpeakingIndicator({
    super.key,
    required this.isPlaying,
    this.color,
  });

  /// When `true` the dots bounce. When `false` they are invisible.
  final bool isPlaying;

  /// Dot colour. Defaults to [TaleColors.terracotta].
  final Color? color;

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with TickerProviderStateMixin {
  static const int _dotCount = 3;
  static const Duration _period = Duration(milliseconds: 600);
  static const Duration _stagger = Duration(milliseconds: 150);
  static const double _bounceHeight = 8.0;
  static const double _dotSize = 8.0;

  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    if (widget.isPlaying) _startAll();
  }

  void _buildAnimations() {
    for (int i = 0; i < _dotCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: _period,
      );

      final animation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: -_bounceHeight)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: -_bounceHeight, end: 0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(controller);

      _controllers.add(controller);
      _animations.add(animation);
    }
  }

  Future<void> _startAll() async {
    for (int i = 0; i < _dotCount; i++) {
      await Future<void>.delayed(_stagger * i);
      if (!mounted) return;
      _controllers[i].repeat();
    }
  }

  void _stopAll() {
    for (final c in _controllers) {
      c.stop();
      c.reset();
    }
  }

  @override
  void didUpdateWidget(SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAll();
      } else {
        _stopAll();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? TaleColors.terracotta;

    return AnimatedOpacity(
      opacity: widget.isPlaying ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        height: _bounceHeight + _dotSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_dotCount, (i) {
            return Padding(
              padding: EdgeInsets.only(left: i > 0 ? 4.0 : 0.0),
              child: AnimatedBuilder(
                animation: _animations[i],
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, _animations[i].value),
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
