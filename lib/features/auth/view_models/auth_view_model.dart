import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // 상태 변수들
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 메시지 설정
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // 사용자 정보 설정
  void _setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  // 앱 시작 시 저장된 사용자 정보 확인
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _authRepository.loadUserFromStorage();
      if (success) {
        _setUser(_authRepository.currentUser);
      }
    } catch (e) {
      _setError('사용자 정보를 불러오는데 실패했습니다');
    } finally {
      _setLoading(false);
    }
  }

  // 로그인
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      if (username.isEmpty || password.isEmpty) {
        _setError('아이디와 비밀번호를 입력해주세요');
        return false;
      }

      final success = await _authRepository.login(username, password);
      if (success) {
        _setUser(_authRepository.currentUser);
        return true;
      } else {
        _setError('로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요');
        return false;
      }
    } catch (e) {
      _setError('로그인 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 회원가입
  Future<bool> signUp(String username, String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        _setError('모든 필드를 입력해주세요');
        return false;
      }

      // 이메일 형식 검증
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _setError('올바른 이메일 형식을 입력해주세요');
        return false;
      }

      // 비밀번호 길이 검증
      if (password.length < 6) {
        _setError('비밀번호는 6자 이상이어야 합니다');
        return false;
      }

      final success = await _authRepository.signUp(username, email, password);
      if (success) {
        _setUser(_authRepository.currentUser);
        return true;
      } else {
        _setError('회원가입에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('회원가입 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authRepository.logout();
      _setUser(null);
    } catch (e) {
      _setError('로그아웃 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      if (email.isEmpty) {
        _setError('이메일을 입력해주세요');
        return false;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _setError('올바른 이메일 형식을 입력해주세요');
        return false;
      }

      final success = await _authRepository.sendPasswordResetEmail(email);
      if (success) {
        return true;
      } else {
        _setError('비밀번호 재설정 이메일 전송에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('이메일 전송 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 에러 메시지 지우기
  void clearError() {
    _setError(null);
  }
} 