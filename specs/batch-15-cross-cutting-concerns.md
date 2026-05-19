# SPEC BATCH 15: Cross-Cutting Concerns & Integration (Post-MVP)

> TaleTrail Feature Specifications | Batch 15 of 15 (Final Batch)
> Produced: 2026-05-18 | Status: Draft
> Tech Stack: Flutter (Riverpod), Node.js (Firebase Cloud Functions), Firestore, Firebase Storage, flutter_svg + Lottie, Strapi v4

---

## Batch Overview

This final batch addresses the foundational cross-cutting concerns that span every feature in TaleTrail. These are not user-facing features in the traditional sense — they are the architectural skeleton that all user-facing features depend on. Navigation, initialization, theming, dependency injection, and CI/CD are typically built incrementally as the app grows, but specifying them here ensures consistency and prevents ad-hoc decisions that accumulate into technical debt.

| # | Item | Effort | Nature |
|---|------|--------|--------|
| 1 | Navigation Architecture | M | App-wide routing, deep linking, route guards |
| 2 | App Initialization Flow | M | Startup sequence, edge case handling |
| 3 | Theming Foundation | M | Themes, fonts, colors, reusable components |
| 4 | Dependency Injection | S | Riverpod provider organization |
| 5 | CI/CD Pipeline | L | Build, test, deploy automation |

---

## Item 1: Navigation Architecture

### A. Overview & Purpose

**What:** A comprehensive GoRouter-based navigation system for TaleTrail defining every route in the application, deep linking support for push notification targets and marketing URLs, and guard middleware that enforces authentication state, parental gate verification, and subscription entitlements before granting access to protected routes.

**Why:** TaleTrail has three distinct user contexts — unauthenticated visitors (onboarding/auth screens), kids (story browsing and playing), and parents (dashboard, settings, purchases). Each context has different access rules. Without a centralized navigation architecture, access control logic scatters across individual screens, leading to inconsistent enforcement and security holes. Deep linking is required for push notifications (Feature 31, 53) to route users directly to specific stories, and for future marketing campaigns.

GoRouter is the Flutter team's recommended routing solution, offering declarative route definitions, nested navigation, redirect-based guards, and deep link handling — all requirements for TaleTrail.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B1.1 | Unauthenticated user | When I open the app for the first time, I see the onboarding flow, then the login/signup screen. I cannot access any other screens. | Must |
| B1.2 | Authenticated parent | After logging in, I am routed to the kid profile selector if I have kid profiles, or to the "add first kid" screen if I do not. | Must |
| B1.3 | Kid (profile selected) | After selecting my profile, I land on the story browser. I can navigate to story details, the story player, and the offline library. I cannot access parent settings or purchase screens. | Must |
| B1.4 | Parent | When I tap the parent dashboard icon and pass the parental gate (PIN/math challenge), I can access settings, account management, subscription, and reading reports. | Must |
| B1.5 | Parent | If my subscription has expired, I can still browse free stories but am redirected to the subscription screen when trying to access premium content. | Must |
| B1.6 | Any user | When I tap a push notification for a new story, the app opens directly to that story's detail screen, even if the app was killed. | Must |
| B1.7 | Any user | If I follow a deep link `taletrail.app/story/abc123`, the app opens to that story's detail screen after any required auth checks. | Should |
| B1.8 | Developer | All routes are defined in a single file. Adding a new screen requires only adding a route entry and optionally a guard. | Must |
| B1.9 | Kid | Pressing the back button from the story browser exits the app (or shows "Are you sure?"). It does not go back to the login screen. | Must |

**Functional Requirements:**

1. All routes are defined declaratively in a single `AppRouter` configuration.
2. Three redirect guards execute in order: AuthGuard, ParentalGateGuard, SubscriptionGuard.
3. Auth guard redirects unauthenticated users to `/login` for any protected route.
4. Parental gate guard requires PIN verification before accessing `/parent/**` routes.
5. Subscription guard checks entitlement before accessing `/stories/:id/play` for premium stories.
6. Deep links follow the pattern `https://taletrail.app/{path}` and `taletrail://{path}`.
7. The back button on the root screen (story browser) shows an exit confirmation for kids, not a back navigation to auth screens.
8. Route transitions use custom page transitions matching TaleTrail's animation guidelines (400-800ms, easeInOutCubic).

### C. Technical Design & Architecture

**Package dependency:**

```yaml
dependencies:
  go_router: ^14.0.0
```

**Route tree:**

```
/                          → Redirects based on auth/profile state
├── /onboarding            → OnboardingScreen (first launch only)
├── /login                 → LoginScreen
├── /signup                → SignupScreen
├── /forgot-password       → ForgotPasswordScreen
│
├── /profiles              → KidProfileSelectorScreen (auth required)
├── /profiles/add          → AddKidProfileScreen (auth required)
│
├── /home                  → StoryBrowserScreen (auth + profile required)
│   ├── /home/new          → NewThisWeekScreen
│   └── /home/collection/:collectionId → CollectionDetailScreen
│
├── /stories/:storyId      → StoryDetailScreen (auth + profile required)
├── /stories/:storyId/play → StoryPlayerScreen (auth + profile + subscription check)
│
├── /library               → OfflineLibraryScreen (auth + profile required)
│
├── /achievements          → AchievementsScreen (auth + profile required)
├── /streaks               → StreaksScreen (auth + profile required)
│
├── /parent                → ParentDashboardShell (auth + parental gate required)
│   ├── /parent/settings   → ParentSettingsScreen
│   ├── /parent/profiles   → ManageProfilesScreen
│   ├── /parent/reports    → ReadingReportsScreen
│   ├── /parent/subscription → SubscriptionScreen
│   └── /parent/notifications → NotificationPreferencesScreen
│
└── /error                 → ErrorScreen (404, generic errors)
```

**Router configuration:**

```dart
// lib/core/navigation/app_router.dart

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final activeProfile = ref.watch(activeKidProfileProvider);
  final isFirstLaunch = ref.watch(isFirstLaunchProvider);
  final parentalGateState = ref.watch(parentalGateStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(
      authState.whenData((s) => s).asStream(),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final hasProfile = activeProfile.valueOrNull != null;
      final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation.startsWith('/forgot-password');
      final isOnParentRoute = state.matchedLocation.startsWith('/parent');

      // Guard 1: First launch → onboarding
      if (isFirstLaunch.valueOrNull == true && state.matchedLocation == '/') {
        return '/onboarding';
      }

      // Guard 2: Not logged in → login (unless already on auth route)
      if (!isLoggedIn && !isOnAuthRoute) {
        return '/login?redirect=${state.matchedLocation}';
      }

      // Guard 3: Logged in but on auth route → redirect to home or profiles
      if (isLoggedIn && isOnAuthRoute) {
        return hasProfile ? '/home' : '/profiles';
      }

      // Guard 4: Logged in but no profile selected → profile selector
      if (isLoggedIn && !hasProfile && !isOnAuthRoute &&
          !state.matchedLocation.startsWith('/profiles')) {
        return '/profiles';
      }

      // Guard 5: Parent route requires parental gate
      if (isOnParentRoute && parentalGateState.valueOrNull != true) {
        return '/parent-gate?redirect=${state.matchedLocation}';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),

      // --- Auth routes ---
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // --- Profile routes ---
      GoRoute(
        path: '/profiles',
        builder: (context, state) => const KidProfileSelectorScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddKidProfileScreen(),
          ),
        ],
      ),

      // --- Main app (kid context) ---
      ShellRoute(
        builder: (context, state, child) => MainAppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const StoryBrowserScreen(),
              transitionsBuilder: _fadeTransition,
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewThisWeekScreen(),
              ),
              GoRoute(
                path: 'collection/:collectionId',
                builder: (context, state) => CollectionDetailScreen(
                  collectionId: state.pathParameters['collectionId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const OfflineLibraryScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/streaks',
            builder: (context, state) => const StreaksScreen(),
          ),
        ],
      ),

      // --- Story routes ---
      GoRoute(
        path: '/stories/:storyId',
        builder: (context, state) => StoryDetailScreen(
          storyId: state.pathParameters['storyId']!,
        ),
        routes: [
          GoRoute(
            path: 'play',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: StoryPlayerScreen(
                storyId: state.pathParameters['storyId']!,
              ),
              transitionsBuilder: _slideUpTransition,
              transitionDuration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),

      // --- Parent gate ---
      GoRoute(
        path: '/parent-gate',
        builder: (context, state) => ParentalGateScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),

      // --- Parent dashboard ---
      ShellRoute(
        builder: (context, state, child) => ParentDashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/parent',
            redirect: (_, __) => '/parent/settings',
          ),
          GoRoute(
            path: '/parent/settings',
            builder: (context, state) => const ParentSettingsScreen(),
          ),
          GoRoute(
            path: '/parent/profiles',
            builder: (context, state) => const ManageProfilesScreen(),
          ),
          GoRoute(
            path: '/parent/reports',
            builder: (context, state) => const ReadingReportsScreen(),
          ),
          GoRoute(
            path: '/parent/subscription',
            builder: (context, state) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/parent/notifications',
            builder: (context, state) => const NotificationPreferencesScreen(),
          ),
        ],
      ),

      // --- Error ---
      GoRoute(
        path: '/error',
        builder: (context, state) => ErrorScreen(
          message: state.uri.queryParameters['message'],
        ),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(
      message: 'Page not found: ${state.matchedLocation}',
    ),
  );
});

// Custom transitions
Widget _fadeTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
    child: child,
  );
}

Widget _slideUpTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
    child: child,
  );
}
```

**Subscription guard (inline in story play route):**

