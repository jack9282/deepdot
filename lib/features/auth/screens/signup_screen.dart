import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';
import '../../../utils/snak_bar.dart';

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

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

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
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
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
                                  
                                  // 아이디 형식 검증 (4자 미만일 때는 경고하지 않음)
                                  if (value.length >= 4 && !RegExp(r'^[a-z0-9]{4,12}$').hasMatch(value)) {
                                    return '아이디는 4~12자의 영문 소문자와 숫자 조합이어야 합니다';
                                  }
                                  
                                  // 중복 확인이 완료되지 않은 경우 (4자 이상일 때만)
                                  if (value.length >= 4 && !authViewModel.isIdAvailable && authViewModel.errorMessage == null) {
                                    return '아이디 중복 확인을 완료해주세요';
                                  }
                                  
                                  // 중복 확인 실패한 경우
                                  if (!authViewModel.isIdAvailable && authViewModel.errorMessage != null) {
                                    return authViewModel.errorMessage;
                                  }
                                  
                                  return null;
                                },
                                onChanged: (value) {
                                  // 아이디가 변경되면 중복 확인 상태 초기화
                                  if (authViewModel.isIdAvailable) {
                                    authViewModel.clearIdAvailability();
                                  }
                                  authViewModel.clearError();
                                  // validate는 호출하지 않음 - 사용자가 중복확인 버튼을 누를 때만 검증
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 58,
                              width: 120,
                              child: ElevatedButton(
                                onPressed:
                                    authViewModel.isLoading
                                    ? null
                                    : () async {
                                        if (_idController.text.trim().isEmpty) {
                                          CustomSnackBar.showError(
                                            context,
                                            '아이디를 입력해주세요',
                                          );
                                          return;
                                        }
                                        
                                        // 아이디 형식 검증
                                        if (!RegExp(r'^[a-z0-9]{4,12}$').hasMatch(_idController.text.trim())) {
                                          CustomSnackBar.showError(
                                            context,
                                            '아이디는 4~12자의 영문 소문자와 숫자 조합이어야 합니다',
                                          );
                                          return;
                                        }
                                        
                                        final result = await authViewModel
                                            .checkIdDuplication(
                                              _idController.text.trim(),
                                            );
                                        
                                        if (result) {
                                          // 중복 확인 성공 (사용 가능)
                                          CustomSnackBar.showSuccess(
                                            context,
                                            '사용 가능한 아이디입니다',
                                          );
                                        } else {
                                          // 중복 확인 실패 (사용 불가능)
                                          CustomSnackBar.showError(
                                            context,
                                            authViewModel.errorMessage ?? '이미 사용 중인 아이디입니다',
                                          );
                                        }
                                        
                                        setState(() {}); // UI 업데이트
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        authViewModel.isIdAvailable 
                                            ? '확인완료' 
                                            : '중복확인',
                                        style: const TextStyle(
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
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
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
                                    return '이메일을 입력해주세요';
                                  }
                                  if (!RegExp(
                                    r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return '올바른 이메일 형식을 입력해주세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  authViewModel.clearError();
                                  // validate는 호출하지 않음
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 58,
                              width: 120,
                              child: ElevatedButton(
                                onPressed:
                                    authViewModel.isLoading
                                        ? null
                                        : () async {
                                            final email = _emailController.text.trim();
                                            if (email.isEmpty) {
                                              CustomSnackBar.showError(context, '이메일을 입력해주세요');
                                              return;
                                            }
                                            final ok = await authViewModel.requestEmailCode(email);
                                            if (ok) {
                                              if (mounted) {
                                                CustomSnackBar.showSuccess(context, '인증 코드를 전송했습니다');
                                              }
                                            } else {
                                              if (mounted) {
                                                CustomSnackBar.showError(context, authViewModel.errorMessage ?? '인증 코드 전송 실패');
                                              }
                                            }
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : Text(
                                        authViewModel.isEmailCodeSent ? '재전송' : '인증코드 요청',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailCodeController,
                                keyboardType: TextInputType.number,
                                enabled: authViewModel.isEmailCodeSent && !authViewModel.isLoading,
                                decoration: InputDecoration(
                                  hintText: '인증코드를 입력하세요',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
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
                                  if (!authViewModel.isEmailCodeSent) return null;
                                  if (value == null || value.isEmpty) {
                                    return '인증 코드를 입력해주세요';
                                  }
                                  if (value.length != 6) {
                                    return '인증 코드는 6자리입니다';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  authViewModel.clearError();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 58,
                              width: 120,
                              child: ElevatedButton(
                                onPressed: (!authViewModel.isEmailCodeSent || authViewModel.isLoading)
                                    ? null
                                    : () async {
                                        final username = _idController.text.trim();
                                        final email = _emailController.text.trim();
                                        final code = _emailCodeController.text.trim();
                                        if (username.isEmpty) {
                                          CustomSnackBar.showError(context, '아이디를 입력해주세요');
                                          return;
                                        }
                                        if (code.length != 6) {
                                          CustomSnackBar.showError(context, '인증 코드는 6자리입니다');
                                          return;
                                        }
                                        final ok = await authViewModel.verifyEmailCode(username, email, code);
                                        if (ok) {
                                          if (mounted) {
                                            CustomSnackBar.showSuccess(context, '이메일 인증이 완료되었습니다');
                                          }
                                        } else {
                                          if (mounted) {
                                            CustomSnackBar.showError(context, authViewModel.errorMessage ?? '이메일 인증 실패');
                                          }
                                        }
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : const Text(
                                        '인증확인',
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
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: '비밀번호',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
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
                            if (value.length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }
                            if (authViewModel.errorMessage != null &&
                                authViewModel.errorMessage!.contains('비밀번호')) {
                              return authViewModel.errorMessage;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // validate는 호출하지 않음
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: '비밀번호 확인',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
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
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppTheme.textSecondaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호 확인을 입력해주세요';
                            }
                            if (value != _passwordController.text) {
                              return '비밀번호가 일치하지 않습니다';
                            }
                            if (authViewModel.errorMessage != null &&
                                authViewModel.errorMessage!.contains('비밀번호')) {
                              return authViewModel.errorMessage;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // validate는 호출하지 않음
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
                    onPressed: () async {
                      // 폼 검증 먼저 수행
                      if (!_formKey.currentState!.validate()) {
                        CustomSnackBar.showError(
                          context,
                          '입력 정보를 확인해주세요',
                        );
                        return;
                      }
                      
                      // 아이디 중복 확인이 완료되지 않은 경우
                      if (!authViewModel.isIdAvailable) {
                        CustomSnackBar.showError(
                          context,
                          '아이디 중복 확인을 완료해주세요',
                        );
                        return;
                      }
                      
                      final result = await authViewModel.signUp(
                        _idController.text.trim(),
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        _confirmPasswordController.text.trim(),
                      );
                      if (result && context.mounted) {
                        context.go('/login');
                      } else if (authViewModel.errorMessage != null &&
                          context.mounted) {
                        CustomSnackBar.showError(
                          context,
                          authViewModel.errorMessage!,
                        );
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
