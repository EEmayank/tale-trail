/// Domain entity representing a parent / guardian account.
///
/// Instances are immutable. Use [copyWith] to derive modified copies.
class ParentUser {
  const ParentUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.authProvider,
    required this.consentGiven,
    required this.createdAt,
    required this.updatedAt,
    this.consentTimestamp,
  });

  /// Firestore document ID — matches the Firebase Auth UID.
  final String id;

  /// Parent's email address.
  final String email;

  /// Display name chosen during sign-up or pulled from Google profile.
  final String displayName;

  /// How the account was authenticated — either `'email'` or `'google'`.
  final String authProvider;

  /// Whether the parent has accepted the parental-consent / privacy policy.
  final bool consentGiven;

  /// When consent was recorded (null until [consentGiven] is true).
  final DateTime? consentTimestamp;

  /// When this document was first created.
  final DateTime createdAt;

  /// When this document was last updated.
  final DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  ParentUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? authProvider,
    bool? consentGiven,
    DateTime? consentTimestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentUser(
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

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ParentUser(id: $id, email: $email, displayName: $displayName, '
      'authProvider: $authProvider, consentGiven: $consentGiven)';
}
