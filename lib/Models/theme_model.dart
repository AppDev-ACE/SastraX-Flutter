import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Neon colors for dark theme
  static const Color neonBlue = Color(0xFF00FFFF);
  static const Color electricBlue = Color(0xFF007FFF);
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1A1A1A);

  // Light theme colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color navyBlue = Color(0xFF1e3a8a);
  static const Color text = Color(0xffcf12e0);

  // Colours for credit page
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color accentAqua = Color(0xFF00BCD4);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53E3E);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color textDarkBlue = Color(0xFF2D3748);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, accentAqua],
  );

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyBlue, Color(0xFF303F9F)],
  );

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyBlue, Color(0xFFE0F6FF)],
  );

  // Text Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDarkBlue,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textDarkBlue,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textDarkBlue,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textDarkBlue,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textDarkBlue,
  );

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(25),
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(38),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  // SGPA Calculator
  static const Color accentBlue = Color(0xFF4A8BF7);
  static const Color buttonTextColor = Colors.white;

  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDarkBlue,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: buttonTextColor,
  );

  static const TextStyle resultTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textDarkBlue,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDarkBlue,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: neonBlue,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: neonBlue,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: neonBlue),
      ),
    );
  }
}

class AppColors {
  static const Color navyBlue = Color(0xFF1e3a8a);
  static const Color neonBlue = Color(0xFF00FFFF);
  static const Color skyBlue = Color(0xFF87CEEB);
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    loadTheme(); // Load saved preference on init
  }

  bool get isDarkMode => _isDarkMode;

  //added as getter
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  // Color getters for easy access
  Color get backgroundColor =>
      _isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground;
  Color get surfaceColor =>
      _isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;

  Color get primaryColor =>
      _isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue;

  /// ✅ Fixed here: use soft grey for cards in light mode
  Color get cardBackgroundColor =>
      _isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundLight;

  Color get appBarBackgroundColor =>
      _isDarkMode ? AppTheme.darkBackground : AppTheme.primaryBlue;

  Color get bottomNavBackgroundColor =>
      _isDarkMode ? AppTheme.darkSurface : Colors.white;

  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get textSecondaryColor =>
      _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get iconColor => _isDarkMode ? Colors.grey : Colors.grey[600]!;


  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}
