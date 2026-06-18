import 'package:get/get.dart';

import 'documents_controller.dart';

class DocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DocumentsController());
  }
}
