import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/gamification/presentation/providers/gamification_provider.dart';

/// Full-screen celebration overlay shown when a child completes a story.
///
/// On mount:
/// 1. Launches a confetti burst.
/// 2. Calls [GamificationNotifier.recordCompletion] to persist the event and
///    unlock any newly earned achievements.
///
/// Layout (bottom-to-top z-order):
/// 1. Semi-transparent black overlay.
/// 2. [ConfettiWidget] burst from the centre.
/// 3. Animated card that slides up from the bottom.
///
/// The card contains:
/// - A "✨ The End ✨" headline.
/// - The [endingTitle].
/// - The [storyTitle] in a subtitle style.
/// - Three action buttons: Read Again, Endings explorer, Library.
class CompletionCelebration extends ConsumerStatefulWidget {
  const CompletionCelebration({
    super.key,
    required this.endingTitle,
    required this.storyTitle,
    required this.storyId,
    required this.theme,
    required this.onReadAgain,
    required this.onExplore,
    required this.onBack,
  });

  /// The ending the child reached (e.g. "The Dragon's Treasure").
  final String endingTitle;

  /// Display title of the story (e.g. "The Enchanted Forest").
  final String storyTitle;

  /// Firestore story ID — passed to [GamificationNotifier.recordCompletion].
  final String storyId;

  /// Story theme slug — passed to [GamificationNotifier.recordCompletion].
  final String theme;

  /// Called when the child taps "Read Again".
  final VoidCallback onReadAgain;

  /// Called when the child taps "Endings" to explore alternate paths.
  final VoidCallback onExplore;

  /// Called when the child taps "Library" to return to the home screen.
  final VoidCallback onBack;

  @override
  ConsumerState<CompletionCelebration> createState() =>
      _CompletionCelebrationState();
}

class _CompletionCelebrationState
    extends ConsumerState<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // ---- Confetti ----
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    )..play();

    // ---- Slide-up animation ----
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _slideController.forward();

    // ---- Record completion (best-effort; errors are swallowed by notifier) ----
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationNotifierProvider.notifier).recordCompletion(
            storyId: widget.storyId,
            theme: widget.theme,
            endingTitle: widget.endingTitle,
          );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // ---- Layer 1: dark overlay ----
        const ModalBarrier(
          color: Colors.black54,
          dismissible: false,
        ),

        // ---- Layer 2: confetti ----
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            shouldLoop: false,
            colors: const [
              TaleColors.terracotta,
              TaleColors.warmGold,
              TaleColors.success,
              TaleColors.info,
            ],
            emissionFrequency: 0.1,
            gravity: 0.3,
          ),
        ),

        // ---- Layer 3: celebration card ----
        Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildCard(context, theme),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card content
  // ---------------------------------------------------------------------------

  Widget _buildCard(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: TaleColors.parchment,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Headline
              Text(
                '✨ The End ✨',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'Baloo2',
                  color: TaleColors.terracotta,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Ending title
              Text(
                widget.endingTitle,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Story title subtitle
              Text(
                '"${widget.storyTitle}"',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: TaleColors.warmGrey500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Read Again
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onReadAgain,
                      style: TextButton.styleFrom(
                        foregroundColor: TaleColors.terracotta,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay, size: 20),
                          SizedBox(height: 2),
                          Text('Read\nAgain', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),

                  // Explore endings
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onExplore,
                      style: TextButton.styleFrom(
                        foregroundColor: TaleColors.terracotta,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fork_right, size: 20),
                          SizedBox(height: 2),
                          Text('Endings', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),

                  // Back to library
                  Expanded(
                    child: TaleButton(
                      onPressed: widget.onBack,
                      label: 'Library',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
