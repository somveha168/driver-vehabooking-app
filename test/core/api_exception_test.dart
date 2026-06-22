import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:veha_driver_app/app/core/network/api_exception.dart';

void main() {
  group('ApiException.fromResponse', () {
    test('reads message + error_code from the backend envelope', () {
      final e = ApiException.fromResponse(
        const Response<dynamic>(
          statusCode: 404,
          body: {
            'success': false,
            'message': 'Booking not found.',
            'error_code': 'BOOKING_NOT_OWNED',
          },
        ),
      );

      expect(e.statusCode, 404);
      expect(e.message, 'Booking not found.');
      expect(e.errorCode, 'BOOKING_NOT_OWNED');
    });

    test('extracts 422 field errors', () {
      final e = ApiException.fromResponse(
        const Response<dynamic>(
          statusCode: 422,
          body: {
            'message': 'The given data was invalid.',
            'errors': {
              'login': ['Phone number or email is required.'],
            },
          },
        ),
      );

      expect(e.isValidation, isTrue);
      expect(e.fieldErrors?['login']?.first, contains('required'));
    });

    test('gives a friendly message when the request never reached the server', () {
      final e = ApiException.fromResponse(const Response<dynamic>(statusCode: null));

      expect(e.statusCode, isNull);
      expect(e.message, contains('connection'));
    });
  });
}
