import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // メインカラーパレット
  static const Color primaryColor = Colors.black; // 黒
  static const Color accentColor = Colors.grey; // グレー
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // テキストカラー
  static const Color textPrimaryColor = Color(0xFF2C3E50);
  static const Color textSecondaryColor = Color(0xFF7F8C8D);
  
  // カテゴリカラー
  static const Map<String, Color> categoryColors = {
    'トップス': Colors.grey,
    'ボトムス': Colors.grey,
    'アウター': Colors.grey,
    'シューズ': Colors.grey,
    'アクセサリー': Colors.grey,
  };
  
  // カテゴリアイコン
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'トップス':
        return Icons.accessibility_new;
      case 'ボトムス':
        return Icons.airline_seat_legroom_normal;
      case 'アウター':
        return Icons.layers;
      case 'シューズ':
        return Icons.directions_walk;
      case 'アクセサリー':
        return Icons.watch;
      default:
        return Icons.checkroom;
    }
  }
  
  // カテゴリカラーの取得
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? primaryColor;
  }
  
  /// 季節カラーの取得
  static Color getSeasonColor(String season) {
    switch (season) {
      case '春':
        return const Color(0xFF81C784); // 春: グリーン
      case '夏':
        return const Color(0xFF4FC3F7); // 夏: ライトブルー
      case '秋':
        return const Color(0xFFFFB74D); // 秋: オレンジ
      case '冬':
        return const Color(0xFF90A4AE); // 冬: ブルーグレー
      default:
        return primaryColor;
    }
  }
  
  // テキストテーマ
  static TextTheme getTextTheme() {
    return GoogleFonts.notoSansJpTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondaryColor,
        ),
      ),
    );
  }
  
  // アプリテーマ
  static ThemeData getTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        disabledColor: Colors.grey[300],
        selectedColor: primaryColor,
        secondarySelectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        labelStyle: const TextStyle(color: textPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: getTextTheme(),
      useMaterial3: true,
    );
  }
  
  // 天気アイコン
  static IconData getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'sunny':
      case '晴れ':
        return Icons.wb_sunny;
      case 'cloudy':
      case '曇り':
        return Icons.cloud;
      case 'rainy':
      case '雨':
        return Icons.water_drop;
      case 'snowy':
      case '雪':
        return Icons.ac_unit;
      case 'stormy':
      case '嵐':
        return Icons.thunderstorm;
      default:
        return Icons.wb_sunny;
    }
  }
  
  // 季節アイコン
  static IconData getSeasonIcon(String season) {
    switch (season.toLowerCase()) {
      case 'spring':
      case '春':
        return Icons.local_florist;
      case 'summer':
      case '夏':
        return Icons.wb_sunny;
      case 'autumn':
      case 'fall':
      case '秋':
        return Icons.eco;
      case 'winter':
      case '冬':
        return Icons.ac_unit;
      default:
        return Icons.calendar_today;
    }
  }
  
  // アニメーション時間
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 500);
  
  // ページトランジション
  static PageRouteBuilder<T> pageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: pageTransitionDuration,
    );
  }
}
