import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'app_initializer.dart';
import 'init_result.dart';

/// The splash screen shown at cold start.
///
/// Behaviour:
/// - Plays `assets/animations/splash.json` full-screen.
/// - Guarantees a **minimum** 2-second display time (branding moment).
/// - If initialization takes longer than 5 seconds a "Still loading…" hint
///   appears at the bottom.
/// - Navigates to [InitResult.initialRoute] via [GoRouter] once **both**
///   the minimum time has elapsed and initialization is complete.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _minSplashDuration = Duration(seconds: 2);
  static const Duration _slowLoadThreshold = Duration(seconds: 5);

  InitResult? _initResult;
  bool _minTimeElapsed = false;
  bool _showStillLoading = false;

  Timer? _slowLoadTimer;

  @override
  void initState() {
    super.initState();
    _startInitialization();
    _scheduleMinSplash();
    _scheduleSlowLoadHint();
  }

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> _startInitialization() async {
    // Firebase must be initialized before any other Firebase service is used.
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Already initialized in tests / hot restart — safe to ignore.
      debugPrint('[SplashScreen] Firebase.initializeApp: $e');
    }

    final result = await AppInitializer().initialize();

    if (!mounted) return;
    setState(() => _initResult = result);
    _maybeNavigate();
  }

  void _scheduleMinSplash() {
    Future.delayed(_minSplashDuration, () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      _maybeNavigate();
    });
  }

  void _scheduleSlowLoadHint() {
    _slowLoadTimer = Timer(_slowLoadThreshold, () {
      if (!mounted) return;
      if (_initResult == null) {
        setState(() => _showStillLoading = true);
      }
    });
  }

  /// Navigates away only when both conditions are satisfied.
  void _maybeNavigate() {
    if (!_minTimeElapsed || _initResult == null) return;
    final route = _initResult!.initialRoute;
    context.go(route);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen Lottie animation
          Lottie.asset(
            'assets/animations/splash.json',
            fit: BoxFit.cover,
            repeat: true,
            // Fallback if the animation asset is not yet bundled:
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xFF1B2838),
            ),
          ),

          // "Still loading…" hint that appears after 5 seconds
          if (_showStillLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: AnimatedOpacity(
                opacity: _showStillLoading ? 0.6 : 0,
                duration: const Duration(milliseconds: 400),
                child: const Text(
                  'Still loading…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
