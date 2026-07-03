import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/driver_notification.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  final NotificationRepository _repo = Get.find<NotificationRepository>();

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isMarkingAll = false.obs;
  final error = RxnString();
  final filter = RxnString();
  final notifications = <DriverNotification>[].obs;

  DriverNotificationPage? _page;

  bool get hasMore => _page?.hasMore ?? false;
  int get unreadCount => notifications.where((item) => !item.isRead).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      _page = await _repo.list(filter: filter.value);
      notifications.assignAll(_page!.items);
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'error_generic'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList() => load();

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      final next = await _repo.list(
        filter: filter.value,
        page: (_page?.currentPage ?? 1) + 1,
      );
      _page = next;
      notifications.addAll(next.items);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> setFilter(String? value) async {
    if (filter.value == value) return;
    filter.value = value;
    await load();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0 || isMarkingAll.value) return;

    isMarkingAll.value = true;
    try {
      await _repo.markAllAsRead();
      await load();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isMarkingAll.value = false;
    }
  }

  Future<void> open(DriverNotification item) async {
    if (!item.isRead) {
      try {
        await _repo.markAsRead(item.id);
      } catch (_) {
        // Opening the useful target is more important than blocking on read sync.
      }
    }

    if (item.canOpenTrip) {
      await Get.toNamed(
        Routes.bookingDetail,
        arguments: {
          'uuid': item.bookingUuid,
          if (item.assignmentId != null) 'assignment_id': item.assignmentId,
        },
      );
    }

    await load();
  }
}
