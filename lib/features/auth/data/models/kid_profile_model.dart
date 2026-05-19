import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kids_stories/features/auth/domain/entities/kid_profile.dart';

/// Firestore data model that mirrors [KidProfile].
///
/// Separates persistence concerns (Firestore serialisation) from the
/// domain entity so that the domain layer has no Firestore dependency.
class KidProfileModel {
  const KidProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarId,
    required this.avatarCustomization,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int age;
  final String avatarId;
  final Map<String, String> avatarCustomization;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Factory — Firestore
  // ---------------------------------------------------------------------------

  /// Constructs a [KidProfileModel] from a Firestore [DocumentSnapshot].
  factory KidProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return KidProfileModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      avatarId: data['avatarId'] as String? ?? 'default',
      avatarCustomization:
          (data['avatarCustomization'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())) ??
              {},
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Constructs a [KidProfileModel] from a [KidProfile] domain entity.
  factory KidProfileModel.fromEntity(KidProfile profile) {
    return KidProfileModel(
      id: profile.id,
      name: profile.name,
      age: profile.age,
      avatarId: profile.avatarId,
      avatarCustomization: profile.avatarCustomization,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation — Firestore
  // ---------------------------------------------------------------------------

  /// Converts this model to a Firestore-compatible map.
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
  // Domain conversion
  // ---------------------------------------------------------------------------

  /// Converts this model to the domain [KidProfile] entity.
  KidProfile toEntity() => KidProfile(
        id: id,
        name: name,
        age: age,
        avatarId: avatarId,
        avatarCustomization: avatarCustomization,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  KidProfileModel copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarId,
    Map<String, String>? avatarCustomization,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KidProfileModel(
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
      other is KidProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'KidProfileModel(id: $id, name: $name, age: $age)';
}
