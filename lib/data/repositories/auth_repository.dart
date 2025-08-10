import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../api/auth_api.dart';

class AuthRepository {
  static const String _userKey = 'user';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  // 현재 로그인된 사용자 정보를 저장하는 변수
  UserModel? _currentUser;

  // 현재 사용자 정보 getter
  UserModel? get currentUser => _currentUser;

  // 로그인 상태 확인
  bool get isLoggedIn => _currentUser != null;

  // 로그인
  Future<bool> login(String username, String password) async {
    try {
      final loginRequest = LoginRequest(
        username: username,
        password: password,
      );

      final authResponse = await AuthAPI.login(loginRequest);
      
      // 사용자 정보 생성
      final user = UserModel(
        id: authResponse.username, // API에서 userId가 없으므로 username을 id로 사용
        username: authResponse.username,
        email: '', // API 응답에 email이 없으므로 빈 문자열
        name: authResponse.username,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _currentUser = user;

      // 토큰과 사용자 정보를 로컬 스토리지에 저장
      await _saveUserToStorage(user);
      await _saveTokenToStorage(authResponse.accessToken);
      await _saveRefreshTokenToStorage(authResponse.refreshToken);

      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // 회원가입
  Future<bool> signUp(String username, String email, String password) async {
    try {
      final signupRequest = SignupRequest(
        userId: 0, // API에서 userId가 0으로 고정되어 있음
        username: username,
        email: email,
        password: password,
        role: 'USER', // 기본 역할
      );

      final authResponse = await AuthAPI.signup(signupRequest);
      
      // 사용자 정보 생성
      final user = UserModel(
        id: authResponse.username,
        username: authResponse.username,
        email: email,
        name: authResponse.username,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _currentUser = user;

      // 토큰과 사용자 정보를 로컬 스토리지에 저장
      await _saveUserToStorage(user);
      await _saveTokenToStorage(authResponse.accessToken);
      await _saveRefreshTokenToStorage(authResponse.refreshToken);

      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  // 사용자명 중복 확인
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await AuthAPI.checkUsername(username);
      return response.isAvailable;
    } catch (e) {
      print('Username check error: $e');
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // 실제 구현에서는 서버 API 호출
      await Future.delayed(const Duration(seconds: 2)); // 네트워크 지연 시뮬레이션
      return true;
    } catch (e) {
      return false;
    }
  }

  // 앱 시작 시 저장된 사용자 정보 로드
  Future<bool> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);

      if (userJson != null && token != null) {
        // JSON에서 사용자 정보 파싱
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);

        _currentUser = user;
        return true;
      }
      return false;
    } catch (e) {
      print('Load user from storage error: $e');
      return false;
    }
  }

  // 사용자 정보를 로컬 스토리지에 저장
  Future<void> _saveUserToStorage(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  // 토큰을 로컬 스토리지에 저장
  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 리프레시 토큰을 로컬 스토리지에 저장
  Future<void> _saveRefreshTokenToStorage(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // 저장된 토큰 가져오기
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 저장된 리프레시 토큰 가져오기
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
} 