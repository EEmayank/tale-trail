import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// AppThemeMode enum
// ---------------------------------------------------------------------------

enum AppThemeMode {
  /// Standard daytime theme with parchment / terracotta palette.
  light,

  /// Dark bedtime theme with navy / soft-gold palette.
  bedtime,

  /// Dynamically generated theme based on the active story's palette.
  storyDynamic,
}

// ---------------------------------------------------------------------------
// SharedPreferences
// ---------------------------------------------------------------------------

/// Async provider for [SharedPreferences].
///
/// Await this in any widget or provider that needs persistent storage.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
  name: 'sharedPreferencesProvider',
);

// ---------------------------------------------------------------------------
// First Launch
// ---------------------------------------------------------------------------

/// Returns `true` when the app has never been launched before.
///
/// Reads the `'hasLaunchedBefore'` key from [SharedPreferences]; if the key
/// is absent the user has never launched the app.
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final hasLaunched = prefs.getBool('hasLaunchedBefore') ?? false;
  return !hasLaunched;
}, name: 'isFirstLaunchProvider');

// ---------------------------------------------------------------------------
// Theme Mode
// ---------------------------------------------------------------------------

/// Mutable theme-mode provider.
///
/// Defaults to [AppThemeMode.light]. Widgets can call
/// `ref.read(themeModeProvider.notifier).state = AppThemeMode.bedtime` to
/// switch themes at runtime.
final themeModeProvider = StateProvider<AppThemeMode>(
  (ref) => AppThemeMode.light,
  name: 'themeModeProvider',
);

// ---------------------------------------------------------------------------
// Connectivity
// ---------------------------------------------------------------------------

/// Emits a [ConnectivityResult] whenever the device's network status changes.
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) =>
            results.isNotEmpty ? results.first : ConnectivityResult.none,
      );
}, name: 'connectivityProvider');

/// Derived provider — `true` when the device has no network connectivity.
final isOfflineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.when(
    data: (result) => result == ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
}, name: 'isOfflineProvider');
