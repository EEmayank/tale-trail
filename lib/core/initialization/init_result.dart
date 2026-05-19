import 'package:kids_stories/core/navigation/app_router.dart';

/// Encapsulates the result of [AppInitializer.initialize].
///
/// All fields are determined during the parallel async initialization phase
/// and are immutable once produced.
class InitResult {
  const InitResult({
    required this.isAuthenticated,
    required this.hasActiveProfile,
    required this.isFirstLaunch,
    required this.isOffline,
    required this.initDurationMs,
    this.errorMessage,
  });

  /// Convenience constructor for catastrophic initialization failures.
  const InitResult.error(String message)
      : isAuthenticated = false,
        hasActiveProfile = false,
        isFirstLaunch = false,
        isOffline = false,
        initDurationMs = 0,
        errorMessage = message;

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Whether a valid authenticated user session was found.
  final bool isAuthenticated;

  /// Whether a previously active kid profile was successfully restored.
  final bool hasActiveProfile;

  /// Whether this is the user's first app launch (onboarding not yet seen).
  final bool isFirstLaunch;

  /// Whether the device had no network connectivity during initialization.
  final bool isOffline;

  /// Wall-clock milliseconds taken to complete all initialization steps.
  final int initDurationMs;

  /// Non-null when a fatal error prevented normal initialization.
  final String? errorMessage;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// `true` when a fatal error occurred during initialization.
  bool get hasError => errorMessage != null;

  /// Returns the initial route the app should navigate to after splash.
  ///
  /// Decision tree:
  /// 1. Fatal error           → /error
  /// 2. First launch          → /onboarding
  /// 3. Not authenticated     → /login
  /// 4. No active profile     → /profiles
  /// 5. All good              → /home
  String get initialRoute {
    if (hasError) {
      final encoded = Uri.encodeComponent(errorMessage!);
      return '${AppRoutes.error}?message=$encoded';
    }
    if (isFirstLaunch) return AppRoutes.onboarding;
    if (!isAuthenticated) return AppRoutes.login;
    if (!hasActiveProfile) return AppRoutes.profiles;
    return AppRoutes.home;
  }

  @override
  String toString() => 'InitResult('
      'isAuthenticated: $isAuthenticated, '
      'hasActiveProfile: $hasActiveProfile, '
      'isFirstLaunch: $isFirstLaunch, '
      'isOffline: $isOffline, '
      'initDurationMs: $initDurationMs, '
      'errorMessage: $errorMessage)';
}
