# Spec 1: Auth, Onboarding & Profile Management

| Field | Value |
|-------|-------|
| **Feature** | Auth, Onboarding & Profile Management |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #1 Firebase Auth, #2 Parent Onboarding, #3 Parental Gate, #4 Kid Profile Switcher |
| **Estimated Effort** | ~47h (6 days) |

---

## Overview

The foundational user identity layer. Parents create accounts via email/password or Google Sign-In, add child profiles, and access a gated settings area. Children select their profile at app launch to get a personalized experience.

### User Stories

- As a parent, I can sign up with email/password or Google so I can create an account quickly.
- As a parent, I can add multiple kid profiles (name, age, avatar) so each child has a personalized experience.
- As a parent, I can set a PIN so only I can access account settings and purchases.
- As a kid, I can tap my avatar on the "Who's reading today?" screen to start reading.
- As a parent, I can reset my password if I forget it.

### Acceptance Criteria

1. Email/password and Google Sign-In both work on iOS and Android.
2. After signup, parent must add at least one kid profile before proceeding.
3. Parental consent checkbox is shown and recorded during signup.
4. Kid profiles store name (required), age (required), and avatar selection (required).
5. Maximum 6 kid profiles per parent account.
6. Parental gate (4-digit PIN) blocks access to settings, profile management, and purchases.
7. Math challenge fallback if parent forgets PIN (e.g., "What is 47 + 38?").
8. Profile switcher shows all kid profiles with animated avatars.
9. Auth tokens persist across app restarts (auto-login).
10. No personal data is collected directly from children (COPPA/DPDP compliant).

---

## Architecture & Project Layout

### Directory Structure

```
lib/
  features/
    auth/
      data/
        repositories/
          auth_repository.dart
        models/
          parent_user_model.dart
          kid_profile_model.dart
      domain/
        entities/
          parent_user.dart
          kid_profile.dart
        usecases/
          sign_up_usecase.dart
          sign_in_usecase.dart
          google_sign_in_usecase.dart
          reset_password_usecase.dart
      presentation/
        screens/
          welcome_screen.dart
          sign_up_screen.dart
          sign_in_screen.dart
          forgot_password_screen.dart
        widgets/
          google_sign_in_button.dart
          auth_form_field.dart
        providers/
          auth_provider.dart
    onboarding/
      presentation/
        screens/
          onboarding_intro_screen.dart
          parental_consent_screen.dart
          create_kid_profile_screen.dart
          setup_pin_screen.dart
        widgets/
          avatar_picker.dart
          age_selector.dart
        providers/
          onboarding_provider.dart
    profile/
      presentation/
        screens/
          profile_switcher_screen.dart
          manage_profiles_screen.dart
        widgets/
          profile_avatar_card.dart
          parental_gate_dialog.dart
          math_challenge_dialog.dart
        providers/
          profile_provider.dart
          parental_gate_provider.dart
```

### Database Schema (Firestore)

