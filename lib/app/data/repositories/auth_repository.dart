import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/auth_user.dart';
import '../models/driver_document.dart';

/// Auth API calls. Failures surface as [ApiException] (thrown by [ApiClient]).
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Login with phone or email. Returns the issued token and the driver.
  Future<({String token, AuthUser user})> login({
    required String login,
    required String password,
    required String deviceName,
  }) async {
    final res = await _api.post(
      '${AppConfig.authApiUrl}/auth/login',
      data: {'login': login, 'password': password, 'device_name': deviceName},
    );

    final data = (res.data as Map)['data'] as Map<String, dynamic>;
    return (
      token: data['token'].toString(),
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Revoke the current device token on the server.
  Future<void> logout(String deviceName) async {
    await _api.post(
      '${AppConfig.authApiUrl}/auth/logout',
      data: {'device_name': deviceName},
    );
  }

  /// Update the driver's editable profile fields. Returns the fresh user.
  Future<AuthUser> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) async {
    final res = await _api.post(
      '${AppConfig.authApiUrl}/auth/update_profile',
      data: {
        'first_name': ?firstName,
        'last_name': ?lastName,
        'phone': ?phone,
        'email': ?email,
      },
    );
    final data = (res.data as Map)['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Upload a new profile photo (multipart). Returns the new image URL.
  Future<String?> uploadAvatar(String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final res = await _api.post('${AppConfig.authApiUrl}/auth/avatar', data: form);
    final data = (res.data as Map)['data'] as Map<String, dynamic>;
    return data['image_url']?.toString();
  }

  /// Set the driver's online/availability state. Returns the new state.
  Future<bool> setAvailability(bool isOnline) async {
    final res = await _api.post(
      '${AppConfig.authApiUrl}/availability',
      data: {'is_online': isOnline},
    );
    final data = (res.data as Map)['data'] as Map<String, dynamic>;
    return data['is_online'] == true;
  }

  /// The driver's read-only documents (Personal ID, Driving License).
  Future<List<DriverDocument>> documents() async {
    final res = await _api.get('${AppConfig.authApiUrl}/documents');
    final list = (res.data as Map)['data'] as List? ?? [];
    return list
        .map((e) => DriverDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the authenticated driver (used to validate a persisted token).
  Future<AuthUser> me() async {
    final res = await _api.get('${AppConfig.authApiUrl}/auth/user');
    final body = res.data as Map;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return AuthUser.fromJson(data);
  }
}
