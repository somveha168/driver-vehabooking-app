import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/external_launcher.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/services/auth_service.dart';
import '../bookings/bookings_controller.dart';
import '../home/home_controller.dart';

class DashboardController extends GetxController {
  final BookingRepository _bookingRepo = Get.find<BookingRepository>();
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final AuthService _auth = Get.find<AuthService>();

  final isLoading = false.obs;
  final isToggling = false.obs;
  final isActing = false.obs;
  final error = RxnString();
  final Rxn<DashboardSummary> summary = Rxn<DashboardSummary>();
  final isOnline = false.obs;

  /// Operational status (available / assign / on_duty / day_off / pending_verification).
  final status = 'available'.obs;

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
      isOnline.value = data.isOnline;
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'error_generic'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle online/availability. Reverts the switch if the request fails.
  Future<void> toggleOnline(bool value) async {
    if (isToggling.value) return;
    isToggling.value = true;
    final previous = isOnline.value;
    isOnline.value = value; // optimistic
    try {
      isOnline.value = await _authRepo.setAvailability(value);
    } on ApiException catch (e) {
      isOnline.value = previous;
      AppSnackbar.error(e.message);
    } catch (_) {
      isOnline.value = previous;
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isToggling.value = false;
    }
  }

  /// Open the next pickup's detail; refresh on return.
  void openNextPickup() {
    final next = summary.value?.nextPickup;
    if (next == null) return;
    openBooking(next.uuid);
  }

  /// Open any booking's detail by uuid; refresh on return.
  void openBooking(String uuid) {
    Get.toNamed(Routes.bookingDetail, arguments: uuid)?.then((_) => load());
  }

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
          await _bookingRepo.start(next.uuid);
          break;
        case 'arrived':
          await _bookingRepo.arrived(next.uuid);
          break;
        case 'meet_passenger':
          await _bookingRepo.meetPassenger(next.uuid);
          break;
        case 'complete':
          await _bookingRepo.complete(next.uuid);
          break;
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
}
