import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../../../utils/snak_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 60),

                            // 환영 메시지
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '안녕하세요!',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'DeepDot 입니다.',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '구글, 비회원으로 로그인이 가능합니다.',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 40),

                            // ID 입력
                            TextFormField(
                              controller: _idController,
                              decoration: InputDecoration(
                                hintText: '아이디 입력',
                                hintStyle: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2.0,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '아이디를 입력해주세요';
                                }
                                // 로그인 실패 시에만 에러 메시지 표시
                                if (authViewModel.errorMessage != null && 
                                    authViewModel.errorMessage!.contains('로그인')) {
                                  return '아이디 혹은 비밀번호가 맞지 않습니다';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                authViewModel.clearError();
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password 입력
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: '비밀번호 입력',
                                hintStyle: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2.0,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '비밀번호를 입력해주세요';
                                }
                                // 로그인 실패 시에만 에러 메시지 표시
                                if (authViewModel.errorMessage != null && 
                                    authViewModel.errorMessage!.contains('로그인')) {
                                  return '아이디 혹은 비밀번호가 맞지 않습니다';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                authViewModel.clearError();
                              },
                            ),

                            const SizedBox(height: 16),

                            // 자동 로그인 체크박스
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Text(
                                  '자동 로그인',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimaryColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 로그인 버튼
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          await _handleLogin(authViewModel);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: authViewModel.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        '로그인',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 링크 버튼들
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    context.push('/forgot-id');
                                  },
                                  child: Text(
                                    "아이디 찾기",
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 12,
                                  color: Colors.grey.shade400,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.push('/forgot-password?tab=1');
                                  },
                                  child: Text(
                                    "비밀번호 찾기",
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 12,
                                  color: Colors.grey.shade400,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.push('/signup');
                                  },
                                  child: Text(
                                    "회원가입",
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // 구분선
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '또는',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 비회원 로그인 버튼
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: authViewModel.isLoading
                                    ? null
                                    : () async {
                                        await _handleGuestLogin(authViewModel);
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimaryColor,
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authViewModel.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        '비회원 로그인',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogin(AuthViewModel authViewModel) async {
    // 로그인 시도 전에 에러 메시지 초기화
    authViewModel.clearError();
    
    final success = await authViewModel.login(
      _idController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go('/home');
    } else if (!success && mounted) {
      // 로그인 실패 시 스낵바로 경고 메시지 표시
      CustomSnackBar.showError(
        context,
        authViewModel.errorMessage ?? '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.',
      );
      
      // 폼 유효성 검사를 다시 실행하여 에러 메시지 표시
      setState(() {
        _formKey.currentState?.validate();
      });
    }
  }

  Future<void> _handleGuestLogin(AuthViewModel authViewModel) async {
    // 비회원 로그인 시도 전에 에러 메시지 초기화
    authViewModel.clearError();
    
    final success = await authViewModel.guestLogin();

    if (success && mounted) {
      context.go('/home');
    } else if (!success && mounted) {
      // 비회원 로그인 실패 시 스낵바로 경고 메시지 표시
      CustomSnackBar.showError(
        context,
        authViewModel.errorMessage ?? '비회원 로그인에 실패했습니다.',
      );
    }
  }
}