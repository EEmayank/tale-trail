import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_provider.dart';
import 'package:kids_stories/features/story_player/data/models/story_step.dart';
import 'package:kids_stories/features/story_player/presentation/providers/audio_provider.dart';
import 'package:kids_stories/features/story_player/presentation/providers/player_provider.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/audio_controls.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/choice_buttons_panel.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/illustration_panel.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/parchment_text_panel.dart';
import 'package:kids_stories/features/story_player/presentation/widgets/progress_trail.dart';

/// Full-screen, immersive story player screen.
///
/// Layout stack (bottom → top):
///   1. [IllustrationPanel]     — top 65 % of screen height.
///   2. [ParchmentTextPanel]    — bottom 40 %, overlapping illustration.
///   3. [ProgressTrail]         — top safe-area strip.
///   4. [AudioControls]         — floating pill above parchment panel.
///   5. [ChoiceButtonsPanel]    — bottom area, revealed after audio ends.
///   6. Back button             — top-left safe-area.
///   7. Ending overlay          — full-screen, fades in on story completion.
///   8. Loading / error overlay — shown while story tree is fetching.
class StoryPlayerScreen extends ConsumerStatefulWidget {
  const StoryPlayerScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen>
    with WidgetsBindingObserver {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _parchmentExpanded = false;
  bool _showEndingOverlay = false;

  /// Key that changes each time [currentStepId] changes, driving
  /// [AnimatedSwitcher] to run the page-turn animation.
  String? _animKey;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Lock to portrait orientation for the immersive player.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Kick off story loading after first frame so providers are fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyPlayerProvider.notifier).loadStory(widget.storyId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Restore all orientations when leaving the player.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    // Stop audio cleanly.
    ref.read(audioPlayerProvider.notifier).stop();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // AppLifecycle — save progress on pause/background
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.inactive) {
      _trySaveProgress();
    }
  }

  void _trySaveProgress() {
    // We need a kidId to save progress. In the real app this would come from
    // the active kid profile provider. For now we use a placeholder that the
    // calling code would replace with the actual profile ID.
    final kidId = _resolveActiveKidId();
    if (kidId != null) {
      ref.read(storyPlayerProvider.notifier).saveProgress(kidId);
    }
  }

  String? _resolveActiveKidId() {
    // The auth state gives us the parent UID, but the active kid profile ID
    // is stored in the profile provider. We read it defensively so this screen
    // doesn't hard-depend on the profile feature.
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      return user?.uid; // Fallback: use parent UID when kid ID unavailable.
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Audio completion listener
  // ---------------------------------------------------------------------------

  /// Called from [_buildListenerLayer] when audio finishes — reveals choices.
  void _onAudioComplete() {
    final playerNotifier = ref.read(storyPlayerProvider.notifier);
    playerNotifier.revealChoices();
  }

  // ---------------------------------------------------------------------------
  // Back button behaviour
  // ---------------------------------------------------------------------------

  Future<bool> _onWillPop() async {
    final playerState = ref.read(storyPlayerProvider);

    if (playerState.isAtRoot) {
      // Ask before leaving the story from the root step.
      final leave = await _showLeaveDialog();
      return leave;
    }

    // Navigate back within the story.
    ref.read(storyPlayerProvider.notifier).goBack();
    return false; // Prevent system pop.
  }

  Future<bool> _showLeaveDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave story?'),
        content: const Text(
          'Your progress will be saved. You can continue later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep reading'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: TaleColors.terracotta,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(storyPlayerProvider);
    final audioState = ref.watch(audioPlayerProvider);

    // Detect when the current step changes to reset parchment state and
    // drive the AnimatedSwitcher key.
    final currentStepId = playerState.currentStepId;
    if (currentStepId != _animKey) {
      _animKey = currentStepId;
      _parchmentExpanded = false;
    }

    // Detect audio playback completion to auto-reveal choices.
    _listenForAudioCompletion(audioState, playerState.choicesRevealed);

    // Detect story ending.
    final isEnding = playerState.currentStep?.isEnding ?? false;
    if (isEnding && !_showEndingOverlay) {
      // Defer to avoid calling setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showEndingOverlay = true);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Illustration ──────────────────────────────────
            _buildIllustrationLayer(playerState.currentStep),

            // ── Layer 2: Parchment text panel ─────────────────────────
            _buildParchmentLayer(playerState.currentStep),

            // ── Layer 3: Progress trail ────────────────────────────────
            _buildProgressLayer(playerState),

            // ── Layer 4: Audio controls ────────────────────────────────
            _buildAudioControlsLayer(playerState),

            // ── Layer 5: Choice buttons ────────────────────────────────
            _buildChoicesLayer(playerState),

            // ── Layer 6: Back button ───────────────────────────────────
            _buildBackButton(playerState),

            // ── Layer 7: Loading / error overlay ─────────────────────
            if (playerState.isLoading || playerState.error != null)
              _buildLoadingOverlay(playerState),

            // ── Layer 8: Ending overlay ────────────────────────────────
            if (_showEndingOverlay)
              _buildEndingOverlay(playerState.currentStep),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Audio completion detection
  // ---------------------------------------------------------------------------

  bool _audioWasPlaying = false;

  void _listenForAudioCompletion(
    AudioState audioState,
    bool choicesAlreadyRevealed,
  ) {
    final isNowFinished = !audioState.isPlaying &&
        !audioState.isBuffering &&
        audioState.duration > Duration.zero &&
        audioState.position >= audioState.duration - const Duration(seconds: 1);

    if (isNowFinished && _audioWasPlaying && !choicesAlreadyRevealed) {
      _audioWasPlaying = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onAudioComplete();
      });
    }

    if (audioState.isPlaying) _audioWasPlaying = true;
  }

  // ---------------------------------------------------------------------------
  // Layer builders
  // ---------------------------------------------------------------------------

  Widget _buildIllustrationLayer(StoryStep? step) {
    final screenHeight = MediaQuery.of(context).size.height;
    final illustrationHeight = screenHeight * 0.65;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: illustrationHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: step != null
            ? IllustrationPanel(
                key: ValueKey('illustration_${step.id}'),
                illustrationUrl: step.illustrationUrl,
                localPath: step.localIllustrationPath,
                height: illustrationHeight,
              )
            : Container(
                key: const ValueKey('illustration_placeholder'),
                color: TaleColors.warmGrey200,
              ),
      ),
    );
  }

  Widget _buildParchmentLayer(StoryStep? step) {
    final screenHeight = MediaQuery.of(context).size.height;
    final parchmentHeight = screenHeight * 0.40;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: step != null
            ? Column(
                key: ValueKey('parchment_${step.id}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ParchmentTextPanel(
                    text: step.text,
                    isExpanded: _parchmentExpanded,
                    onToggle: () => setState(
                        () => _parchmentExpanded = !_parchmentExpanded),
                  ),
                  // Extra space so the parchment doesn't overlap choice buttons.
                  const SizedBox(height: 80),
                ],
              )
            : SizedBox(
                key: const ValueKey('parchment_placeholder'),
                height: parchmentHeight,
              ),
      ),
    );
  }

  Widget _buildProgressLayer(
    dynamic playerState, // StoryPlayerState
  ) {
    final totalSteps = playerState.storyTree?.totalStepCount ?? 1;
    final currentStep = playerState.stepHistory.length;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ProgressTrail(
            totalSteps: totalSteps,
            currentStep: currentStep,
            hasBranches: true,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControlsLayer(dynamic playerState) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Position AudioControls just above the parchment panel (bottom 40%).
    final bottomOffset = screenHeight * 0.40 + 12;

    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: Center(child: const AudioControls()),
    );
  }

  Widget _buildChoicesLayer(dynamic playerState) {
    final step = playerState.currentStep as StoryStep?;
    if (step == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: ChoiceButtonsPanel(
          choices: step.choices,
          isRevealed: playerState.choicesRevealed as bool,
          onChoiceSelected: (choiceId) async {
            final notifier = ref.read(storyPlayerProvider.notifier);
            await notifier.selectChoice(choiceId);
            // Save progress after each choice.
            final kidId = _resolveActiveKidId();
            if (kidId != null) {
              await notifier.saveProgress(kidId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(dynamic playerState) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: _GlassBackButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) context.pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(dynamic playerState) {
    final hasError = playerState.error != null;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(153),
        child: Center(
          child: hasError
              ? _ErrorOverlay(
                  message: playerState.error as String,
                  onRetry: () => ref
                      .read(storyPlayerProvider.notifier)
                      .loadStory(widget.storyId),
                )
              : const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(TaleColors.warmGold),
                ),
        ),
      ),
    );
  }

  Widget _buildEndingOverlay(StoryStep? endingStep) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _showEndingOverlay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TaleColors.nightNavy.withAlpha(230),
                TaleColors.nightNavy.withAlpha(250),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decorative star icon.
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: TaleColors.softGold,
                  size: 64,
                ),
                const SizedBox(height: 24),

                // Ending title (e.g. "The River Ending")
                if (endingStep?.endingTitle != null) ...[
                  Text(
                    endingStep!.endingTitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontFamily: 'Baloo2',
                        ),
                  ),
                  const SizedBox(height: 8),
                ],

                // "The End" subtitle.
                Text(
                  'The End',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: TaleColors.softGold,
                        fontStyle: FontStyle.italic,
                      ),
                ),

                const SizedBox(height: 48),

                // Action buttons.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      TaleButton(
                        label: 'Read Again',
                        isPrimary: false,
                        onPressed: () {
                          setState(() => _showEndingOverlay = false);
                          ref
                              .read(storyPlayerProvider.notifier)
                              .loadStory(widget.storyId);
                        },
                      ),
                      const SizedBox(height: 12),
                      TaleButton(
                        label: 'Back to Library',
                        isPrimary: true,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GlassBackButton
// ---------------------------------------------------------------------------

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(102),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorOverlay
// ---------------------------------------------------------------------------

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: TaleColors.warmGold,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          TaleButton(
            label: 'Try Again',
            isPrimary: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