```dart
// Inside StoryPlayerScreen build or init
final story = ref.watch(storyProvider(storyId)).valueOrNull;
final subscription = ref.watch(subscriptionStateProvider).valueOrNull;

if (story != null && story.isPremium && subscription?.isActive != true) {
  // Show paywall bottom sheet instead of playing
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showSubscriptionPaywall(context, storyId: storyId);
  });
}
```

**Deep link configuration:**

```xml
<!-- Android: android/app/src/main/AndroidManifest.xml -->
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="taletrail.app" />
  <data android:scheme="taletrail" android:host="" />
</intent-filter>
```

```xml
<!-- iOS: ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>taletrail</string>
    </array>
  </dict>
</array>
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

**Firebase Dynamic Links replacement (App Links / Universal Links):**

Since Firebase Dynamic Links is deprecated, use native App Links (Android) and Universal Links (iOS):

- Host an `assetlinks.json` at `https://taletrail.app/.well-known/assetlinks.json` for Android.
- Host an `apple-app-site-association` at `https://taletrail.app/.well-known/apple-app-site-association` for iOS.

### D. Data Models & Schema

**No Firestore schema changes.** Navigation is a client-side concern.

**State models:**

```dart
// Auth state — already exists from Feature 1
// Provided by: authStateProvider (StreamProvider<User?>)

// Active kid profile — already exists from Feature 4
// Provided by: activeKidProfileProvider (StateProvider<KidProfile?>)

// Parental gate state
class ParentalGateState {
  final bool isVerified;
  final DateTime? verifiedAt;
  final Duration gateTimeout; // Re-verify after this duration (default: 15 min)

  bool get isExpired =>
    verifiedAt == null ||
    DateTime.now().difference(verifiedAt!) > gateTimeout;

  bool get isActive => isVerified && !isExpired;
}

// First launch detection
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasLaunchedBefore') != true;
});
```

**Route parameter types:**

| Route | Parameters | Source |
|-------|-----------|--------|
| `/stories/:storyId` | `storyId: String` | Path parameter |
| `/stories/:storyId/play` | `storyId: String` | Path parameter |
| `/home/collection/:collectionId` | `collectionId: String` | Path parameter |
| `/login?redirect=` | `redirect: String?` | Query parameter |
| `/parent-gate?redirect=` | `redirect: String?` | Query parameter |
| `/error?message=` | `message: String?` | Query parameter |

### E. UI/UX Specification

**Navigation shell structure:**

The main app (kid context) uses a `ShellRoute` with a bottom navigation bar:

```
┌──────────────────────────────────────────────┐
│                                              │
│                                              │
│            [Current Screen]                  │
│                                              │
│                                              │
├──────────────────────────────────────────────┤
│  🏠 Home    📚 Library    ⭐ Me    👤 Parent │
│                                              │
└──────────────────────────────────────────────┘
```

| Tab | Route | Icon | Label |
|-----|-------|------|-------|
| Home | `/home` | Custom SVG house | Home |
| Library | `/library` | Custom SVG bookshelf | My Books |
| Me | `/achievements` | Custom SVG star | Me |
| Parent | triggers parental gate, then `/parent/settings` | Custom SVG lock | Parent |

- Bottom nav uses custom SVG icons matching the hand-drawn storybook aesthetic (not Material icons).
- Active tab icon is filled/colored with the primary brand color. Inactive icons are outlined, gray.
- Bottom nav is hidden in the story player (full-screen immersive experience).
- The "Parent" tab is visually distinct (smaller, different style) to signal it is not a kid feature.

**Transition animations:**

| Navigation | Transition | Duration |
|------------|-----------|----------|
| Tab switch (Home ↔ Library ↔ Me) | Cross-fade | 300ms |
| Story browser → Story detail | Shared element (cover image) + slide up | 500ms |
| Story detail → Story player | Full slide up from bottom | 600ms |
| Any → Parent dashboard | Fade through (after parental gate) | 400ms |
| Back navigation | Reverse of forward transition | Same as forward |
| Deep link landing | Fade in | 300ms |

**Back button behavior:**

| Current Screen | Back Button Action |
|----------------|-------------------|
| Story Browser (home tab) | Show "Exit TaleTrail?" dialog with illustrated fox waving goodbye |
| Offline Library tab | Switch to Home tab |
| Me/Achievements tab | Switch to Home tab |
| Story Detail | Pop to Story Browser |
| Story Player | Show "Leave story? Your progress is saved." dialog, then pop to Story Detail |
| Parent Dashboard | Pop to previous kid screen |
| Login / Signup | System back (exit app) |

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T1.1 | Redirect: unauthenticated user accessing `/home` | Redirect to `/login?redirect=/home` |
| T1.2 | Redirect: authenticated user accessing `/login` | Redirect to `/home` (or `/profiles` if no active profile) |
| T1.3 | Redirect: authenticated user without profile accessing `/home` | Redirect to `/profiles` |
| T1.4 | Redirect: accessing `/parent/settings` without parental gate | Redirect to `/parent-gate?redirect=/parent/settings` |
| T1.5 | Redirect: first launch accessing `/` | Redirect to `/onboarding` |
| T1.6 | No redirect: authenticated user with profile accessing `/home` | No redirect (null) |
| T1.7 | Parental gate expires after timeout | `isActive` returns false after 15 minutes |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T1.8 | Bottom navigation renders 4 tabs | Four tab items found |
| T1.9 | Tapping "Library" tab navigates to `/library` | Route changes to `/library` |
| T1.10 | Bottom nav hidden on story player screen | Bottom nav not in widget tree when on `/stories/:id/play` |
| T1.11 | Back button on home shows exit dialog | Dialog appears with confirmation |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T1.12 | Deep link `taletrail://stories/abc123` opens story detail | StoryDetailScreen renders with storyId `abc123` |
| T1.13 | Deep link with unauthenticated user | Redirects to login, then to story detail after login |
| T1.14 | Push notification tap navigates to correct story | Story detail screen appears after notification tap |
| T1.15 | Full navigation flow: launch → login → profiles → home → story → play → back → home | Each screen renders correctly; transitions are smooth |

**Manual QA checklist:**

- [ ] Every route in the route tree is reachable via its intended user flow.
- [ ] No route is accessible without proper authentication.
- [ ] Parent routes always require parental gate verification.
- [ ] Deep links work on both Android and iOS from a fresh app kill state.
- [ ] Back button never navigates from kid context to auth screens.
- [ ] Transition animations feel smooth and match the specified durations.
- [ ] Bottom navigation state is preserved when switching tabs (scroll position, etc.).
- [ ] Story player is full-screen with no bottom nav.

---

## Item 2: App Initialization Flow

### A. Overview & Purpose

**What:** The ordered startup sequence that executes every time TaleTrail launches, from the moment the native splash screen is displayed to the moment the user sees their first interactive screen. This sequence handles Firebase initialization, authentication state restoration, Remote Config fetching, active profile loading, offline state detection, and routing to the correct initial screen based on the resolved state.

**Why:** A mobile app's cold start is the most fragile moment in the user experience. TaleTrail depends on Firebase Auth, Firestore, Firebase Storage, Remote Config, and Crashlytics — all of which must initialize before the app can function. If any of these fail (network timeout, expired token, corrupted cache), the user must still see a graceful experience, not a blank screen or crash. The initialization flow must handle at minimum 6 distinct edge cases: first launch, returning user with active session, returning user with expired session, offline first launch (impossible — must have network for initial auth), offline returning user (should work), and Firebase init failure.

**Success metric:** App cold start to interactive screen in under 3 seconds on a mid-range device (Snapdragon 665, 4GB RAM) with a stable network connection.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B2.1 | Any user | When I open the app, I see the animated splash screen (Feature 14a) while the app initializes. I never see a blank white screen. | Must |
| B2.2 | Returning user | When I open the app, my login is remembered and I go directly to the profile selector (or story browser if I last had a profile active). | Must |
| B2.3 | Returning user (offline) | When I open the app without internet, I can still access my offline library and resume downloaded stories. | Must |
| B2.4 | New user (first launch) | When I open the app for the first time, I see the onboarding screens after the splash animation. | Must |
| B2.5 | Returning user (expired session) | If my auth token has expired and I'm online, the app silently refreshes it. If it cannot refresh (e.g., account deleted), I am redirected to login with a message. | Must |
| B2.6 | Any user | If Firebase fails to initialize (extremely rare), I see a friendly error screen with a "Retry" button, not a crash. | Must |
| B2.7 | Developer | The initialization sequence is observable — each step logs to Crashlytics for debugging cold-start issues. | Should |

**Functional Requirements:**

1. The native splash screen (launch storyboard on iOS, splash theme on Android) is displayed by the OS while the Flutter engine loads.
2. Once Flutter renders its first frame, the animated Lottie splash (Feature 14a) takes over.
3. While the Lottie splash plays (minimum 2 seconds for animation, maximum 5 seconds total), the initialization sequence executes in the background.
4. If initialization completes before the minimum splash duration, the splash continues playing until the minimum time elapses.
5. If initialization takes longer than 5 seconds, a subtle "Still loading..." text appears below the splash animation.
6. Initialization steps execute in the order specified in Section C, with each step's success/failure determining subsequent steps.
7. The resolved state determines the initial route per the navigation architecture (Item 1).

### C. Technical Design & Architecture

**Initialization sequence:**

