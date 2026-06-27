import 'place.dart';

/// Full booking detail (from `DriverBookingDetailResource`).
class BookingDetail {
  const BookingDetail({
    required this.uuid,
    required this.stage,
    this.assignmentId,
    this.code,
    this.serviceType,
    this.tripType,
    this.isRoundTrip = false,
    this.status,
    this.driverPickupStatus,
    this.driverTripStatus,
    this.acceptedAt,
    this.startedAt,
    this.arrivedAt,
    this.metPassengerAt,
    this.droppedAt,
    this.pickupIssueReason,
    this.pickupIssueReasonOptions = const [],
    this.pickupIssueNoteMaxLength = 500,
    this.allowedActions = const [],
    this.startLocked = false,
    this.customerName,
    this.customerPhone,
    this.pickup = const Place(),
    this.dropoff = const Place(),
    this.departureDatetime,
    this.legDepartureDatetime,
    this.linkedOutboundDatetime,
    this.linkedReturnDatetime,
    this.arrivalDatetime,
    this.duration,
    this.passengerCount,
    this.nationality,
    this.notes,
    this.vehicleBooked,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleSeats,
    this.operator,
    this.isReturn = false,
    this.returnDate,
    this.returnTime,
    this.flightNumber,
    this.airline,
    this.terminal,
    this.flightDatetime,
  });

  final String uuid;
  final String stage;
  final int? assignmentId;
  final String? code;
  final String? serviceType;
  final String? tripType;
  final bool isRoundTrip;
  final String? status;
  final String? driverPickupStatus;
  final String? driverTripStatus;
  final String? acceptedAt;
  final String? startedAt;
  final String? arrivedAt;
  final String? metPassengerAt;
  final String? droppedAt;
  final String? pickupIssueReason;
  final List<String> pickupIssueReasonOptions;
  final int pickupIssueNoteMaxLength;
  final List<String> allowedActions;

  /// Start is gated behind "finish your current trip first" (another trip blocks it).
  final bool startLocked;

  final String? customerName;
  final String? customerPhone;

  final Place pickup;
  final Place dropoff;

  final String? departureDatetime;
  final String? legDepartureDatetime;
  final String? linkedOutboundDatetime;
  final String? linkedReturnDatetime;
  final String? arrivalDatetime; // estimated drop = departure + duration
  final int? duration; // route minutes
  final int? passengerCount;
  final String? nationality;
  final String? notes;

  final String? vehicleBooked; // class the customer booked, e.g. "Van 10 Seats"
  final String? vehicleModel; // real assigned vehicle, e.g. "Luxis Camary"
  final String? vehiclePlate;
  final String? vehicleColor;
  final int? vehicleSeats;
  final OperatorContact? operator;

  final bool isReturn;
  final String? returnDate; // ISO date (yyyy-MM-dd)
  final String? returnTime; // HH:mm

  final String? flightNumber;
  final String? airline;
  final String? terminal;
  final String? flightDatetime;

  bool get isAirport => serviceType == 'airport';
  bool get isReturnLeg => tripType == 'return';
  bool get isOutboundLeg => tripType == null || tripType == 'outbound';
  String get displayDepartureDatetime =>
      legDepartureDatetime ?? departureDatetime ?? '';
  String? get linkedLegDatetime =>
      isReturnLeg ? linkedOutboundDatetime : linkedReturnDatetime;
  bool get can => allowedActions.isNotEmpty;
  bool allows(String action) => allowedActions.contains(action);
  bool get canReportPickupIssue => allows('report_pickup_issue');

