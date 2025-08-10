import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _isLoggedInKey = 'is_logged_in';

  static TokenManager? _instance;
  static TokenManager get instance {
    _instance ??= TokenManager._();
    return _instance!;
  }

  TokenManager._();

  /// 액세스 토큰 저장
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// 사용자명 저장
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  /// 로그인 상태 저장
  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  /// 액세스 토큰 가져오기
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// 리프레시 토큰 가져오기
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 사용자명 가져오기
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// 모든 토큰 및 사용자 정보 저장
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUsername(username),
      setLoggedIn(true),
    ]);
  }

  /// 모든 토큰 및 사용자 정보 삭제 (로그아웃)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_usernameKey),
      setLoggedIn(false),
    ]);
  }

  /// 토큰이 유효한지 확인 (기본적인 형식 검증)
  bool isTokenValid(String? token) {
    return token != null && token.isNotEmpty && token != 'null';
  }

  /// 현재 저장된 토큰이 유효한지 확인
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return isTokenValid(token);
  }
} 