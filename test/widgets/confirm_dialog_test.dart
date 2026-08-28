import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:veha_driver_app/app/core/widgets/confirm_dialog.dart';

void main() {
  Future<void> pumpHost(WidgetTester tester, void Function() onTap) {
    return tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: onTap, child: const Text('go')),
          ),
        ),
      ),
    );
  }

  testWidgets('confirming returns true and lets the action run', (
    tester,
  ) async {
    var ran = false;
    await pumpHost(tester, () async {
      if (await confirmStepAction('arrived')) ran = true;
    });

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('confirm_arrived_title'), findsOneWidget);

    await tester.tap(find.text('yes'));
    await tester.pumpAndSettle();
    expect(ran, isTrue);
  });

  testWidgets('declining runs nothing', (tester) async {
    var ran = false;
    await pumpHost(tester, () async {
      if (await confirmStepAction('arrived')) ran = true;
    });

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('no'));
    await tester.pumpAndSettle();

    expect(ran, isFalse);
    expect(find.text('confirm_arrived_title'), findsNothing);
  });

  testWidgets('a tap outside the dialog does not count as consent', (
    tester,
  ) async {
    var ran = false;
    await pumpHost(tester, () async {
      if (await confirmStepAction('start')) ran = true;
    });

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(ran, isFalse);
    expect(find.text('confirm_start_title'), findsOneWidget);
  });

  testWidgets('an action with no copy runs without prompting', (tester) async {
    var ran = false;
    await pumpHost(tester, () async {
      if (await confirmStepAction('complete')) ran = true;
    });

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(ran, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