  DateTime? get departureAt {
    final value = displayDepartureDatetime;
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  Duration? get startOverdueBy {
    final dt = departureAt;
    if (!allows('start') || dt == null) return null;
    final diff = DateTime.now().difference(dt);
    return diff.isNegative ? null : diff;
  }

  bool get isStartOverdue {
    final diff = startOverdueBy;
    return diff != null && diff.inMinutes >= 0;
  }

  bool get isStartVeryOverdue {
    final diff = startOverdueBy;
    return diff != null && diff >= const Duration(hours: 2);
  }

  bool get isStartTooOld {
    final diff = startOverdueBy;
    return diff != null && diff >= const Duration(hours: 6);
  }

  /// A round-trip booking with a usable return date.
  bool get hasReturn =>
      isReturn && returnDate != null && returnDate!.isNotEmpty;

  /// Whether any vehicle info (booked or assigned) exists.
  bool get hasVehicle =>
      (vehicleBooked?.isNotEmpty ?? false) ||
      (vehicleModel?.isNotEmpty ?? false) ||
      (vehiclePlate?.isNotEmpty ?? false);

  /// The real assigned vehicle line, e.g. "Luxis Camary · 2A-2025".
  String? get assignedVehicleLabel {
    final parts = <String>[
      if (vehicleModel != null && vehicleModel!.isNotEmpty) vehicleModel!,
      if (vehiclePlate != null && vehiclePlate!.isNotEmpty) vehiclePlate!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  bool get hasOperatorContact => operator?.hasContact == true;

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final operator = json['operator'] as Map<String, dynamic>?;
    final flight = json['flight'] as Map<String, dynamic>?;
    final returnTrip = json['return_trip'] as Map<String, dynamic>?;

    return BookingDetail(
      uuid: json['uuid']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'assigned',
      assignmentId: (json['assignment_id'] as num?)?.toInt(),
      code: json['code']?.toString(),
      serviceType: json['service_type']?.toString(),
      tripType: json['trip_type']?.toString(),
      isRoundTrip: json['is_round_trip'] == true || json['is_return'] == true,
      status: json['status']?.toString(),
      driverPickupStatus: json['driver_pickup_status']?.toString(),
      driverTripStatus: json['driver_trip_status']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      startedAt: json['started_at']?.toString(),
      arrivedAt: json['arrived_at']?.toString(),
      metPassengerAt: json['met_passenger_at']?.toString(),
      droppedAt: json['dropped_at']?.toString(),
      pickupIssueReason: json['pickup_issue_reason']?.toString(),
      pickupIssueReasonOptions:
          (json['pickup_issue_reason_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pickupIssueNoteMaxLength:
          (json['pickup_issue_note_max_length'] as num?)?.toInt() ?? 500,
      allowedActions:
          (json['allowed_actions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      startLocked: json['start_locked'] == true,
      customerName: customer?['name']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      pickup: Place.fromJson(json['pickup'] as Map<String, dynamic>?),
      dropoff: Place.fromJson(json['dropoff'] as Map<String, dynamic>?),
      departureDatetime: json['departure_datetime']?.toString(),
      legDepartureDatetime: json['leg_departure_datetime']?.toString(),
      linkedOutboundDatetime: json['linked_outbound_datetime']?.toString(),
      linkedReturnDatetime: json['linked_return_datetime']?.toString(),
      arrivalDatetime: json['arrival_datetime']?.toString(),
      duration: (json['duration'] as num?)?.toInt(),
      passengerCount: (json['passenger_count'] as num?)?.toInt(),
      nationality: json['nationality']?.toString(),
      notes: json['notes']?.toString(),
      vehicleBooked: vehicle?['booked_name']?.toString(),
      vehicleModel: vehicle?['model']?.toString(),
      vehiclePlate: vehicle?['plate_number']?.toString(),
      vehicleColor: vehicle?['color']?.toString(),
      vehicleSeats: (vehicle?['seats'] as num?)?.toInt(),
      operator: OperatorContact.fromJson(operator),
      isReturn: json['is_return'] == true,
      returnDate: returnTrip?['date']?.toString(),
      returnTime: returnTrip?['time']?.toString(),
      flightNumber: flight?['number']?.toString(),
      airline: flight?['airline']?.toString(),
      terminal: flight?['terminal']?.toString(),
      flightDatetime: flight?['datetime']?.toString(),
    );
  }
}

class OperatorContact {
  const OperatorContact({
    this.name,
    this.phone,
    this.email,
    this.telegramChatId,
  });

  final String? name;
  final String? phone;
  final String? email;
  final String? telegramChatId;

  bool get hasContact =>
      (name != null && name!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty) ||
      (email != null && email!.isNotEmpty) ||
      (telegramChatId != null && telegramChatId!.isNotEmpty);

  bool get hasPhone => phone != null && phone!.isNotEmpty && phone != 'N/A';

  factory OperatorContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OperatorContact();

    return OperatorContact(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      telegramChatId: json['telegram_chat_id']?.toString(),
    );
  }
}