```
┌──────────────────────────────────────────────┐
│                 APP LAUNCH                    │
│                                              │
│  1. Native Splash (OS-level)                 │
│     └── Flutter engine loading               │
│                                              │
│  2. Flutter First Frame                      │
│     └── Show Lottie splash animation         │
│     └── Start init sequence in parallel      │
│                                              │
│  3. Firebase.initializeApp()                 │
│     ├── SUCCESS → continue                   │
│     └── FAILURE → show error screen + retry  │
│                                              │
│  4. Firebase Crashlytics init                │
│     └── (non-blocking, fire-and-forget)      │
│                                              │
│  5. Firebase Auth state check                │
│     ├── User exists (token valid) → continue │
│     ├── User exists (token expired)          │
│     │   ├── Online → silent refresh → cont.  │
│     │   └── Offline → use cached data → cont.│
│     └── No user → mark as unauthenticated    │
│                                              │
│  6. Remote Config fetch                      │
│     ├── Online → fetch + activate            │
│     └── Offline → use cached/defaults        │
│     (non-blocking: timeout after 3s, use     │
│      cached values on timeout)               │
│                                              │
│  7. Load active kid profile (if auth'd)      │
│     ├── Last active profile in SharedPrefs   │
│     │   └── Verify exists in Firestore/cache │
│     └── No last profile → null               │
│                                              │
│  8. Check first launch flag                  │
│     └── SharedPreferences: 'hasLaunchedBefore'│
│                                              │
│  9. Resolve initial route                    │
│     ├── First launch → /onboarding           │
│     ├── Not auth'd → /login                  │
│     ├── Auth'd + no profile → /profiles      │
│     ├── Auth'd + profile → /home             │
│     └── Error → /error                       │
│                                              │
│  10. Dismiss splash → Navigate to route      │
│      (cross-fade, 400ms)                     │
│                                              │
└──────────────────────────────────────────────┘
```

**Implementation:**

```dart
// lib/core/initialization/app_initializer.dart

class AppInitializer {
  final Ref ref;

  AppInitializer(this.ref);

  Future<InitResult> initialize() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Step 3: Firebase core init
      _log('Firebase init starting');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _log('Firebase init complete');

      // Step 4: Crashlytics (non-blocking)
      unawaited(
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode),
      );

      // Steps 5, 6, 7, 8 can partially parallelize
      final results = await Future.wait([
        _checkAuthState(),        // Step 5
        _fetchRemoteConfig(),     // Step 6
        _loadActiveProfile(),     // Step 7 (depends on auth, but can start)
        _checkFirstLaunch(),      // Step 8
      ].map((f) => f.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Init step timed out'),
      )));

      final authResult = results[0] as AuthInitResult;
      final remoteConfigOk = results[1] as bool;
      final profileResult = results[2] as KidProfile?;
      final isFirstLaunch = results[3] as bool;

      stopwatch.stop();
      _log('Init complete in ${stopwatch.elapsedMilliseconds}ms');

      return InitResult(
        isAuthenticated: authResult.isAuthenticated,
        hasActiveProfile: profileResult != null,
        isFirstLaunch: isFirstLaunch,
        isOffline: authResult.isOffline,
        initDurationMs: stopwatch.elapsedMilliseconds,
      );
    } on FirebaseException catch (e) {
      _log('Firebase init failed: $e');
      return InitResult.error('Unable to start TaleTrail. Please try again.');
    } on TimeoutException {
      _log('Init timed out');
      return InitResult.error('Loading is taking longer than usual. Please check your connection.');
    } catch (e) {
      _log('Init failed: $e');
      return InitResult.error('Something went wrong. Please try again.');
    }
  }

  Future<AuthInitResult> _checkAuthState() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      return AuthInitResult(isAuthenticated: false, isOffline: false);
    }

    try {
      // Attempt to get a fresh ID token (validates session)
      await user.getIdToken(true);
      return AuthInitResult(isAuthenticated: true, isOffline: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        // Offline but have cached credentials — allow access
        return AuthInitResult(isAuthenticated: true, isOffline: true);
      }
      // Token refresh failed (e.g., account disabled/deleted)
      await auth.signOut();
      return AuthInitResult(isAuthenticated: false, isOffline: false);
    }
  }

  Future<bool> _fetchRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 3),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(<String, dynamic>{
        'parallax_enabled': true,
        'bedtime_mode_enabled': true,
        'max_offline_stories': 10,
        'content_refresh_interval_hours': 6,
      });
      await remoteConfig.fetchAndActivate();
      return true;
    } catch (e) {
      // Non-critical: use defaults/cached values
      _log('Remote Config fetch failed, using defaults: $e');
      return false;
    }
  }

  Future<KidProfile?> _loadActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final lastProfileId = prefs.getString('lastActiveProfileId');
    if (lastProfileId == null) return null;

    try {
      // Try Firestore first, fall back to local cache
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('kid_profiles')
          .doc(lastProfileId)
          .get(const GetOptions(source: Source.cache));

      if (doc.exists) {
        final profile = KidProfile.fromFirestore(doc);
        ref.read(activeKidProfileProvider.notifier).state = profile;
        return profile;
      }
    } catch (e) {
      _log('Profile load failed: $e');
    }
    return null;
  }

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasLaunchedBefore') != true;
  }

  void _log(String message) {
    debugPrint('[AppInit] $message');
    FirebaseCrashlytics.instance.log('[AppInit] $message');
  }
}

class InitResult {
  final bool isAuthenticated;
  final bool hasActiveProfile;
  final bool isFirstLaunch;
  final bool isOffline;
  final int initDurationMs;
  final String? errorMessage;

  InitResult({
    this.isAuthenticated = false,
    this.hasActiveProfile = false,
    this.isFirstLaunch = false,
    this.isOffline = false,
    this.initDurationMs = 0,
    this.errorMessage,
  });

  factory InitResult.error(String message) => InitResult(errorMessage: message);

  bool get hasError => errorMessage != null;

  String get initialRoute {
    if (hasError) return '/error?message=${Uri.encodeComponent(errorMessage!)}';
    if (isFirstLaunch) return '/onboarding';
    if (!isAuthenticated) return '/login';
    if (!hasActiveProfile) return '/profiles';
    return '/home';
  }
}
```

**Splash screen controller:**

```dart
// lib/core/initialization/splash_controller.dart

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showLoadingText = false;
  InitResult? _initResult;
  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    _runInit();
    _startMinSplashTimer();
    _startMaxSplashTimer();
  }

  void _runInit() async {
    final initializer = AppInitializer(ref);
    _initResult = await initializer.initialize();
    _tryNavigate();
  }

  void _startMinSplashTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      _minSplashElapsed = true;
      _tryNavigate();
    });
  }

  void _startMaxSplashTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_initResult == null) {
        setState(() => _showLoadingText = true);
      }
    });
  }

  void _tryNavigate() {
    if (_initResult != null && _minSplashElapsed) {
      context.go(_initResult!.initialRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Lottie splash animation (Feature 14a)
          Center(
            child: Lottie.asset(
              'assets/animations/splash.json',
              fit: BoxFit.cover,
            ),
          ),
          // "Still loading..." text (appears after 5s)
          if (_showLoadingText)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Text(
                'Still loading...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### D. Data Models & Schema

**No Firestore schema changes.** Initialization reads existing data structures.

**Local storage keys (SharedPreferences):**

| Key | Type | Purpose |
|-----|------|---------|
| `hasLaunchedBefore` | bool | Determines first launch vs. returning user |
| `lastActiveProfileId` | String? | Persists last selected kid profile for quick restore |
| `lastRemoteConfigFetch` | int (epoch ms) | Tracks when Remote Config was last fetched |

**Remote Config keys (with defaults):**

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `parallax_enabled` | bool | true | Kill switch for parallax (Feature 49) |
| `bedtime_mode_enabled` | bool | true | Kill switch for bedtime mode (Feature 34) |
| `max_offline_stories` | int | 10 | Maximum stories downloadable for offline |
| `content_refresh_interval_hours` | int | 6 | How often to re-fetch story list from Firestore |
| `force_update_min_version` | String | "1.0.0" | Force update if app version is below this |
| `maintenance_mode` | bool | false | Shows maintenance screen if true |

### E. UI/UX Specification

**Splash screen timeline:**

```
0ms                    2000ms              5000ms         Variable
 │                       │                    │              │
 ├── Lottie plays ──────►├── Can navigate ──►├── Show      │
 │   (min splash)        │   if init done    │   "Still    │
 │                       │                    │   loading"  │
 │                       │                    │              │
 └── Init runs ─────────────────────────────────────────────┘
     in background
