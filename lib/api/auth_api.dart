import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// 회원가입 요청 모델
class SignupRequest {
  final int userId;
  final String username;
  final String email;
  final String password;
  final String role;
  
  SignupRequest({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

// 로그인 요청 모델
class LoginRequest {
  final String username;
  final String password;
  
  LoginRequest({
    required this.username,
    required this.password,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

// 인증 응답 모델
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String username;
  
  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.username,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      username: json['username'] ?? '',
    );
  }
}

// 사용자명 확인 응답 모델
class UsernameCheckResponse {
  final bool isAvailable;
  final String message;
  
  UsernameCheckResponse({
    required this.isAvailable,
    required this.message,
  });
  
  factory UsernameCheckResponse.fromJson(Map<String, dynamic> json) {
    return UsernameCheckResponse(
      isAvailable: json['isAvailable'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class AuthAPI {
  /// 회원가입 API
  /// POST /api/user/signup
  static Future<AuthResponse> signup(SignupRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.signupEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(request.toJson()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception('회원가입 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }
  
  /// 로그인 API
  /// POST /api/user/login
  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(request.toJson()),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception('로그인 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('로그인 중 오류 발생: $e');
    }
  }
  
  /// 사용자명 확인 API
  /// GET /api/user/check-username?username={username}
  static Future<UsernameCheckResponse> checkUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkUsernameEndpoint}?username=$username'),
        headers: ApiConfig.defaultHeaders,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return UsernameCheckResponse.fromJson(responseData);
      } else {
        throw Exception('사용자명 확인 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('사용자명 확인 중 오류 발생: $e');
    }
  }
}
