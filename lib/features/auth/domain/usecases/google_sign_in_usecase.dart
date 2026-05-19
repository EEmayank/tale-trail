import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_stories/features/auth/data/repositories/auth_repository.dart';

/// Use-case that initiates Google OAuth sign-in and creates / updates the
/// parent document in Firestore.
class GoogleSignInUseCase {
  const GoogleSignInUseCase(this._repository);

  final AuthRepository _repository;

  /// Starts the Google sign-in flow.
  ///
  /// Throws [AuthException] if the user cancels or an error occurs.
  Future<UserCredential> call() {
    return _repository.signInWithGoogle();
  }
}
