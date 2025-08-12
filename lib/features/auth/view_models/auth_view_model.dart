import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/token_manager.dart';
import '../../../api/password-reset-api.dart';
import '../../../api/find-id-api.dart';

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

  // 앱 시작 시 저장된 토큰으로 자동 로그인 확인
  Future<bool> checkAutoLogin() async {
    try {
      final isLoggedIn = await TokenManager.instance.isLoggedIn();
      final hasValidToken = await TokenManager.instance.hasValidToken();
      
      if (isLoggedIn && hasValidToken) {
        final username = await TokenManager.instance.getUsername();
        if (username != null) {
          // 저장된 사용자 정보로 UserModel 생성
          _currentUser = UserModel(
            id: '0', // 실제 사용자 ID는 서버에서 가져와야 함
            username: username,
            email: '', // 이메일은 별도로 저장하지 않으므로 빈 문자열
            createdAt: DateTime.now(), // 임시로 현재 시간 사용
          );
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Auto login check error: $e');
      return false;
    }
  }

  // 아이디 중복 확인
  bool _isIdAvailable = false;
  bool get isIdAvailable => _isIdAvailable;
  Future<bool> checkIdDuplication(String username) async {
    _setLoading(true);
    _setError(null);
    try {
      if (username.isEmpty) {
        _setError('아이디를 입력해주세요');
        return false;
      }
      
      // 사용자명 형식 검증 (4~12자, 영문 소문자, 숫자 조합)
      if (!RegExp(r'^[a-z0-9]{4,12}$').hasMatch(username)) {
        _setError('아이디는 4~12자의 영문 소문자와 숫자 조합이어야 합니다');
        return false;
      }
      
      // 실제 사용자명 중복 확인 API 호출
      final response = await _authRepository.checkUsernameAvailability(username);
      _isIdAvailable = response.isAvailable;
      
      if (!response.isAvailable) {
        _setError(response.message);
      } else {
        _setError(null);
      }
      
      notifyListeners();
      return response.isAvailable;
    } catch (e) {
      _setError('아이디 중복 확인 중 오류가 발생했습니다');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 이메일 인증 코드 요청
  bool _isEmailCodeSent = false;
  bool get isEmailCodeSent => _isEmailCodeSent;
  Future<bool> requestEmailCode(String email) async {
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
      
      final success = await FindIdApi.sendEmailCode(email);
      if (success) {
        _isEmailCodeSent = true;
        _isEmailVerified = false; // 재전송 시 인증 상태 초기화
        notifyListeners();
        return true;
      } else {
        _setError('인증 코드 전송에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('이메일 코드 요청 중 오류가 발생했습니다');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 이메일 인증 코드 확인
  bool _isEmailVerified = false;
  bool get isEmailVerified => _isEmailVerified;
  Future<bool> verifyEmailCode(String code) async {
    _setLoading(true);
    _setError(null);
    try {
      if (code.isEmpty) {
        _setError('인증 코드를 입력해주세요');
        return false;
      }
      
      // TODO: 실제 이메일 인증 API 구현 시 여기에 API 호출 추가
      // 현재는 6자리 코드를 입력하면 자동으로 인증 완료
      if (code.length == 6) {
        await Future.delayed(const Duration(seconds: 1));
        _isEmailVerified = true;
        _setError(null);
        notifyListeners();
        return true;
      } else if (code.length > 6) {
        _setError('인증 코드는 6자리입니다');
        return false;
      } else {
        // 6자리 미만일 때는 에러 메시지를 표시하지 않음
        return false;
      }
    } catch (e) {
      _setError('이메일 인증 중 오류가 발생했습니다');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String newPassword, String confirmPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      if (newPassword.isEmpty) {
        _setError('새 비밀번호를 입력해주세요');
        return false;
      }

      if (newPassword.length < 6) {
        _setError('비밀번호는 6자 이상이어야 합니다');
        return false;
      }

      if (newPassword != confirmPassword) {
        _setError('비밀번호가 일치하지 않습니다');
        return false;
      }

      // 현재 로그인된 사용자의 username 가져오기
      final username = await TokenManager.instance.getUsername();
      if (username == null) {
        _setError('사용자 정보를 찾을 수 없습니다');
        return false;
      }

      final success = await PasswordResetApi.resetPassword(username, newPassword);
      if (success) {
        return true;
      } else {
        _setError('비밀번호 재설정에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('비밀번호 재설정 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

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
  Future<bool> signUp(String username, String email, String password, String confirmPassword) async {
    _setLoading(true);
    _setError(null);

    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        _setError('모든 필드를 입력해주세요');
        return false;
      }

      // 아이디 중복 확인은 선택사항으로 변경 (중복확인을 하지 않아도 회원가입 가능)
      // if (!_isIdAvailable) {
      //   _setError('아이디 중복 확인을 완료해주세요');
      //   return false;
      // }

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

      // 비밀번호 확인 검증
      if (password != confirmPassword) {
        _setError('비밀번호가 일치하지 않습니다');
        return false;
      }

      final success = await _authRepository.signUp(username, email, password, confirmPassword);
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
      await TokenManager.instance.clearAuthData();
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

  // 비밀번호 재설정 코드 전송
  Future<bool> sendResetCode(String username, String email) async {
    _setLoading(true);
    _setError(null);

    try {
      if (username.isEmpty) {
        _setError('아이디를 입력해주세요');
        return false;
      }

      if (email.isEmpty) {
        _setError('이메일을 입력해주세요');
        return false;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _setError('올바른 이메일 형식을 입력해주세요');
        return false;
      }

      final success = await PasswordResetApi.sendResetCode(username, email);
      if (success) {
        return true;
      } else {
        _setError('인증 코드 전송에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('인증 코드 전송 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 비밀번호 재설정 코드 검증
  Future<bool> verifyResetCode(String username, String email, String code) async {
    _setLoading(true);
    _setError(null);

    try {
      if (username.isEmpty) {
        _setError('아이디를 입력해주세요');
        return false;
      }

      if (email.isEmpty) {
        _setError('이메일을 입력해주세요');
        return false;
      }

      if (code.isEmpty) {
        _setError('인증 코드를 입력해주세요');
        return false;
      }

      final success = await PasswordResetApi.verifyResetCode(username, email, code);
      if (success) {
        return true;
      } else {
        _setError('인증 코드가 올바르지 않습니다');
        return false;
      }
    } catch (e) {
      _setError('인증 코드 검증 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 아이디 찾기 이메일 인증
  Future<Map<String, dynamic>> verifyIdEmail(String email, String code) async {
    _setLoading(true);
    _setError(null);

    try {
      if (email.isEmpty) {
        _setError('이메일을 입력해주세요');
        return {'success': false, 'message': '이메일을 입력해주세요'};
      }

      if (code.isEmpty) {
        _setError('인증 코드를 입력해주세요');
        return {'success': false, 'message': '인증 코드를 입력해주세요'};
      }

      final result = await FindIdApi.verifyIdEmail(email, code);
      if (result['success']) {
        return result;
      } else {
        _setError(result['message']);
        return result;
      }
    } catch (e) {
      _setError('아이디 찾기 중 오류가 발생했습니다: ${e.toString()}');
      return {'success': false, 'message': '네트워크 오류가 발생했습니다'};
    } finally {
      _setLoading(false);
    }
  }

  // 에러 메시지 지우기
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  // 아이디 중복 확인 상태 초기화
  void clearIdAvailability() {
    _isIdAvailable = false;
    notifyListeners();
  }
} 