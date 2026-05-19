import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_stories/core/widgets/badge_chip.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BadgeChip', () {
    testWidgets('renders label', (tester) async {
      await pumpTestableWidget(
        tester,
        const BadgeChip(label: 'Test'),
      );
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('BadgeChip.age shows correct label', (tester) async {
      await pumpTestableWidget(tester, BadgeChip.age(7));
      expect(find.text('Age 7+'), findsOneWidget);
    });

    testWidgets('BadgeChip.duration shows minutes', (tester) async {
      await pumpTestableWidget(tester, BadgeChip.duration(15));
      expect(find.text('15m'), findsOneWidget);
    });

    testWidgets('BadgeChip.free renders FREE chip', (tester) async {
      await pumpTestableWidget(tester, const BadgeChip.free());
      expect(find.text('FREE'), findsOneWidget);
    });

    testWidgets('BadgeChip.premium renders ⭐ Premium chip', (tester) async {
      await pumpTestableWidget(tester, const BadgeChip.premium());
      expect(find.textContaining('Premium'), findsOneWidget);
    });
  });
}
