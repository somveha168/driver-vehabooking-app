import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/external_launcher.dart';
import '../../data/models/booking_detail.dart';
import '../../data/repositories/booking_repository.dart';

class BookingDetailController extends GetxController {
  final BookingRepository _repo = Get.find<BookingRepository>();

  late final String uuid;
  late final int? assignmentId;

  final isLoading = false.obs;
  final isActing = false.obs;
  final error = RxnString();
  final Rxn<BookingDetail> booking = Rxn<BookingDetail>();

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
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'error_generic'.tr;
    } finally {
      isLoading.value = false;
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
    String successMsg,
  ) async {
    if (isActing.value) return;
    isActing.value = true;
    try {
      booking.value = await action();
      AppSnackbar.success(successMsg);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isActing.value = false;
    }
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

  Future<void> callCustomer() async {
    final phone = booking.value?.customerPhone;
    if (phone == null || phone.isEmpty || phone == 'N/A') return;
    await ExternalLauncher.call(phone);
  }
}
