import 'package:flutter/material.dart';

class AppColors {
  // 메인 테마 색상
  static const Color primary = Color(0xFF81ECE1); // 메인 컬러
  static const Color background = Color(0xFF4C6EF5); // 배경 컬러
  static const Color surface = Color(0xFFFFFFFF); // 표면 컬러

  // 텍스트 관련
  static const Color text = Color(0xFFFFFFFF); // 기본 텍스트 컬러
  static const Color textSecondary = Color(0xFF757575); // 두번째 텍스트 컬러

  // 기능성 컬러 (정확한 8자리)
  static const Color pointGreen = Color(0xFF58D68D); // 처음페이지 컬러
  static const Color pointBlue = Color(0xFF4C6EF5); // 퀴즈게임 컬러
  static const Color importantYellow = Color.fromARGB(
    255,
    238,
    197,
    63,
  ); // 단어장 컬러
  static const Color warningRed = Color(0xFFFF5C5C); // 설정 페이지 컬러
  static const Color widgetAlert = Color(0xFF1976D2); //위젯 알림
}

class AppTheme {
  static Color get widgetAlert => AppColors.widgetAlert; //위젯 알림
  static Color get primary => AppColors.primary; // 메인 컬러
  static Color get background => AppColors.background; // 배경 컬러
  static Color get surface => AppColors.surface; // 표면 컬러

  // 텍스트 관련
  static Color get text => AppColors.text; // 기본 텍스트 컬러
  static Color get textSecondary => AppColors.textSecondary; // 두번째 텍스트 컬러

  // 기능성 컬러 (정확한 8자리)
  static Color get pointGreen => AppColors.pointGreen; // 처음페이지 컬러
  static Color get pointBlue => AppColors.pointBlue; // 퀴즈게임 컬러
  static Color get importantYellow => AppColors.importantYellow; // 단어장 컬러
  static Color get warningRed => AppColors.warningRed; // 설정 페이지 컬러

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Pretendard',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Pretendard',
    );
  }
}
