import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final String key = 'theme';
  SharedPreferences? _prefs;
  bool _darkTheme = false;
  bool get dark => _darkTheme;

  ThemeProvider() {
    _darkTheme = false;
    _loadfromPrefs();
  }

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadfromPrefs() async {
    await _initPrefs();
    _darkTheme = _prefs!.getBool(key) ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    _prefs!.setBool(key, _darkTheme);
    notifyListeners();
  }
}
