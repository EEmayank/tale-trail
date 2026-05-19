import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a kid's progress through a specific story.
class StoryProgress {
  const StoryProgress({
    required this.storyId,
    required this.storyTitle,
    required this.currentStepId,
    required this.choicesMade,
    required this.stepsVisited,
    required this.percentComplete,
    required this.isComplete,
    required this.startedAt,
    required this.updatedAt,
    this.endingTitle,
    this.completedAt,
  });

  final String storyId;
  final String storyTitle;

  /// ID of the story node the kid is currently on.
  final String currentStepId;

  /// Map of stepId → choiceId for every decision made so far.
  final Map<String, String> choicesMade;

  /// Ordered list of all step IDs the kid has visited.
  final List<String> stepsVisited;

  /// 0–100 inclusive.
  final double percentComplete;

  final bool isComplete;

  /// Human-readable title of the ending reached (null if not complete).
  final String? endingTitle;

  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory StoryProgress.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return StoryProgress(
      storyId: doc.id,
      storyTitle: data['storyTitle'] as String? ?? '',
      currentStepId: data['currentStepId'] as String? ?? '',
      choicesMade: (data['choicesMade'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      stepsVisited: (data['stepsVisited'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      percentComplete: (data['percentComplete'] as num?)?.toDouble() ?? 0.0,
      isComplete: data['isComplete'] as bool? ?? false,
      endingTitle: data['endingTitle'] as String?,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storyTitle': storyTitle,
      'currentStepId': currentStepId,
      'choicesMade': choicesMade,
      'stepsVisited': stepsVisited,
      'percentComplete': percentComplete,
      'isComplete': isComplete,
      'endingTitle': endingTitle,
      'startedAt': Timestamp.fromDate(startedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (completedAt != null)
        'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  StoryProgress copyWith({
    String? storyId,
    String? storyTitle,
    String? currentStepId,
    Map<String, String>? choicesMade,
    List<String>? stepsVisited,
    double? percentComplete,
    bool? isComplete,
    String? endingTitle,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return StoryProgress(
      storyId: storyId ?? this.storyId,
      storyTitle: storyTitle ?? this.storyTitle,
      currentStepId: currentStepId ?? this.currentStepId,
      choicesMade: choicesMade ?? this.choicesMade,
      stepsVisited: stepsVisited ?? this.stepsVisited,
      percentComplete: percentComplete ?? this.percentComplete,
      isComplete: isComplete ?? this.isComplete,
      endingTitle: endingTitle ?? this.endingTitle,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryProgress &&
          runtimeType == other.runtimeType &&
          storyId == other.storyId;

  @override
  int get hashCode => storyId.hashCode;

  @override
  String toString() =>
      'StoryProgress(storyId: $storyId, percent: $percentComplete)';
}
