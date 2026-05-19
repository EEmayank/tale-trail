import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TaleButton', () {
    testWidgets('renders label text', (tester) async {
      await pumpTestableWidget(
        tester,
        TaleButton(
          label: 'Get Started',
          onPressed: () {},
        ),
      );
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await pumpTestableWidget(
        tester,
        TaleButton(
          label: 'Submit',
          isLoading: true,
          onPressed: () {},
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await pumpTestableWidget(
        tester,
        TaleButton(
          label: 'Tap Me',
          onPressed: () => pressed = true,
        ),
      );
      await tester.tap(find.byType(TaleButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when null (disabled)', (tester) async {
      await pumpTestableWidget(
        tester,
        const TaleButton(label: 'Disabled'),
      );
      // Should not throw
      await tester.tap(find.byType(TaleButton), warnIfMissed: false);
    });
  });
}
