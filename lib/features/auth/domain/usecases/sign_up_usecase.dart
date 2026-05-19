import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_stories/features/auth/data/repositories/auth_repository.dart';

/// Use-case that registers a new parent account with email and password.
class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  /// Creates the Firebase Auth user and parent Firestore document.
  ///
  /// Throws [AuthException] on failure.
  Future<UserCredential> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
