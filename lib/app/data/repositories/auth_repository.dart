import 'dart:io';

import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
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

  /// Start the driver password-reset flow. The backend accepts either phone or
  /// email and returns a short-lived OTP token.
  Future<({String token, int expiresIn, String message})> requestPasswordReset({
    required String identifier,
    required bool viaEmail,
  }) async {
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/password/forgot',
      data: _identifierPayload(identifier, viaEmail: viaEmail),
    );

    final data = _responseData(res);
    return (
      token: data['token'].toString(),
      expiresIn: int.tryParse(data['expires_in']?.toString() ?? '') ?? 0,
      message: data['message']?.toString() ?? '',
    );
  }

  /// Verify the OTP and exchange it for a reset token.
  Future<({String resetToken, int minPasswordLength, String message})>
  verifyPasswordResetOtp({
    required String identifier,
    required bool viaEmail,
    required String otp,
    required String token,
  }) async {
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/password/verify_otp',
      data: {
        ..._identifierPayload(identifier, viaEmail: viaEmail),
        'otp': otp.trim(),
        'token': token,
      },
    );

    final data = _responseData(res);
    return (
      resetToken: data['reset_token'].toString(),
      minPasswordLength:
          int.tryParse(data['min_password_length']?.toString() ?? '') ?? 8,
      message: data['message']?.toString() ?? '',
    );
  }

  /// Resend a password reset OTP for an existing reset request token.
  Future<({String token, int expiresIn, String message})>
  resendPasswordResetOtp({required String token}) async {
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/password/resend_otp',
      data: {'token': token},
    );

    final data = _responseData(res);
    return (
      token: data['token']?.toString() ?? token,
      expiresIn: int.tryParse(data['expires_in']?.toString() ?? '') ?? 0,
      message: data['message']?.toString() ?? '',
    );
  }

  /// Save the new password after OTP verification.
  Future<void> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.postJson(
      '${AppConfig.authApiUrl}/auth/password/reset',
      data: {
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
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
  Future<String> uploadAvatar(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const ApiException(
        message: 'Selected photo is no longer available.',
      );
    }
    if (await file.length() > AppConstants.avatarMaxUploadBytes) {
      throw const ApiException(
        message: 'Profile photo is too large. Please choose another photo.',
      );
    }

    final filename = file.uri.pathSegments.isEmpty
        ? 'avatar.jpg'
        : file.uri.pathSegments.last;
    final form = FormData({
      'image': MultipartFile(
        file,
        filename: filename,
        contentType: _imageContentType(filename),
      ),
    });
    final res = await _api.postJson(
      '${AppConfig.authApiUrl}/auth/avatar',
      data: form,
    );
    final data = (res as Map)['data'] as Map<String, dynamic>;
    final imageUrl = data['image_url']?.toString().trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw const ApiException(
        message: 'The server did not confirm the saved profile photo.',
      );
    }
    return imageUrl;
  }

  String _imageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';

    return 'image/jpeg';
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

  Map<String, dynamic> _identifierPayload(
    String identifier, {
    required bool viaEmail,
  }) {
    final value = identifier.trim();
    return viaEmail ? {'email': value} : {'phone': value};
  }

  Map<String, dynamic> _responseData(dynamic response) {
    final body = response as Map;
    return (body['data'] ?? body) as Map<String, dynamic>;
  }
}
