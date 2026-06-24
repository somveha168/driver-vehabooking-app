import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/config/app_config.dart';
import 'app/core/i18n/app_translations.dart';
import 'app/core/network/api_client.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/routes/app_routes.dart';
import 'app/core/storage/storage_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/repositories/auth_repository.dart';
import 'app/data/repositories/booking_repository.dart';
import 'app/data/repositories/guide_repository.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // Core singletons (order matters: storage → client → repos → services).
  final storage = Get.put(StorageService(), permanent: true);
  final api = Get.put(ApiClient(storage), permanent: true);

  Get.put(AuthRepository(api), permanent: true);
  Get.put(BookingRepository(api), permanent: true);
  Get.put(GuideRepository(api), permanent: true);

  final auth = Get.put(
    AuthService(Get.find<AuthRepository>(), api, storage),
    permanent: true,
  );
  await auth.bootstrap();

  final settings = Get.put(SettingsService(storage).init(), permanent: true);

  // On a 401 anywhere, reset to login.
  api.onUnauthorized = () => Get.offAllNamed(Routes.login);

  // Every launch starts on the animated splash, which then routes to
  // Welcome (first run) / Home (logged in) / Login.
  runApp(VehaDriverApp(settings: settings));
}

class VehaDriverApp extends StatelessWidget {
  const VehaDriverApp({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode.value,
      translations: AppTranslations(),
      locale: settings.locale.value,
      fallbackLocale: AppTranslations.fallbackLocale,
      supportedLocales: AppTranslations.supportedLocales,
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
    );
  }
}
