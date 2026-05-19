import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight model used in list/browser views.
class StorySummary {
  const StorySummary({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.description,
    required this.ageMin,
    required this.ageMax,
    required this.themes,
    required this.isFree,
    required this.isPremium,
    required this.durationMinutes,
    required this.language,
    required this.endingCount,
    required this.isNew,
    required this.isPopular,
    this.colorAccent,
  });

  final String id;
  final String title;
  final String coverUrl;
  final String description;
  final int ageMin;
  final int ageMax;
  final List<String> themes;
  final bool isFree;
  final bool isPremium;
  final int durationMinutes;

  /// Language code: 'en' or 'hi'.
  final String language;

  /// How many distinct endings this story has.
  final int endingCount;
  final bool isNew;
  final bool isPopular;

  /// Optional hex color string representing the story's visual accent (e.g. '#4A7C59').
  final String? colorAccent;

  // ---------------------------------------------------------------------------
  // JSON / Firestore
  // ---------------------------------------------------------------------------

  factory StorySummary.fromJson(Map<String, dynamic> json) {
    return StorySummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ageMin: (json['ageMin'] as num?)?.toInt() ?? 3,
      ageMax: (json['ageMax'] as num?)?.toInt() ?? 12,
      themes: (json['themes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isFree: json['isFree'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 10,
      language: json['language'] as String? ?? 'en',
      endingCount: (json['endingCount'] as num?)?.toInt() ?? 1,
      isNew: json['isNew'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      colorAccent: json['colorAccent'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'description': description,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'themes': themes,
      'isFree': isFree,
      'isPremium': isPremium,
      'durationMinutes': durationMinutes,
      'language': language,
      'endingCount': endingCount,
      'isNew': isNew,
      'isPopular': isPopular,
      'colorAccent': colorAccent,
    };
  }

  factory StorySummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return StorySummary.fromJson({...data, 'id': doc.id});
  }

  StorySummary copyWith({
    String? id,
    String? title,
    String? coverUrl,
    String? description,
    int? ageMin,
    int? ageMax,
    List<String>? themes,
    bool? isFree,
    bool? isPremium,
    int? durationMinutes,
    String? language,
    int? endingCount,
    bool? isNew,
    bool? isPopular,
    String? colorAccent,
  }) {
    return StorySummary(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      themes: themes ?? this.themes,
      isFree: isFree ?? this.isFree,
      isPremium: isPremium ?? this.isPremium,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      language: language ?? this.language,
      endingCount: endingCount ?? this.endingCount,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      colorAccent: colorAccent ?? this.colorAccent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorySummary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StorySummary(id: $id, title: $title)';
}
