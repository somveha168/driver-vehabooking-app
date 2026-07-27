import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/driver_notification.dart';

void main() {
  test('parses cancelled leg identity from notification data', () {
    final notification = DriverNotification.fromJson({
      'id': 'notice-1',
      'type': 'booking.taxi.driver.leg_cancelled',
      'title': 'Trip cancelled',
      'message': 'Your return trip was cancelled.',
      'data': {
        'booking_uuid': 'booking-uuid',
        'assignment_id': '123',
        'booking_leg_id': '456',
        'trip_type': 'return',
      },
    });

    expect(notification.assignmentId, 123);
    expect(notification.bookingLegId, 456);
    expect(notification.tripType, 'return');
    expect(notification.canOpenTrip, isTrue);
  });
}
