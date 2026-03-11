import 'package:flutter/material.dart';

const kBgColor = Color(0xFF0A0E1A);
const kSurfaceColor = Color(0xFF141824);
const kCardColor = Color(0xFF1A2035);
const kProfitColor = Color(0xFF00FF88);
const kDangerColor = Color(0xFFFF4444);
const kWarningColor = Color(0xFFFFB800);
const kAccentColor = Color(0xFFF7A600);
const kBlueAccent = Color(0xFF2196F3);
const kTextPrimary = Color(0xFFFFFFFF);
const kTextSecondary = Color(0xFF8B92A5);
const kDividerColor = Color(0xFF1E2740);
const kBullColor = Color(0xFF00FF88);
const kBearColor = Color(0xFFFF4444);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBgColor,
  colorScheme: const ColorScheme.dark(
    surface: kSurfaceColor,
    primary: kProfitColor,
    secondary: kAccentColor,
    error: kDangerColor,
    onPrimary: kBgColor,
    onSecondary: kBgColor,
    onSurface: kTextPrimary,
  ),
  cardTheme: const CardThemeData(
    color: kCardColor,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBgColor,
    elevation: 0,
    iconTheme: IconThemeData(color: kTextPrimary),
    titleTextStyle: TextStyle(
      color: kTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kSurfaceColor,
    selectedItemColor: kProfitColor,
    unselectedItemColor: kTextSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: kTextPrimary),
    titleSmall: TextStyle(color: kTextSecondary),
    bodyLarge: TextStyle(color: kTextPrimary),
    bodyMedium: TextStyle(color: kTextSecondary),
    bodySmall: TextStyle(color: kTextSecondary, fontSize: 12),
    labelLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600),
  ),
  dividerTheme: const DividerThemeData(
    color: kDividerColor,
    thickness: 1,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kDividerColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kDividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kProfitColor, width: 2),
    ),
    hintStyle: const TextStyle(color: kTextSecondary),
    labelStyle: const TextStyle(color: kTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kProfitColor,
      foregroundColor: kBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return kProfitColor;
      return kTextSecondary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return kProfitColor.withValues(alpha: 0.3);
      }
      return kDividerColor;
    }),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: kSurfaceColor,
    selectedColor: kProfitColor.withValues(alpha: 0.2),
    labelStyle: const TextStyle(color: kTextPrimary),
    side: const BorderSide(color: kDividerColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);