**Collection: `parents`**
```json
{
  "parents/{parentId}": {
    "email": "string",
    "displayName": "string",
    "authProvider": "email | google",
    "pinHash": "string (bcrypt hash of 4-digit PIN)",
    "consentGiven": "boolean",
    "consentTimestamp": "timestamp",
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

**Collection: `parents/{parentId}/kids`**
```json
{
  "parents/{parentId}/kids/{kidId}": {
    "name": "string (max 20 chars)",
    "age": "number (3-12)",
    "avatarId": "string (references pre-built SVG avatar)",
    "avatarCustomization": {
      "hair": "style1",
      "eyes": "style2",
      "outfit": "outfit3"
    },
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

**No API endpoints needed** — direct Firestore access from Flutter via Firebase SDK for auth/profile operations (serverless architecture).

**State Management:** Riverpod with `StateNotifier` for auth state, profile state, and onboarding progress. `AsyncValue` for loading/error handling.

---

## Implementation Plan

| # | Task | Files | Description | Est. |
|---|------|-------|-------------|------|
| 1 | Firebase project setup | `firebase.json`, `pubspec.yaml`, platform configs | Create Firebase project, enable Auth + Firestore. Install `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`. | 2h |
| 2 | Auth repository | `auth_repository.dart` | `signUp()`, `signIn()`, `signInWithGoogle()`, `signOut()`, `resetPassword()`, `authStateChanges` stream. | 4h |
| 3 | Parent user model | `parent_user_model.dart` | Firestore serialization. `fromFirestore()` / `toFirestore()`. | 1h |
| 4 | Kid profile model | `kid_profile_model.dart` | Name, age, avatarId, customization map. Firestore serialization. | 1h |
| 5 | Auth state provider | `auth_provider.dart` | Riverpod `StreamProvider` wrapping `authStateChanges`. `StateNotifier` for signup/signin loading. | 2h |
| 6 | Welcome screen | `welcome_screen.dart` | Full-screen SVG background. "Sign Up" / "Sign In" buttons. Google Sign-In button. | 3h |
| 7 | Sign-up screen | `sign_up_screen.dart`, `auth_form_field.dart` | Email, password, confirm password. Validation. On success → onboarding. | 3h |
| 8 | Sign-in screen | `sign_in_screen.dart` | Email + password. "Forgot password?" link. | 2h |
| 9 | Forgot password | `forgot_password_screen.dart` | Email input → `resetPassword()`. Success confirmation. | 1h |
| 10 | Parental consent | `parental_consent_screen.dart` | Plain-language privacy info. Checkbox consent. Records timestamp. | 2h |
| 11 | Onboarding intro | `onboarding_intro_screen.dart` | 3-page PageView with SVG illustrations. Skip button. | 3h |
| 12 | Avatar picker | `avatar_picker.dart` | Grid of 12+ SVG avatars. Tap to select with bounce animation. | 3h |
| 13 | Create kid profile | `create_kid_profile_screen.dart`, `age_selector.dart` | Name (max 20 chars), age (3-12), avatar. "Add another" or "Done". Saves to Firestore. | 4h |
| 14 | Setup PIN | `setup_pin_screen.dart` | 4-digit PIN entry with custom numpad. Confirm. Hash with bcrypt, store. | 3h |
| 15 | Profile switcher | `profile_switcher_screen.dart`, `profile_avatar_card.dart` | "Who's reading today?" Grid of avatar cards. Tap → set active kid → navigate to home. | 4h |
| 16 | Parental gate | `parental_gate_dialog.dart`, `math_challenge_dialog.dart` | PIN numpad modal. 3 attempts → math challenge. | 3h |
| 17 | Profile provider | `profile_provider.dart` | `activeKidProfile` state. `kidProfiles` from Firestore stream. CRUD. | 2h |
| 18 | Manage profiles | `manage_profiles_screen.dart` | Edit/delete profiles. Add new. Behind parental gate. | 3h |
| 19 | Auth routing | `app_router.dart` | GoRouter redirects: unauthenticated → welcome, no kids → onboarding, kids → profile switcher. | 2h |

### Dependencies

`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `flutter_riverpod`, `go_router`, `flutter_svg`, `bcrypt`/`crypto`, `flutter_secure_storage`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Network down during signup | Illustrated "lost in forest" error. Retry button. |
| Google Sign-In cancelled | Return to welcome silently. |
| Email already registered | Inline error: "This email has an account. Sign in instead?" |
| Weak password | Client-side: min 8 chars, 1 number, 1 letter. Show requirements. |
| Max 6 kid profiles | Disable "Add". Message: "Maximum 6 profiles." |
| PIN forgotten + math challenge failed | After 3 math failures → "Contact support" link. |
| Token expired | `authStateChanges` redirects. Firebase auto-refreshes. |
| Offline profile creation | Firestore offline persistence queues writes. |

### Validation Rules

| Field | Rule |
|-------|------|
| Email | Valid email format |
| Password | Min 8 chars, at least 1 letter + 1 number |
| Kid name | 1-20 characters |
| Age | 3-12 (integer) |
| PIN | Exactly 4 digits |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | Auth repository: mock Firebase Auth, test all methods. PIN hashing roundtrip. Model serialization. |
| **Widget** | Sign-up validation. PIN dialog: 4-digit enforcement, math challenge after 3 failures. Avatar picker selection. |
| **Integration** | Full onboarding: signup → consent → profile → PIN → profile switcher. |
| **E2E** | Create account → 2 kid profiles → switch → verify persistence. |

**Mocks:** `MockFirebaseAuth`, `MockGoogleSignIn`, `FakeFirebaseFirestore`

---

## Effort Estimate

**Total: ~47h (6 days)**
