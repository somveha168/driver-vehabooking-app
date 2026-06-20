import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/booking_detail.dart';

void main() {
  group('BookingDetail.fromJson', () {
    test('parses an airport booking with pickup coordinates and actions', () {
      final json = {
        'uuid': 'abc-123',
        'code': 'TAX-1',
        'service_type': 'airport',
        'trip_type': 'outbound',
        'stage': 'accepted',
        'status': 'confirmed',
        'driver_pickup_status': 'pending',
        'accepted_at': '2026-06-18T08:00:00+07:00',
        'allowed_actions': ['confirm_pickup'],
        'customer': {'name': 'Jane Doe', 'phone': '+85599999999'},
        'pickup': {
          'address': 'Hotel Sunrise',
          'location_name': 'BKK1',
          'latitude': 11.5564,
          'longitude': 104.9282,
        },
        'dropoff': {'address': 'PNH Airport'},
        'departure_datetime': '2026-06-18T09:00:00+07:00',
        'passenger_count': 2,
        'vehicle': {'type': 'Sedan', 'plate_number': '2AB-1234'},
        'flight': {'number': 'QR123', 'airline': 'Qatar', 'terminal': '1'},
      };

      final b = BookingDetail.fromJson(json);

      expect(b.uuid, 'abc-123');
      expect(b.stage, 'accepted');
      expect(b.isAirport, isTrue);
      expect(b.allows('confirm_pickup'), isTrue);
      expect(b.allows('complete'), isFalse);
      expect(b.customerPhone, '+85599999999');
      expect(b.pickup.hasCoordinates, isTrue);
      expect(b.pickup.latitude, 11.5564);
      expect(b.pickup.label, 'BKK1');
      expect(b.flightNumber, 'QR123');
    });

    test('parses the trip lifecycle status, timestamps and next action', () {
      final b = BookingDetail.fromJson({
        'uuid': 'u1',
        'stage': 'arrived_location',
        'driver_trip_status': 'arrived_location',
        'started_at': '2026-06-19T09:00:00+07:00',
        'arrived_at': '2026-06-19T09:20:00+07:00',
        'met_passenger_at': null,
        'dropped_at': null,
        'allowed_actions': ['meet_passenger'],
      });

      expect(b.driverTripStatus, 'arrived_location');
      expect(b.startedAt, isNotNull);
      expect(b.arrivedAt, isNotNull);
      expect(b.metPassengerAt, isNull);
      expect(b.allows('meet_passenger'), isTrue);
    });

    test('offers report_not_met_passenger and parses the not-met reason', () {
      final b = BookingDetail.fromJson({
        'uuid': 'u2',
        'stage': 'arrived_location',
        'driver_trip_status': 'arrived_location',
        'allowed_actions': ['meet_passenger', 'report_not_met_passenger'],
      });

      expect(b.allows('report_not_met_passenger'), isTrue);

      final closed = BookingDetail.fromJson({
        'uuid': 'u3',
        'stage': 'not_met_passenger',
        'driver_trip_status': 'not_met_passenger',
        'not_met_passenger_reason': 'didnt_show',
        'allowed_actions': [],
      });

      expect(closed.stage, 'not_met_passenger');
      expect(closed.notMetPassengerReason, 'didnt_show');
      expect(closed.can, isFalse);
    });

    test('handles missing optional blocks gracefully', () {
      final b = BookingDetail.fromJson({'uuid': 'x', 'stage': 'assigned'});

      expect(b.allowedActions, isEmpty);
      expect(b.can, isFalse);
      expect(b.pickup.hasCoordinates, isFalse);
      expect(b.pickup.label, '—');
      expect(b.isAirport, isFalse);
    });
  });
}
