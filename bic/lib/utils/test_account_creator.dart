import 'package:flutter/foundation.dart';
import 'package:bic/services/auth_service.dart';

class TestAccountCreator {
  static final AuthService _authService = AuthService();

  static Future<Map<String, dynamic>> createTestAccount() async {
    try {
      final result = await _authService.register(
        username: 'testuser',
        email: 'test@bic.com',
        country: 'Kurdistan',
        password: '123456',
        passwordConfirmation: '123456',
      );

      if (result['success']) {
        debugPrint('هەژماری تاقیکردنەوە دروستکرا بە سەرکەوتوویی');
      } else {
        debugPrint('کێشە: ${result['message']}');
      }

      return result;
    } catch (e) {
      debugPrint('test account error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static void printTestAccountInfo() {
    debugPrint('email: test@bic.com');
    debugPrint('password: 123456');
    debugPrint('username: testuser');
    debugPrint('country: Kurdistan');
  }
}
