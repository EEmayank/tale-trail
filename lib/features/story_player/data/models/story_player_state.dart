import 'package:kids_stories/features/story_player/data/models/story_step.dart';
import 'package:kids_stories/features/story_player/data/models/story_tree.dart';

/// Immutable snapshot of the Story Player's runtime state.
///
/// All mutations return a new instance via [copyWith]. The [PlayerNotifier]
/// holds a single instance of this state and emits updated copies on every
/// state change.
class StoryPlayerState {
  const StoryPlayerState({
    this.storyTree,
    this.currentStepId,
    this.stepHistory = const [],
    this.choicesMade = const {},
    this.isLoading = false,
    this.isAudioPlaying = false,
    this.choicesRevealed = false,
    this.audioProgress = 0.0,
    this.error,
  });

  /// The complete story tree. `null` while the story is being fetched.
  final StoryTree? storyTree;

  /// The ID of the step currently being displayed. `null` before loading.
  final String? currentStepId;

  /// Ordered history of step IDs the reader has visited (excluding the
  /// current step). The last element is the step visited just before the
  /// current one. Used to implement the back-navigation gesture.
  final List<String> stepHistory;

  /// Maps each visited step ID to the choice ID the reader selected.
  /// Used to reconstruct paths and report outcomes to parents.
  final Map<String, String> choicesMade;

  /// `true` while the story tree or audio are being loaded.
  final bool isLoading;

  /// `true` while narration audio is actively playing.
  final bool isAudioPlaying;

  /// `true` once the choice buttons have been revealed (either automatically
  /// when audio ends, or manually by the reader).
  final bool choicesRevealed;

  /// Playback progress of the current audio track in the range [0.0, 1.0].
  final double audioProgress;

  /// Non-null when a recoverable error has occurred (e.g. audio load failure).
  final String? error;

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// Returns the [StoryStep] currently being displayed, or `null` if the
  /// story hasn't loaded yet or the ID resolves to nothing.
  StoryStep? get currentStep =>
      storyTree?.getStep(currentStepId ?? '');

  /// `true` when the reader is on the root step (back would leave the story).
  bool get isAtRoot => stepHistory.isEmpty;

  /// Reading progress as a percentage (0–100), based on how many steps the
  /// reader has completed relative to the total step count of the tree.
  ///
  /// This is an approximation because the total path length varies by branch.
  double get progressPercent =>
      stepHistory.length / (storyTree?.totalStepCount ?? 1) * 100;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  StoryPlayerState copyWith({
    StoryTree? storyTree,
    String? currentStepId,
    List<String>? stepHistory,
    Map<String, String>? choicesMade,
    bool? isLoading,
    bool? isAudioPlaying,
    bool? choicesRevealed,
    double? audioProgress,
    String? error,
    // Explicit nullability sentinels for nullable fields.
    bool clearStoryTree = false,
    bool clearCurrentStepId = false,
    bool clearError = false,
  }) =>
      StoryPlayerState(
        storyTree: clearStoryTree ? null : (storyTree ?? this.storyTree),
        currentStepId: clearCurrentStepId
            ? null
            : (currentStepId ?? this.currentStepId),
        stepHistory: stepHistory ?? this.stepHistory,
        choicesMade: choicesMade ?? this.choicesMade,
        isLoading: isLoading ?? this.isLoading,
        isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
        choicesRevealed: choicesRevealed ?? this.choicesRevealed,
        audioProgress: audioProgress ?? this.audioProgress,
        error: clearError ? null : (error ?? this.error),
      );

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryPlayerState &&
          runtimeType == other.runtimeType &&
          storyTree == other.storyTree &&
          currentStepId == other.currentStepId &&
          stepHistory == other.stepHistory &&
          choicesMade == other.choicesMade &&
          isLoading == other.isLoading &&
          isAudioPlaying == other.isAudioPlaying &&
          choicesRevealed == other.choicesRevealed &&
          audioProgress == other.audioProgress &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        storyTree,
        currentStepId,
        Object.hashAll(stepHistory),
        Object.hashAll(choicesMade.entries),
        isLoading,
        isAudioPlaying,
        choicesRevealed,
        audioProgress,
        error,
      );

  @override
  String toString() => 'StoryPlayerState('
      'currentStepId: $currentStepId, '
      'stepHistory: ${stepHistory.length} steps, '
      'choicesRevealed: $choicesRevealed, '
      'isLoading: $isLoading, '
      'isAudioPlaying: $isAudioPlaying, '
      'error: $error)';
}
