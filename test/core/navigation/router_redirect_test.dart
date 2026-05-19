import 'package:flutter_test/flutter_test.dart';
import 'package:kids_stories/core/initialization/init_result.dart';

/// Unit tests for InitResult.initialRoute — the navigation logic at startup.
/// Matches the spec test IDs T2.1–T2.5.
void main() {
  group('InitResult.initialRoute', () {
    test('T2.1 — first launch → /onboarding', () {
      final result = InitResult(
        isAuthenticated: false,
        hasActiveProfile: false,
        isFirstLaunch: true,
      );
      expect(result.initialRoute, equals('/onboarding'));
    });

    test('T2.2 — unauthenticated returning user → /login', () {
      final result = InitResult(
        isAuthenticated: false,
        hasActiveProfile: false,
        isFirstLaunch: false,
      );
      expect(result.initialRoute, equals('/login'));
    });

    test('T2.3 — authenticated user without profile → /profiles', () {
      final result = InitResult(
        isAuthenticated: true,
        hasActiveProfile: false,
        isFirstLaunch: false,
      );
      expect(result.initialRoute, equals('/profiles'));
    });

    test('T2.4 — authenticated user with profile → /home', () {
      final result = InitResult(
        isAuthenticated: true,
        hasActiveProfile: true,
        isFirstLaunch: false,
      );
      expect(result.initialRoute, equals('/home'));
    });

    test('T2.5 — error state → /error with message', () {
      final result = InitResult.error('Unable to start TaleTrail.');
      expect(result.initialRoute, startsWith('/error'));
      expect(result.initialRoute, contains('Unable+to+start'));
    });

    test('hasError is false for successful init', () {
      final result = InitResult(isAuthenticated: true, hasActiveProfile: true);
      expect(result.hasError, isFalse);
    });

    test('hasError is true for error result', () {
      final result = InitResult.error('Something went wrong');
      expect(result.hasError, isTrue);
    });

    test('isFirstLaunch takes priority over unauthenticated', () {
      // First launch and unauthenticated → should show onboarding, not login
      final result = InitResult(
        isAuthenticated: false,
        isFirstLaunch: true,
      );
      expect(result.initialRoute, equals('/onboarding'));
    });
  });
}
