/// Compact booking card (from `DriverBookingListResource`).
class BookingListItem {
  const BookingListItem({
    required this.uuid,
    required this.stage,
    this.assignmentId,
    this.code,
    this.serviceType,
    this.tripType,
    this.isRoundTrip = false,
    this.customerName,
    this.customerPhone,
    this.pickupPoint,
    this.pickupLocationName,
    this.dropoffPoint,
    this.dropoffLocationName,
    this.departureDatetime,
    this.legDepartureDatetime,
    this.linkedOutboundDatetime,
    this.linkedReturnDatetime,
    this.passengerCount,
    this.vehicleBooked,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleSeats,
    this.acceptedAt,
    this.allowedActions = const [],
    this.pickupIssueReasonOptions = const [],
    this.pickupIssueNoteMaxLength = 500,
  });

  final String uuid;
  final String stage;
  final int? assignmentId;
  final String? code;
  final String? serviceType;
  final String? tripType;
  final bool isRoundTrip;
  final String? customerName;
  final String? customerPhone;
  final String? pickupPoint;
  final String? pickupLocationName;
  final String? dropoffPoint;
  final String? dropoffLocationName;
  final String? departureDatetime;
  final String? legDepartureDatetime;
  final String? linkedOutboundDatetime;
  final String? linkedReturnDatetime;
  final int? passengerCount;
  final String? vehicleBooked;
  final String? vehicleModel;
  final String? vehiclePlate;
  final String? vehicleColor;
  final int? vehicleSeats;
  final String? acceptedAt;
  final List<String> allowedActions;
  final List<String> pickupIssueReasonOptions;
  final int pickupIssueNoteMaxLength;

  String get pickupLabel {
    if (pickupLocationName != null && pickupLocationName!.isNotEmpty) {
      return pickupLocationName!;
    }
    return pickupPoint ?? '—';
  }

  String get dropoffLabel {
    if (dropoffLocationName != null && dropoffLocationName!.isNotEmpty) {
      return dropoffLocationName!;
    }
    return dropoffPoint ?? '—';
  }

  /// Whether a usable destination is present.
  bool get hasDropoff => dropoffLabel != '—';

  /// Whether a dialable customer phone is present.
  bool get hasPhone =>
      customerPhone != null &&
      customerPhone!.isNotEmpty &&
      customerPhone != 'N/A';

  bool get hasVehicle =>
      (vehicleBooked?.isNotEmpty ?? false) ||
      (vehicleModel?.isNotEmpty ?? false) ||
      (vehiclePlate?.isNotEmpty ?? false);

  String? get assignedVehicleLabel {
    final parts = <String>[
      if (vehicleModel != null && vehicleModel!.isNotEmpty) vehicleModel!,
      if (vehiclePlate != null && vehiclePlate!.isNotEmpty) vehiclePlate!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  bool get isReturnLeg => tripType == 'return';
  bool get isOutboundLeg => tripType == null || tripType == 'outbound';
  String get displayDepartureDatetime =>
      legDepartureDatetime ?? departureDatetime ?? '';

  String? get linkedLegDatetime =>
      isReturnLeg ? linkedOutboundDatetime : linkedReturnDatetime;

  /// The forward trip step to act on (start → arrived → meet_passenger →
  /// complete), ignoring the secondary pickup-issue action.
  /// Null when there's nothing to advance.
  String? get nextAction {
    for (final a in allowedActions) {
      if (a != 'report_pickup_issue') return a;
    }
    return null;
  }

  factory BookingListItem.fromJson(
    Map<String, dynamic> json,
  ) => BookingListItem(
    uuid: json['uuid']?.toString() ?? '',
    stage: json['stage']?.toString() ?? 'assigned',
    assignmentId: (json['assignment_id'] as num?)?.toInt(),
    code: json['code']?.toString(),
    serviceType: json['service_type']?.toString(),
    tripType: json['trip_type']?.toString(),
    isRoundTrip: json['is_round_trip'] == true,
    customerName: json['customer_name']?.toString(),
    customerPhone: json['customer_phone']?.toString(),
    pickupPoint: json['pickup_point']?.toString(),
    pickupLocationName: json['pickup_location_name']?.toString(),
    dropoffPoint: json['dropoff_point']?.toString(),
    dropoffLocationName: json['dropoff_location_name']?.toString(),
    departureDatetime: json['departure_datetime']?.toString(),
    legDepartureDatetime: json['leg_departure_datetime']?.toString(),
    linkedOutboundDatetime: json['linked_outbound_datetime']?.toString(),
    linkedReturnDatetime: json['linked_return_datetime']?.toString(),
    passengerCount: (json['passenger_count'] as num?)?.toInt(),
    vehicleBooked: (json['vehicle'] as Map<String, dynamic>?)?['booked_name']
        ?.toString(),
    vehicleModel: (json['vehicle'] as Map<String, dynamic>?)?['model']
        ?.toString(),
    vehiclePlate: (json['vehicle'] as Map<String, dynamic>?)?['plate_number']
        ?.toString(),
    vehicleColor: (json['vehicle'] as Map<String, dynamic>?)?['color']
        ?.toString(),
    vehicleSeats: ((json['vehicle'] as Map<String, dynamic>?)?['seats'] as num?)
        ?.toInt(),
    acceptedAt: json['accepted_at']?.toString(),
    pickupIssueReasonOptions:
        (json['pickup_issue_reason_options'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    pickupIssueNoteMaxLength:
        (json['pickup_issue_note_max_length'] as num?)?.toInt() ?? 500,
    allowedActions:
        (json['allowed_actions'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
  );
}