```

**Edge case screens:**

| Condition | Screen | Visual |
|-----------|--------|--------|
| Firebase init failure | Error screen | Illustrated character looking confused; "We're having trouble starting TaleTrail. Please check your connection and try again." + [Retry] button |
| Maintenance mode (Remote Config) | Maintenance screen | Illustrated character painting/building; "TaleTrail is getting a fresh coat of paint! We'll be back shortly." |
| Force update required | Update screen | Illustrated character holding a gift; "A new adventure awaits! Update TaleTrail to continue." + [Update] button (links to store) |
| Init timeout (>10s) | Timeout screen | Illustrated character lost in fog; "This is taking a while. Check your internet connection." + [Retry] button |

Each error screen follows the "Illustrated Empty States" design pattern from Feature 14c — every state tells a mini-story.

**Transition from splash to first screen:**

A 400ms cross-fade from the Lottie splash to the resolved first screen. The splash animation freezes on its last frame during the fade to prevent jarring movement.

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T2.1 | `InitResult.initialRoute` for first launch | `/onboarding` |
| T2.2 | `InitResult.initialRoute` for unauthenticated returning user | `/login` |
| T2.3 | `InitResult.initialRoute` for authenticated user without profile | `/profiles` |
| T2.4 | `InitResult.initialRoute` for authenticated user with profile | `/home` |
| T2.5 | `InitResult.initialRoute` for error state | `/error?message=...` |
| T2.6 | Auth state check with valid token resolves successfully | `isAuthenticated == true` |
| T2.7 | Auth state check with network error resolves as offline-authenticated | `isAuthenticated == true, isOffline == true` |
| T2.8 | Auth state check with invalid/revoked token signs out | `isAuthenticated == false` |
| T2.9 | Remote Config fetch failure returns false but does not throw | Returns `false`, no exception |
| T2.10 | Remote Config defaults are set before fetch attempt | Defaults accessible immediately |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T2.11 | Cold start with valid session: measure time from launch to home screen | < 3 seconds on target device |
| T2.12 | Cold start with no internet, previously logged in | App starts; navigates to home; offline library accessible |
| T2.13 | Cold start with no internet, never logged in | App starts; navigates to login; shows offline message |
| T2.14 | Cold start, first ever launch | Splash → onboarding flow |
| T2.15 | Cold start, account was deleted server-side | Auth refresh fails; user redirected to login |
| T2.16 | Cold start with `maintenance_mode: true` in Remote Config | Maintenance screen displayed |
| T2.17 | Cold start with `force_update_min_version` > current app version | Update screen displayed |

**Performance tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T2.18 | Firebase init time (isolated) | < 500ms |
| T2.19 | Auth state check time (valid token, online) | < 1000ms |
| T2.20 | Remote Config fetch time (online) | < 3000ms (with 3s timeout) |
| T2.21 | Total init time (all steps, online) | < 3000ms on mid-range device |
| T2.22 | Total init time (all steps, offline) | < 2000ms (no network calls except cached) |

**Manual QA checklist:**

- [ ] Splash animation plays smoothly from cold start.
- [ ] No white/blank screen flash before splash appears.
- [ ] "Still loading..." text appears after 5 seconds if init is slow.
- [ ] Killing network mid-init does not crash the app.
- [ ] Returning user goes directly to home (not login) on app reopen.
- [ ] First launch user sees onboarding, not login.
- [ ] After onboarding completes, `hasLaunchedBefore` is set and future launches skip onboarding.
- [ ] Transition from splash to first screen is a smooth cross-fade, not a hard cut.

---

## Item 3: Theming Foundation

### A. Overview & Purpose

**What:** The app-wide `ThemeData` configuration for TaleTrail, encompassing three theme modes (light, bedtime/dark, and story-dynamic), font registration and typography scale, color palette constants, and a library of reusable styled components (story cards, buttons, text panels, badges, navigation elements) that enforce visual consistency across all screens.

**Why:** The project brief (section 10) establishes a precise visual identity: hand-drawn warmth, parchment textures, rounded shapes, organic curves, and "storybook-first" aesthetics. Without a centralized theming foundation, individual screens will drift from this identity, creating visual inconsistency. Three theme modes are needed: the default light theme for daytime use, the bedtime/dark theme (Feature 34) for nighttime reading, and a dynamic theme system (Feature 36) where the story player adapts its colors to each story's palette. The theming foundation must support all three simultaneously.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B3.1 | Kid | The app looks warm and inviting with soft colors, rounded shapes, and big readable text. It feels like a storybook. | Must |
| B3.2 | Kid | When I enter bedtime mode, the app becomes darker and calmer with deep navy blues and soft gold highlights. | Must |
| B3.3 | Kid | When I play a forest story, the player interface uses green tones. An ocean story uses blues. Each story feels like its own world. | Should |
| B3.4 | Parent | The parent dashboard looks mature and clean — warm but not childish. | Must |
| B3.5 | Developer | I can access any color, font style, or dimension through theme constants without hardcoding values. | Must |
| B3.6 | Developer | Adding a new story-dynamic theme requires only adding a color palette entry in the CMS, not changing app code. | Must |
| B3.7 | Developer | Reusable components (StoryCard, PrimaryButton, TextPanel) are available and automatically adapt to the active theme. | Must |

**Functional Requirements:**

1. Three `ThemeData` definitions: `lightTheme`, `bedtimeTheme`, `storyDynamicTheme(StoryPalette)`.
2. Font families registered: Baloo 2 (headings), Nunito (body text and UI), Inter (parent dashboard).
3. Color palette defined as constants with semantic naming (not `Colors.red` but `TaleColors.terracotta`).
4. Typography scale covering: display (splash/titles), headline (section headers), title (story titles), body (story text), label (buttons/badges), caption (metadata/timestamps).
5. Component library providing at minimum: `StoryCard`, `TaleButton`, `TextPanel`, `BadgeChip`, `SectionHeader`, `IllustratedEmptyState`, `AvatarWidget`.
6. Theme switching is handled via a Riverpod `StateProvider<ThemeMode>` where `ThemeMode` is one of `light`, `bedtime`, or `storyDynamic`.
7. Story-dynamic theme is generated at runtime from a story's accent color palette stored in Firestore/CMS.

### C. Technical Design & Architecture

**Font registration:**

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Baloo2
      fonts:
        - asset: assets/fonts/Baloo2-Regular.ttf
        - asset: assets/fonts/Baloo2-Medium.ttf
          weight: 500
        - asset: assets/fonts/Baloo2-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Baloo2-Bold.ttf
          weight: 700
        - asset: assets/fonts/Baloo2-ExtraBold.ttf
          weight: 800
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Regular.ttf
        - asset: assets/fonts/Nunito-Medium.ttf
          weight: 500
        - asset: assets/fonts/Nunito-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Nunito-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
```

**Color palette:**

```dart
// lib/core/theme/tale_colors.dart

class TaleColors {
  TaleColors._();

  // --- Brand Primary ---
  static const Color terracotta = Color(0xFFC8553D);
  static const Color terracottaLight = Color(0xFFE8836D);
  static const Color terracottaDark = Color(0xFF8E3828);

  // --- Brand Secondary ---
  static const Color warmGold = Color(0xFFF4E285);
  static const Color warmGoldLight = Color(0xFFFFF3C4);
  static const Color warmGoldDark = Color(0xFFD4B84A);

  // --- Neutrals (Warm) ---
  static const Color parchment = Color(0xFFFFF8F0);     // primary background
  static const Color parchmentDark = Color(0xFFF5EDE0);  // card backgrounds
  static const Color warmWhite = Color(0xFFFFFBF5);      // elevated surfaces
  static const Color cream = Color(0xFFFAF3E8);
  static const Color warmGrey100 = Color(0xFFF0E8DC);
  static const Color warmGrey200 = Color(0xFFE0D5C7);
  static const Color warmGrey300 = Color(0xFFC4B5A3);
  static const Color warmGrey400 = Color(0xFFA89882);
  static const Color warmGrey500 = Color(0xFF8C7B64);
  static const Color warmGrey600 = Color(0xFF6B5D4D);
  static const Color warmGrey700 = Color(0xFF4A3F33);
  static const Color warmGrey800 = Color(0xFF2E2720);
  static const Color warmGrey900 = Color(0xFF1A1510);

  // --- Bedtime Theme ---
  static const Color nightNavy = Color(0xFF1B2838);       // bedtime primary bg
  static const Color nightNavyLight = Color(0xFF253549);   // bedtime card bg
  static const Color nightNavySurface = Color(0xFF2D3F52); // bedtime elevated
  static const Color softGold = Color(0xFFE8C872);         // bedtime accent
  static const Color moonlight = Color(0xFFF0E6CE);        // bedtime text

  // --- Semantic Colors ---
  static const Color success = Color(0xFF5B8C5A);    // sage green
  static const Color error = Color(0xFFDC4C4C);      // warm red
  static const Color warning = Color(0xFFE8A838);     // amber
  static const Color info = Color(0xFF5B8FC5);        // sky blue

  // --- Story Theme Accent Presets ---
  static const Color forestGreen = Color(0xFF4A7C59);
  static const Color oceanBlue = Color(0xFF3B7CB8);
  static const Color spacePurple = Color(0xFF6B5BB8);
  static const Color desertOrange = Color(0xFFD4853A);
  static const Color mountainGrey = Color(0xFF6B7B8D);
  static const Color sunsetPink = Color(0xFFD46B8C);
}
```

**Typography scale:**

```dart
// lib/core/theme/tale_typography.dart

class TaleTypography {
  TaleTypography._();

  static TextTheme get textTheme => const TextTheme(
    // Splash / hero titles
    displayLarge: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),

    // Section headers
    headlineLarge: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),

    // Story titles, card titles
    titleLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),

    // Story text, body copy
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.6,       // generous line height for readability
      letterSpacing: 0.2,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),

    // Buttons, badges, labels
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.3,
    ),
  );

  // Parent dashboard uses Inter for a more mature feel
  static TextTheme get parentTextTheme => const TextTheme(
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
  );
}
```

**Theme definitions:**

