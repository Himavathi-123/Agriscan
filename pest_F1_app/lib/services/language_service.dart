import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  static const String _firstRunKey = 'is_first_run';
  static const String _cropsKey = 'selected_crops';

  Locale _locale = const Locale('en');
  bool _isFirstRun = true;
  List<String> _selectedCrops = [];

  Locale get locale => _locale;
  bool get isFirstRun => _isFirstRun;
  List<String> get selectedCrops => _selectedCrops;

  LanguageService() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'en';
    _locale = Locale(localeCode);
    _isFirstRun = prefs.getBool(_firstRunKey) ?? true;
    _selectedCrops = prefs.getStringList(_cropsKey) ?? [];
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    notifyListeners();
  }

  Future<void> setFirstRunComplete() async {
    _isFirstRun = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, false);
    notifyListeners();
  }

  Future<void> setSelectedCrops(List<String> crops) async {
    _selectedCrops = crops;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cropsKey, crops);
    notifyListeners();
  }
}
