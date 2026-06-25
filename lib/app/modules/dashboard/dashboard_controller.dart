import 'package:get/get.dart';

import '../../core/location/driver_tracking_service.dart';
import '../../core/maps/route_map_args.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/external_launcher.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/services/auth_service.dart';
import '../bookings/bookings_controller.dart';
import '../home/home_controller.dart';

class DashboardController extends GetxController {
  final BookingRepository _bookingRepo = Get.find<BookingRepository>();
  final DriverTrackingService _trackingService =
      Get.find<DriverTrackingService>();
  final AuthService _auth = Get.find<AuthService>();

  final isLoading = false.obs;
  final isActing = false.obs;
  final error = RxnString();
  final Rxn<DashboardSummary> summary = Rxn<DashboardSummary>();

  /// Verification status (pending / approved / rejected).
  final status = 'pending'.obs;
  final active = false.obs;

  AuthUser? get user => _auth.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final data = await _bookingRepo.dashboard();
      summary.value = data;
      status.value = data.status;
      active.value = data.active;
      _watchNextPickupTracking();
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'error_generic'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  /// Open the next pickup's detail; refresh on return.
  void openNextPickup() {
    final next = summary.value?.nextPickup;
    if (next == null) return;
    openBooking(next.uuid, assignmentId: next.assignmentId);
  }

  /// Open the full-screen route map from the Home NOW card.
  Future<void> openNextPickupMap() async {
    final next = summary.value?.nextPickup;
    if (next == null) {
      return;
    }

    var pickup = next.pickupPlace;
    var dropoff = next.dropoffPlace;

    if (!pickup.hasCoordinates || !dropoff.hasCoordinates) {
      try {
        final detail = await _bookingRepo.show(
          next.uuid,
          assignmentId: next.assignmentId,
        );
        pickup = detail.pickup;
        dropoff = detail.dropoff;
      } on ApiException catch (e) {
        AppSnackbar.error(e.message);
        return;
      } catch (_) {
        AppSnackbar.error('location_unavailable'.tr);
        return;
      }
    }

    if (!pickup.hasCoordinates || !dropoff.hasCoordinates) {
      AppSnackbar.error('location_unavailable'.tr);
      return;
    }

    Get.toNamed(
      Routes.tripMap,
      arguments: RouteMapArgs(
        uuid: next.uuid,
        assignmentId: next.assignmentId,
        title: 'trip_map'.tr,
        subtitle: next.code ?? next.customerName ?? '',
        pickup: pickup,
        dropoff: dropoff,
        navigateToDropoff: _navigatesToDropoff(next.stage, next.nextAction),
      ),
    );
  }

  /// Open any booking leg's detail by uuid + assignment id; refresh on return.
  void openBooking(String uuid, {int? assignmentId}) {
    Get.toNamed(
      Routes.bookingDetail,
      arguments: {'uuid': uuid, ...?(_assignmentArgument(assignmentId))},
    )?.then((_) => load());
  }

  Map<String, dynamic>? _assignmentArgument(int? assignmentId) =>
      assignmentId == null ? null : {'assignment_id': assignmentId};

  /// Dial the passenger from the NOW card.
  Future<void> callCustomer(String phone) => ExternalLauncher.call(phone);

  /// Advance the NOW pickup one step (start / arrived / meet_passenger /
  /// complete) straight from the Home card, then refresh the dashboard.
  Future<void> runNextAction(String action) async {
    final next = summary.value?.nextPickup;
    if (next == null || isActing.value) return;

    isActing.value = true;
    try {
      switch (action) {
        case 'start':
          await _bookingRepo.start(next.uuid, assignmentId: next.assignmentId);
          break;
        case 'arrived':
          await _bookingRepo.arrived(
            next.uuid,
            assignmentId: next.assignmentId,
          );
          break;
        case 'meet_passenger':
          await _bookingRepo.meetPassenger(
            next.uuid,
            assignmentId: next.assignmentId,
          );
          break;
        case 'complete':
          await _syncNextPickupLocation();
          await _bookingRepo.complete(
            next.uuid,
            assignmentId: next.assignmentId,
          );
          break;
      }
      if (action != 'complete') {
        await _syncNextPickupLocation();
      }
      await load();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isActing.value = false;
    }
  }

  /// Report a pickup issue from the Home NOW card.
  Future<void> reportPickupIssue(String reason, {String? note}) async {
    final next = summary.value?.nextPickup;
    if (next == null || isActing.value) return;

    isActing.value = true;
    try {
      await _syncNextPickupLocation();
      await _bookingRepo.reportPickupIssue(
        next.uuid,
        assignmentId: next.assignmentId,
        reason: reason,
        note: note,
      );
      AppSnackbar.success('pickup_issue_reported'.tr);
      await load();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isActing.value = false;
    }
  }

  /// Jump to the Bookings tab filtered to [status].
  void goToBookings(String status) {
    Get.find<HomeController>().changeTab(1);
    final bookings = Get.find<BookingsController>();
    final index = BookingsController.tabs.indexOf(status);
    if (index >= 0) bookings.tabController.animateTo(index);
  }

  /// Header notification bell. Real notifications arrive in v2 (FCM); for now
  /// this acknowledges there's nothing new.
  void openNotifications() => AppSnackbar.info('no_notifications'.tr);

  Future<void> _syncNextPickupLocation() async {
    final next = summary.value?.nextPickup;
    final assignmentId = next?.assignmentId;
    if (next == null || assignmentId == null) return;

    try {
      await _trackingService.syncSnapshot(
        uuid: next.uuid,
        assignmentId: assignmentId,
      );
    } catch (_) {
      // Do not block the home action when location is unavailable.
    }
  }

  void _watchNextPickupTracking() {
    final next = summary.value?.nextPickup;
    if (next == null) {
      _trackingService.stop();
      return;
    }

    _trackingService.watch(
      uuid: next.uuid,
      assignmentId: next.assignmentId,
      mode: _trackingModeForNextAction(next.nextAction),
    );
  }

  DriverTrackingMode _trackingModeForNextAction(String? nextAction) {
    return switch (nextAction) {
      'arrived' || 'meet_passenger' || 'complete' => DriverTrackingMode.live,
      'start' => DriverTrackingMode.snapshot,
      _ => DriverTrackingMode.off,
    };
  }

  bool _navigatesToDropoff(String stage, String? nextAction) {
    return stage == 'meet_passenger' ||
        stage == 'drop_passenger' ||
        nextAction == 'complete';
  }

  @override
  void onClose() {
    _trackingService.stop();
    super.onClose();
  }
}
