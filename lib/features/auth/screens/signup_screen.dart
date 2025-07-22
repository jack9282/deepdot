import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';

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

  bool _isLoadingIdCheck = false;
  bool _isIdAvailable = false;

  bool _isLoadingEmailRequest = false;
  bool _isEmailCodeSent = false;
  bool _isLoadingEmailVerify = false;
  bool _isEmailVerified = false;

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  // 아이디 중복 확인 로직
  void _checkIdDuplication() async {
    if (_idController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디를 입력해주세요.')));
      return;
    }

    setState(() {
      _isLoadingIdCheck = true;
      _isIdAvailable = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoadingIdCheck = false;
      _isIdAvailable = true; // Mock: Always available
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('사용 가능한 아이디입니다.')));
  }

  // 이메일 인증 코드 요청 로직
  void _requestEmailCode() async {
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요.')));
      return;
    }

    setState(() {
      _isLoadingEmailRequest = true;
      _isEmailCodeSent = false;
      _isEmailVerified = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoadingEmailRequest = false;
      _isEmailCodeSent = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('인증 코드가 전송되었습니다.')));
  }

  // 이메일 인증 코드 확인 로직
  void _verifyEmailCode() async {
    if (_emailCodeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증 코드를 입력해주세요.')));
      return;
    }

    setState(() {
      _isLoadingEmailVerify = true;
      _isEmailVerified = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoadingEmailVerify = false;
      _isEmailVerified = true; // Mock: Always verified
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이메일 인증이 완료되었습니다.')));
  }

  // 최종 회원가입 처리 로직
  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필수 정보를 올바르게 입력해주세요.')));
      return;
    }

    if (!_isIdAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디 중복 확인을 완료해주세요.')));
      return;
    }

    if (!_isEmailVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 인증을 완료해주세요.')));
      return;
    }

    // TODO: Implement actual signup API call here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입이 진행 중입니다...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    await Future.delayed(const Duration(seconds: 2)); // Simulate signup process

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입이 완료되었습니다!'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );

    // Navigate to login screen on successful signup
    context.go('/login');
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
                        const SizedBox(height: 60),
                        Center(
                          child: Text(
                            'Sign Up',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ID 입력 섹션
                        const Text(
                          'ID',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
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
                                  hintText: '아이디를 입력하세요',
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      topRight: Radius.zero,
                                      bottomRight: Radius.zero,
                                    ),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      topRight: Radius.zero,
                                      bottomRight: Radius.zero,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '아이디를 입력해주세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isIdAvailable = false;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 58,
                              width: 80,
                              child: ElevatedButton(
                                onPressed: _isLoadingIdCheck || _isIdAvailable
                                    ? null
                                    : _checkIdDuplication,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isIdAvailable
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                  foregroundColor: _isIdAvailable
                                      ? Colors.white
                                      : Colors.black,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.zero,
                                      bottomLeft: Radius.zero,
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: _isLoadingIdCheck
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
                                        _isIdAvailable ? '확인 완료' : '중복확인',
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Email 입력 섹션
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
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
                                decoration: const InputDecoration(
                                  hintText: '이메일을 입력하세요',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      topRight: Radius.zero,
                                      bottomRight: Radius.zero,
                                    ),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                      topRight: Radius.zero,
                                      bottomRight: Radius.zero,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이메일을 입력해주세요';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return '올바른 이메일 형식을 입력해주세요';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isEmailCodeSent = false;
                                    _isEmailVerified = false;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 58,
                              width: 80,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoadingEmailRequest || _isEmailCodeSent
                                    ? null
                                    : _requestEmailCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isEmailCodeSent
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                  foregroundColor: _isEmailCodeSent
                                      ? Colors.white
                                      : Colors.black,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.zero,
                                      bottomLeft: Radius.zero,
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: _isLoadingEmailRequest
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
                                        _isEmailCodeSent ? '전송 완료' : '인증코드 요청',
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        // 이메일 인증 코드 입력 섹션 (코드 전송 후 표시)
                        if (_isEmailCodeSent) ...[
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCodeController,
                                  keyboardType: TextInputType.number,
                                  enabled:
                                      _isEmailCodeSent && !_isEmailVerified,
                                  decoration: const InputDecoration(
                                    hintText: '인증코드를 입력하세요',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                        topRight: Radius.zero,
                                        bottomRight: Radius.zero,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                        topRight: Radius.zero,
                                        bottomRight: Radius.zero,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '인증 코드를 입력해주세요';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isEmailVerified = false;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 58,
                                width: 80,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoadingEmailVerify || _isEmailVerified
                                      ? null
                                      : _verifyEmailCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEmailVerified
                                        ? AppTheme.primaryColor
                                        : Colors.white,
                                    foregroundColor: _isEmailVerified
                                        ? Colors.white
                                        : Colors.black,
                                    shape: const RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.zero,
                                        bottomLeft: Radius.zero,
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoadingEmailVerify
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
                                          _isEmailVerified ? '인증 완료' : '인증 확인',
                                          overflow: TextOverflow.visible,
                                          softWrap: false,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Password 입력 섹션
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          enabled: _isEmailVerified, // 이메일 인증 완료 시에만 활성화
                          decoration: InputDecoration(
                            hintText: '비밀번호를 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
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
                            if (!_isEmailVerified)
                              return null; // 이메일 인증 전에는 유효성 검사 안함
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            if (value.length < 6) {
                              return '비밀번호는 6자 이상이어야 합니다';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // 비밀번호 변경 시 폼 유효성 재평가
                            setState(() {
                              _formKey.currentState?.validate();
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Confirm Password 입력 섹션
                        const Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          enabled: _isEmailVerified, // 이메일 인증 완료 시에만 활성화
                          decoration: InputDecoration(
                            hintText: '비밀번호를 다시 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
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
                            if (!_isEmailVerified)
                              return null; // 이메일 인증 전에는 유효성 검사 안함
                            if (value == null || value.isEmpty) {
                              return '비밀번호 확인을 입력해주세요';
                            }
                            if (value != _passwordController.text) {
                              return '비밀번호가 일치하지 않습니다';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // 비밀번호 확인 변경 시 폼 유효성 재평가
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
                    // 모든 조건 충족 시에만 버튼 활성화
                    onPressed:
                        (_isIdAvailable &&
                            _isEmailVerified &&
                            _formKey.currentState?.validate() == true)
                        ? _handleSignup
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
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
