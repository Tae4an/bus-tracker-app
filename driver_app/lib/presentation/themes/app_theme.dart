// 앱 테마 및 스타일 정의
// 앱 전체에서 사용되는 색상, 글꼴, 스타일 등을 정의

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // 브랜드 색상
  static const primary = Color(0xFF1976D2);   // 메인 색상
  static const secondary = Color(0xFF03A9F4); // 보조 색상
  static const accent = Color(0xFF4CAF50);    // 강조 색상
  
  // 상태 색상
  static const success = Color(0xFF4CAF50);  // 성공
  static const warning = Color(0xFFFFC107);  // 경고
  static const error = Color(0xFFF44336);    // 오류
  static const info = Color(0xFF2196F3);     // 정보
  
  // 중립 색상
  static const background = Color(0xFFF5F5F5); // 배경
  static const surface = Color(0xFFFFFFFF);    // 표면
  static const cardBg = Color(0xFFFFFFFF);     // 카드 배경
  
  // 텍스트 색상
  static const textPrimary = Color(0xFF212121);    // 기본 텍스트
  static const textSecondary = Color(0xFF757575);  // 보조 텍스트
  static const textDisabled = Color(0xFFBDBDBD);   // 비활성화 텍스트
  
  // 테두리 색상
  static const border = Color(0xFFE0E0E0);
  static const divider = Color(0xFFE0E0E0);
  
  // 다크 모드 색상
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCardBg = Color(0xFF2C2C2C);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB0B0B0);
}

class AppTheme {
  // 라이트 테마
  static final ThemeData lightTheme = ThemeData(
    // 기본 색상 설정
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
    ),
    
    // 밝은 테마 시스템 오버레이 설정
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    
    // 카드 테마
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),
    
    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // 기타 설정
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Pretendard',
    useMaterial3: true,
  );

  // 다크 테마
  static final ThemeData darkTheme = ThemeData(
    // 다크 모드 색상 설정
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      error: AppColors.error,
    ),
    
    // 다크 테마 시스템 오버레이 설정
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.darkSurface,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    
    // 카드 테마
    cardTheme: CardTheme(
      color: AppColors.darkCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),
    
    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // 기타 설정
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: 'Pretendard',
    useMaterial3: true,
  );
}