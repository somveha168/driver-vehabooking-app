import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/core/network/api_exception.dart';

void main() {
  group('ApiException.fromDio', () {
    final req = RequestOptions(path: '/x');

    test('reads message + error_code from the backend envelope', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 404,
            data: {
              'success': false,
              'message': 'Booking not found.',
              'error_code': 'BOOKING_NOT_OWNED',
            },
          ),
        ),
      );

      expect(e.statusCode, 404);
      expect(e.message, 'Booking not found.');
      expect(e.errorCode, 'BOOKING_NOT_OWNED');
    });

    test('extracts 422 field errors', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 422,
            data: {
              'message': 'The given data was invalid.',
              'errors': {
                'login': ['Phone number or email is required.'],
              },
            },
          ),
        ),
      );

      expect(e.isValidation, isTrue);
      expect(e.fieldErrors?['login']?.first, contains('required'));
    });

    test('gives a friendly message for connection errors', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: req,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(e.statusCode, isNull);
      expect(e.message, contains('connection'));
    });
  });
}
