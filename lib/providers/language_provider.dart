import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _language;
  bool _isLanguageSelected = false;

  LanguageProvider(this._language) {
    _isLanguageSelected = true;
  }

  String get language => _language;
  bool get isLanguageSelected => _isLanguageSelected;

  Future<void> setLanguage(String newLanguage) async {
    _language = newLanguage;
    _isLanguageSelected = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguage);
    notifyListeners();
  }
}
