import 'package:kids_stories/features/story_player/data/models/story_step.dart';

/// The complete branching story structure loaded before playback begins.
///
/// Steps are keyed by their [StoryStep.id] in a flat map so any step can be
/// retrieved in O(1) time during navigation.
class StoryTree {
  const StoryTree({
    required this.storyId,
    required this.title,
    required this.rootStepId,
    required this.steps,
    required this.totalStepCount,
    required this.version,
  });

  /// The Firestore document ID of the parent story.
  final String storyId;

  /// Human-readable story title (e.g. "The Fox and the River").
  final String title;

  /// The [StoryStep.id] that starts the story (the root node).
  final String rootStepId;

  /// All steps in the tree, keyed by [StoryStep.id] for O(1) lookup.
  final Map<String, StoryStep> steps;

  /// Total number of steps across all branches. Used to calculate reading
  /// progress percentage. This is the count of unique steps, not the longest
  /// possible path.
  final int totalStepCount;

  /// Schema / content version used for cache invalidation. Increment when the
  /// story content changes so that cached offline copies are refreshed.
  final int version;

  // ---------------------------------------------------------------------------
  // Convenience helpers
  // ---------------------------------------------------------------------------

  /// Returns the step with [id], or `null` if not found.
  StoryStep? getStep(String id) => steps[id];

  /// Convenience getter for the root step.
  StoryStep? get rootStep => steps[rootStepId];

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory StoryTree.fromJson(Map<String, dynamic> json) {
    // Steps may arrive as a List<Map> (Firestore array) or as a Map<String, Map>
    // (keyed object). Both formats are handled here.
    final rawSteps = json['steps'];
    final Map<String, StoryStep> stepsMap = {};

    if (rawSteps is Map) {
      rawSteps.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final step = StoryStep.fromJson(value);
          stepsMap[step.id] = step;
        }
      });
    } else if (rawSteps is List) {
      for (final item in rawSteps) {
        if (item is Map<String, dynamic>) {
          final step = StoryStep.fromJson(item);
          stepsMap[step.id] = step;
        }
      }
    }

    return StoryTree(
      storyId: json['storyId'] as String,
      title: json['title'] as String,
      rootStepId: json['rootStepId'] as String,
      steps: stepsMap,
      totalStepCount: (json['totalStepCount'] as num?)?.toInt() ??
          stepsMap.length,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'title': title,
        'rootStepId': rootStepId,
        'steps': {
          for (final entry in steps.entries) entry.key: entry.value.toJson(),
        },
        'totalStepCount': totalStepCount,
        'version': version,
      };

  // ---------------------------------------------------------------------------
  // Equality / copy
  // ---------------------------------------------------------------------------

  StoryTree copyWith({
    String? storyId,
    String? title,
    String? rootStepId,
    Map<String, StoryStep>? steps,
    int? totalStepCount,
    int? version,
  }) =>
      StoryTree(
        storyId: storyId ?? this.storyId,
        title: title ?? this.title,
        rootStepId: rootStepId ?? this.rootStepId,
        steps: steps ?? this.steps,
        totalStepCount: totalStepCount ?? this.totalStepCount,
        version: version ?? this.version,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryTree &&
          runtimeType == other.runtimeType &&
          storyId == other.storyId &&
          version == other.version;

  @override
  int get hashCode => Object.hash(storyId, version);

  @override
  String toString() =>
      'StoryTree(storyId: $storyId, title: $title, steps: ${steps.length}, version: $version)';
}