```dart
// lib/core/theme/tale_theme.dart

class TaleTheme {
  TaleTheme._();

  // ──────────────── LIGHT THEME (Default) ────────────────

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: TaleColors.terracotta,
      onPrimary: Colors.white,
      primaryContainer: TaleColors.terracottaLight,
      secondary: TaleColors.warmGold,
      onSecondary: TaleColors.warmGrey800,
      secondaryContainer: TaleColors.warmGoldLight,
      surface: TaleColors.parchment,
      onSurface: TaleColors.warmGrey800,
      surfaceContainerHighest: TaleColors.parchmentDark,
      error: TaleColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: TaleColors.parchment,
    textTheme: TaleTypography.textTheme.apply(
      bodyColor: TaleColors.warmGrey800,
      displayColor: TaleColors.warmGrey900,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: TaleColors.warmGrey700),
      titleTextStyle: TextStyle(
        fontFamily: 'Baloo2',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: TaleColors.warmGrey800,
      ),
    ),
    cardTheme: CardTheme(
      color: TaleColors.warmWhite,
      elevation: 2,
      shadowColor: TaleColors.warmGrey300.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TaleColors.terracotta,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        elevation: 2,
        shadowColor: TaleColors.terracotta.withOpacity(0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TaleColors.terracotta,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: const BorderSide(color: TaleColors.terracotta, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TaleColors.terracotta,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TaleColors.warmWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TaleColors.warmGrey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TaleColors.warmGrey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: TaleColors.terracotta, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(
        fontFamily: 'Nunito',
        color: TaleColors.warmGrey400,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TaleColors.warmWhite,
      selectedItemColor: TaleColors.terracotta,
      unselectedItemColor: TaleColors.warmGrey400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: TaleColors.warmGrey100,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TaleColors.warmGrey800,
      contentTextStyle: const TextStyle(
        fontFamily: 'Nunito',
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ──────────────── BEDTIME THEME ────────────────

  static ThemeData get bedtime => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: TaleColors.softGold,
      onPrimary: TaleColors.nightNavy,
      primaryContainer: Color(0xFF3D4F60),
      secondary: TaleColors.moonlight,
      onSecondary: TaleColors.nightNavy,
      surface: TaleColors.nightNavy,
      onSurface: TaleColors.moonlight,
      surfaceContainerHighest: TaleColors.nightNavyLight,
      error: Color(0xFFE88080),
      onError: TaleColors.nightNavy,
    ),
    scaffoldBackgroundColor: TaleColors.nightNavy,
    textTheme: TaleTypography.textTheme.apply(
      bodyColor: TaleColors.moonlight,
      displayColor: TaleColors.softGold,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: TaleColors.moonlight),
      titleTextStyle: TextStyle(
        fontFamily: 'Baloo2',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: TaleColors.softGold,
      ),
    ),
    cardTheme: CardTheme(
      color: TaleColors.nightNavyLight,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TaleColors.softGold,
        foregroundColor: TaleColors.nightNavy,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF152030),
      selectedItemColor: TaleColors.softGold,
      unselectedItemColor: Color(0xFF5A6A7A),
      type: BottomNavigationBarType.fixed,
    ),
  );

  // ──────────────── STORY-DYNAMIC THEME ────────────────

  static ThemeData storyDynamic(StoryPalette palette) {
    final base = light;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: palette.accent,
        primaryContainer: palette.accentLight,
        secondary: palette.secondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(palette.accent),
          shadowColor: WidgetStatePropertyAll(palette.accent.withOpacity(0.3)),
        ),
      ),
    );
  }
}

// Palette derived from story metadata
class StoryPalette {
  final Color accent;
  final Color accentLight;
  final Color secondary;
  final Color textOnAccent;

  const StoryPalette({
    required this.accent,
    required this.accentLight,
    required this.secondary,
    required this.textOnAccent,
  });

  factory StoryPalette.fromHex({
    required String accentHex,
    String? secondaryHex,
  }) {
    final accent = Color(int.parse(accentHex.replaceFirst('#', '0xFF')));
    final hsl = HSLColor.fromColor(accent);
    return StoryPalette(
      accent: accent,
      accentLight: hsl.withLightness((hsl.lightness + 0.2).clamp(0, 1)).toColor(),
      secondary: secondaryHex != null
          ? Color(int.parse(secondaryHex.replaceFirst('#', '0xFF')))
          : hsl.withLightness((hsl.lightness + 0.3).clamp(0, 1)).toColor(),
      textOnAccent: hsl.lightness > 0.5 ? TaleColors.warmGrey800 : Colors.white,
    );
  }
}
```

**Theme provider:**

```dart
// lib/core/providers/theme_provider.dart

enum TaleThemeMode { light, bedtime, storyDynamic }

final themeModeProvider = StateProvider<TaleThemeMode>((ref) => TaleThemeMode.light);

final activeStoryPaletteProvider = StateProvider<StoryPalette?>((ref) => null);

final currentThemeProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  final storyPalette = ref.watch(activeStoryPaletteProvider);

  switch (mode) {
    case TaleThemeMode.light:
      return TaleTheme.light;
    case TaleThemeMode.bedtime:
      return TaleTheme.bedtime;
    case TaleThemeMode.storyDynamic:
      if (storyPalette != null) {
        return TaleTheme.storyDynamic(storyPalette);
      }
      return TaleTheme.light; // Fallback if no palette set
  }
});
```

**Usage in MaterialApp:**

