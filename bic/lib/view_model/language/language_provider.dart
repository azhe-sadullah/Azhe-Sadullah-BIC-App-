import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isKurdish = false;

  bool get isKurdish => _isKurdish;
  AppStrings get strings => AppStrings(_isKurdish);

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isKurdish = prefs.getBool('isKurdish') ?? false;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isKurdish = !_isKurdish;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKurdish', _isKurdish);
  }
}
