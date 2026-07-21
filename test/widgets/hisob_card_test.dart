import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_card.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('HisobCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        buildApp(const HisobCard(child: Text('Card Content'))),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('responds to tap when onTap provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildApp(
          HisobCard(onTap: () => tapped = true, child: const Text('Tappable')),
        ),
      );

      await tester.tap(find.text('Tappable'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('does not respond to tap when no onTap', (tester) async {
      await tester.pumpWidget(buildApp(const HisobCard(child: Text('Static'))));

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('hero variant renders content', (tester) async {
      await tester.pumpWidget(
        buildApp(HisobCard.hero(child: const Text('Hero'))),
      );

      expect(find.text('Hero'), findsOneWidget);
    });
  });
}
