import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRepository {
  static const String _userKey = 'user';
  static const String _tokenKey = 'auth_token';

  // 현재 로그인된 사용자 정보를 저장하는 변수
  UserModel? _currentUser;

  // 현재 사용자 정보 getter
  UserModel? get currentUser => _currentUser;

  // 로그인 상태 확인
  bool get isLoggedIn => _currentUser != null;

  // 로그인
  Future<bool> login(String username, String password) async {
    try {
      // 실제 구현에서는 서버 API 호출
      // 지금은 임시로 더미 데이터 사용
      await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

      // 더미 사용자 생성
      final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: '$username@example.com',
        name: username,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _currentUser = user;

      // 로컬 스토리지에 저장
      await _saveUserToStorage(user);
      await _saveTokenToStorage('fake_token_${user.id}');

      return true;
    } catch (e) {
      return false;
    }
  }

  // 회원가입
  Future<bool> signUp(String username, String email, String password) async {
    try {
      // 실제 구현에서는 서버 API 호출
      await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

      // 더미 사용자 생성
      final user = UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        name: username,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _currentUser = user;

      // 로컬 스토리지에 저장
      await _saveUserToStorage(user);
      await _saveTokenToStorage('fake_token_${user.id}');

      return true;
    } catch (e) {
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
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
        final userMap = <String, dynamic>{};
        // 실제로는 json.decode(userJson)을 사용하지만 
        // 지금은 간단하게 더미 데이터로 처리
        final user = UserModel(
          id: 'stored_user',
          username: 'stored_username',
          email: 'stored@example.com',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        _currentUser = user;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 사용자 정보를 로컬 스토리지에 저장
  Future<void> _saveUserToStorage(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    // 실제로는 json.encode(user.toJson())을 사용
    await prefs.setString(_userKey, user.toString());
  }

  // 토큰을 로컬 스토리지에 저장
  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 저장된 토큰 가져오기
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
} 