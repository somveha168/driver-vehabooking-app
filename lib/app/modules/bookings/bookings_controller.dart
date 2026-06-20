import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_constants.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/booking_list_item.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/booking_repository.dart';

class BookingsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final BookingRepository _repo = Get.find<BookingRepository>();

  static const List<String> tabs = ['assigned', 'active', 'completed'];

  late final TabController tabController;

  final isLoading = false.obs;
  final items = <BookingListItem>[].obs;
  final error = RxnString();

  /// Mirrors [tabController.index] so the segmented control can react.
  final activeIndex = 0.obs;

  /// Pipeline counts shown as badges on the tabs (reused from the dashboard).
  final counts = const DashboardCounts().obs;

  Timer? _poll;

  String get currentStatus => tabs[tabController.index];

  /// Trips on the active tab benefit from day-grouping only when they're
  /// forward-looking (Assigned/Active); Completed stays a flat history list.
  bool get groupByDay => currentStatus != 'completed';

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabs.length, vsync: this);
    tabController.addListener(() {
      activeIndex.value = tabController.index;
      if (!tabController.indexIsChanging) fetch();
    });
    fetch();
    // Light polling keeps the active tab fresh without push (v1).
    _poll = Timer.periodic(
      AppConfig.bookingsPollInterval,
      (_) => fetch(silent: true),
    );
  }

  /// Reload the active tab. [silent] skips the spinner/error reset (polling).
  Future<void> fetch({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
      error.value = null;
    }
    try {
      final page = await _repo.list(
        status: currentStatus,
        limit: AppConstants.pageSize,
      );
      items.assignAll(page.items);
      error.value = null;
    } on ApiException catch (e) {
      if (!silent) error.value = e.message;
    } catch (_) {
      if (!silent) error.value = 'error_generic'.tr;
    } finally {
      if (!silent) isLoading.value = false;
    }
    // Refresh tab badges alongside the list (fire-and-forget).
    refreshCounts();
  }

  /// Update the tab count badges from the dashboard summary. Best-effort:
  /// failures never disrupt the list.
  Future<void> refreshCounts() async {
    try {
      counts.value = (await _repo.dashboard()).counts;
    } catch (_) {
      // Badges are non-critical; ignore.
    }
  }

  @override
  void onClose() {
    _poll?.cancel();
    tabController.dispose();
    super.onClose();
  }
}
