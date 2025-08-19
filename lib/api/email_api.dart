import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class EmailSendCodeRequest {
  final String email;

  EmailSendCodeRequest({required this.email});

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}

class EmailVerifyRequest {
  final String username;
  final String email;
  final String code;

  EmailVerifyRequest({
    required this.username,
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'code': code,
      };
}

class EmailAPI {
  /// 인증 코드 보내기
  /// POST /api/email/send-code
  static Future<void> sendCode(EmailSendCodeRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.emailSendCodeEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(request.toJson()),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode != 200) {
        String errorMessage = '이메일 코드 전송 실패: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = '$errorMessage - ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('이메일 코드 전송 중 오류 발생: $e');
    }
  }

  /// 회원가입용 이메일 인증 검증
  /// POST /api/email/verify-signup
  static Future<void> verifySignup(EmailVerifyRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.emailVerifySignupEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(request.toJson()),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode != 200) {
        String errorMessage = '이메일 인증 검증 실패(회원가입): ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = '$errorMessage - ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('이메일 인증 검증 중 오류 발생(회원가입): $e');
    }
  }

  /// 아이디 찾기용 이메일 인증 검증
  /// POST /api/email/verify-id
  static Future<String> verifyId(EmailVerifyRequest request) async {
    try {
      final headers = {
        ...ApiConfig.defaultHeaders,
        'Accept': '*/*',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.emailVerifyIdEndpoint}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return '';
        }
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return data['username']?.toString() ?? '';
        } catch (_) {
          // JSON이 아닌 평문 등으로 올 경우 빈 문자열 반환
          return '';
        }
      } else {
        String errorMessage = '이메일 인증 검증 실패(아이디 찾기): ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = '$errorMessage - ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('이메일 인증 검증 중 오류 발생(아이디 찾기): $e');
    }
  }
}
