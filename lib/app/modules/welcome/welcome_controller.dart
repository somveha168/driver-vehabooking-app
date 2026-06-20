import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/settings_service.dart';

/// First-run welcome screen. Lets the driver pick a language, then enter the app.
class WelcomeController extends GetxController {
  final SettingsService settings = Get.find<SettingsService>();
  final StorageService _storage = Get.find<StorageService>();

  void setLanguage(Locale locale) => settings.setLocale(locale);

  /// Mark onboarding seen (so it never shows again) and continue.
  void start() {
    _storage.seenOnboarding = true;
    final loggedIn = Get.find<AuthService>().isLoggedIn;
    Get.offAllNamed(loggedIn ? Routes.home : Routes.login);
  }
}
