import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core
import 'package:kids_stories/core/navigation/go_router_refresh_stream.dart';
import 'package:kids_stories/core/providers/core_providers.dart';
import 'package:kids_stories/core/screens/error_screen.dart';
import 'package:kids_stories/core/widgets/main_app_shell.dart';
import 'package:kids_stories/core/widgets/parent_dashboard_shell.dart';

// Feature screens
import 'package:kids_stories/features/auth/presentation/providers/auth_provider.dart';
import 'package:kids_stories/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kids_stories/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:kids_stories/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:kids_stories/features/auth/presentation/screens/welcome_screen.dart';
import 'package:kids_stories/features/gamification/presentation/screens/achievements_screen.dart';
import 'package:kids_stories/features/gamification/presentation/screens/streaks_screen.dart';
import 'package:kids_stories/features/offline_library/presentation/screens/offline_library_screen.dart';
import 'package:kids_stories/features/onboarding/presentation/screens/create_kid_profile_screen.dart';
import 'package:kids_stories/features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import 'package:kids_stories/features/onboarding/presentation/screens/parental_consent_screen.dart';
import 'package:kids_stories/features/onboarding/presentation/screens/setup_pin_screen.dart';
import 'package:kids_stories/features/parent/presentation/screens/manage_profiles_screen.dart';
import 'package:kids_stories/features/parent/presentation/screens/notification_preferences_screen.dart';
import 'package:kids_stories/features/parent/presentation/screens/parental_gate_screen.dart';
import 'package:kids_stories/features/parent/presentation/screens/parent_settings_screen.dart';
import 'package:kids_stories/features/parent/presentation/screens/reading_reports_screen.dart';
import 'package:kids_stories/features/parent/presentation/screens/subscription_screen.dart';
import 'package:kids_stories/features/profile/presentation/providers/parental_gate_provider.dart';
import 'package:kids_stories/features/profile/presentation/providers/profile_provider.dart';
import 'package:kids_stories/features/profile/presentation/screens/profile_switcher_screen.dart';
import 'package:kids_stories/features/story_browser/presentation/screens/collection_detail_screen.dart';
import 'package:kids_stories/features/story_browser/presentation/screens/new_this_week_screen.dart';
import 'package:kids_stories/features/story_browser/presentation/screens/search_screen.dart';
import 'package:kids_stories/features/story_browser/presentation/screens/story_browser_screen.dart';
import 'package:kids_stories/features/story_browser/presentation/screens/story_detail_screen.dart';
import 'package:kids_stories/features/story_player/presentation/screens/story_player_screen.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  static const String root = '/';
  static const String onboarding = '/onboarding';
  static const String parentalConsent = '/onboarding/consent';
  static const String setupPin = '/onboarding/pin';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profiles = '/profiles';
  static const String addProfile = '/profiles/add';
  static const String home = '/home';
  static const String library = '/library';
  static const String achievements = '/achievements';
  static const String streaks = '/streaks';
  static const String storyDetail = '/stories/:storyId';
  static const String storyPlay = '/stories/:storyId/play';
  static const String parentGate = '/parent-gate';
  static const String parent = '/parent';
  static const String parentSettings = '/parent/settings';
  static const String parentProfiles = '/parent/profiles';
  static const String parentReports = '/parent/reports';
  static const String parentSubscription = '/parent/subscription';
  static const String parentNotifications = '/parent/notifications';
  static const String error = '/error';
  static const String newThisWeek = '/new-this-week';
  static const String search = '/search';
  static const String collectionDetail = '/collections/:collectionId';

  // Helpers
  static String storyDetailPath(String storyId) => '/stories/$storyId';
  static String storyPlayPath(String storyId) => '/stories/$storyId/play';
  static String collectionDetailPath(String id) => '/collections/$id';
}

// ---------------------------------------------------------------------------
// Transition helpers
// ---------------------------------------------------------------------------

/// 300 ms fade transition used for most route changes.
CustomTransitionPage<void> _fadeTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
        child: child,
      );
    },
  );
}

/// 600 ms slide-up transition used for immersive screens (e.g. story player).
CustomTransitionPage<void> _slideUpTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurveTween(curve: Curves.easeInOutCubic).animate(animation);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

// ---------------------------------------------------------------------------
// appRouterProvider
// ---------------------------------------------------------------------------

