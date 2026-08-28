import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:veha_driver_app/app/core/widgets/trip_step_tracker.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String stage,
    String? driverTripStatus,
    bool compact = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripStepTracker(
            stage: stage,
            driverTripStatus: driverTripStatus,
            compact: compact,
          ),
        ),
      ),
    );
  }

  int ticks(WidgetTester tester) =>
      tester.widgetList(find.byIcon(IconsaxPlusLinear.tick_circle)).length;

  testWidgets('renders four steps', (tester) async {
    await pump(tester, stage: 'start');
    expect(find.byType(Icon), findsNWidgets(4));
  });

  testWidgets('marks earlier steps done and leaves later ones as icons', (
    tester,
  ) async {
    await pump(tester, stage: 'meet_passenger');

    // Start + Arrived are behind us; Meet is current; Drop is ahead.
    expect(ticks(tester), 2);
    expect(find.byIcon(IconsaxPlusLinear.profile), findsOneWidget);
    expect(find.byIcon(IconsaxPlusLinear.location), findsOneWidget);
  });

  testWidgets('nothing is done before the trip starts', (tester) async {
    await pump(tester, stage: 'assigned');
    expect(ticks(tester), 0);
    expect(find.byIcon(IconsaxPlusBold.car), findsOneWidget);
  });

  testWidgets('a completed trip marks every step done', (tester) async {
    await pump(tester, stage: 'completed');
    expect(ticks(tester), 4);
  });

  testWidgets('driverTripStatus takes precedence over stage', (tester) async {
    // Stage still says the trip is only assigned, but the driver has reported
    // arriving - the tracker must follow the driver's status.
    await pump(tester, stage: 'assigned', driverTripStatus: 'meet_passenger');
    expect(ticks(tester), 2);
  });

  testWidgets('compact renders smaller markers than the default', (
    tester,
  ) async {
    await pump(tester, stage: 'start');
    final normal = tester.getSize(find.byType(Icon).first);

    await pump(tester, stage: 'start', compact: true);
    final compact = tester.getSize(find.byType(Icon).first);

    expect(compact.width, lessThan(normal.width));
  });
}
