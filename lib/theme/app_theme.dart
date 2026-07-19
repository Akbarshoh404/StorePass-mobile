import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Enterprise SaaS Trust": indigo primary + violet secondary, Plus Jakarta
/// Sans, pill-shaped buttons, colored soft shadows, and floating-label
/// inputs. Deliberately not `ColorScheme.fromSeed` — colors are hand-picked
/// per tone so surfaces/outlines stay controlled rather than seed-derived.
class AppTheme {
  AppTheme._();

  static const _accentLight = Color(0xFF4F46E5);
  static const _accentDark = Color(0xFF818CF8);
  static const _secondaryLight = Color(0xFF7C3AED);
  static const _secondaryDark = Color(0xFFA78BFA);

  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _accentLight,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE7E5FB),
    onPrimaryContainer: _accentLight,
    secondary: _secondaryLight,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDE4FD),
    onSecondaryContainer: _secondaryLight,
    tertiary: _accentLight,
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFCE8E6),
    onErrorContainer: Color(0xFFEF4444),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF8FAFC),
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFFE2E8F0),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF27272A),
    onInverseSurface: Color(0xFFFAFAFA),
    inversePrimary: _accentDark,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _accentDark,
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF2E2A5C),
    onPrimaryContainer: _accentDark,
    secondary: _secondaryDark,
    onSecondary: Color(0xFF2E1065),
    secondaryContainer: Color(0xFF2E2A5C),
    onSecondaryContainer: _secondaryDark,
    tertiary: _accentDark,
    onTertiary: Color(0xFF1E1B4B),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF3A1414),
    onErrorContainer: Color(0xFFF87171),
    surface: Color(0xFF0B1120),
    onSurface: Color(0xFFF1F5F9),
    surfaceContainerLowest: Color(0xFF08080C),
    surfaceContainerLow: Color(0xFF131B2E),
    surfaceContainer: Color(0xFF131B2E),
    surfaceContainerHigh: Color(0xFF1B2540),
    surfaceContainerHighest: Color(0xFF1B2540),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF263047),
    outlineVariant: Color(0xFF263047),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF5F5F7),
    onInverseSurface: Color(0xFF18181B),
    inversePrimary: _accentLight,
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, brightness: scheme.brightness, colorScheme: scheme);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: scheme.onSurface),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: scheme.onSurface),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: scheme.onSurface),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: scheme.onSurface),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
    );

    final borderRadius = BorderRadius.circular(16);
    final hairline = BorderSide(color: scheme.outlineVariant, width: 1);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.primary.withValues(alpha: 0.18),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: borderRadius, side: hairline),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary.withValues(alpha: 0.1),
        disabledColor: scheme.surfaceContainer,
        labelStyle: textTheme.labelMedium,
        side: hairline,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 32),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.onSurface,
          foregroundColor: scheme.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.onSurface, textStyle: textTheme.labelLarge),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.error)),
        labelStyle: textTheme.bodyMedium,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: scheme.onSurface.withValues(alpha: 0.08),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.onSurface : scheme.surfaceContainerHighest,
        ),
        thumbColor: WidgetStatePropertyAll(scheme.surface),
        trackOutlineColor: WidgetStatePropertyAll(scheme.outline),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: hairline),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          selectedForegroundColor: scheme.onSurface,
          selectedBackgroundColor: scheme.surfaceContainer,
          side: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}

/// The single accent color, exposed for the handful of places that should
/// draw the eye — cashback amounts, wallet balances, active/primary states.
extension AppAccent on ColorScheme {
  Color get accent => primary;
}