```dart
class TaleTrailApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TaleTrail',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### D. Data Models & Schema

**Story palette in Firestore (already part of Dynamic Theme Feature 36 schema):**

```
/stories/{storyId}
{
  ...existing fields...,
  "theme": {
    "accentColorHex": "#4A7C59",
    "secondaryColorHex": "#A8D5A2"
  }
}
```

**Bedtime mode schedule in Firestore (part of Feature 34):**

```
/users/{userId}/settings/preferences
{
  "bedtimeMode": {
    "enabled": false,
    "autoSchedule": true,
    "startTime": "20:00",    // 8PM
    "endTime": "07:00"       // 7AM
  }
}
```

**No new schema additions** for theming beyond what Features 34 and 36 already define.

### E. UI/UX Specification

**Design token summary:**

| Token | Light | Bedtime |
|-------|-------|---------|
| Background | #FFF8F0 (parchment) | #1B2838 (night navy) |
| Surface | #FFFBF5 (warm white) | #253549 (navy light) |
| Primary | #C8553D (terracotta) | #E8C872 (soft gold) |
| On Primary | #FFFFFF | #1B2838 |
| Text Primary | #2E2720 (warm grey 800) | #F0E6CE (moonlight) |
| Text Secondary | #6B5D4D (warm grey 600) | #8A9AAA |
| Card Background | #FFFBF5 | #253549 |
| Border/Divider | #F0E8DC (warm grey 100) | #3A4A5C |
| Shadow | warmGrey300 at 30% | black at 20% |

**Corner radius standards:**

| Element | Radius |
|---------|--------|
| Card | 16dp |
| Button (pill) | 24dp |
| Input field | 16dp |
| Bottom sheet | 24dp (top corners) |
| Dialog | 20dp |
| Badge/chip | 12dp |
| Avatar (circular) | 50% |
| Story player (full bleed) | 0dp |

**Spacing scale (8dp base):**

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4dp | Tight spacing (icon-to-text) |
| `sm` | 8dp | Component internal padding |
| `md` | 16dp | Standard element spacing |
| `lg` | 24dp | Section spacing |
| `xl` | 32dp | Screen-level padding |
| `xxl` | 48dp | Major section separators |

**Elevation scale:**

| Level | Elevation | Usage |
|-------|-----------|-------|
| 0 | 0dp | Flat surfaces, backgrounds |
| 1 | 2dp | Cards, buttons (resting) |
| 2 | 4dp | Cards (hovered/pressed), FAB |
| 3 | 8dp | Bottom navigation, bottom sheets |
| 4 | 12dp | Dialogs, modals |

**Reusable component library:**

| Component | Description | Theme-Aware Properties |
|-----------|-------------|----------------------|
| `StoryCard` | Card with cover image, title, age badge, optional cultural frame | Card color, text color, shadow, frame SVG |
| `TaleButton` | Primary (filled) and secondary (outlined) pill buttons | Background, foreground, border, shadow |
| `TextPanel` | Semi-transparent parchment overlay for story text | Background opacity, text color, border radius |
| `BadgeChip` | Small pill for "NEW", "FREE", age range, etc. | Background, text color |
| `SectionHeader` | Title + "See All" row for story browser sections | Text color, icon color |
| `IllustratedEmptyState` | SVG illustration + message for empty/error states | Text color adapts to theme |
| `AvatarWidget` | Circular SVG avatar with optional wiggle animation | Border color from theme |
| `ParchmentCard` | Card with subtle paper texture background | Texture tint adapts to theme (warm cream vs. dark parchment) |

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T3.1 | `TaleTheme.light` produces valid `ThemeData` with correct brightness | `brightness == Brightness.light` |
| T3.2 | `TaleTheme.bedtime` produces valid `ThemeData` with correct brightness | `brightness == Brightness.dark` |
| T3.3 | `TaleTheme.storyDynamic(palette)` overrides primary color | `colorScheme.primary == palette.accent` |
| T3.4 | `StoryPalette.fromHex` parses valid hex colors | Correct `Color` values |
| T3.5 | `StoryPalette.fromHex` with light accent generates dark `textOnAccent` | `textOnAccent` is dark |
| T3.6 | `StoryPalette.fromHex` with dark accent generates light `textOnAccent` | `textOnAccent` is white |
| T3.7 | All `TaleColors` constants have correct hex values | Spot check 5 colors |
| T3.8 | Typography uses correct font families | Baloo2 for headings, Nunito for body |

**Widget tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T3.9 | `StoryCard` renders correctly in light theme | Golden file match |
| T3.10 | `StoryCard` renders correctly in bedtime theme | Golden file match (dark background, light text) |
| T3.11 | `TaleButton` uses pill shape with 24dp radius | Shape matches spec |
| T3.12 | `BadgeChip` renders "NEW" text with correct styling | Text and colors match |
| T3.13 | `TextPanel` has semi-transparent background | Background opacity < 1.0 |
| T3.14 | `SectionHeader` shows title and "See All" action | Both elements present |

**Visual regression tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T3.15 | Story browser screen — light theme golden file | Pixel-perfect match |
| T3.16 | Story browser screen — bedtime theme golden file | Pixel-perfect match |
| T3.17 | Story player screen — forest dynamic theme golden file | Green accents applied |
| T3.18 | Parent dashboard — light theme golden file | Inter font, mature styling |

**Manual QA checklist:**

- [ ] All screens use Baloo 2 for headings and Nunito for body text. No system font fallbacks.
- [ ] No screen uses pure white (#FFFFFF) as a background — all use parchment/off-white.
- [ ] Bedtime theme has no bright/jarring colors. Everything is muted navy and gold.
- [ ] Story-dynamic theme changes are visible when entering/leaving the story player.
- [ ] Font sizes are readable on a small phone (5" screen) — body text at least 16sp.
- [ ] Rounded corners are consistent (16dp cards, 24dp buttons) across all screens.
- [ ] Parent dashboard feels visually distinct (mature) from kid-facing screens.
- [ ] Color contrast ratios meet WCAG AA for all text on all backgrounds.
- [ ] Switching from light to bedtime and back produces no visual artifacts or flicker.

---

## Item 4: Dependency Injection

### A. Overview & Purpose

**What:** A structured Riverpod provider organization strategy that defines where providers live in the codebase, how they are scoped, how services are registered, and how providers can be overridden for testing. This is the architectural pattern that all feature providers must follow.

**Why:** As TaleTrail grows from MVP to Post-MVP (27 to 58+ features), the number of Riverpod providers will grow into the hundreds. Without an explicit organization strategy, providers become scattered, circular dependencies emerge, service lifetimes become unclear, and testing requires ad-hoc overrides. Establishing the pattern early — with feature-folder scoping, core shared services, and a standardized testing override approach — prevents the provider graph from becoming unmaintainable.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B4.1 | Developer | I can find any provider by looking in its feature folder. Shared services are in `core/providers/`. | Must |
| B4.2 | Developer | I can write a widget test that overrides any provider (e.g., mock an API response) using a standard pattern. | Must |
| B4.3 | Developer | Providers that depend on async initialization (Firebase, SharedPreferences) are properly awaited before use. | Must |
| B4.4 | Developer | The provider dependency graph has no circular dependencies. | Must |
| B4.5 | Developer | Providers that are scoped to a specific screen/feature are disposed when that screen is unmounted, preventing memory leaks. | Must |
| B4.6 | Developer | I can look at a feature folder and understand all its state management without reading other folders. | Should |

**Functional Requirements:**

1. Provider files are colocated with their feature code in feature folders.
2. Shared/cross-cutting providers live in `lib/core/providers/`.
3. All providers that represent services (API clients, repositories, managers) are created as `Provider` (not `StateProvider`) and are overridable.
4. All providers that represent async data fetches use `FutureProvider` or `StreamProvider` with `.autoDispose` where the data is screen-scoped.
5. All providers that represent mutable UI state use `StateNotifierProvider` or `NotifierProvider`.
6. A `ProviderContainer` override pattern is documented and used in all tests.
7. Service providers that require async initialization use the `AsyncValue` pattern and are awaited in the init flow.

### C. Technical Design & Architecture

**Folder structure:**

```
lib/
├── core/
│   ├── providers/                    # Shared, cross-cutting providers
│   │   ├── firebase_providers.dart   # Firebase Auth, Firestore, Storage instances
│   │   ├── auth_providers.dart       # Auth state, current user
│   │   ├── theme_providers.dart      # Theme mode, active palette
│   │   ├── connectivity_provider.dart # Online/offline state
│   │   ├── remote_config_provider.dart
│   │   └── shared_prefs_provider.dart
│   ├── services/                     # Service interfaces + implementations
│   │   ├── auth_service.dart
│   │   ├── storage_service.dart
│   │   └── analytics_service.dart
│   ├── models/                       # Shared data models
│   ├── theme/                        # Theme definitions (Item 3)
│   ├── navigation/                   # Router (Item 1)
│   └── initialization/              # Init flow (Item 2)
│
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   ├── login_provider.dart
│   │   │   └── signup_provider.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── models/
│   │
│   ├── profiles/
│   │   ├── providers/
│   │   │   ├── profile_list_provider.dart
│   │   │   ├── active_profile_provider.dart
│   │   │   └── profile_repository_provider.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── models/
│   │
│   ├── story_browser/
│   │   ├── providers/
│   │   │   ├── story_list_provider.dart
│   │   │   ├── story_filter_provider.dart
│   │   │   ├── new_this_week_provider.dart
│   │   │   └── story_repository_provider.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── models/
│   │
│   ├── story_player/
│   │   ├── providers/
│   │   │   ├── story_tree_provider.dart
│   │   │   ├── current_step_provider.dart
│   │   │   ├── audio_player_provider.dart
│   │   │   ├── parallax_provider.dart
│   │   │   ├── waveform_provider.dart
│   │   │   └── story_progress_provider.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── models/
│   │
│   ├── offline_library/
│   │   ├── providers/
│   │   │   ├── download_manager_provider.dart
│   │   │   ├── offline_stories_provider.dart
│   │   │   └── download_progress_provider.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── models/
│   │
│   ├── achievements/
│   ├── streaks/
│   ├── bedtime_mode/
│   ├── cultural_collections/
│   ├── parent_dashboard/
│   ├── subscription/
│   └── notifications/
│
└── main.dart
```

**Provider categorization rules:**

| Provider Type | Riverpod Construct | Dispose Strategy | Location |
|--------------|-------------------|-----------------|----------|
| Firebase instances | `Provider` | Never (app lifetime) | `core/providers/` |
| Auth state | `StreamProvider` | Never (app lifetime) | `core/providers/` |
| Active kid profile | `StateProvider` | Never (app lifetime) | `core/providers/` |
| Theme mode | `StateProvider` | Never (app lifetime) | `core/providers/` |
| Repository instances | `Provider` | Never (app lifetime) | Feature `providers/` |
| Screen data fetches | `FutureProvider.autoDispose` | On screen unmount | Feature `providers/` |
| Streams (audio, sensors) | `StreamProvider.autoDispose` | On screen unmount | Feature `providers/` |
| UI state (form, filter) | `StateNotifierProvider.autoDispose` | On screen unmount | Feature `providers/` |
| Per-story data | `FutureProvider.family.autoDispose` | On story change | Feature `providers/` |

**Core providers:**

```dart
// lib/core/providers/firebase_providers.dart

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// lib/core/providers/auth_providers.dart

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// lib/core/providers/connectivity_provider.dart

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider).valueOrNull;
  return connectivity != null && connectivity != ConnectivityResult.none;
});

// lib/core/providers/shared_prefs_provider.dart

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});
```

**Async initialization pattern:**

Providers that depend on async initialization (like `SharedPreferences`) are overridden at the root `ProviderScope` after initialization:

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Async inits that must complete before provider graph is ready
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
      ],
      child: const TaleTrailApp(),
    ),
  );
}
```

**Testing override pattern:**

```dart
// test/helpers/test_helpers.dart

/// Creates a ProviderScope with common test overrides
Widget createTestWidget({
  required Widget child,
  List<Override> overrides = const [],
  User? mockUser,
  KidProfile? mockProfile,
}) {
  return ProviderScope(
    overrides: [
      // Core service mocks
      firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      sharedPrefsProvider.overrideWithValue(MockSharedPreferences()),
      connectivityProvider.overrideWith((ref) => Stream.value(ConnectivityResult.wifi)),

      // Auth state mock
      if (mockUser != null)
        authStateProvider.overrideWith((ref) => Stream.value(mockUser)),

      // Profile mock
      if (mockProfile != null)
        activeKidProfileProvider.overrideWith((ref) => mockProfile),

      // Feature-specific overrides
      ...overrides,
    ],
    child: MaterialApp(
      theme: TaleTheme.light,
      home: child,
    ),
  );
}

// Usage in a test:
testWidgets('StoryBrowserScreen shows stories', (tester) async {
  await tester.pumpWidget(
    createTestWidget(
      child: const StoryBrowserScreen(),
      mockUser: FakeUser(uid: 'test-user'),
      mockProfile: FakeKidProfile(name: 'Aarav', age: 8),
      overrides: [
        storyListProvider.overrideWith((ref) async {
          return [FakeStory(title: 'Test Story')];
        }),
      ],
    ),
  );

  expect(find.text('Test Story'), findsOneWidget);
});
```

**Provider dependency graph validation:**

To prevent circular dependencies, follow these rules:

1. `core/providers/` providers may only depend on other `core/providers/` providers.
2. Feature providers may depend on `core/providers/` and on providers within the same feature folder.
3. Feature providers must NEVER depend on providers from another feature folder. If two features need to share data, extract the shared provider to `core/providers/`.
4. A lint rule or CI check should enforce import boundaries (e.g., using `import_sorter` or custom lint rules).

**Import rules:**

```
core/providers/ → can import: core/services/, core/models/
core/services/  → can import: core/models/
features/X/providers/ → can import: core/**, features/X/models/
features/X/screens/   → can import: core/**, features/X/**
features/X/widgets/   → can import: core/**, features/X/models/, features/X/providers/
```

### D. Data Models & Schema

No Firestore or CMS schema changes. This item is entirely a code organization concern.

**Provider inventory (current as of Batch 15):**

| Provider | Type | Location | Lifetime |
|----------|------|----------|----------|
| `firebaseAuthProvider` | Provider | core/providers/ | App |
| `firestoreProvider` | Provider | core/providers/ | App |
| `firebaseStorageProvider` | Provider | core/providers/ | App |
| `authStateProvider` | StreamProvider | core/providers/ | App |
| `currentUserProvider` | Provider | core/providers/ | App |
| `isAuthenticatedProvider` | Provider | core/providers/ | App |
| `connectivityProvider` | StreamProvider | core/providers/ | App |
| `isOnlineProvider` | Provider | core/providers/ | App |
| `themeModeProvider` | StateProvider | core/providers/ | App |
| `activeStoryPaletteProvider` | StateProvider | core/providers/ | App |
| `currentThemeProvider` | Provider | core/providers/ | App |
| `sharedPrefsProvider` | Provider (overridden) | core/providers/ | App |
| `remoteConfigProvider` | Provider | core/providers/ | App |
| `activeKidProfileProvider` | StateProvider | features/profiles/ | App |
| `profileListProvider` | FutureProvider | features/profiles/ | App |
| `storyListProvider` | FutureProvider.autoDispose | features/story_browser/ | Screen |
| `storyFilterProvider` | StateNotifierProvider.autoDispose | features/story_browser/ | Screen |
| `newThisWeekStoriesProvider` | FutureProvider.autoDispose | features/story_browser/ | Screen |
| `storyTreeProvider` | FutureProvider.family.autoDispose | features/story_player/ | Per-story |
| `currentStepProvider` | StateNotifierProvider.autoDispose | features/story_player/ | Screen |
| `audioPlayerProvider` | Provider.autoDispose | features/story_player/ | Screen |
| `parallaxControllerProvider` | StateNotifierProvider.autoDispose | features/story_player/ | Screen |
| `waveformBarHeightsProvider` | StateNotifierProvider.autoDispose | features/story_player/ | Screen |
| `downloadManagerProvider` | Provider | features/offline_library/ | App |
| `downloadProgressProvider` | StreamProvider.family | features/offline_library/ | Per-download |
| `offlineStoriesProvider` | FutureProvider | features/offline_library/ | Screen |
| `culturalCollectionsProvider` | FutureProvider | features/cultural_collections/ | App |
| `subscriptionStateProvider` | StreamProvider | features/subscription/ | App |

