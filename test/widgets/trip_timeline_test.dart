import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:veha_driver_app/app/core/i18n/app_translations.dart';
import 'package:veha_driver_app/app/core/widgets/trip_timeline.dart';

Widget _host(Widget child) => GetMaterialApp(
  translations: AppTranslations(),
  locale: const Locale('en', 'US'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders all four stage labels', (tester) async {
    await tester.pumpWidget(_host(const TripTimeline(stage: 'assigned')));

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('Meet Passenger'), findsOneWidget);
    expect(find.text('Drop Passenger'), findsOneWidget);
  });

  testWidgets('shows a check for each completed step', (tester) async {
    // arrived_location => Start + Arrived done (2 checks).
    await tester.pumpWidget(
      _host(
        const TripTimeline(
          stage: 'arrived_location',
          startedAt: '2026-06-20T07:00:00Z',
          arrivedAt: '2026-06-20T07:20:00Z',
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets('marks the current step as in progress', (tester) async {
    await tester.pumpWidget(_host(const TripTimeline(stage: 'start')));
    await tester.pump(const Duration(milliseconds: 100)); // let pulse start

    // Start is done, Arrived is the current (in-progress) node.
    expect(find.text('In progress…'), findsOneWidget);
  });
}
