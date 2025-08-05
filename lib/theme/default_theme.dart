import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Color schemes - Black and White Theme
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);

  // Light Theme (White background, Black text)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme - Black and White
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlack,
        brightness: Brightness.light,
        primary: primaryBlack,
        secondary: greyDark,
        surface: surfaceLight,
        onPrimary: primaryWhite,
        onSecondary: primaryWhite,
        onSurface: primaryBlack,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: primaryWhite,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryBlack,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: primaryBlack,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceLight,
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: primaryBlack,
          foregroundColor: primaryWhite,
          disabledBackgroundColor: greyMedium,
          disabledForegroundColor: primaryWhite,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: greyMedium),
          backgroundColor: primaryWhite,
          foregroundColor: greyDark,
          disabledBackgroundColor: greyLight,
          disabledForegroundColor: greyMedium,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: greyDark,
          disabledForegroundColor: greyMedium,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: greyLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyDark, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyDark, width: 2),
        ),
        labelStyle: TextStyle(
          color: greyMedium,
          fontSize: 16,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryBlack,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: greyMedium,
          fontSize: 16,
        ),
        errorStyle: const TextStyle(
          color: greyDark,
          fontSize: 12,
        ),
        iconColor: greyMedium,
        prefixIconColor: greyMedium,
        suffixIconColor: greyMedium,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryBlack,
        unselectedItemColor: greyMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryBlack,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryBlack,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryBlack,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryBlack,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: greyMedium,
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: greyDark,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: greyMedium,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: greyLight,
        deleteIconColor: greyMedium,
        disabledColor: greyLight,
        selectedColor: primaryBlack,
        secondarySelectedColor: greyDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          color: primaryBlack,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primaryWhite,
          fontSize: 14,
        ),
        brightness: Brightness.light,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlack,
        foregroundColor: primaryWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceLight,
        titleTextStyle: TextStyle(
          color: primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: primaryBlack,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        modalBackgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryBlack,
        contentTextStyle: TextStyle(
          color: primaryWhite,
          fontSize: 14,
        ),
        actionTextColor: greyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlack;
          }
          return greyMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return greyMedium;
          }
          return greyLight;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlack;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(primaryWhite),
        side: BorderSide(color: greyMedium, width: 2),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlack;
          }
          return greyMedium;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlack,
        linearTrackColor: greyLight,
        circularTrackColor: greyLight,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlack,
        inactiveTrackColor: greyLight,
        thumbColor: primaryBlack,
        overlayColor: primaryBlack.withOpacity(0.2),
        valueIndicatorColor: primaryBlack,
        valueIndicatorTextStyle: const TextStyle(
          color: primaryWhite,
          fontSize: 14,
        ),
      ),
    );
  }

  // Dark Theme (Black background, White text)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme - Dark Theme (White on Black)
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryWhite,
        brightness: Brightness.dark,
        primary: primaryWhite,
        secondary: greyMedium,
        surface: surfaceDark,
        onPrimary: primaryBlack,
        onSecondary: primaryBlack,
        onSurface: primaryWhite,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: backgroundDark,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryWhite,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: primaryWhite,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceDark,
        shadowColor: Colors.black.withOpacity(0.3),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: primaryWhite,
          foregroundColor: primaryBlack,
          disabledBackgroundColor: greyDark,
          disabledForegroundColor: greyMedium,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: greyMedium),
          backgroundColor: surfaceDark,
          foregroundColor: primaryWhite,
          disabledBackgroundColor: greyDark,
          disabledForegroundColor: greyMedium,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: greyMedium,
          disabledForegroundColor: greyDark,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: greyDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryWhite, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyMedium, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyMedium, width: 2),
        ),
        labelStyle: TextStyle(
          color: greyMedium,
          fontSize: 16,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryWhite,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: greyMedium,
          fontSize: 16,
        ),
        errorStyle: const TextStyle(
          color: greyMedium,
          fontSize: 12,
        ),
        iconColor: greyMedium,
        prefixIconColor: greyMedium,
        suffixIconColor: greyMedium,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryWhite,
        unselectedItemColor: greyMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryWhite,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryWhite,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryWhite,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: greyMedium,
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: greyMedium,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: greyMedium,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: greyDark,
        deleteIconColor: greyMedium,
        disabledColor: greyDark,
        selectedColor: primaryWhite,
        secondarySelectedColor: greyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          color: primaryWhite,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primaryBlack,
          fontSize: 14,
        ),
        brightness: Brightness.dark,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryWhite,
        foregroundColor: primaryBlack,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceDark,
        titleTextStyle: TextStyle(
          color: primaryWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: primaryWhite,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryWhite,
        contentTextStyle: const TextStyle(
          color: primaryBlack,
          fontSize: 14,
        ),
        actionTextColor: greyDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryWhite;
          }
          return greyMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return greyMedium;
          }
          return greyDark;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryWhite;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(primaryBlack),
        side: BorderSide(color: greyMedium, width: 2),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryWhite;
          }
          return greyMedium;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryWhite,
        linearTrackColor: greyDark,
        circularTrackColor: greyDark,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryWhite,
        inactiveTrackColor: greyDark,
        thumbColor: primaryWhite,
        overlayColor: primaryWhite.withOpacity(0.2),
        valueIndicatorColor: primaryWhite,
        valueIndicatorTextStyle: const TextStyle(
          color: primaryBlack,
          fontSize: 14,
        ),
      ),
    );
  }

  // Custom gradient colors - Black and White Theme
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlack, greyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [greyMedium, primaryBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voiceGradient = LinearGradient(
    colors: [greyDark, primaryBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [primaryBlack, greyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Reverse gradients for dark theme
  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [primaryWhite, greyMedium],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voiceGradientDark = LinearGradient(
    colors: [greyMedium, primaryWhite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Custom shadows
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> get buttonShadow {
    return [
      BoxShadow(
        color: primaryBlack.withOpacity(0.3),
        spreadRadius: 0,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> get elevatedShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        spreadRadius: 1,
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> get darkShadow {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        spreadRadius: 0,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration extraLongAnimation = Duration(milliseconds: 800);

  // Border radius values
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  static const double circularRadius = 50.0;

  // Spacing values
  static const double tinySpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  static const double massiveSpacing = 48.0;

  // Icon sizes
  static const double smallIcon = 16.0;
  static const double mediumIcon = 24.0;
  static const double largeIcon = 32.0;
  static const double extraLargeIcon = 48.0;

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // App-specific colors - Black and White Theme
  static const Color successColor = Color(0xFF424242);
  static const Color warningColor = Color(0xFF757575);
  static const Color errorColor = Color(0xFF424242);
  static const Color infoColor = Color(0xFF000000);

  // Voice Assistant specific colors
  static const Color voiceActiveColor = Color(0xFF424242);
  static const Color voiceInactiveColor = Color(0xFF000000);
  static const Color microphoneColor = Color(0xFFFFFFFF);

  // Helper methods for responsive design
  static double getResponsiveSpacing(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return desktop;
    if (screenWidth > 600) return tablet;
    return mobile;
  }

  static double getResponsiveFontSize(BuildContext context, {
    double mobile = 16.0,
    double tablet = 18.0,
    double desktop = 20.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return desktop;
    if (screenWidth > 600) return tablet;
    return mobile;
  }

  // Theme helper method
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Get appropriate gradient based on theme
  static LinearGradient getPrimaryGradient(BuildContext context) {
    return isDarkMode(context) ? primaryGradientDark : primaryGradient;
  }

  static LinearGradient getVoiceGradient(BuildContext context) {
    return isDarkMode(context) ? voiceGradientDark : voiceGradient;
  }

  // Get appropriate shadow based on theme
  static List<BoxShadow> getCardShadow(BuildContext context) {
    return isDarkMode(context) ? darkShadow : cardShadow;
  }

  // Custom text styles - Black and White Theme
  static TextStyle get logoTextStyle => const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: primaryBlack,
  );

  static TextStyle get logoTextStyleDark => const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: primaryWhite,
  );

  static TextStyle getLogoTextStyle(BuildContext context) {
    return isDarkMode(context) ? logoTextStyleDark : logoTextStyle;
  }

  static TextStyle get subtitleTextStyle => TextStyle(
    fontSize: 16,
    color: greyMedium,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle get cardSubtitleStyle => TextStyle(
    fontSize: 14,
    color: greyMedium,
    height: 1.4,
  );

  // Input field text styles
  static TextStyle get inputTextStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryBlack,
  );

  static TextStyle get inputTextStyleDark => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryWhite,
  );

  static TextStyle getInputTextStyle(BuildContext context) {
    return isDarkMode(context) ? inputTextStyleDark : inputTextStyle;
  }

  // Error text styles
  static TextStyle get errorTextStyle => TextStyle(
    fontSize: 12,
    color: greyDark,
    fontWeight: FontWeight.w500,
  );

  // Link text styles
  static TextStyle get linkTextStyle => const TextStyle(
    fontSize: 14,
    color: primaryBlack,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
  );

  static TextStyle get linkTextStyleDark => const TextStyle(
    fontSize: 14,
    color: primaryWhite,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
  );

  static TextStyle getLinkTextStyle(BuildContext context) {
    return isDarkMode(context) ? linkTextStyleDark : linkTextStyle;
  }

  // Caption text styles
  static TextStyle get captionTextStyle => TextStyle(
    fontSize: 12,
    color: greyMedium,
    fontWeight: FontWeight.w400,
  );

  // Voice assistant specific styles
  static TextStyle get voiceActiveTextStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryBlack,
  );

  static TextStyle get voiceActiveTextStyleDark => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryWhite,
  );

  static TextStyle getVoiceActiveTextStyle(BuildContext context) {
    return isDarkMode(context) ? voiceActiveTextStyleDark : voiceActiveTextStyle;
  }

  // App bar title styles
  static TextStyle get appBarTitleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryBlack,
  );

  static TextStyle get appBarTitleStyleDark => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryWhite,
  );

  static TextStyle getAppBarTitleStyle(BuildContext context) {
    return isDarkMode(context) ? appBarTitleStyleDark : appBarTitleStyle;
  }

  // Custom decorations
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: surfaceLight,
    borderRadius: BorderRadius.circular(mediumRadius),
    boxShadow: cardShadow,
  );

  static BoxDecoration get containerDecorationDark => BoxDecoration(
    color: surfaceDark,
    borderRadius: BorderRadius.circular(mediumRadius),
    boxShadow: darkShadow,
  );

  static BoxDecoration getContainerDecoration(BuildContext context) {
    return isDarkMode(context) ? containerDecorationDark : containerDecoration;
  }

  // Logo container decoration
  static BoxDecoration get logoContainerDecoration => BoxDecoration(
    color: primaryBlack,
    borderRadius: BorderRadius.circular(circularRadius),
    boxShadow: cardShadow,
  );

  static BoxDecoration get logoContainerDecorationDark => BoxDecoration(
    color: primaryWhite,
    borderRadius: BorderRadius.circular(circularRadius),
    boxShadow: darkShadow,
  );

  static BoxDecoration getLogoContainerDecoration(BuildContext context) {
    return isDarkMode(context) ? logoContainerDecorationDark : logoContainerDecoration;
  }

  // Voice button decoration
  static BoxDecoration get voiceButtonDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(circularRadius),
    boxShadow: buttonShadow,
  );

  static BoxDecoration get voiceButtonDecorationDark => BoxDecoration(
    gradient: primaryGradientDark,
    borderRadius: BorderRadius.circular(circularRadius),
    boxShadow: darkShadow,
  );

  static BoxDecoration getVoiceButtonDecoration(BuildContext context) {
    return isDarkMode(context) ? voiceButtonDecorationDark : voiceButtonDecoration;
  }

  // Border decorations
  static BoxDecoration get borderDecoration => BoxDecoration(
    border: Border.all(color: greyMedium, width: 1),
    borderRadius: BorderRadius.circular(mediumRadius),
  );

  // Input field decorations
  static InputDecoration getInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
    );
  }

  // Button styles helpers
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode(context) ? primaryWhite : primaryBlack,
      foregroundColor: isDarkMode(context) ? primaryBlack : primaryWhite,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: isDarkMode(context) ? primaryWhite : primaryBlack,
      side: BorderSide(
        color: isDarkMode(context) ? greyMedium : greyMedium,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
    );
  }

  // Color getters based on theme
  static Color getPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? primaryWhite : primaryBlack;
  }

  static Color getSecondaryColor(BuildContext context) {
    return greyMedium;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? backgroundDark : primaryWhite;
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surfaceLight;
  }

  static Color getTextColor(BuildContext context) {
    return isDarkMode(context) ? primaryWhite : primaryBlack;
  }

  static Color getSubtitleColor(BuildContext context) {
    return greyMedium;
  }

  // Icon colors
  static Color getIconColor(BuildContext context) {
    return isDarkMode(context) ? greyMedium : greyDark;
  }

  // Divider colors
  static Color getDividerColor(BuildContext context) {
    return greyMedium;
  }

  // Voice assistant colors
  static Color getVoiceActiveColor(BuildContext context) {
    return isDarkMode(context) ? primaryWhite : primaryBlack;
  }

  static Color getVoiceInactiveColor(BuildContext context) {
    return greyMedium;
  }

  // Utility methods for common UI patterns
  static Widget buildGradientContainer({
    required Widget child,
    required BuildContext context,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: getPrimaryGradient(context),
        borderRadius: BorderRadius.circular(mediumRadius),
        boxShadow: getCardShadow(context),
      ),
      child: child,
    );
  }

  static Widget buildThemedCard({
    required Widget child,
    required BuildContext context,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? elevation,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(largeSpacing),
      margin: margin,
      decoration: BoxDecoration(
        color: getSurfaceColor(context),
        borderRadius: BorderRadius.circular(largeRadius),
        boxShadow: getCardShadow(context),
      ),
      child: child,
    );
  }

  // Animation curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve slowCurve = Curves.easeIn;

  // Page transitions
  static PageRouteBuilder<T> createPageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = defaultCurve;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: mediumAnimation,
    );
  }

  // Fade transition
  static PageRouteBuilder<T> createFadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: mediumAnimation,
    );
  }

  // Scale transition
  static PageRouteBuilder<T> createScaleRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: defaultCurve,
          )),
          child: child,
        );
      },
      transitionDuration: mediumAnimation,
    );
  }
}