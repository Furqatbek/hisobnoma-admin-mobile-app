import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_empty_state.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('HisobEmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(buildApp(
        const HisobEmptyState(
          icon: Icons.inbox,
          title: 'No items',
        ),
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders optional message', (tester) async {
      await tester.pumpWidget(buildApp(
        const HisobEmptyState(
          icon: Icons.inbox,
          title: 'No items',
          message: 'Try adding something',
        ),
      ));

      expect(find.text('Try adding something'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildApp(
        HisobEmptyState(
          icon: Icons.inbox,
          title: 'No items',
          actionLabel: 'Retry',
          onAction: () => pressed = true,
        ),
      ));

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('does not render action button when no label', (tester) async {
      await tester.pumpWidget(buildApp(
        const HisobEmptyState(
          icon: Icons.inbox,
          title: 'No items',
        ),
      ));

      expect(find.byType(TextButton), findsNothing);
    });
  });
}
