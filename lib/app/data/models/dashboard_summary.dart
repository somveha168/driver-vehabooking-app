import 'booking_list_item.dart';

/// Driver pipeline counts for the Home dashboard.
class DashboardCounts {
  const DashboardCounts({
    this.assigned = 0,
    this.active = 0,
    this.completed = 0,
  });

  final int assigned;
  final int active;
  final int completed;

  factory DashboardCounts.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return DashboardCounts(
      assigned: n(json['assigned']),
      active: n(json['active']),
      completed: n(json['completed']),
    );
  }
}

/// Home dashboard summary (from `GET api/taxi/v1/driver/dashboard`).
class DashboardSummary {
  const DashboardSummary({
    required this.isOnline,
    required this.counts,
    this.nextPickup,
  });

  final bool isOnline;
  final DashboardCounts counts;
  final BookingListItem? nextPickup;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final next = json['next_pickup'];
    return DashboardSummary(
      isOnline: json['is_online'] == true,
      counts: DashboardCounts.fromJson(json['counts'] as Map<String, dynamic>?),
      nextPickup: next is Map<String, dynamic>
          ? BookingListItem.fromJson(next)
          : null,
    );
  }
}
