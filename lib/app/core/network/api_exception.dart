import 'package:get/get.dart';

/// A normalized, UI-friendly error surfaced from the network layer.
///
/// The backend speaks one envelope: `{ success:false, message, error_code }`.
/// [ApiException] flattens GetConnect/transport/HTTP failures into that shape so
/// controllers never touch the raw [Response].
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.fieldErrors,
  });

  /// Human-readable message (already localized by the backend, or a fallback).
  final String message;

  /// HTTP status code, when the failure reached the server.
  final int? statusCode;

  /// Stable machine code (e.g. `BOOKING_NOT_OWNED`) for branching in the app.
  final String? errorCode;

  /// Validation errors keyed by field name (422 responses).
  final Map<String, List<String>>? fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;

  /// Build from a GetConnect [Response], reading the backend envelope when
  /// present. A null [Response.statusCode] means the request never reached the
  /// server (timeout / no connection).
  factory ApiException.fromResponse(Response<dynamic> res) {
    final data = res.body;

    String message = 'Something went wrong. Please try again.';
    String? errorCode;
    Map<String, List<String>>? fieldErrors;

    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        message = data['message'] as String;
      }
      if (data['error_code'] is String) {
        errorCode = data['error_code'] as String;
      }
      if (data['errors'] is Map) {
        fieldErrors = (data['errors'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value is List)
                ? value.map((v) => v.toString()).toList()
                : [value.toString()],
          ),
        );
      }
    }

    // Transport-level failure → never reached the server → friendlier copy.
    if (res.statusCode == null) {
      message = 'Cannot reach the server. Check your connection.';
    }

    return ApiException(
      message: message,
      statusCode: res.statusCode,
      errorCode: errorCode,
      fieldErrors: fieldErrors,
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $errorCode): $message';
}
