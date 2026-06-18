import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:veha_driver_app/app/core/i18n/app_translations.dart';
import 'package:veha_driver_app/app/data/models/booking_list_item.dart';
import 'package:veha_driver_app/app/modules/bookings/widgets/booking_card.dart';

void main() {
  testWidgets('renders customer + pickup and fires onTap', (tester) async {
    var tapped = false;
    const item = BookingListItem(
      uuid: 'u1',
      stage: 'assigned',
      serviceType: 'private',
      customerName: 'Jane Doe',
      pickupLocationName: 'BKK1',
      passengerCount: 2,
      allowedActions: ['accept'],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: BookingCard(booking: item, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('BKK1'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget); // stage chip via i18n

    await tester.tap(find.byType(BookingCard));
    expect(tapped, isTrue);
  });
}
