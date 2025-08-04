import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../view_models/auth_view_model.dart';

class EmailVerifyWidget extends StatefulWidget {
  final ValueChanged<String> onVerificationSuccess;

  const EmailVerifyWidget({super.key, required this.onVerificationSuccess});

  @override
  State<EmailVerifyWidget> createState() => _EmailVerifyWidgetState();
}

class _EmailVerifyWidgetState extends State<EmailVerifyWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCodeSent = false;
  int _remainingTime = 300; // 5분 (300초)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'example@gmail.com'; // 예시 이메일
    _codeController.text = '749583'; // 예시 인증 코드
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Builder(
            builder: (context) {
              final authViewModel = Provider.of<AuthViewModel>(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimaryColor,
                      ),
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
                              borderSide: BorderSide(color: Colors.grey[300]!),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          onPressed: authViewModel.isLoading || _isCodeSent
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요')),
                                    );
                                    return;
                                  }
                                  final result = await authViewModel.requestEmailCode(_emailController.text.trim());
                                  if (result && context.mounted) {
                                    setState(() {
                                      _isCodeSent = true;
                                      _remainingTime = 300;
                                    });
                                    _startTimer();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('인증 코드가 전송되었습니다.')),
                                    );
                                  } else if (authViewModel.errorMessage != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(authViewModel.errorMessage!)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: authViewModel.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '인증코드 요청',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCodeSent) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${_emailController.text}으로 인증코드를 발송했습니다.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '인증코드를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_codeController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _codeController.clear();
                                setState(() {});
                              },
                            ),
                          if (_isCodeSent && _remainingTime > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                _formatTime(_remainingTime),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '인증코드를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const Spacer(),
                  if (_codeController.text.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authViewModel.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                final result = await authViewModel.verifyEmailCode(_codeController.text.trim());
                                if (result && context.mounted) {
                                  final String retrievedId = 'user12345'; // 실제로는 서버에서 받아온 ID 사용
                                  widget.onVerificationSuccess(retrievedId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('인증이 완료되었습니다. 다음 화면으로 이동합니다.')),
                                  );
                                } else if (authViewModel.errorMessage != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(authViewModel.errorMessage!)),
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
                        child: authViewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '인증완료',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
} 