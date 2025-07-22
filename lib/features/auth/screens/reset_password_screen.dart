import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  // 생성자에 'token' 또는 'email' 등 비밀번호 재설정을 위한 식별자를 받을 수 있도록 추가
  // 여기서는 목업이므로 사용하지 않지만, 실제 앱에서는 필요합니다.
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      // 유효성 검사 실패 시 스낵바 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 올바르게 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: 여기에 실제 비밀번호 재설정 API 호출 로직을 구현합니다.
    // _passwordController.text를 백엔드로 전송합니다.
    await Future.delayed(const Duration(seconds: 2)); // 2초 지연 시뮬레이션

    setState(() {
      _isLoading = false;
    });

    // 재설정 성공 시 다이얼로그 표시
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // 사용자가 외부 탭으로 닫을 수 없게 설정
        builder: (context) => AlertDialog(
          title: const Text('비밀번호 재설정 완료'),
          content: const Text(
            '비밀번호가 성공적으로 재설정되었습니다.\n새로운 비밀번호로 로그인해주세요.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                context.go('/login'); // 로그인 화면으로 이동
              },
              child: const Text(
                '확인',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            // 뒤로가기 시 로그인 화면으로 이동 (혹은 이전 화면으로 pop)
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 85),
                Center(
                  child: Text(
                    'Reset Password', // 화면 제목
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // New Password Input
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // 비밀번호 가리기/보이기
                  decoration: InputDecoration(
                    hintText: '새 비밀번호를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.darkColor,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    // 비밀번호 가리기/보이기 아이콘
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                      return '비밀번호를 입력해주세요.';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다.';
                    }
                    // 더 강력한 비밀번호 규칙 추가 가능 (예: 숫자, 특수문자 포함)
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm New Password Input
                const Text(
                  'Confirm New Password',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible, // 비밀번호 가리기/보이기
                  decoration: InputDecoration(
                    hintText: '새 비밀번호를 다시 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.darkColor,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    // 비밀번호 가리기/보이기 아이콘
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요.';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),

                const Spacer(), // 남은 공간 채우기

                // Reset Password Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword, // 로딩 중에는 버튼 비활성화
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '비밀번호 재설정',
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
      ),
    );
  }
}