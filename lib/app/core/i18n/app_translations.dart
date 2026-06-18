import 'package:get/get.dart';

import 'translations/en.dart';
import 'translations/km.dart';

/// GetX translation registry. Use anywhere via `'key'.tr`.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'km_KH': kmKH,
      };

  static const Locale englishLocale = Locale('en', 'US');
  static const Locale khmerLocale = Locale('km', 'KH');
  static const Locale fallbackLocale = englishLocale;

  static const List<Locale> supportedLocales = [englishLocale, khmerLocale];

  /// Resolve a stored `en_US` / `km_KH` string back to a [Locale].
  static Locale fromCode(String? code) {
    if (code == 'km_KH') return khmerLocale;
    return englishLocale;
  }
}
