import 'package:flutter/material.dart';

import 'package:kids_stories/features/story_player/data/models/story_choice.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/illustrated_choice_button.dart';

/// Animated panel displaying the available story choices.
///
/// - Hidden (height 0) when [isRevealed] is `false`.
/// - When [isRevealed] becomes `true`, each button slides up from an offset
///   of 40 px with a stagger of 80 ms between consecutive buttons, scaling
///   from 0.9 → 1.0 with [Curves.elasticOut] for a playful spring feel.
/// - Tracks the locally selected choice to highlight it.
class ChoiceButtonsPanel extends StatefulWidget {
  const ChoiceButtonsPanel({
    super.key,
    required this.choices,
    required this.onChoiceSelected,
    required this.isRevealed,
  });

  /// The choices to display, in order.
  final List<StoryChoice> choices;

  /// Called with the selected choice's ID when the reader taps a button.
  final void Function(String choiceId) onChoiceSelected;

  /// When `false` the panel occupies no vertical space. When `true` buttons
  /// animate into view with a staggered entrance.
  final bool isRevealed;

  @override
  State<ChoiceButtonsPanel> createState() => _ChoiceButtonsPanelState();
}

class _ChoiceButtonsPanelState extends State<ChoiceButtonsPanel>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];

  String? _selectedChoiceId;

  static const Duration _stagger = Duration(milliseconds: 80);
  static const Duration _itemDuration = Duration(milliseconds: 600);
  static const double _slideStartOffset = 40.0; // logical px

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    if (widget.isRevealed) _triggerEntrance();
  }

  void _buildAnimations() {
    for (int i = 0; i < widget.choices.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: _itemDuration,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 1), // will be scaled in build via LayoutBuilder
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );

      final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );

      _controllers.add(controller);
      _slideAnimations.add(slide);
      _scaleAnimations.add(scale);
    }
  }

  Future<void> _triggerEntrance() async {
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].reset();
      await Future<void>.delayed(_stagger * i);
      if (!mounted) return;
      _controllers[i].forward();
    }
  }

  void _resetAnimations() {
    for (final c in _controllers) {
      c.reset();
    }
    _selectedChoiceId = null;
  }

  @override
  void didUpdateWidget(ChoiceButtonsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Rebuild animations if choices count changed.
    if (widget.choices.length != oldWidget.choices.length) {
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers.clear();
      _slideAnimations.clear();
      _scaleAnimations.clear();
      _buildAnimations();
    }

    if (widget.isRevealed && !oldWidget.isRevealed) {
      _selectedChoiceId = null;
      _triggerEntrance();
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _resetAnimations();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: widget.isRevealed && widget.choices.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Convert the 40 px logical offset to fractional (required by
                  // SlideTransition which uses fractional box offsets).
                  // We use a FractionalTranslation-equivalent via Transform.translate.
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < widget.choices.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _AnimatedChoiceItem(
                          controller: _controllers[i],
                          scaleAnimation: _scaleAnimations[i],
                          slideOffsetPx: _slideStartOffset,
                          child: IllustratedChoiceButton(
                            choice: widget.choices[i],
                            isSelected:
                                _selectedChoiceId == widget.choices[i].id,
                            onTap: () {
                              setState(() {
                                _selectedChoiceId = widget.choices[i].id;
                              });
                              widget.onChoiceSelected(widget.choices[i].id);
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedChoiceItem
// ---------------------------------------------------------------------------

class _AnimatedChoiceItem extends StatelessWidget {
  const _AnimatedChoiceItem({
    required this.controller,
    required this.scaleAnimation,
    required this.slideOffsetPx,
    required this.child,
  });

  final AnimationController controller;
  final Animation<double> scaleAnimation;
  final double slideOffsetPx;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        // Interpolate slide offset: start at +slideOffsetPx, end at 0.
        // Elastic out: the controller value goes from 0 → 1 (may overshoot).
        final yOffset = slideOffsetPx * (1.0 - t.clamp(0.0, 1.0));

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scaleAnimation.value.clamp(0.0, 1.5),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
