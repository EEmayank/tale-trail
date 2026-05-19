import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// Semi-transparent parchment-coloured panel that displays story narration text.
///
/// Features:
///   - Collapsible / expandable via the drag handle at the top centre.
///   - When collapsed: clips to 3 lines of text.
///   - When expanded: full [SingleChildScrollView] content.
///   - Background: [TaleColors.parchment] at 90 % opacity with top rounded corners.
///   - A subtle 8 × 4 px pill drag-handle is shown at the top centre.
class ParchmentTextPanel extends StatefulWidget {
  const ParchmentTextPanel({
    super.key,
    required this.text,
    required this.isExpanded,
    this.onToggle,
  });

  /// The narration text to display.
  final String text;

  /// Whether the panel is in the expanded (full-scroll) state.
  final bool isExpanded;

  /// Called when the drag handle is tapped to toggle expansion.
  final VoidCallback? onToggle;

  @override
  State<ParchmentTextPanel> createState() => _ParchmentTextPanelState();
}

class _ParchmentTextPanelState extends State<ParchmentTextPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  static const double _collapsedHeight = 120.0;
  static const double _expandedHeight = 320.0;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(ParchmentTextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final panelHeight = _collapsedHeight +
            (_expandedHeight - _collapsedHeight) * _expandAnimation.value;

        return Container(
          width: double.infinity,
          height: panelHeight,
          decoration: BoxDecoration(
            color: TaleColors.parchment.withAlpha(230), // ~90% opacity
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────
              GestureDetector(
                onTap: widget.onToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: Center(
                    child: Container(
                      width: 8 * 5, // 40px — visually a wide pill
                      height: 4,
                      decoration: BoxDecoration(
                        color: TaleColors.warmGrey400,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Text content ──────────────────────────────────────────
              Expanded(child: _buildTextContent()),

              // Bottom inset so text doesn't hide behind choice buttons.
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: TaleColors.warmGrey800,
          fontSize: 18,
          height: 1.6,
          fontFamily: 'Nunito',
        );

    if (!widget.isExpanded) {
      // Collapsed: show 3 lines with overflow clipping.
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Text(
          widget.text,
          style: textStyle,
          maxLines: 3,
          overflow: TextOverflow.fade,
        ),
      );
    }

    // Expanded: full scrollable text.
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Text(
        widget.text,
        style: textStyle,
      ),
    );
  }
}
