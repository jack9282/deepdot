import 'package:shared_preferences/shared_preferences.dart';
import 'auth_api.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
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

  /// 사용자 ID 저장
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
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

  /// 사용자 ID 가져오기
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
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
    int? userId,
  }) async {
    final futures = [
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUsername(username),
      setLoggedIn(true),
    ];
    
    // userId가 제공된 경우에만 저장
    if (userId != null) {
      futures.add(saveUserId(userId));
    }
    
    await Future.wait(futures);
  }

  /// 모든 토큰 및 사용자 정보 삭제 (로그아웃)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_usernameKey),
      prefs.remove(_userIdKey),
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

  /// username을 기반으로 임시 userId 생성
  /// 백엔드에서 실제 userId를 제공할 때까지 사용하는 임시 방법
  int generateUserIdFromUsername(String username) {
    // username의 해시코드를 양수로 변환하여 userId로 사용
    return username.hashCode.abs();
  }

  /// 현재 사용자 ID 가져오기 (없으면 username 기반으로 생성)
  Future<int> getCurrentUserId() async {
    int? userId = await getUserId();
    
    if (userId == null) {
      // userId가 없으면 username 기반으로 생성
      final username = await getUsername();
      if (username != null) {
        userId = generateUserIdFromUsername(username);
        await saveUserId(userId); // 생성된 userId 저장
      } else {
        throw Exception('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.');
      }
    }
    
    return userId;
  }

  /// 토큰 갱신 시도
  Future<bool> refreshToken() async {
    try {
      final authResponse = await AuthAPI.refreshToken();
      return true;
    } catch (e) {
      print('토큰 갱신 실패: $e');
      return false;
    }
  }

  /// 토큰이 만료되었는지 확인하고 갱신 시도
  Future<bool> ensureValidToken() async {
    if (await hasValidToken()) {
      return true;
    }
    
    return await refreshToken();
  }

  /// 비회원 모드인지 확인 (토큰이 없거나 유효하지 않은 경우)
  Future<bool> isGuestMode() async {
    final loggedInStatus = await isLoggedIn();
    final hasValidToken = await this.hasValidToken();
    return !loggedInStatus || !hasValidToken;
  }
} 