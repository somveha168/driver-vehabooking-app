import 'dart:async';

import 'package:get/get.dart';

import '../../core/location/driver_tracking_service.dart';
import '../../core/location/location_service.dart';
import '../../core/maps/route_map_args.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/external_launcher.dart';
import '../../data/models/booking_detail.dart';
import '../../data/repositories/booking_repository.dart';

class BookingDetailController extends GetxController {
  final BookingRepository _repo = Get.find<BookingRepository>();
  final DriverTrackingService _trackingService =
      Get.find<DriverTrackingService>();

  late final String uuid;
  late final int? assignmentId;

  final isLoading = false.obs;
  final isActing = false.obs;
  final error = RxnString();
  final Rxn<BookingDetail> booking = Rxn<BookingDetail>();
  final isLocating = false.obs;
  final Rxn<DriverLocation> driverLocation = Rxn<DriverLocation>();
  final RxnString locationMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      uuid = args['uuid']?.toString() ?? '';
      assignmentId = (args['assignment_id'] as num?)?.toInt();
    } else {
      uuid = args?.toString() ?? '';
      assignmentId = null;
    }
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      booking.value = await _repo.show(uuid, assignmentId: assignmentId);
      _watchTracking();
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'error_generic'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDriverLocation({bool showErrors = true}) async {
    if (isLocating.value) return;
    isLocating.value = true;
    locationMessage.value = null;
    try {
      final location = await _trackingService.syncSnapshot(
        uuid: uuid,
        assignmentId: _currentAssignmentId,
      );
      if (location != null) driverLocation.value = location;
    } on LocationUnavailableException catch (e) {
      locationMessage.value = e.messageKey.tr;
      if (showErrors) AppSnackbar.error(e.messageKey.tr);
    } catch (_) {
      locationMessage.value = 'location_unavailable'.tr;
      if (showErrors) AppSnackbar.error('location_unavailable'.tr);
    } finally {
      isLocating.value = false;
    }
  }

  // Trip lifecycle.
  Future<void> start() => _act(
    () => _repo.start(uuid, assignmentId: assignmentId),
    'started_done'.tr,
  );

  Future<void> arrived() => _act(
    () => _repo.arrived(uuid, assignmentId: assignmentId),
    'arrived_done'.tr,
  );

  Future<void> meetPassenger() => _act(
    () => _repo.meetPassenger(uuid, assignmentId: assignmentId),
    'met_done'.tr,
  );

  Future<void> complete() => _act(
    () => _repo.complete(uuid, assignmentId: assignmentId),
    'completed_done'.tr,
    syncBefore: true,
    syncAfter: false,
  );

  /// Pickup issue → terminal note, completes the booking and frees the driver.
  Future<void> reportPickupIssue(String reason, String? note) => _act(
    () => _repo.reportPickupIssue(
      uuid,
      assignmentId: assignmentId,
      reason: reason,
      note: note,
    ),
    'pickup_issue_reported'.tr,
    syncBefore: true,
    syncAfter: false,
  );

  /// Run the action key from `allowed_actions`.
  Future<void> runAction(String action) {
    switch (action) {
      case 'start':
        return start();
      case 'arrived':
        return arrived();
      case 'meet_passenger':
        return meetPassenger();
      case 'complete':
        return complete();
      default:
        return Future.value();
    }
  }

  Future<void> _act(
    Future<BookingDetail> Function() action,
    String successMsg, {
    bool syncBefore = false,
    bool syncAfter = true,
  }) async {
    if (isActing.value) return;
    isActing.value = true;
    try {
      if (syncBefore) {
        await _syncCurrentLocationSnapshot();
      }
      booking.value = await action();
      _watchTracking();
      if (syncAfter) {
        unawaited(refreshDriverLocation(showErrors: false));
      }
      AppSnackbar.success(successMsg);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isActing.value = false;
    }
  }

  int? get _currentAssignmentId => assignmentId ?? booking.value?.assignmentId;

  Future<void> _syncCurrentLocationSnapshot() async {
    try {
      final location = await _trackingService.syncSnapshot(
        uuid: uuid,
        assignmentId: _currentAssignmentId,
      );
      if (location != null) driverLocation.value = location;
    } catch (_) {
      // Location sync must not block the driver's trip workflow.
    }
  }

  void _watchTracking() {
    final b = booking.value;
    if (b == null) {
      _trackingService.stop();
      return;
    }

    _trackingService.watch(
      uuid: uuid,
      assignmentId: _currentAssignmentId,
      mode: _trackingModeFor(b),
    );
  }

  DriverTrackingMode _trackingModeFor(BookingDetail b) {
    final status = b.status;
    final driverStatus = b.driverTripStatus;

    if (status == 'completed' ||
        status == 'cancelled' ||
        b.pickupIssueReason != null) {
      return DriverTrackingMode.off;
    }

    if (driverStatus == 'start' ||
        driverStatus == 'arrived_location' ||
        driverStatus == 'meet_passenger' ||
        b.stage == 'on_trip') {
      return DriverTrackingMode.live;
    }

    if (driverStatus == 'assigned' ||
        b.stage == 'assigned' ||
        b.stage == 'accepted') {
      return DriverTrackingMode.snapshot;
    }

    return DriverTrackingMode.off;
  }

  Future<void> navigateToPickup() async {
    final b = booking.value;
    if (b == null) return;
    final ok = await ExternalLauncher.navigateTo(
      latitude: b.pickup.latitude,
      longitude: b.pickup.longitude,
      address: b.pickup.address,
    );
    if (!ok) AppSnackbar.error('error_generic'.tr);
  }

  Future<void> navigateToActiveDestination() async {
    final b = booking.value;
    if (b == null) return;

    final destination = switch (b.stage) {
      'meet_passenger' || 'drop_passenger' => b.dropoff,
      _ => b.pickup,
    };

    final ok = await ExternalLauncher.navigateTo(
      latitude: destination.latitude,
      longitude: destination.longitude,
      address: destination.address,
    );
    if (!ok) AppSnackbar.error('error_generic'.tr);
  }

  void openMap() {
    final b = booking.value;
    if (b == null || !b.pickup.hasCoordinates || !b.dropoff.hasCoordinates) {
      return;
    }

    Get.toNamed(
      Routes.tripMap,
      arguments: RouteMapArgs(
        uuid: uuid,
        assignmentId: _currentAssignmentId,
        title: 'trip_map'.tr,
        subtitle: b.code ?? b.customerName ?? '',
        pickup: b.pickup,
        dropoff: b.dropoff,
        navigateToDropoff:
            b.stage == 'meet_passenger' || b.stage == 'drop_passenger',
      ),
    );
  }

  Future<void> callCustomer() async {
    final phone = booking.value?.customerPhone;
    if (phone == null || phone.isEmpty || phone == 'N/A') return;
    await ExternalLauncher.call(phone);
  }

  @override
  void onClose() {
    _trackingService.stop();
    super.onClose();
  }
}