### E. UI/UX Specification

Not applicable — this item has no user-facing visual output. It is purely an architectural specification.

### F. Testing & Acceptance Criteria

**Unit tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T4.1 | `createTestWidget` helper successfully overrides `firebaseAuthProvider` | No `UnimplementedError`; mock is used |
| T4.2 | `createTestWidget` helper successfully overrides `sharedPrefsProvider` | Mock prefs accessible |
| T4.3 | `.autoDispose` providers are disposed when their consumer is unmounted | Provider state is null after unmount |
| T4.4 | `.family` providers create distinct instances for different arguments | Two `storyTreeProvider('a')` and `storyTreeProvider('b')` are independent |
| T4.5 | Override a `FutureProvider` with a mock async value | Provider resolves to mock value |
| T4.6 | Override a `StreamProvider` with a mock stream | Provider emits mock events |

**Architecture tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T4.7 | No `features/X/` file imports from `features/Y/` (X != Y) | Import boundary lint passes |
| T4.8 | No `core/providers/` file imports from `features/` | Import boundary lint passes |
| T4.9 | All providers in `core/providers/` are non-autoDispose | Compile-time or lint check |
| T4.10 | Every feature folder has a `providers/` subfolder | Directory structure check |

**Integration tests:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T4.11 | Full app starts with real Firebase providers in `ProviderScope` | No provider errors on startup |
| T4.12 | Full app starts with all providers mocked (no Firebase) | App renders home screen with mock data |

**Manual QA checklist:**

- [ ] Developer documentation (inline comments) in each `providers/` folder explains the folder's provider inventory.
- [ ] Every provider has a dartdoc comment explaining its purpose and lifetime.
- [ ] No `Provider` uses a global variable — all state is within the Riverpod container.
- [ ] Memory profiling shows no leaked providers after navigating away from a screen that uses `.autoDispose` providers.

---

## Item 5: CI/CD Pipeline

### A. Overview & Purpose

**What:** A fully automated continuous integration and continuous deployment pipeline using GitHub Actions that builds, tests, signs, and deploys all three components of TaleTrail: the Flutter mobile app (Android APK/AAB + iOS IPA), Firebase Cloud Functions, and the Strapi v4 CMS. The pipeline supports three environments (development, staging, production) with environment-specific configuration, automated test execution, and gated deployments.

**Why:** TaleTrail is a solo developer + AI project. Manual build/sign/deploy cycles are time-consuming, error-prone, and unsustainable as the project grows. A CI/CD pipeline ensures that every push to a feature branch runs tests, every merge to `main` triggers a staging build, and production releases are controlled, signed, and traceable. Code signing for mobile apps is particularly painful to do manually — automating it eliminates a major friction point.

### B. User Stories & Requirements

| ID | Role | Story | Priority |
|----|------|-------|----------|
| B5.1 | Developer | Every push to a feature branch triggers automated linting, testing (unit + widget), and build verification for the Flutter app. | Must |
| B5.2 | Developer | Every merge to `main` triggers a full build (Android AAB + iOS IPA) and deploys to the staging environment. | Must |
| B5.3 | Developer | I can trigger a production release by creating a Git tag (e.g., `v1.2.0`). The pipeline builds, signs, and uploads to Google Play (internal track) and TestFlight. | Must |
| B5.4 | Developer | Cloud Functions are deployed to staging on merge to `main` and to production on tag. | Must |
| B5.5 | Developer | Strapi CMS is deployed to its hosting environment on merge to `main` (staging) and tag (production). | Should |
| B5.6 | Developer | If any test fails, the pipeline blocks the merge/deploy and notifies me. | Must |
| B5.7 | Developer | Secrets (signing keys, API keys, Firebase credentials) are stored in GitHub Actions secrets, never in the repository. | Must |
| B5.8 | Developer | The pipeline takes less than 20 minutes for a full build + test cycle. | Should |

**Functional Requirements:**

1. Three workflow files: `ci.yml` (branch pushes), `staging.yml` (merge to main), `release.yml` (tag push).
2. Flutter build targets: Android AAB (release), Android APK (debug for testing), iOS IPA (release).
3. Test execution: `flutter test` (unit + widget), `flutter analyze` (lint), `dart format --set-exit-if-changed` (formatting).
4. Code signing: Android keystore and iOS provisioning profiles managed via Fastlane.
5. Upload destinations: Google Play Internal Testing (Android), TestFlight (iOS), Firebase App Distribution (optional, for beta testers).
6. Cloud Functions deploy via Firebase CLI.
7. Environment-specific config files: `.env.dev`, `.env.staging`, `.env.prod` (not committed; injected via CI secrets).
8. Caching: Flutter SDK, pub cache, Gradle, CocoaPods cache for faster builds.

### C. Technical Design & Architecture

**Repository structure (CI-relevant files):**

```
.github/
  workflows/
    ci.yml              # Feature branch CI
    staging.yml         # Main branch → staging deploy
    release.yml         # Tag → production deploy
  CODEOWNERS            # Require review for critical paths

android/
  fastlane/
    Fastfile            # Fastlane config for Android build + upload
    Appfile             # Package name, JSON key path

ios/
  fastlane/
    Fastfile            # Fastlane config for iOS build + upload
    Appfile             # App ID, team ID

functions/
  package.json
  tsconfig.json
  src/

strapi/
  package.json
  config/

firebase.json           # Firebase project config
.firebaserc             # Project aliases (dev, staging, prod)
```

**Workflow 1: CI (Feature Branches)**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches-ignore: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze-and-test:
    name: Analyze & Test
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Check formatting
        run: dart format --set-exit-if-changed .

      - name: Analyze code
        run: flutter analyze --no-fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep 'lines' | awk '{print $2}' | sed 's/%//')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "Coverage below 70% threshold"
            exit 1
          fi

  build-android:
    name: Build Android (verify)
    runs-on: ubuntu-latest
    needs: analyze-and-test
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - name: Build APK (debug)
        run: flutter build apk --debug

  test-functions:
    name: Test Cloud Functions
    runs-on: ubuntu-latest
    timeout-minutes: 10
    defaults:
      run:
        working-directory: functions
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm test
```

**Workflow 2: Staging Deploy (Main Branch)**

```yaml
# .github/workflows/staging.yml
name: Deploy to Staging

on:
  push:
    branches: [main]

