import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class FindIdApi {
  static const String baseUrl = ApiConfig.baseUrl;

  // 이메일 인증 코드 전송
  static Future<bool> sendEmailCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/email/send-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
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

  // 아이디 찾기 이메일 인증
  static Future<Map<String, dynamic>> verifyIdEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/email/verify-id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'username': responseData['username'],
        };
      } else {
        return {
          'success': false,
          'message': '인증에 실패했습니다',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다',
      };
    }
  }

  // 회원가입 이메일 인증
  static Future<bool> verifySignupEmail(String username, String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/email/verify-signup'),
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
}
