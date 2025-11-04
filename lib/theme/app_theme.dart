import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF7755FF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE6DEFF),
      onPrimaryContainer: Color(0xFF1F0062),
      secondary: Color(0xFF16E4D6),
      onSecondary: Color(0xFF00201E),
      secondaryContainer: Color(0xFF9AFFF3),
      onSecondaryContainer: Color(0xFF00201E),
      tertiary: Color(0xFFFF8DC9),
      onTertiary: Color(0xFF40001D),
      tertiaryContainer: Color(0xFFFFD9EA),
      onTertiaryContainer: Color(0xFF310014),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Colors.white,
      onSurface: Color(0xFF1D1830),
      surfaceContainerHighest: Color(0xFFE6E0F3),
      onSurfaceVariant: Color(0xFF474152),
      outline: Color(0xFF7A728E),
      outlineVariant: Color(0xFFD0CAE2),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2B253B),
      onInverseSurface: Color(0xFFF3EDFF),
      inversePrimary: Color(0xFFBEA5FF),
      surfaceTint: Color(0xFF7755FF),
    );

    return _baseTheme(colorScheme, Brightness.light);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFBEA5FF),
      onPrimary: Color(0xFF3A0099),
      primaryContainer: Color(0xFF5132D6),
      onPrimaryContainer: Color(0xFFE6DEFF),
      secondary: Color(0xFF64F6E6),
      onSecondary: Color(0xFF003733),
      secondaryContainer: Color(0xFF005048),
      onSecondaryContainer: Color(0xFF9AFFF3),
      tertiary: Color(0xFFFFB1DD),
      onTertiary: Color(0xFF560034),
      tertiaryContainer: Color(0xFF77004A),
      onTertiaryContainer: Color(0xFFFFD9EA),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF13172A),
      onSurface: Color(0xFFE2DEF5),
      surfaceContainerHighest: Color(0xFF3D3750),
      onSurfaceVariant: Color(0xFFCAC3DB),
      outline: Color(0xFF958DA7),
      outlineVariant: Color(0xFF3D3750),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE8E1FF),
      onInverseSurface: Color(0xFF120630),
      inversePrimary: Color(0xFF7755FF),
      surfaceTint: Color(0xFFBEA5FF),
    );

    return _baseTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        toolbarHeight: 70,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: Colors.white.withValues(
          alpha: brightness == Brightness.dark ? 0.04 : 0.55,
        ),
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.7),
            size: states.contains(WidgetState.selected) ? 28 : 24,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: scheme.primary,
        brightness: brightness,
        labelStyle: textTheme.labelLarge!,
      ).copyWith(
        backgroundColor: scheme.surface.withValues(alpha: 0.6),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface
            .withValues(alpha: brightness == Brightness.dark ? 0.52 : 0.72),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface.withValues(
          alpha: brightness == Brightness.dark ? 0.9 : 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface.withValues(alpha: 0.9),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface
            .withValues(alpha: brightness == Brightness.dark ? 0.9 : 0.85),
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
