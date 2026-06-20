import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../config/app_constants.dart';

/// Single access point for persistence.
///
/// - Sensitive values (auth token, serialized user) → [FlutterSecureStorage].
/// - Non-sensitive preferences (locale, theme) → [GetStorage].
///
/// Registered as a permanent service in the initial binding so any controller
/// can `Get.find<StorageService>()`.
class StorageService extends GetxService {
  StorageService({FlutterSecureStorage? secure, GetStorage? box})
      : _secure = secure ?? const FlutterSecureStorage(),
        _box = box ?? GetStorage();

  final FlutterSecureStorage _secure;
  final GetStorage _box;

  /// Must be awaited once before `runApp` (GetStorage needs init).
  static Future<void> init() => GetStorage.init();

  // ---- Secure (token / user) -------------------------------------------------

  Future<String?> readToken() => _secure.read(key: AppConstants.tokenKey);

  Future<void> writeToken(String token) =>
      _secure.write(key: AppConstants.tokenKey, value: token);

  Future<String?> readUser() => _secure.read(key: AppConstants.userKey);

  Future<void> writeUser(String json) =>
      _secure.write(key: AppConstants.userKey, value: json);

  /// Wipe all sensitive values (logout).
  Future<void> clearSecure() async {
    await _secure.delete(key: AppConstants.tokenKey);
    await _secure.delete(key: AppConstants.userKey);
  }

  // ---- Preferences -----------------------------------------------------------

  String? get locale => _box.read<String>(AppConstants.localeKey);
  set locale(String? value) => _box.write(AppConstants.localeKey, value);

  String? get themeMode => _box.read<String>(AppConstants.themeModeKey);
  set themeMode(String? value) => _box.write(AppConstants.themeModeKey, value);

  String? get deviceName => _box.read<String>(AppConstants.deviceNameKey);
  set deviceName(String? value) => _box.write(AppConstants.deviceNameKey, value);

  /// Whether the first-run welcome screen has been seen.
  bool get seenOnboarding => _box.read<bool>(AppConstants.onboardingSeenKey) ?? false;
  set seenOnboarding(bool value) => _box.write(AppConstants.onboardingSeenKey, value);
}
