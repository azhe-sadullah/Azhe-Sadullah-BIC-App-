import 'package:flutter/material.dart';

class Constants {
  static String appName = "BIC";

  static const Color skyBlue    = Color(0xFF29B6F6);
  static const Color skyBlueDark= Color(0xFF0288D1);
  static const Color brandGreen = Color(0xFF4CAF50);
  static const Color brandGreenDark = Color(0xFF388E3C);

  static Color lightPrimary = const Color(0xFFF5F5F5);
  static Color darkPrimary  = const Color(0xFF0A0A0A);
  static Color lightAccent  = skyBlue;
  static Color darkAccent   = skyBlue;
  static Color lightBG      = const Color(0xFFF5F5F5);
  static Color darkBG       = const Color(0xFF0A0A0A);
  static Color darkSecondary= const Color(0xFF1A1A1A);

  static Color tealLight = const Color(0xFF98D1C2);
  static Color tealDark  = const Color(0xFF459BA8);

  static Color customerPrimary = const Color(0xFF66BB6A);
  static Color customerLight = const Color(0xFFDCEDC8);
  static Color customerBackground = const Color(0xFFF1F8E9);
  static Color customerAccent = const Color(0xFF2E7D32);

  static Color sailorPrimary = const Color(0xFF1565C0);
  static Color sailorDark = const Color(0xFF0D47A1);
  static Color sailorBackground = const Color(0xFFECEFF1);
  static Color sailorCard = const Color(0xFFFFFFFF);

  static ThemeData lightTheme = ThemeData(
    canvasColor: lightBG,
    primaryColor: lightPrimary,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: lightAccent,
    ),
    scaffoldBackgroundColor: lightBG,
    bottomAppBarTheme: BottomAppBarThemeData(
      elevation: 0,
      color: lightBG,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0.0,
      backgroundColor: lightBG,
      iconTheme: const IconThemeData(color: Colors.black),
      toolbarTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
      ),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: lightAccent,
      surface: lightBG,
    ),
  );

  static List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }
}