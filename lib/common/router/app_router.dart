import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/auth/screens/forgot_id_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/taking/screens/taking_list.dart';
import '../../features/home/screens/main_screen.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // 스플래시 화면
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 온보딩 화면
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 웰컴 화면
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // 회원가입 화면
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // 로그인 화면
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/forgot-id',
        builder: (context, state) => const ForgotIdScreen(),
      ),

      // 비밀번호 찾기 화면
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // 비밀번호 재설정 화면
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(),
      ),

      // 메인 홈 화면 (기존 홈)
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      // 메인 화면 (탭 네비게이션 포함)
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),

      // 복용 이력 리스트
      GoRoute(
        path: '/taking-list',
        builder: (context, state) => const TakingList(),
      ),
    ],
  );

  static GoRouter get router => _router;
}
