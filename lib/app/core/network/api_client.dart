import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../config/app_config.dart';
import '../storage/storage_service.dart';
import 'api_exception.dart';

/// Configured [Dio] wrapper, registered once as a service.
///
/// Responsibilities:
///   - inject the bearer token on every request (kept in-memory, mirrored to
///     [StorageService] by AuthService);
///   - normalize every failure into an [ApiException];
///   - on a 401, clear the session and bounce to the login route.
class ApiClient extends GetxService {
  ApiClient(this._storage);

  final StorageService _storage;
  late final Dio dio;

  /// In-memory token, set by AuthService so the interceptor stays synchronous.
  String? token;

  /// Called on a 401 so the app can reset to the login screen. Wired by main()
  /// to avoid a hard dependency on the routing/auth layers from here.
  void Function()? onUnauthorized;

  ApiClient init() {
    dio = Dio(
      BaseOptions(
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null && token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            token = null;
            _storage.clearSecure();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    return this;
  }

  // ---- Thin verbs that always throw [ApiException] on failure ---------------

  Future<Response<dynamic>> get(String url, {Map<String, dynamic>? query}) =>
      _guard(() => dio.get(url, queryParameters: query));

  Future<Response<dynamic>> post(String url, {Object? data}) =>
      _guard(() => dio.post(url, data: data));

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
