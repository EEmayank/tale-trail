# Spec 8: Monitoring & Launch Readiness

| Field | Value |
|-------|-------|
| **Feature** | Monitoring & Launch Readiness |
| **Status** | Planned |
| **Date** | 2026-05-18 |
| **Spec Version** | 1.0 |
| **Phase** | MVP |
| **Features Covered** | #21 Error Monitoring & Crashlytics, #23 App Store Optimization |
| **Estimated Effort** | ~29h (4 days) |

---

## Overview

Firebase Crashlytics integration for crash and error monitoring across iOS and Android. App store listings for both platforms with kids category compliance, Hindi localization, and privacy policy hosting.

### Acceptance Criteria

1. Crashlytics active on iOS + Android. Non-fatal errors logged with custom keys (screen name, storyId, kidProfileId).
2. Key flows instrumented: API failures, audio playback failures, SVG render failures, download failures, auth errors.
3. Alert configured when crash-free rate drops below 99%.
4. Privacy policy (COPPA/DPDP compliant) hosted on Firebase Hosting.
5. App Store (iOS) + Play Store (Android) listings with Hindi localization.
6. Kids category metadata configured for both stores.

---

## Architecture

### Crash Reporter

```dart
class CrashReporter {
  // Singleton
  static final instance = CrashReporter._();

  void logError(dynamic error, StackTrace stack, {Map<String, String>? context});
  void setCustomKey(String key, String value);
  void log(String message);
  void setUserId(String parentId);  // Parent ID only, never child ID
}
```

### Error Categories

| Category | Examples | Custom Keys |
|----------|----------|-------------|
| `api` | 4xx/5xx responses, timeouts | endpoint, statusCode |
| `audio` | Load failure, playback error | storyId, stepId |
| `svg` | Render failure, parse error | storyId, stepId, assetUrl |
| `download` | Network failure, disk full | storyId, fileType |
| `auth` | Sign-in failure, token refresh | provider, errorCode |

### App Store Requirements

| Platform | Kids Category | Requirements |
|----------|--------------|-------------|
| iOS | Kids (6-8, 9-11) | No third-party analytics, no ads, privacy policy URL, age rating |
| Android | Designed for Families | Target age group, teacher-approved eligibility, privacy policy, ads declaration (none) |

---

## Implementation Plan

| # | Task | Description | Est. |
|---|------|-------------|------|
| 1 | Crashlytics setup | Add `firebase_crashlytics` package, configure iOS (Xcode build phase) and Android (Gradle plugin) | 2h |
| 2 | Crash reporter singleton | Implement `CrashReporter` class: `logError()`, `setCustomKey()`, `log()`, `setUserId()` | 2h |
| 3 | Structured error logger | Category-based logging (api, audio, svg, download, auth) with consistent custom key formatting | 3h |
| 4 | Global error handler | Configure `FlutterError.onError` for framework errors. Wrap `main()` with `runZonedGuarded` for async errors. | 2h |
| 5 | Instrument key flows | Add error logging across: API service, audio player, SVG renderer, download manager, auth repository | 4h |
| 6 | Crashlytics alerts | Configure velocity alerts in Firebase Console. Set threshold: crash-free rate < 99% | 1h |
| 7 | Privacy policy | Write plain-language, COPPA/DPDP compliant privacy policy. Deploy to Firebase Hosting. | 4h |
| 8 | iOS App Store listing | Title, subtitle, description, keywords, screenshots spec, age rating, kids category config | 3h |
| 9 | Android Play Store listing | Title, short/full description, tags, screenshots spec, content rating, Designed for Families config | 3h |
| 10 | Hindi localization | Translate store listing metadata (title, description) to Hindi for India market | 2h |
| 11 | Screenshot specification | Define 6 key screenshot scenes per platform (splash, profile selector, browser, player, choices, offline library) | 2h |
| 12 | Kids compliance checklist | Verify Apple Kids Category and Google Designed for Families requirements. Document compliance evidence. | 2h |

### Dependencies

`firebase_crashlytics`

---

## Edge Cases & Error Handling

| Edge Case | Handling |
|-----------|---------|
| Crashlytics init failure | Fail silently, log to console. App functions normally without crash reporting. |
| Excessive error volume | Sampling: log first occurrence + every 10th for repeated errors. |
| Privacy: child data in logs | Never log kid names, ages, or profile IDs to Crashlytics. Use parent ID only. |
| Store rejection for kids category | Pre-submission checklist. No third-party SDKs that collect child data. |

---

## Testing Strategy

| Test Type | Cases |
|-----------|-------|
| **Unit** | CrashReporter methods called with correct parameters. Category-based key formatting. |
| **Integration** | Trigger known errors → verify they appear in Firebase Crashlytics console. |
| **Manual** | Force crash → verify Crashlytics report. Review store listing previews. Privacy policy readability review. |

---

## Effort Estimate

**Total: ~29h (4 days)**
