import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'init_result.dart';

/// Orchestrates all async work that must complete before the app is usable.
///
/// Call [initialize] once from [SplashScreen.initState]. All steps run in
/// parallel via [Future.wait], each guarded by a 5-second timeout. If any
/// non-critical step times out the app continues with the best available state.
class AppInitializer {
  AppInitializer({
    FirebaseAuth? auth,
    FirebaseRemoteConfig? remoteConfig,
    FirebaseFirestore? firestore,
    FirebaseCrashlytics? crashlytics,
    SharedPreferences? prefs,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _prefs = prefs; // null means we'll fetch it lazily

  final FirebaseAuth _auth;
  final FirebaseRemoteConfig _remoteConfig;
  final FirebaseFirestore _firestore;
  final FirebaseCrashlytics _crashlytics;

  /// Lazily initialised when [initialize] runs.
  SharedPreferences? _prefs;

  // Resolved during initialization
  bool _isAuthenticated = false;
  bool _hasActiveProfile = false;
  bool _isFirstLaunch = false;
  bool _isOffline = false;

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  /// Runs all initialization steps in parallel and returns an [InitResult].
  ///
  /// Safe to call multiple times, but typically only called once from splash.
  Future<InitResult> initialize() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Ensure SharedPreferences is ready before parallel steps that need it.
      _prefs ??= await SharedPreferences.getInstance();

      // Run all steps concurrently, each with its own 5-second ceiling.
      await Future.wait([
        _runWithTimeout(_checkAuthState, 'checkAuthState'),
        _runWithTimeout(_fetchRemoteConfig, 'fetchRemoteConfig'),
        _runWithTimeout(_loadActiveProfile, 'loadActiveProfile'),
        _runWithTimeout(_checkFirstLaunch, 'checkFirstLaunch'),
        _runWithTimeout(_checkConnectivity, 'checkConnectivity'),
      ]);
    } catch (e, st) {
      _log('Fatal initialization error: $e');
      _crashlytics.recordError(e, st, fatal: false);
      return InitResult.error(e.toString());
    } finally {
      stopwatch.stop();
    }

    return InitResult(
      isAuthenticated: _isAuthenticated,
      hasActiveProfile: _hasActiveProfile,
      isFirstLaunch: _isFirstLaunch,
      isOffline: _isOffline,
      initDurationMs: stopwatch.elapsedMilliseconds,
    );
  }

  // ---------------------------------------------------------------------------
  // Step: Auth state
  // ---------------------------------------------------------------------------

  Future<void> _checkAuthState() async {
    _log('Checking auth state…');
    final user = _auth.currentUser;

    if (user == null) {
      _isAuthenticated = false;
      _log('No current user found');
      return;
    }

    // Attempt token refresh to validate session.
    try {
      await user.getIdToken(true); // force refresh
      _isAuthenticated = true;
      _log('Token refreshed — user ${user.uid} is authenticated');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        // Network is down but we still have a cached session — allow offline.
        _isAuthenticated = true;
        _isOffline = true;
        _log('Network down — treating cached user as authenticated (offline)');
      } else {
        // Invalid / revoked token — sign out to force re-login.
        _log('Invalid token (${e.code}), signing out');
        await _auth.signOut();
        _isAuthenticated = false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Step: Remote Config
  // ---------------------------------------------------------------------------

  Future<void> _fetchRemoteConfig() async {
    _log('Fetching Remote Config…');

    // Apply defaults so the app works even when the network is unavailable.
    await _remoteConfig.setDefaults({
      'parallax_enabled': true,
      'bedtime_mode_enabled': true,
      'max_offline_stories': 10,
      'content_refresh_interval_hours': 6,
      'force_update_min_version': '1.0.0',
      'maintenance_mode': false,
    });

    try {
      await _remoteConfig
          .fetchAndActivate()
          .timeout(const Duration(seconds: 3));
      _log('Remote Config fetched and activated');
    } catch (e) {
      // Non-fatal — defaults are already applied.
      _log('Remote Config fetch failed (using defaults): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Step: Active profile
  // ---------------------------------------------------------------------------

  Future<void> _loadActiveProfile() async {
    _log('Loading active profile…');
    final prefs = _prefs!;
    final profileId = prefs.getString('lastActiveProfileId');

    if (profileId == null || profileId.isEmpty) {
      _hasActiveProfile = false;
      _log('No last active profile ID in SharedPreferences');
      return;
    }

    try {
      // Use cache-first to avoid blocking on network during startup.
      final user = _auth.currentUser;
      if (user == null) {
        _hasActiveProfile = false;
        return;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profiles')
          .doc(profileId)
          .get(const GetOptions(source: Source.cache));

      _hasActiveProfile = doc.exists;
      _log(
        doc.exists
            ? 'Active profile restored: $profileId'
            : 'Cached profile not found: $profileId',
      );
    } catch (e) {
      // Cache miss or Firestore unavailable — proceed without a profile.
      _hasActiveProfile = false;
      _log('Could not load active profile from cache: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Step: First launch
  // ---------------------------------------------------------------------------

  Future<void> _checkFirstLaunch() async {
    _log('Checking first launch…');
    final hasLaunched = _prefs!.getBool('hasLaunchedBefore') ?? false;
    _isFirstLaunch = !hasLaunched;
    _log(_isFirstLaunch ? 'First launch detected' : 'Returning user');
  }

  // ---------------------------------------------------------------------------
  // Step: Connectivity
  // ---------------------------------------------------------------------------

  Future<void> _checkConnectivity() async {
    _log('Checking connectivity…');
    try {
      final results = await Connectivity().checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) {
        _isOffline = true;
      }
      _log('Connectivity: $result');
    } catch (e) {
      _log('Connectivity check failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Runs [step] with a 5-second timeout. Logs and swallows [TimeoutException]
  /// so that one slow step cannot block the rest of the app from launching.
  Future<void> _runWithTimeout(
    Future<void> Function() step,
    String name,
  ) async {
    try {
      await step().timeout(const Duration(seconds: 5));
    } catch (e) {
      _log('Step "$name" failed or timed out: $e');
    }
  }

  /// Writes [message] to both [debugPrint] and Firebase Crashlytics logs.
  void _log(String message) {
    debugPrint('[AppInitializer] $message');
    _crashlytics.log(message);
  }
}
