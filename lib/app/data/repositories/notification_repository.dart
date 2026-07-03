import 'dart:io';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/driver_notification.dart';

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

  Future<DriverNotificationPage> list({
    String? filter,
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _api.getJson(
      '${AppConfig.authApiUrl}/notifications',
      query: {
        'page': page,
        'per_page': perPage,
        if (filter != null && filter.isNotEmpty) 'filter': filter,
      },
    );

    final envelope = res as Map;
    final body = envelope['data'] is Map ? envelope['data'] as Map : envelope;
    final items = (body['data'] as List? ?? [])
        .map(
          (item) => DriverNotification.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final meta = body['meta'] as Map?;

    return DriverNotificationPage(
      items: items,
      currentPage: (meta?['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta?['last_page'] as num?)?.toInt() ?? page,
    );
  }

  Future<void> markAsRead(String id) async {
    await _api.postJson('${AppConfig.authApiUrl}/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _api.postJson('${AppConfig.authApiUrl}/notifications/read-all');
  }
}
