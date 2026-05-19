import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_stories/app.dart';
import 'package:kids_stories/core/theme/app_theme.dart';

/// Wraps a widget under test with the minimum providers and theme needed
/// to render TaleTrail UI components in isolation.
Widget buildTestableWidget(
  Widget widget, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: lightTheme,
      home: widget,
    ),
  );
}

/// Pumps a testable widget and settles animations.
Future<void> pumpTestableWidget(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(buildTestableWidget(widget, overrides: overrides));
  await tester.pumpAndSettle();
}
