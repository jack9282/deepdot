/// API 설정을 관리하는 클래스
class ApiConfig {
  // 실제 API 베이스 URL
  static const String baseUrl = 'https://deepdot.zapto.org';
  
  // API 타임아웃 설정 (초)
  static const int timeoutSeconds = 30;
  
  // 공통 헤더
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };
  
  // API 엔드포인트들
  static const String signupEndpoint = '/api/user/signup';
  static const String signupEndpointAlt = '/api/auth/signup'; // 대체 엔드포인트
  static const String loginEndpoint = '/api/user/login';
  static const String checkUsernameEndpoint = '/api/user/check-username';
  
  // Medication API 엔드포인트들
  static const String medicationEndpoint = '/api/medication';
} 