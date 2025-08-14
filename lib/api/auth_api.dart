import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'token_manager.dart';

// 회원가입 요청 모델
class SignupRequest {
  final int userId;
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String role;
  
  SignupRequest({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.role,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
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
    // 첫 번째 엔드포인트 시도
    try {
      return await _trySignup(request, ApiConfig.signupEndpoint);
    } catch (e) {
      print('First signup endpoint failed: $e');
      
      // 두 번째 엔드포인트 시도
      try {
        return await _trySignup(request, ApiConfig.signupEndpointAlt);
      } catch (e2) {
        print('Second signup endpoint failed: $e2');
        throw Exception('모든 회원가입 엔드포인트 실패: $e2');
      }
    }
  }
  
  /// 실제 회원가입 요청을 수행하는 내부 메서드
  static Future<AuthResponse> _trySignup(SignupRequest request, String endpoint) async {
    try {
      print('Trying signup endpoint: $endpoint');
      print('Signup request: ${jsonEncode(request.toJson())}');
      print('Signup URL: ${ApiConfig.baseUrl}$endpoint');
      print('Signup headers: ${ApiConfig.defaultHeaders}');
      
      // 기본 헤더에 추가 헤더 설정
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
      headers['Authorization'] = 'Bearer null'; // 임시 인증 헤더
      
      // POST 메서드 시도
      var response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      // POST가 실패하면 PUT 메서드 시도
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('POST failed, trying PUT method...');
        response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: headers,
          body: jsonEncode(request.toJson()),
        ).timeout(const Duration(seconds: 30));
      }
      
      print('Signup response status: ${response.statusCode}');
      print('Signup response headers: ${response.headers}');
      print('Signup response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);
        
        // 토큰 자동 저장
        await TokenManager.instance.saveAuthData(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          username: authResponse.username,
        );
        
        return authResponse;
      } else {
        String errorMessage = '회원가입 실패: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Signup error: $e');
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
        final authResponse = AuthResponse.fromJson(responseData);
        
        // 토큰 자동 저장
        await TokenManager.instance.saveAuthData(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          username: authResponse.username,
        );
        
        return authResponse;
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
      print('Check username request: $username');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkUsernameEndpoint}?username=$username'),
        headers: ApiConfig.defaultHeaders,
      );
      
      print('Check username response status: ${response.statusCode}');
      print('Check username response body: "${response.body}"');
      print('Check username response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        // 200: 사용자명이 사용 가능한 경우
        if (response.body.isEmpty) {
          // 응답 본문이 비어있는 경우, 사용 가능한 것으로 처리
          return UsernameCheckResponse(
            isAvailable: true,
            message: '사용 가능한 아이디입니다',
          );
        }
        
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return UsernameCheckResponse.fromJson(responseData);
        } catch (e) {
          // JSON 파싱 실패 시, 사용 가능한 것으로 처리
          print('JSON parsing error: $e');
          return UsernameCheckResponse(
            isAvailable: true,
            message: '사용 가능한 아이디입니다',
          );
        }
      } else if (response.statusCode == 409) {
        // 409: 사용자명이 이미 존재하는 경우 (사용 불가능)
        return UsernameCheckResponse(
          isAvailable: false,
          message: '이미 사용 중인 아이디입니다',
        );
      } else {
        String errorMessage = '사용자명 확인 실패: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Check username error: $e');
      throw Exception('사용자명 확인 중 오류 발생: $e');
    }
  }
  
  /// 로그아웃 API
  /// POST /api/user/logout
  static Future<void> logout() async {
    try {
      final accessToken = await TokenManager.instance.getAccessToken();
      
      if (accessToken != null && TokenManager.instance.isTokenValid(accessToken)) {
        final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
        headers['Authorization'] = 'Bearer $accessToken';
        
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/user/logout'),
          headers: headers,
        );
      }
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      // 로컬 토큰 데이터 삭제
      await TokenManager.instance.clearAuthData();
    }
  }
  
  /// 토큰 갱신 API
  /// POST /api/user/refresh
  static Future<AuthResponse> refreshToken() async {
    try {
      final refreshToken = await TokenManager.instance.getRefreshToken();
      
      if (refreshToken == null || !TokenManager.instance.isTokenValid(refreshToken)) {
        throw Exception('리프레시 토큰이 유효하지 않습니다');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/refresh'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);
        
        // 새로운 토큰 저장
        await TokenManager.instance.saveAuthData(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          username: authResponse.username,
        );
        
        return authResponse;
      } else {
        throw Exception('토큰 갱신 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('토큰 갱신 중 오류 발생: $e');
    }
  }
  
  /// 현재 저장된 토큰으로 인증된 요청 헤더 생성
  static Future<Map<String, String>> getAuthHeaders() async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    final accessToken = await TokenManager.instance.getAccessToken();
    
    if (accessToken != null && TokenManager.instance.isTokenValid(accessToken)) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }
}
