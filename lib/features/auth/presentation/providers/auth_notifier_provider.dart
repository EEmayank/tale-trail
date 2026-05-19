import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/features/auth/data/repositories/auth_repository.dart';
import 'package:kids_stories/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:kids_stories/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:kids_stories/features/auth/domain/usecases/sign_up_usecase.dart';

// ---------------------------------------------------------------------------
// AuthState
// ---------------------------------------------------------------------------

/// Immutable state object for [AuthNotifier].
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  /// Whether an auth operation is currently in progress.
  final bool isLoading;

  /// User-friendly error message, or `null` when no error is present.
  final String? error;

  /// The currently authenticated Firebase [User], or `null` when signed out.
  final User? user;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    User? user,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      user: clearUser ? null : user ?? this.user,
    );
  }

  @override
  String toString() =>
      'AuthState(isLoading: $isLoading, error: $error, user: ${user?.uid})';
}

// ---------------------------------------------------------------------------
// AuthRepository provider
// ---------------------------------------------------------------------------

/// Provides the singleton [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
  name: 'authRepositoryProvider',
);

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

/// Manages all auth-related mutations: sign-up, sign-in, sign-out, etc.
///
/// Widgets should watch [authNotifierProvider] for loading / error state and
/// call methods on the notifier to trigger operations.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState()) {
    // Seed the current user synchronously from FirebaseAuth.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser);
    }
  }

  final AuthRepository _repository;

  // ---------------------------------------------------------------------------
  // Sign-up
  // ---------------------------------------------------------------------------

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final useCase = SignUpUseCase(_repository);
      final credential = await useCase(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false, user: credential.user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-in
  // ---------------------------------------------------------------------------

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final useCase = SignInUseCase(_repository);
      final credential = await useCase(email: email, password: password);
      state = state.copyWith(isLoading: false, user: credential.user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-in failed. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Google sign-in
  // ---------------------------------------------------------------------------

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final useCase = GoogleSignInUseCase(_repository);
      final credential = await useCase();
      state = state.copyWith(isLoading: false, user: credential.user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.signOut();
      state = const AuthState(); // Reset to clean state.
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-out failed. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Error management
  // ---------------------------------------------------------------------------

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ---------------------------------------------------------------------------
// authNotifierProvider
// ---------------------------------------------------------------------------

/// [StateNotifierProvider] that exposes [AuthNotifier] and [AuthState].
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    return AuthNotifier(repository);
  },
  name: 'authNotifierProvider',
);
