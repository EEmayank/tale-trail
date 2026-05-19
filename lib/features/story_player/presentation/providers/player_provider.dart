import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kids_stories/features/story_player/data/models/story_player_state.dart';
import 'package:kids_stories/features/story_player/data/repositories/player_repository.dart';
import 'package:kids_stories/features/story_player/presentation/providers/audio_provider.dart';

// ---------------------------------------------------------------------------
// PlayerNotifier
// ---------------------------------------------------------------------------

/// StateNotifier that drives the interactive story player.
///
/// Responsibilities:
///   - Loading story trees from [PlayerRepository].
///   - Handling choice selection and back navigation.
///   - Revealing choices after audio playback completes.
///   - Triggering audio loads via [AudioNotifier].
///   - Persisting progress to Firestore.
class PlayerNotifier extends StateNotifier<StoryPlayerState> {
  PlayerNotifier(this._ref)
      : _repository = PlayerRepository(),
        super(const StoryPlayerState());

  final Ref _ref;
  final PlayerRepository _repository;

  // Completion callback registered by the screen.
  VoidCallback? _onEndingReached;

  /// Registers a callback invoked when an ending step is reached.
  void setEndingCallback(VoidCallback callback) {
    _onEndingReached = callback;
  }

  // ---------------------------------------------------------------------------
  // Load story
  // ---------------------------------------------------------------------------

  /// Fetches the story tree for [storyId] and sets the initial (root) step.
  ///
  /// Emits an [isLoading] state while the fetch is in progress. On success,
  /// immediately loads audio for the root step.
  Future<void> loadStory(String storyId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCurrentStepId: true,
      clearStoryTree: true,
      stepHistory: const [],
      choicesMade: const {},
      choicesRevealed: false,
      audioProgress: 0.0,
    );

    try {
      final tree = await _repository.fetchStoryTree(storyId);
      final rootStep = tree.rootStep;

      if (rootStep == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Story structure is invalid: root step not found.',
        );
        return;
      }

      state = state.copyWith(
        storyTree: tree,
        currentStepId: tree.rootStepId,
        isLoading: false,
        stepHistory: const [],
        choicesMade: const {},
        choicesRevealed: false,
        audioProgress: 0.0,
        clearError: true,
      );

      _loadAudioForCurrentStep();
    } catch (e, stack) {
      debugPrint('[PlayerNotifier] loadStory error: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load story. Please check your connection.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Choice selection
  // ---------------------------------------------------------------------------

  /// Records the reader's choice and advances to the next step.
  ///
  /// [choiceId] must be the ID of one of the current step's choices.
  Future<void> selectChoice(String choiceId) async {
    final currentStep = state.currentStep;
    if (currentStep == null) return;

    // Find the selected choice.
    final choice = currentStep.choices
        .where((c) => c.id == choiceId)
        .firstOrNull;
    if (choice == null) {
      debugPrint('[PlayerNotifier] Choice "$choiceId" not found in current step.');
      return;
    }

    // Update history, choices map, and advance to new step.
    final newHistory = [...state.stepHistory, currentStep.id];
    final newChoices = {...state.choicesMade, currentStep.id: choiceId};

    state = state.copyWith(
      stepHistory: newHistory,
      choicesMade: newChoices,
      currentStepId: choice.nextStepId,
      choicesRevealed: false,
      audioProgress: 0.0,
      clearError: true,
    );

    // Load audio for the new step.
    _loadAudioForCurrentStep();

    // Check for ending.
    final newStep = state.currentStep;
    if (newStep != null && newStep.isEnding) {
      await _handleEnding(kidId: null);
    }
  }

  // ---------------------------------------------------------------------------
  // Back navigation
  // ---------------------------------------------------------------------------

  /// Navigates back to the previous step by popping [stepHistory].
  ///
  /// Does nothing if already at the root step.
  void goBack() {
    if (state.isAtRoot) return;

    final history = List<String>.from(state.stepHistory);
    final previousStepId = history.removeLast();

    // Remove the choice that led to the current step.
    final newChoices = Map<String, String>.from(state.choicesMade);
    newChoices.remove(previousStepId);

    state = state.copyWith(
      stepHistory: history,
      choicesMade: newChoices,
      currentStepId: previousStepId,
      choicesRevealed: false,
      audioProgress: 0.0,
      clearError: true,
    );

    _loadAudioForCurrentStep();
  }

  // ---------------------------------------------------------------------------
  // Reveal choices
  // ---------------------------------------------------------------------------

  /// Marks choices as revealed so [ChoiceButtonsPanel] becomes visible.
  ///
  /// Called either automatically when audio finishes or manually by the reader
  /// tapping the narration panel.
  void revealChoices() {
    if (state.choicesRevealed) return;
    if (state.currentStep?.isEnding ?? false) return;
    state = state.copyWith(choicesRevealed: true);
  }

  // ---------------------------------------------------------------------------
  // Save progress
  // ---------------------------------------------------------------------------

  /// Persists the current state to Firestore for the given [kidId].
  Future<void> saveProgress(String kidId) async {
    final storyId = state.storyTree?.storyId;
    if (storyId == null) return;

    await _repository.saveProgress(storyId, kidId, state);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _loadAudioForCurrentStep() {
    final step = state.currentStep;
    if (step == null) return;

    final audioNotifier = _ref.read(audioPlayerProvider.notifier);

    if (step.localAudioPath != null) {
      audioNotifier.loadLocalAndPlay(step.localAudioPath!);
    } else if (step.audioUrl.isNotEmpty) {
      audioNotifier.loadAndPlay(step.audioUrl);
    }
  }

  /// Handles story completion: saves progress with [isComplete] = `true` and
  /// fires the registered ending callback.
  Future<void> _handleEnding({required String? kidId}) async {
    if (kidId != null) {
      await saveProgress(kidId);
    }
    _onEndingReached?.call();
  }

  /// Called by the screen when a choice is selected so progress auto-saves.
  Future<void> selectChoiceAndSave(String choiceId, String kidId) async {
    await selectChoice(choiceId);
    await saveProgress(kidId);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Global StateNotifierProvider for the story player.
///
/// A single instance is maintained for the lifetime of the app.
/// The screen must call [PlayerNotifier.loadStory] in its [initState].
final storyPlayerProvider =
    StateNotifierProvider<PlayerNotifier, StoryPlayerState>((ref) {
  return PlayerNotifier(ref);
});
