import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:veha_driver_app/app/core/widgets/swipe_to_confirm.dart';

void main() {
  Widget harness(Future<void> Function() onConfirmed) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: SwipeToConfirm(label: 'Complete', onConfirmed: onConfirmed),
        ),
      ),
    ),
  );

  testWidgets('fires onConfirmed when dragged to the end', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(harness(() async => confirmed = true));

    await tester.drag(
      find.byIcon(IconsaxPlusLinear.arrow_right_3),
      const Offset(500, 0),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(confirmed, isTrue);
  });

  testWidgets('does not confirm on a short partial drag', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(harness(() async => confirmed = true));

    await tester.drag(
      find.byIcon(IconsaxPlusLinear.arrow_right_3),
      const Offset(40, 0),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(confirmed, isFalse);
  });
}
