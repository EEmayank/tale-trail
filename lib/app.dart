import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kids_stories/core/navigation/app_router.dart';
import 'package:kids_stories/core/providers/core_providers.dart';
import 'package:kids_stories/core/theme/app_theme.dart';

/// Root widget for TaleTrail.
///
/// Watches [appRouterProvider] and [themeModeProvider] and rebuilds
/// [MaterialApp.router] whenever either changes.
class TaleTrailApp extends ConsumerWidget {
  const TaleTrailApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appThemeMode = ref.watch(themeModeProvider);

    // Map TaleTrail's theme mode enum to Flutter's ThemeMode.
    final flutterThemeMode = switch (appThemeMode) {
      AppThemeMode.bedtime => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      // storyDynamic uses the light scaffold; the player overrides colours
      // locally via Theme.of inheritance.
      AppThemeMode.storyDynamic => ThemeMode.light,
    };

    return MaterialApp.router(
      routerConfig: router,
      title: 'TaleTrail',
      theme: TaleTheme.lightTheme,
      darkTheme: TaleTheme.bedtimeTheme,
      themeMode: flutterThemeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
    );
  }
}