/// Riverpod provider that builds and exposes the [GoRouter] instance.
///
/// The router is rebuilt whenever authentication state changes (via
/// [GoRouterRefreshStream]), ensuring redirects are re-evaluated on sign-in /
/// sign-out / profile change.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();

  return GoRouter(
    initialLocation: AppRoutes.root,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(authStream),

    // -------------------------------------------------------------------------
    // Global redirect logic
    // -------------------------------------------------------------------------
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Read providers synchronously — values may still be loading.
      final authAsync = ref.read(authStateProvider);
      final isFirstLaunchAsync = ref.read(isFirstLaunchProvider);
      final activeProfile = ref.read(activeKidProfileProvider);
      final gateNotifier = ref.read(parentalGateStateProvider.notifier);

      // While auth / first-launch are still loading, stay put.
      final isLoading =
          authAsync.isLoading || isFirstLaunchAsync.isLoading;
      if (isLoading) return null;

      final user = authAsync.valueOrNull;
      final isFirstLaunch = isFirstLaunchAsync.valueOrNull ?? false;

      // 1. First launch → onboarding
      if (isFirstLaunch &&
          location != AppRoutes.onboarding &&
          location != AppRoutes.addProfile) {
        return AppRoutes.onboarding;
      }

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.onboarding;

      // 2. Not logged in → login (preserve redirect target)
      if (user == null && !isAuthRoute) {
        final redirect = Uri.encodeComponent(location);
        return '${AppRoutes.login}?redirect=$redirect';
      }

      // 3. Logged in but on an auth route → home or profiles
      if (user != null && isAuthRoute && !isFirstLaunch) {
        return activeProfile != null ? AppRoutes.home : AppRoutes.profiles;
      }

      // 4. Logged in but no active profile (and not on profiles / add-profile)
      if (user != null &&
          activeProfile == null &&
          location != AppRoutes.profiles &&
          location != AppRoutes.addProfile &&
          !isAuthRoute) {
        return AppRoutes.profiles;
      }

      // 5. Parent route without valid gate → parent gate
      final isParentRoute = location.startsWith('/parent') &&
          location != AppRoutes.parentGate;
      if (isParentRoute && !gateNotifier.checkAndRefresh()) {
        final redirect = Uri.encodeComponent(location);
        return '${AppRoutes.parentGate}?redirect=$redirect';
      }

      return null; // No redirect needed.
    },

    // -------------------------------------------------------------------------
    // Route tree
    // -------------------------------------------------------------------------
    routes: [
      // Root — handled entirely by redirect logic above.
      GoRoute(
        path: AppRoutes.root,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const WelcomeScreen(),
        ),
      ),

      // --- Auth Routes -------------------------------------------------------
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return _fadeTransition(
            context: context,
            state: state,
            child: LoginScreen(redirectTo: redirect),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // --- Profile Routes ----------------------------------------------------
      GoRoute(
        path: AppRoutes.profiles,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const KidProfileSelectorScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addProfile,
        pageBuilder: (context, state) => _slideUpTransition(
          context: context,
          state: state,
          child: const AddKidProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.parentalConsent,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const ParentalConsentScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.setupPin,
        pageBuilder: (context, state) => _slideUpTransition(
          context: context,
          state: state,
          child: const SetupPinScreen(),
        ),
      ),

      // --- Kid Context Shell (bottom nav) ------------------------------------
      ShellRoute(
        builder: (context, state, child) => MainAppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const StoryBrowserScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const OfflineLibraryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.achievements,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const AchievementsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.streaks,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const StreaksScreen(),
            ),
          ),
        ],
      ),

      // --- Story Routes (outside shell so player is full-screen) ------------
      GoRoute(
        path: AppRoutes.storyDetail,
        pageBuilder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          return _fadeTransition(
            context: context,
            state: state,
            child: StoryDetailScreen(storyId: storyId),
          );
        },
        routes: [
          GoRoute(
            path: 'play',
            pageBuilder: (context, state) {
              final storyId = state.pathParameters['storyId']!;
              return _slideUpTransition(
                context: context,
                state: state,
                child: StoryPlayerScreen(storyId: storyId),
              );
            },
          ),
        ],
      ),

      // --- Parental Gate -----------------------------------------------------
      GoRoute(
        path: AppRoutes.parentGate,
        pageBuilder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return _slideUpTransition(
            context: context,
            state: state,
            child: ParentalGateScreen(redirectTo: redirect),
          );
        },
      ),

      // --- Parent Dashboard Shell -------------------------------------------
      ShellRoute(
        builder: (context, state, child) =>
            ParentDashboardShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.parent,
            redirect: (_, __) => AppRoutes.parentSettings,
          ),
          GoRoute(
            path: AppRoutes.parentSettings,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const ParentSettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.parentProfiles,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const ManageProfilesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.parentReports,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const ReadingReportsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.parentSubscription,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const SubscriptionScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.parentNotifications,
            pageBuilder: (context, state) => _fadeTransition(
              context: context,
              state: state,
              child: const NotificationPreferencesScreen(),
            ),
          ),
        ],
      ),

      // --- Discovery Routes (no shell) --------------------------------------
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.newThisWeek,
        pageBuilder: (context, state) => _fadeTransition(
          context: context,
          state: state,
          child: const NewThisWeekScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.collectionDetail,
        pageBuilder: (context, state) {
          final collectionId = state.pathParameters['collectionId']!;
          return _fadeTransition(
            context: context,
            state: state,
            child: CollectionDetailScreen(collectionId: collectionId),
          );
        },
      ),

      // --- Error ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.error,
        pageBuilder: (context, state) {
          final message = state.uri.queryParameters['message'];
          return _fadeTransition(
            context: context,
            state: state,
            child: ErrorScreen(message: message),
          );
        },
      ),
    ],

    // Fallback error builder for unmatched routes.
    errorBuilder: (context, state) =>
        ErrorScreen(message: state.error?.message),
  );
});
