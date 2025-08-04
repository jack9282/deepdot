import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailCodeController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 중복 함수 및 상태 변수 삭제

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  // 아래 중복 함수들 삭제
  // void _checkIdDuplication() async { ... }
  // void _requestEmailCode() async { ... }
  // void _verifyEmailCode() async { ... }
  // void _handleSignup() async { ... }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
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
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        // ID 입력 섹션
                        const Text(
                          '아이디',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _idController,
                                decoration: InputDecoration(
                                  hintText: '아이디 입력',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
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
                                  if (!authViewModel.isIdAvailable && authViewModel.errorMessage != null) {
                                    return authViewModel.errorMessage;
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  authViewModel.clearError();
                                  setState(() {
                                    _formKey.currentState?.validate();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 58,
                              width: 120,
                              child: ElevatedButton(
                                onPressed: authViewModel.isLoading || authViewModel.isIdAvailable
                                    ? null
                                    : () async {
                                        final result = await authViewModel.checkIdDuplication(_idController.text.trim());
                                        setState(() {}); // validator에서 에러 메시지 노출
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.0,
                                    ),
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
                                            Colors.black,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        '중복확인',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Text(
                          '4~12자/영문 소문자(숫자 조합가능)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email 입력 섹션
                        const Text(
                          '이메일',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: '이메일 입력',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
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
                                    return '이메일을 입력해주세요';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}',
                                  ).hasMatch(value)) {
                                    return '올바른 이메일 형식을 입력해주세요';
                                  }
                                  if (!authViewModel.isEmailCodeSent && authViewModel.errorMessage != null) {
                                    return authViewModel.errorMessage;
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  authViewModel.clearError();
                                  setState(() {
                                    _formKey.currentState?.validate();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 58,
                              width: 120,
                              child: ElevatedButton(
                                onPressed: authViewModel.isLoading || authViewModel.isEmailCodeSent
                                    ? null
                                    : () async {
                                        final result = await authViewModel.requestEmailCode(_emailController.text.trim());
                                        setState(() {}); // validator에서 에러 메시지 노출
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.0,
                                    ),
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
                                            Colors.black,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        '인증코드 요청',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 58,
                          child: TextFormField(
                            controller: _emailCodeController,
                            keyboardType: TextInputType.number,
                            enabled: authViewModel.isEmailCodeSent && !authViewModel.isEmailVerified,
                            decoration: InputDecoration(
                              hintText: '인증코드를 입력하세요',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
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
                                return '인증 코드를 입력해주세요';
                              }
                              if (!authViewModel.isEmailVerified && authViewModel.errorMessage != null) {
                                return authViewModel.errorMessage;
                              }
                              return null;
                            },
                            onChanged: (value) async {
                              authViewModel.clearError();
                              setState(() {
                                _formKey.currentState?.validate();
                              });
                              if (authViewModel.isEmailCodeSent && !authViewModel.isEmailVerified && value.length >= 6) {
                                final result = await authViewModel.verifyEmailCode(value.trim());
                                setState(() {}); // 인증 상태 갱신
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password 입력 섹션
                        const Text(
                          '비밀번호',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          enabled: authViewModel.isEmailVerified,
                          decoration: InputDecoration(
                            hintText: '비밀번호',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
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
                            if (!authViewModel.isEmailVerified)
                              return null;
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            if (value.length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }
                            if (authViewModel.errorMessage != null && authViewModel.errorMessage!.contains('비밀번호')) {
                              return authViewModel.errorMessage;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _formKey.currentState?.validate();
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          enabled: authViewModel.isEmailVerified,
                          decoration: InputDecoration(
                            hintText: '비밀번호 확인',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
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
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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
                            if (!authViewModel.isEmailVerified)
                              return null;
                            if (value == null || value.isEmpty) {
                              return '비밀번호 확인을 입력해주세요';
                            }
                            if (value != _passwordController.text) {
                              return '비밀번호가 일치하지 않습니다';
                            }
                            if (authViewModel.errorMessage != null && authViewModel.errorMessage!.contains('비밀번호')) {
                              return authViewModel.errorMessage;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _formKey.currentState?.validate();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 가입하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (authViewModel.isIdAvailable &&
                            authViewModel.isEmailVerified &&
                            _formKey.currentState?.validate() == true)
                        ? () async {
                            final result = await authViewModel.signUp(
                              _idController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (result && context.mounted) {
                              context.go('/login');
                            } else if (authViewModel.errorMessage != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authViewModel.errorMessage!)),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '가입하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
