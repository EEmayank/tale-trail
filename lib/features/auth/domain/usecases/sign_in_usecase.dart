import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_stories/features/auth/data/repositories/auth_repository.dart';

/// Use-case that signs in an existing parent with email and password.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  /// Authenticates the user with Firebase Auth.
  ///
  /// Throws [AuthException] on failure.
  Future<UserCredential> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
