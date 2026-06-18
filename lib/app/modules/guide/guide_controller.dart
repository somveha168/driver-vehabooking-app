import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/external_launcher.dart';

class GuideController extends GetxController {
  Future<void> callDispatch() => ExternalLauncher.call(AppConfig.supportPhone);

  Future<void> openTelegram() =>
      ExternalLauncher.openUrl(AppConfig.supportTelegramUrl);
}
