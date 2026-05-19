import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/hive_setup.dart';

/// TaleTrail entry point.
///
/// Firebase is **not** initialized here — it is initialized inside
/// [AppInitializer] (called from [SplashScreen]) so that the initialization
/// timeline is tracked and errors are surfaced gracefully.
///
/// Hive IS initialized here so local storage is ready before the first frame.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait orientation.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive local storage before the app renders.
  await initHive();

  // Set system UI overlay style (status bar).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: TaleTrailApp(),
    ),
  );
}
