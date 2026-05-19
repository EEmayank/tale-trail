# Tasks: Monitoring & Launch Readiness

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 12 |
| **Total Estimated Effort** | ~29h |
| **Phase** | MVP |
| **Sprint** | 9-10 |
| **Status** | 🚧 Partially Complete (2 code tasks done; remaining are external/ops) |

---

## Phase 1: Crashlytics Setup (~9h)

- [x] **Task 1:** Crashlytics package setup — `firebase_crashlytics` added to `pubspec.yaml`. `FirebaseCrashlytics.instance.recordError()` calls in `AppInitializer`. *(2h)* — **Note:** iOS dSYM Xcode build phase and Android Gradle plugin config are build-time steps; configure when first building.
- [ ] **Task 2:** Crash reporter singleton — Dedicated `CrashReporter` class with `logError()`, `setCustomKey()`, `log()`, `setUserId()`. Wire to `FirebaseCrashlytics.instance`. *(2h)* — **Not implemented** (direct calls in `AppInitializer` for now; full singleton pending).
- [ ] **Task 3:** Structured error logger — Category-based error logging (api, audio, svg, download, auth) with consistent Crashlytics custom keys. *(3h)* — **Not implemented yet.**
- [ ] **Task 4:** Global error handler — `FlutterError.onError` for widget framework errors. `runZonedGuarded` in `main()` for uncaught async errors. *(2h)* — **Not implemented yet.**

## Phase 2: Instrumentation (~5h)

- [ ] **Task 5:** Instrument key flows — Structured logging added to: API service, audio player, SVG renderer, download manager, auth repository. *(4h)* — **Not implemented yet.**
- [ ] **Task 6:** Crashlytics alerts — Configure velocity alerts in Firebase Console. 99% crash-free rate threshold. Email notifications. *(1h)* — **External console config.**

## Phase 3: Privacy & Legal (~4h)

- [ ] **Task 7:** Privacy policy — COPPA/DPDP compliant policy deployed to Firebase Hosting at `/privacy`. *(4h)* — **Not implemented yet.** URL placeholder set in `AppConstants.privacyPolicyUrl`.

## Phase 4: Store Listings (~10h)

- [ ] **Task 8:** iOS App Store listing — Title, subtitle, promotional text, description, keywords. Kids category (6-8, 9-11), age rating 4+. *(3h)* — **External task.**
- [ ] **Task 9:** Android Play Store listing — Title, descriptions, content rating, Designed for Families program. *(3h)* — **External task.**
- [ ] **Task 10:** Hindi localization — Translate store listing metadata to Hindi for India market visibility. *(2h)* — **External task.**
- [ ] **Task 11:** Screenshot specification — 6 key screenshot scenes per platform: splash, profile selector, story browser, story player, choice selection, offline library. *(2h)* — **External task.**

## Phase 5: Compliance Verification (~2h)

- [x] **Task 12:** Kids compliance implementation — No child PII collected; parental consent screen records timestamp to Firestore; PIN stored as SHA-256 hash; `UIRequiresFullScreen` + portrait-only in `Info.plist`; no third-party ad SDKs; COPPA/DPDP privacy bullets on consent screen. *(2h)*
