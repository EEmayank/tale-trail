# Tasks: Auth, Onboarding & Profile Management

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 19 |
| **Total Estimated Effort** | ~47h |
| **Phase** | MVP |
| **Sprint** | 1-2 |
| **Status** | ✅ Complete |

---

## Phase 1: Firebase & Data Layer Setup (~8h)

- [x] **Task 1:** Firebase project setup — Installed `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore` in `pubspec.yaml`. Created placeholder `firebase_options.dart`. Configured `AndroidManifest.xml` and `ios/Runner/Info.plist`. *(2h)* — **Note:** Firebase Console project creation + `google-services.json` / `GoogleService-Info.plist` are env-level steps; run `flutterfire configure` when ready.
- [x] **Task 2:** Auth repository — `auth_repository.dart` with `signUp()`, `signIn()`, `signInWithGoogle()`, `signOut()`, `resetPassword()`, `recordConsent()`, `setupPin()` (SHA-256), `verifyPin()`, `authStateChanges` stream. *(4h)*
- [x] **Task 3:** Parent user model — `parent_user_model.dart` with `fromFirestore()` / `toFirestore()`. *(1h)*
- [x] **Task 4:** Kid profile model — `kid_profile_model.dart` with name, age, avatarId, customization map, Firestore serialization. *(1h)*

## Phase 2: Auth Screens & Providers (~11h)

- [x] **Task 5:** Auth state provider — Riverpod `StreamProvider` wrapping `authStateChanges` (`auth_provider.dart`). `AuthNotifier` StateNotifier for signup/signin loading states (`auth_notifier_provider.dart`). *(2h)*
- [x] **Task 6:** Welcome screen — Gradient background (terracotta → warmGold), "Create Account" / "Sign In" buttons, `GoogleSignInButton`, loading overlay. *(3h)*
- [x] **Task 7:** Sign-up screen — Name, email, password, confirm-password fields with full validation. On success → navigates to `/onboarding`. *(3h)*
- [x] **Task 8:** Sign-in screen — Email + password form, "Forgot password?" link, Google button, "Sign up" link. On success → `context.go(redirectTo ?? '/profiles')`. *(2h)*
- [x] **Task 9:** Forgot password screen — Email input → `resetPassword()`. Inline success confirmation message. *(1h)*

## Phase 3: Onboarding Flow (~12h)

- [x] **Task 10:** Parental consent screen — Privacy info bullets (COPPA/DPDP), checkbox consent, records timestamp to Firestore via `authRepository.recordConsent()`. *(2h)*
- [x] **Task 11:** Onboarding intro screens — 3-page `PageView` with gradient backgrounds per page, dot indicators, "Next" / "Get Started" / "Skip" actions. Saves `hasLaunchedBefore` to SharedPreferences. *(3h)*
- [x] **Task 12:** Avatar picker widget — Inline 4-column grid of 12 emoji avatars with colored backgrounds and bounce animation, built into `create_kid_profile_screen.dart`. *(3h)*
- [x] **Task 13:** Create kid profile screen — Name input (max 20 chars), age selector (3–12), avatar picker. "Add Another" / "Let's Go!" actions. Saves to Firestore. *(4h)*

## Phase 4: PIN & Profile Management (~14h)

- [x] **Task 14:** Setup PIN screen — 4-digit PIN entry with custom 3×3 numpad, 4-dot indicator, confirm phase, shake animation on mismatch. SHA-256 hash stored as `pinHash` in Firestore. "Skip for now" option. *(3h)*
- [x] **Task 15:** Profile switcher screen — "Who's reading today?" grid of avatar cards. Tap → sets `activeKidProfileProvider` + SharedPreferences `lastActiveProfileId` → navigates to `/home`. "+" card for add. "Parent ⚙️" button at bottom. *(4h)*
- [x] **Task 16:** Parental gate dialog — PIN numpad modal (`parental_gate_dialog.dart`). 3 failed attempts → math challenge fallback (2-digit addition). Full-screen variant (`parental_gate_screen.dart`) with back + "Forgot PIN?" email reset. *(3h)*
- [x] **Task 17:** Profile provider — `activeKidProfileProvider` StateProvider (`profile_provider.dart`). `parentalGateStateProvider` with 15-minute timeout and `checkAndRefresh()` (`parental_gate_provider.dart`). *(2h)*
- [x] **Task 18:** Manage profiles screen — StreamBuilder on Firestore kids subcollection. Edit bottom sheet (name + age selector), delete AlertDialog confirmation. "Add New Profile" button disabled at 6 profiles max. *(3h)*

## Phase 5: Routing & Integration (~2h)

- [x] **Task 19:** Auth routing — `app_router.dart` with 5 redirect guards: first-launch → `/onboarding`, unauthenticated → `/login` (preserving redirect target), logged-in on auth route → home/profiles, no active profile → `/profiles`, parent route without valid gate → `/parent-gate`. *(2h)*