concurrency:
  group: staging
  cancel-in-progress: false  # Don't cancel staging deploys

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter test

  build-android:
    name: Build Android AAB
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4

      - uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build AAB
        run: flutter build appbundle --release --dart-define=ENV=staging
        env:
          FIREBASE_OPTIONS_STAGING: ${{ secrets.FIREBASE_OPTIONS_STAGING }}

      - name: Upload AAB artifact
        uses: actions/upload-artifact@v4
        with:
          name: staging-aab
          path: build/app/outputs/bundle/release/app-release.aab

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_ANDROID_APP_ID_STAGING }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: internal-testers
          file: build/app/outputs/bundle/release/app-release.aab

  build-ios:
    name: Build iOS IPA
    runs-on: macos-latest
    needs: test
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true

      - name: Install CocoaPods
        run: cd ios && pod install

      - name: Setup code signing
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_DISTRIBUTION_CERT_BASE64 }}
          p12-password: ${{ secrets.IOS_DISTRIBUTION_CERT_PASSWORD }}

      - name: Install provisioning profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}" | \
            base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/staging.mobileprovision

      - name: Build IPA
        run: flutter build ipa --release --dart-define=ENV=staging --export-options-plist=ios/ExportOptions-staging.plist

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: staging-ipa
          path: build/ios/ipa/*.ipa

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v2
        with:
          app-path: build/ios/ipa/TaleTrail.ipa
          issuer-id: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          api-key-id: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          api-private-key: ${{ secrets.APP_STORE_CONNECT_PRIVATE_KEY }}

  deploy-functions:
    name: Deploy Cloud Functions (Staging)
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Install function dependencies
        run: cd functions && npm ci

      - name: Deploy to staging
        run: firebase deploy --only functions --project staging
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_CI_TOKEN }}
```

**Workflow 3: Production Release (Git Tag)**

```yaml
# .github/workflows/release.yml
name: Production Release

on:
  push:
    tags:
      - 'v*.*.*'  # Triggered by tags like v1.0.0, v1.2.3

jobs:
  validate-tag:
    name: Validate Tag Format
    runs-on: ubuntu-latest
    steps:
      - name: Check tag format
        run: |
          TAG="${GITHUB_REF#refs/tags/}"
          if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Invalid tag format: $TAG (expected vX.Y.Z)"
            exit 1
          fi
          echo "TAG_VERSION=${TAG#v}" >> $GITHUB_ENV

  test:
    name: Run Full Test Suite
    runs-on: ubuntu-latest
    needs: validate-tag
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-and-release-android:
    name: Build & Release Android
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4

      - uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build AAB
        run: flutter build appbundle --release --dart-define=ENV=production

      - name: Upload to Google Play (Internal Testing)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.taletrail.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed

  build-and-release-ios:
    name: Build & Release iOS
    runs-on: macos-latest
    needs: test
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - uses: subosiro/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: stable
          cache: true

      - run: cd ios && pod install

      - uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_DISTRIBUTION_CERT_BASE64 }}
          p12-password: ${{ secrets.IOS_DISTRIBUTION_CERT_PASSWORD }}

      - name: Install provisioning profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}" | \
            base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/production.mobileprovision

      - name: Build IPA
        run: flutter build ipa --release --dart-define=ENV=production --export-options-plist=ios/ExportOptions-production.plist

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v2
        with:
          app-path: build/ios/ipa/TaleTrail.ipa
          issuer-id: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          api-key-id: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          api-private-key: ${{ secrets.APP_STORE_CONNECT_PRIVATE_KEY }}

  deploy-functions-prod:
    name: Deploy Cloud Functions (Production)
    runs-on: ubuntu-latest
    needs: test
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json
      - run: npm install -g firebase-tools
      - run: cd functions && npm ci
      - name: Deploy to production
        run: firebase deploy --only functions --project production
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_CI_TOKEN }}

  create-github-release:
    name: Create GitHub Release
    runs-on: ubuntu-latest
    needs: [build-and-release-android, build-and-release-ios, deploy-functions-prod]
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          draft: false
```

**Environment configuration strategy:**

```dart
// lib/core/config/environment.dart

enum Environment { dev, staging, production }

class AppConfig {
  static Environment get environment {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'production': return Environment.production;
      case 'staging': return Environment.staging;
      default: return Environment.dev;
    }
  }

  static String get strapiBaseUrl {
    switch (environment) {
      case Environment.production: return 'https://cms.taletrail.app';
      case Environment.staging: return 'https://cms-staging.taletrail.app';
      case Environment.dev: return 'http://localhost:1337';
    }
  }

  static String get firebaseProject {
    switch (environment) {
      case Environment.production: return 'taletrail-prod';
      case Environment.staging: return 'taletrail-staging';
      case Environment.dev: return 'taletrail-dev';
    }
  }
}
```

**Firebase project aliases:**

```json
// .firebaserc
{
  "projects": {
    "default": "taletrail-dev",
    "staging": "taletrail-staging",
    "production": "taletrail-prod"
  }
}
```

**GitHub Actions secrets inventory:**

| Secret Name | Description |
|-------------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded Android release keystore (.jks) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias name |
| `IOS_DISTRIBUTION_CERT_BASE64` | Base64-encoded iOS distribution certificate (.p12) |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | Certificate password |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded provisioning profile |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API issuer ID |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | App Store Connect API private key (.p8 contents) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Google Play service account JSON |
| `FIREBASE_CI_TOKEN` | Firebase CLI auth token |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account for App Distribution |
| `FIREBASE_ANDROID_APP_ID_STAGING` | Firebase Android app ID for staging |
| `FIREBASE_OPTIONS_STAGING` | Firebase options Dart file content for staging |

### D. Data Models & Schema

Not applicable. CI/CD is an infrastructure concern with no data model impact.

**Configuration files that differ per environment:**

| File | Dev | Staging | Production |
|------|-----|---------|------------|
| `lib/firebase_options.dart` | Dev project | Staging project | Prod project |
| `android/app/google-services.json` | Dev project | Staging project | Prod project |
| `ios/Runner/GoogleService-Info.plist` | Dev project | Staging project | Prod project |
| `.firebaserc` | Default: dev | Alias: staging | Alias: production |

These files are generated per environment during CI and are NOT committed to the repository (they are injected from secrets or generated via `flutterfire configure`).

### E. UI/UX Specification

Not applicable. CI/CD has no user-facing visual output.

**Developer experience specification:**

| Interaction | Expected |
|-------------|----------|
| Push to feature branch | CI runs within 30s of push; results in ~10 minutes |
| Open PR | CI status checks appear on PR page; merge blocked if failing |
| Merge to main | Staging build + deploy triggers automatically; notification when complete |
| Create tag `v1.2.0` | Production pipeline triggers; builds uploaded to Play Store internal + TestFlight |
| CI failure | GitHub notification (email + in-app) with clear error message and log link |

**Pipeline timing targets:**

| Workflow | Target Duration |
|----------|----------------|
| CI (analyze + test + build verify) | < 12 minutes |
| Staging (full build + deploy) | < 20 minutes |
| Release (full build + sign + upload + deploy) | < 25 minutes |

### F. Testing & Acceptance Criteria

**Pipeline validation tests (run manually during setup):**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T5.1 | Push to feature branch triggers CI workflow | Workflow runs; tests execute; results reported on PR |
| T5.2 | CI catches a lint error (introduce one intentionally) | Workflow fails; error message identifies the lint violation |
| T5.3 | CI catches a test failure (introduce one intentionally) | Workflow fails; error message identifies the failing test |
| T5.4 | Merge to main triggers staging deploy | AAB and IPA built; uploaded to App Distribution and TestFlight |
| T5.5 | Tag `v0.1.0-test` triggers release workflow | Production build and upload executes |
| T5.6 | Cloud Functions deploy to staging succeeds | Functions visible in Firebase Console staging project |
| T5.7 | Cloud Functions deploy to production succeeds | Functions visible in Firebase Console production project |
| T5.8 | All secrets are accessible in CI | No "secret not found" errors in workflow logs |
| T5.9 | Android code signing produces a valid signed AAB | AAB can be installed on a device without "untrusted source" warning |
| T5.10 | iOS code signing produces a valid signed IPA | IPA installs via TestFlight without signing errors |
| T5.11 | CI caching works (second run is faster) | Second run of same workflow is at least 30% faster than first |
| T5.12 | Concurrent CI runs on different branches do not interfere | Two branches build simultaneously without artifact collision |

**Security verification:**

| Test ID | Description | Expected |
|---------|-------------|----------|
| T5.13 | Secrets are not printed in workflow logs | Grep logs for secret values; none found |
| T5.14 | Keystore/certificate files are not committed to git | `git ls-files` does not contain .jks, .p12, .mobileprovision |
| T5.15 | `.env` files are in `.gitignore` | Confirmed in .gitignore |
| T5.16 | `google-services.json` and `GoogleService-Info.plist` are in `.gitignore` | Confirmed |

**Manual QA checklist:**

- [ ] CI workflow completes successfully on a clean feature branch.
- [ ] Staging workflow produces installable APK (via Firebase App Distribution) and IPA (via TestFlight).
- [ ] Production workflow uploads to Google Play Internal Testing track.
- [ ] Production workflow uploads to TestFlight.
- [ ] Cloud Functions are deployed correctly to the right Firebase project per environment.
- [ ] GitHub Release is created with auto-generated release notes on tag push.
- [ ] All caching (Flutter SDK, Gradle, CocoaPods, npm) is functioning.
- [ ] Workflow concurrency settings prevent conflicting deploys.

---

## Batch 15 Summary

| Item | Effort | Key Technologies | Impact Scope |
|------|--------|-----------------|--------------|
| 1 — Navigation Architecture | M | GoRouter, deep links, redirect guards | Every screen in the app |
| 2 — App Initialization Flow | M | Firebase init, auth state, Remote Config | App startup, every launch |
| 3 — Theming Foundation | M | ThemeData, fonts, colors, components | Every visual element |
| 4 — Dependency Injection | S | Riverpod providers, testing overrides | Every provider, every test |
| 5 — CI/CD Pipeline | L | GitHub Actions, Fastlane, Firebase CLI | Every build and deploy |

**Recommended build order:**

1. **Item 4 (Dependency Injection)** — Foundational. All other items create providers that must follow this structure.
2. **Item 3 (Theming Foundation)** — Required before any UI work. Fonts, colors, and components are used everywhere.
3. **Item 2 (App Initialization Flow)** — Required for the app to start. Depends on provider structure (Item 4) and theme (Item 3 for splash screen).
4. **Item 1 (Navigation Architecture)** — Depends on auth providers (Item 4), initialization flow (Item 2), and theme (Item 3 for transitions).
5. **Item 5 (CI/CD Pipeline)** — Can be built in parallel with Items 1-4 since it is infrastructure. Should be operational before the first staging deploy.

**Cross-cutting dependencies on other batches:**

| This Batch Item | Depends On | From Batch |
|----------------|-----------|------------|
| Navigation — Auth guard | Firebase Auth (Feature 1) | Batch 1 |
| Navigation — Parental gate guard | Parental Gate (Feature 3) | Batch 1 |
| Navigation — Subscription guard | Subscription (Feature 24) | Batch 8 |
| Navigation — Deep links | Push Notifications (Feature 31) | Batch 10 |
| Initialization — Firebase init | Firebase Auth (Feature 1) | Batch 1 |
| Initialization — Remote Config | Feature Flags (Feature 45) | Batch 10 |
| Theming — Bedtime theme | Bedtime Mode (Feature 34) | Batch 9 |
| Theming — Story dynamic theme | Dynamic Theme System (Feature 36) | Batch 9 |
| Theming — Cultural palettes | Indian Folklore (Feature 37) | Batch 14 |
| CI/CD — Cloud Functions | All Cloud Function features | Batches 2, 10, 14 |

---

*This concludes the TaleTrail feature specification series. Batches 1-15 cover all 58 Post-MVP features plus 5 cross-cutting architectural concerns across 15 specification documents.*
