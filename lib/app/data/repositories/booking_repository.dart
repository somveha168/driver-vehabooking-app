import '../../core/config/app_config.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_client.dart';
import '../models/booking_detail.dart';
import '../models/booking_list_item.dart';
import '../models/dashboard_summary.dart';
import '../models/trip_route.dart';

/// Paged list result for the bookings screen.
typedef BookingPage = ({
  List<BookingListItem> items,
  int currentPage,
  int lastPage,
});

/// Driver booking API calls (Taxi module). Failures surface as [ApiException].
class BookingRepository {
  BookingRepository(this._api);

  final ApiClient _api;

  String get _base => AppConfig.bookingsApiUrl;

  /// Home dashboard summary: online state, pipeline counts, next pickup.
  Future<DashboardSummary> dashboard() async {
    final res = await _api.getJson('$_base/dashboard');
    final data = _mapAt(res, 'data');
    return DashboardSummary.fromJson(data);
  }

  /// List the driver's bookings, optionally filtered by [status]
  /// (assigned | active | completed).
  Future<BookingPage> list({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '$_base/bookings',
      query: {'status': ?status, 'page': page, 'limit': limit},
    );

    final body = res is Map ? res : const {};
    final items = (body['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => BookingListItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final meta = body['meta'] is Map ? body['meta'] as Map : const {};

    return (
      items: items,
      currentPage: _toInt(meta['current_page']) ?? page,
      lastPage: _toInt(meta['last_page']) ?? page,
    );
  }

  Future<BookingDetail> show(String uuid, {int? assignmentId}) => _detail(
    _api.getJson('$_base/bookings/$uuid', query: {...?_legData(assignmentId)}),
  );

  // Trip lifecycle: Start Now → Arrived → Meet Passenger → Drop Passenger.
  Future<BookingDetail> start(String uuid, {int? assignmentId}) => _detail(
    _api.postJson('$_base/bookings/$uuid/start', data: _legData(assignmentId)),
  );

  Future<BookingDetail> arrived(String uuid, {int? assignmentId}) => _detail(
    _api.postJson(
      '$_base/bookings/$uuid/arrived',
      data: _legData(assignmentId),
    ),
  );

  Future<BookingDetail> meetPassenger(String uuid, {int? assignmentId}) =>
      _detail(
        _api.postJson(
          '$_base/bookings/$uuid/meet-passenger',
          data: _legData(assignmentId),
        ),
      );

  Future<BookingDetail> complete(String uuid, {int? assignmentId}) => _detail(
    _api.postJson(
      '$_base/bookings/$uuid/complete',
      data: _legData(assignmentId),
    ),
  );

  /// Pickup issue → terminal outcome for this exact assignment leg.
  Future<BookingDetail> reportPickupIssue(
    String uuid, {
    int? assignmentId,
    required String reason,
    String? note,
  }) => _detail(
    _api.postJson(
      '$_base/bookings/$uuid/report-pickup-issue',
      data: {
        ...?_legData(assignmentId),
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    ),
  );

  Future<void> storeLocation(
    String uuid, {
    required int assignmentId,
    required DriverLocation location,
  }) async {
    await _api.postJson(
      '$_base/bookings/$uuid/location',
      data: {
        'assignment_id': assignmentId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        if (location.accuracyMeters != null)
          'accuracy': location.accuracyMeters,
        if (location.speedKmh != null) 'speed': location.speedKmh,
        if (location.heading != null) 'heading': location.heading,
        'is_moving': location.isMoving,
        'provider': 'driver_app',
      },
    );
  }

  Future<TripRoute> route(
    String uuid, {
    required int assignmentId,
    required String mode,
    double? originLatitude,
    double? originLongitude,
  }) async {
    final res = await _api.getJson(
      '$_base/bookings/$uuid/route',
      query: {
        'assignment_id': assignmentId,
        'mode': mode,
        'origin_latitude': ?originLatitude,
        'origin_longitude': ?originLongitude,
      },
    );

    final data = _mapAt(res, 'data');
    return TripRoute.fromJson(data);
  }

  Map<String, dynamic>? _legData(int? assignmentId) =>
      assignmentId == null ? null : {'assignment_id': assignmentId};

  Future<BookingDetail> _detail(Future<dynamic> request) async {
    final res = await request;
    final data = _mapAt(res, 'data');
    return BookingDetail.fromJson(data);
  }

  Map<String, dynamic> _mapAt(dynamic value, String key) {
    if (value is! Map) return const {};
    final data = value[key];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
