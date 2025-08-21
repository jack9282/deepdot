import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF799EFF); // 보라색 계열
  static const Color primaryColorBright = Color(0xFF1F5DFF); // 보라색 계열
  static const Color secondaryColor = Color(0xFF4CAF50); // 초록색 계열
  static const Color backgroundColor = Color(0xFFF8F9FB);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF2D3748);
  static const Color textSecondaryColor = Color(0xFF718096);
  static const Color borderColor = Color(0xFFE2E8F0);
  
  static const Color greyPrimaryColor = Color(0xFF979797);
  static const Color textBlackColor = Color(0xFF27292B);
  static const Color textGreyColor = Color(0xFFB4B5B6);
  static const Color iconGreyColor = Color(0xFFD6D8D9);
  static const Color darkColor = Color(0xFF2D3748);
  static const Color buttonColor = Color(0xFF6C63FF);
  
  static const Color urgentImportantColor = Color(0xFFE53E3E); // 빨간색 - 지금 바로 해야해요
  static const Color importantColor = Color(0xFF3182CE); // 파란색 - 미리 계획해서 준비해요
  static const Color urgentColor = Color(0xFFD69E2E); // 노란색 - 나중에 처리해요
  static const Color neitherColor = Color(0xFF74787B); // 회색 - 시간이 남을 때 해요

  static const List<Color> checkListColor = [
    Color(0xFF3A71FF), // 파란색
    Color(0xFFFFBC4C), // 주황색
    Color(0xFFFF4C4C), // 빨간색
    Color(0xFF4CAF50), // 초록색
    Color(0xFF9C27B0), // 보라색
  ];

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