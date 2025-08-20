import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  static TokenManager get instance => _instance;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _lastRefreshKey = 'last_refresh_timestamp';

  Timer? _refreshTimer;
  bool _isRefreshing = false;

  /// 토큰 자동 갱신 시작
  Future<void> startAutoRefresh() async {
    await _stopAutoRefresh(); // 기존 타이머 정리
    
    final accessToken = await getAccessToken();
    if (accessToken == null) return;

    final expiresAt = _getTokenExpiryTime(accessToken);
    if (expiresAt == null) return;

    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);
    
    // 토큰이 이미 만료되었거나 5분 이내에 만료되는 경우 즉시 갱신
    if (timeUntilExpiry.inMinutes <= 5) {
      await _refreshTokenIfNeeded();
      return;
    }

    // 토큰 만료 5분 전에 갱신하도록 타이머 설정
    final refreshTime = expiresAt.subtract(Duration(minutes: 5));
    final timeUntilRefresh = refreshTime.difference(now);
    
    if (timeUntilRefresh.isNegative) {
      // 이미 갱신 시간이 지났으면 즉시 갱신
      await _refreshTokenIfNeeded();
    } else {
      // 갱신 시간까지 대기
      _refreshTimer = Timer(timeUntilRefresh, () async {
        await _refreshTokenIfNeeded();
      });
      print('토큰 자동 갱신 타이머 설정: ${timeUntilRefresh.inMinutes}분 후');
    }
  }

  /// 토큰 자동 갱신 중지
  Future<void> stopAutoRefresh() async {
    await _stopAutoRefresh();
  }

  /// 내부: 타이머 정리
  Future<void> _stopAutoRefresh() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 내부: 필요시 토큰 갱신
  Future<void> _refreshTokenIfNeeded() async {
    if (_isRefreshing) return; // 이미 갱신 중이면 중복 실행 방지
    
    _isRefreshing = true;
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) return;

      final expiresAt = _getTokenExpiryTime(accessToken);
      if (expiresAt == null) return;

      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);
      
      // 토큰이 5분 이내에 만료되는 경우에만 갱신
      if (timeUntilExpiry.inMinutes <= 5) {
        await _performTokenRefresh();
      }
    } catch (e) {
      print('토큰 자동 갱신 실패: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// 내부: 실제 토큰 갱신 수행
  Future<void> _performTokenRefresh() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || !isTokenValid(refreshToken)) {
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
        await saveAuthData(
          accessToken: responseData['accessToken'] ?? '',
          refreshToken: responseData['refreshToken'] ?? '',
          username: responseData['username'] ?? '',
        );
        
        // 갱신 성공 후 다음 갱신 타이머 설정
        await startAutoRefresh();
        
        print('토큰 자동 갱신 성공');
      } else {
        throw Exception('토큰 갱신 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('토큰 갱신 중 오류: $e');
      // 갱신 실패 시 로그아웃 처리
      await clearAuthData();
      throw e;
    }
  }

  /// 토큰 만료 시간 추출
  DateTime? _getTokenExpiryTime(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final exp = decodedToken['exp'];
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      print('토큰 디코딩 실패: $e');
    }
    return null;
  }

  /// 토큰 유효성 검사
  bool isTokenValid(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final exp = decodedToken['exp'];
      if (exp != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isBefore(expiryTime);
      }
    } catch (e) {
      print('토큰 유효성 검사 실패: $e');
    }
    return false;
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

  /// 인증 데이터 저장
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
    
    // 토큰 저장 후 자동 갱신 시작
    await startAutoRefresh();
  }

  /// 인증 데이터 삭제
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_lastRefreshKey);
    
    // 자동 갱신 중지
    await stopAutoRefresh();
  }

  /// 게스트 모드 확인
  Future<bool> isGuestMode() async {
    final accessToken = await getAccessToken();
    return accessToken == null || accessToken.isEmpty;
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty && isTokenValid(accessToken);
  }

  /// 유효한 토큰 보유 여부 확인
  Future<bool> hasValidToken() async {
    final accessToken = await getAccessToken();
    return accessToken != null && isTokenValid(accessToken);
  }

  /// 마지막 갱신 시간 가져오기
  Future<DateTime?> getLastRefreshTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastRefreshKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// 토큰 만료까지 남은 시간 (분)
  Future<int?> getMinutesUntilExpiry() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return null;

    final expiresAt = _getTokenExpiryTime(accessToken);
    if (expiresAt == null) return null;

    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);
    return timeUntilExpiry.inMinutes;
  }

  /// 수동 토큰 갱신 (테스트용)
  Future<void> manualRefresh() async {
    await _performTokenRefresh();
  }
} 