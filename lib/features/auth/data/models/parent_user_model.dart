import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kids_stories/features/auth/domain/entities/parent_user.dart';

/// Firestore data model for [ParentUser].
///
/// Handles serialisation between the domain entity and the raw Firestore
/// document format (using [Timestamp] for all date fields).
class ParentUserModel extends ParentUser {
  const ParentUserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.authProvider,
    required super.consentGiven,
    required super.createdAt,
    required super.updatedAt,
    super.consentTimestamp,
  });

  // ---------------------------------------------------------------------------
  // Factory — Firestore
  // ---------------------------------------------------------------------------

  /// Constructs a [ParentUserModel] from a Firestore [DocumentSnapshot].
  factory ParentUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ParentUserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      authProvider: data['authProvider'] as String? ?? 'email',
      consentGiven: data['consentGiven'] as bool? ?? false,
      consentTimestamp:
          (data['consentTimestamp'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation — Firestore
  // ---------------------------------------------------------------------------

  /// Converts this model to a Firestore-compatible map.
  ///
  /// Date fields are stored as [Timestamp] objects so that Firestore can index
  /// and query them correctly.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'authProvider': authProvider,
      'consentGiven': consentGiven,
      if (consentTimestamp != null)
        'consentTimestamp': Timestamp.fromDate(consentTimestamp!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ---------------------------------------------------------------------------
  // Domain conversion
  // ---------------------------------------------------------------------------

  /// Returns the underlying [ParentUser] domain entity.
  ParentUser toEntity() => ParentUser(
        id: id,
        email: email,
        displayName: displayName,
        authProvider: authProvider,
        consentGiven: consentGiven,
        consentTimestamp: consentTimestamp,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  // ---------------------------------------------------------------------------
  // CopyWith override (keeps concrete type)
  // ---------------------------------------------------------------------------

  @override
  ParentUserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? authProvider,
    bool? consentGiven,
    DateTime? consentTimestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      authProvider: authProvider ?? this.authProvider,
      consentGiven: consentGiven ?? this.consentGiven,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
