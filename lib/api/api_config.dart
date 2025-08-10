/// API 설정을 관리하는 클래스
class ApiConfig {
  // 실제 API 베이스 URL로 변경 필요
  static const String baseUrl = 'http://3.35.142.72:8080';
  
  // API 타임아웃 설정 (초)
  static const int timeoutSeconds = 30;
  
  // 공통 헤더
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // API 엔드포인트들
  static const String signupEndpoint = '/api/user/signup';
  static const String loginEndpoint = '/api/user/login';
  static const String checkUsernameEndpoint = '/api/user/check-username';
} 