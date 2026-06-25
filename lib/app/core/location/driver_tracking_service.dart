import 'dart:async';

import 'package:get/get.dart';

import '../utils/app_snackbar.dart';
import '../../data/repositories/booking_repository.dart';
import 'location_service.dart';

enum DriverTrackingMode { off, snapshot, live }

class DriverTrackingService extends GetxService {
  DriverTrackingService(this._bookingRepository, this._locationService);

  static const Duration snapshotInterval = Duration(minutes: 3);
  static const Duration liveInterval = Duration(seconds: 25);
  static const Duration maxLiveDuration = Duration(hours: 12);

  final BookingRepository _bookingRepository;
  final LocationService _locationService;

  Timer? _timer;
  String? _activeKey;
  DateTime? _watchStartedAt;
  DriverTrackingMode _mode = DriverTrackingMode.off;
  bool _isSyncing = false;
  bool _expiredNoticeShown = false;

  Future<DriverLocation?> syncSnapshot({
    required String uuid,
    required int? assignmentId,
  }) async {
    if (uuid.isEmpty || assignmentId == null) return null;

    final location = await _locationService.current();
    await _bookingRepository.storeLocation(
      uuid,
      assignmentId: assignmentId,
      location: location,
    );

    return location;
  }

  void watch({
    required String uuid,
    required int? assignmentId,
    required DriverTrackingMode mode,
  }) {
    if (uuid.isEmpty ||
        assignmentId == null ||
        mode == DriverTrackingMode.off) {
      stop();
      return;
    }

    final key = '$uuid:$assignmentId';
    if (_activeKey == key && _mode == mode && _timer?.isActive == true) {
      return;
    }

    stop();
    _activeKey = key;
    _mode = mode;
    _watchStartedAt = DateTime.now();
    _expiredNoticeShown = false;

    if (mode == DriverTrackingMode.live) {
      unawaited(_safeSync(uuid: uuid, assignmentId: assignmentId));
    }

    final interval = mode == DriverTrackingMode.live
        ? liveInterval
        : snapshotInterval;

    _timer = Timer.periodic(interval, (_) {
      if (_mode == DriverTrackingMode.live && _liveWindowExpired) {
        _notifyTrackingExpired();
        stop();
        return;
      }

      unawaited(_safeSync(uuid: uuid, assignmentId: assignmentId));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeKey = null;
    _watchStartedAt = null;
    _mode = DriverTrackingMode.off;
  }

  bool get _liveWindowExpired {
    final startedAt = _watchStartedAt;
    if (startedAt == null) return false;

    return DateTime.now().difference(startedAt) > maxLiveDuration;
  }

  void _notifyTrackingExpired() {
    if (_expiredNoticeShown) return;

    _expiredNoticeShown = true;
    AppSnackbar.info('tracking_action_required'.tr);
  }

  Future<void> _safeSync({
    required String uuid,
    required int assignmentId,
  }) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await syncSnapshot(uuid: uuid, assignmentId: assignmentId);
    } catch (_) {
      // Tracking must never block the driver's trip workflow.
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
