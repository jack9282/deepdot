import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class PasswordResetApi {
  static const String baseUrl = ApiConfig.baseUrl;

  // 비밀번호 재설정 코드 전송
  static Future<bool> sendResetCode(String username, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password/send-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 비밀번호 재설정 코드 검증
  static Future<bool> verifyResetCode(String username, String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 비밀번호 재설정
  static Future<bool> resetPassword(String username, String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password/reset'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
