import 'dart:io';

import 'package:get/get.dart';

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
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/login',
      data: {'login': login, 'password': password, 'device_name': deviceName},
    );

    final data = (res as Map)['data'] as Map<String, dynamic>;
    return (
      token: data['token'].toString(),
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Revoke the current device token on the server.
  Future<void> logout(String deviceName) async {
    await _api.postJson(
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
    String? gender,
    String? dateOfBirth,
    String? currentAddress,
  }) async {
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/update_profile',
      data: {
        'first_name': ?firstName,
        'last_name': ?lastName,
        'phone': ?phone,
        'email': ?email,
        'gender': ?gender,
        'date_of_birth': ?dateOfBirth,
        'current_address': ?currentAddress,
      },
    );
    final data = (res as Map)['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Upload a new profile photo (multipart). Returns the new image URL.
  Future<String?> uploadAvatar(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final form = FormData({
      'image': MultipartFile(bytes, filename: filePath.split('/').last),
    });
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/avatar',
      data: form,
    );
    final data = (res as Map)['data'] as Map<String, dynamic>;
    return data['image_url']?.toString();
  }

  /// The driver's read-only documents (Personal ID, Driving License).
  Future<List<DriverDocument>> documents() async {
    final res = await _api.getJson('${AppConfig.authApiUrl}/documents');
    final list = (res as Map)['data'] as List? ?? [];
    return list
        .map((e) => DriverDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the authenticated driver (used to validate a persisted token).
  Future<AuthUser> me() async {
    final res = await _api.getJson('${AppConfig.authApiUrl}/auth/user');
    final body = res as Map;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return AuthUser.fromJson(data);
  }
}
