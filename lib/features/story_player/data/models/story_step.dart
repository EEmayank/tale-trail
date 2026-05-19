import 'package:kids_stories/features/story_player/data/models/story_choice.dart';

/// A single node in the interactive story tree.
///
/// Each step has narration text, an illustration, an audio track, and zero
/// or more choices that branch the narrative. Steps with [isEnding] set to
/// `true` are leaf nodes — no further choices are presented and the ending
/// overlay is shown instead.
class StoryStep {
  const StoryStep({
    required this.id,
    this.title,
    required this.text,
    required this.illustrationUrl,
    required this.audioUrl,
    required this.choices,
    this.isEnding = false,
    this.endingTitle,
    this.localIllustrationPath,
    this.localAudioPath,
  });

  /// Unique identifier for this step within its [StoryTree].
  final String id;

  /// Optional short title displayed above the narration text.
  final String? title;

  /// Narration text rendered inside the parchment panel.
  final String text;

  /// Remote URL for the illustration. May be an SVG (`.svg`) or a raster image.
  final String illustrationUrl;

  /// Remote URL for the narration audio track (MP3 / AAC / OGG).
  final String audioUrl;

  /// Ordered list of choices available to the reader after this step.
  /// Empty for ending steps.
  final List<StoryChoice> choices;

  /// When `true` this step is a story ending — no choices are shown and the
  /// ending overlay is presented.
  final bool isEnding;

  /// Decorative title displayed on the ending overlay (e.g. "The Brave Ending").
  /// Only meaningful when [isEnding] is `true`.
  final String? endingTitle;

  /// Absolute path to a locally cached copy of the illustration.
  /// Used when the device is offline.
  final String? localIllustrationPath;

  /// Absolute path to a locally cached copy of the audio file.
  /// Used when the device is offline.
  final String? localAudioPath;

  // ---------------------------------------------------------------------------
  // Convenience helpers
  // ---------------------------------------------------------------------------

  /// Whether the step has at least one choice available.
  bool get hasChoices => choices.isNotEmpty;

  /// Whether a local illustration is available for offline playback.
  bool get hasLocalIllustration => localIllustrationPath != null;

  /// Whether a local audio track is available for offline playback.
  bool get hasLocalAudio => localAudioPath != null;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory StoryStep.fromJson(Map<String, dynamic> json) {
    // Choices may be stored as a List or may be absent (ending steps).
    final rawChoices = json['choices'];
    final List<StoryChoice> choices;
    if (rawChoices is List) {
      choices = rawChoices
          .cast<Map<String, dynamic>>()
          .map(StoryChoice.fromJson)
          .toList();
    } else {
      choices = const [];
    }

    return StoryStep(
      id: json['id'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      illustrationUrl: json['illustrationUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      choices: choices,
      isEnding: (json['isEnding'] as bool?) ?? false,
      endingTitle: json['endingTitle'] as String?,
      localIllustrationPath: json['localIllustrationPath'] as String?,
      localAudioPath: json['localAudioPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        'text': text,
        'illustrationUrl': illustrationUrl,
        'audioUrl': audioUrl,
        'choices': choices.map((c) => c.toJson()).toList(),
        'isEnding': isEnding,
        if (endingTitle != null) 'endingTitle': endingTitle,
        if (localIllustrationPath != null)
          'localIllustrationPath': localIllustrationPath,
        if (localAudioPath != null) 'localAudioPath': localAudioPath,
      };

  // ---------------------------------------------------------------------------
  // Equality / copy
  // ---------------------------------------------------------------------------

  StoryStep copyWith({
    String? id,
    String? title,
    String? text,
    String? illustrationUrl,
    String? audioUrl,
    List<StoryChoice>? choices,
    bool? isEnding,
    String? endingTitle,
    String? localIllustrationPath,
    String? localAudioPath,
  }) =>
      StoryStep(
        id: id ?? this.id,
        title: title ?? this.title,
        text: text ?? this.text,
        illustrationUrl: illustrationUrl ?? this.illustrationUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        choices: choices ?? this.choices,
        isEnding: isEnding ?? this.isEnding,
        endingTitle: endingTitle ?? this.endingTitle,
        localIllustrationPath:
            localIllustrationPath ?? this.localIllustrationPath,
        localAudioPath: localAudioPath ?? this.localAudioPath,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryStep &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StoryStep(id: $id, title: $title, isEnding: $isEnding, choices: ${choices.length})';
}
