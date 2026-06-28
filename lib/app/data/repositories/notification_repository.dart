import 'dart:io';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<void> registerDevice({
    required String udid,
    required String name,
    required String fcmToken,
  }) async {
    await _api.postJson(
      '${AppConfig.authApiUrl}/devices',
      data: {
        'udid': udid,
        'name': name,
        'fcm_token': fcmToken,
        'os': Platform.isIOS ? 'ios' : 'android',
        'manufacturer': Platform.isIOS ? 'Apple' : 'Android',
        'model': name,
        'app_version': '1.0.0',
      },
    );
  }

  Future<int> unreadCount() async {
    final res = await _api.getJson(
      '${AppConfig.authApiUrl}/notifications/unread-count',
    );
    final data = (res as Map)['data'] as Map<String, dynamic>;
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }
}
