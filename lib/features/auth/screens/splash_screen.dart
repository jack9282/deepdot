import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../view_models/auth_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // 2초 후 자동 로그인 확인 후 적절한 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        final authViewModel = Provider.of<AuthViewModel>(
          context,
          listen: false,
        );
        final isAutoLoggedIn = await authViewModel.checkAutoLogin();

        if (isAutoLoggedIn) {
          // 자동 로그인 성공 시 메인 화면으로 이동
          context.go('/home');
        } else {
          // 자동 로그인 실패 시 온보딩 화면으로 이동
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SvgPicture.asset(
            'assets/svg/logo.svg',
            width: 200,
            semanticsLabel: 'DeepDot Logo',
          ),
        ),
      ),
    );
  }
}
