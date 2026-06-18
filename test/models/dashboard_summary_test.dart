import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/data/models/dashboard_summary.dart';

void main() {
  group('DashboardSummary.fromJson', () {
    test('parses online state, counts and next pickup', () {
      final summary = DashboardSummary.fromJson({
        'is_online': true,
        'counts': {'assigned': 2, 'accepted': 1, 'on_trip': 0, 'completed': 5},
        'next_pickup': {
          'uuid': 'u1',
          'stage': 'assigned',
          'customer_name': 'Jane',
          'allowed_actions': ['accept'],
        },
      });

      expect(summary.isOnline, isTrue);
      expect(summary.counts.assigned, 2);
      expect(summary.counts.completed, 5);
      expect(summary.nextPickup, isNotNull);
      expect(summary.nextPickup!.customerName, 'Jane');
    });

    test('handles null next pickup and missing counts', () {
      final summary = DashboardSummary.fromJson({
        'is_online': false,
        'counts': null,
        'next_pickup': null,
      });

      expect(summary.isOnline, isFalse);
      expect(summary.counts.assigned, 0);
      expect(summary.nextPickup, isNull);
    });
  });
}
