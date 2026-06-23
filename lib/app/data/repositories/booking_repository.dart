import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/booking_detail.dart';
import '../models/booking_list_item.dart';
import '../models/dashboard_summary.dart';

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
    final data = (res as Map)['data'] as Map<String, dynamic>;
    return DashboardSummary.fromJson(data);
  }

  /// List the driver's bookings, optionally filtered by [status]
  /// (assigned | accepted | on_trip | completed).
  Future<BookingPage> list({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '$_base/bookings',
      query: {'status': ?status, 'page': page, 'limit': limit},
    );

    final body = res as Map;
    final items = (body['data'] as List? ?? [])
        .map((e) => BookingListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map?;

    return (
      items: items,
      currentPage: (meta?['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta?['last_page'] as num?)?.toInt() ?? page,
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

  /// Pickup issue → terminal note, completes the booking and frees the driver.
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

  Map<String, dynamic>? _legData(int? assignmentId) =>
      assignmentId == null ? null : {'assignment_id': assignmentId};

  Future<BookingDetail> _detail(Future<dynamic> request) async {
    final res = await request;
    final data = (res as Map)['data'] as Map<String, dynamic>;
    return BookingDetail.fromJson(data);
  }
}
