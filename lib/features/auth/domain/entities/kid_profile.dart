import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain entity representing a child's reading profile.
class KidProfile {
  const KidProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarId,
    required this.avatarCustomization,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique Firestore document ID.
  final String id;

  /// Display name chosen for this profile.
  final String name;

  /// Child's age (used to filter age-appropriate stories).
  final int age;

  /// Identifier for the selected base avatar illustration.
  final String avatarId;

  /// Key/value map of avatar customization options
  /// (e.g. {'hair': 'curly', 'skin': 'medium', 'accessory': 'stars'}).
  final Map<String, String> avatarCustomization;

  /// When this profile was first created.
  final DateTime createdAt;

  /// When this profile was last modified.
  final DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Factory — Firestore
  // ---------------------------------------------------------------------------

  /// Constructs a [KidProfile] from a Firestore [DocumentSnapshot].
  factory KidProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return KidProfile(
      id: doc.id,
      name: data['name'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      avatarId: data['avatarId'] as String? ?? 'default',
      avatarCustomization:
          (data['avatarCustomization'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())) ??
              {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization — Firestore
  // ---------------------------------------------------------------------------

  /// Converts this profile to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'avatarId': avatarId,
      'avatarCustomization': avatarCustomization,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  KidProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarId,
    Map<String, String>? avatarCustomization,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KidProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarId: avatarId ?? this.avatarId,
      avatarCustomization: avatarCustomization ?? this.avatarCustomization,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KidProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'KidProfile(id: $id, name: $name, age: $age)';
}
