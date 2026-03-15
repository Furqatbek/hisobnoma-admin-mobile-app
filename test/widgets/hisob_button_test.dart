import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_button.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('HisobButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildApp(
        HisobButton(label: 'Submit', onPressed: () {}),
      ));

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildApp(
        HisobButton(label: 'Tap Me', onPressed: () => tapped = true),
      ));

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(buildApp(
        const HisobButton(label: 'Loading', isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('renders even when onPressed is null', (tester) async {
      await tester.pumpWidget(buildApp(
        const HisobButton(label: 'Disabled'),
      ));

      expect(find.text('Disabled'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(buildApp(
        HisobButton(
          label: 'Add',
          icon: Icons.add,
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('secondary variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(buildApp(
        HisobButton.secondary(label: 'Cancel', onPressed: () {}),
      ));

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('text variant renders TextButton', (tester) async {
      await tester.pumpWidget(buildApp(
        HisobButton.text(label: 'Skip', onPressed: () {}),
      ));

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('destructive variant has red background', (tester) async {
      await tester.pumpWidget(buildApp(
        HisobButton.destructive(label: 'Delete', onPressed: () {}),
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
