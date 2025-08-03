import 'package:flutter/material.dart';

class AppTheme {
  // 메인 색상들
  static const Color primaryColor = Color(0xFF6C63FF); // 보라색 계열
  static const Color secondaryColor = Color(0xFF4CAF50); // 초록색 계열
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF2D3748);
  static const Color textSecondaryColor = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE2E8F0);
  
  // 아이젠하워 매트릭스 색상
  static const Color urgentImportantColor = Color(0xFFE53E3E); // 빨간색
  static const Color importantColor = Color(0xFFD69E2E); // 노란색
  static const Color urgentColor = Color(0xFF3182CE); // 파란색
  static const Color neitherColor = Color(0xFF38A169); // 초록색

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // Pretendard 폰트를 기본 폰트로 설정
      fontFamily: 'Pretendard',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        // Headline (32px, 24px)
        headlineLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        // Title (20px)
        titleLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        // Body (18px, 16px, 14px)
        bodyLarge: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
} 