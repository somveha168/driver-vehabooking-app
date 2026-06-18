import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/driver_document.dart';
import '../../data/repositories/auth_repository.dart';

class DocumentsController extends GetxController {
  final AuthRepository _repo = Get.find<AuthRepository>();

  final isLoading = false.obs;
  final error = RxnString();
  final docs = <DriverDocument>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      docs.assignAll(await _repo.documents());
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'error_generic'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
