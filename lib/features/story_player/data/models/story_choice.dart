/// Represents a single branching choice the reader can make at a story step.
///
/// Choices appear as illustrated pill buttons at the bottom of the player
/// screen once the narration audio has completed or the user manually reveals
/// them. Selecting a choice navigates the story tree to [nextStepId].
class StoryChoice {
  const StoryChoice({
    required this.id,
    required this.label,
    required this.nextStepId,
    this.iconUrl,
    this.localIconPath,
  });

  /// Unique identifier for this choice within a step.
  final String id;

  /// Short human-readable label shown on the choice button (e.g. "Follow the river").
  final String label;

  /// The [StoryStep.id] that becomes active when this choice is selected.
  final String nextStepId;

  /// Optional remote URL pointing to an SVG icon rendered to the left of
  /// the label. When null the button renders text-only.
  final String? iconUrl;

  /// Path to a locally cached copy of the icon SVG, used when offline.
  final String? localIconPath;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory StoryChoice.fromJson(Map<String, dynamic> json) => StoryChoice(
        id: json['id'] as String,
        label: json['label'] as String,
        nextStepId: json['nextStepId'] as String,
        iconUrl: json['iconUrl'] as String?,
        localIconPath: json['localIconPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'nextStepId': nextStepId,
        if (iconUrl != null) 'iconUrl': iconUrl,
        if (localIconPath != null) 'localIconPath': localIconPath,
      };

  // ---------------------------------------------------------------------------
  // Equality / copy
  // ---------------------------------------------------------------------------

  StoryChoice copyWith({
    String? id,
    String? label,
    String? nextStepId,
    String? iconUrl,
    String? localIconPath,
  }) =>
      StoryChoice(
        id: id ?? this.id,
        label: label ?? this.label,
        nextStepId: nextStepId ?? this.nextStepId,
        iconUrl: iconUrl ?? this.iconUrl,
        localIconPath: localIconPath ?? this.localIconPath,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryChoice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          nextStepId == other.nextStepId &&
          iconUrl == other.iconUrl &&
          localIconPath == other.localIconPath;

  @override
  int get hashCode => Object.hash(id, label, nextStepId, iconUrl, localIconPath);

  @override
  String toString() =>
      'StoryChoice(id: $id, label: $label, nextStepId: $nextStepId)';
}
