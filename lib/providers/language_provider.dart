import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  late String _language;

  LanguageProvider(String defaultLanguage) {
    _language = defaultLanguage;
  }

  String get language => _language;

  Future<void> setLanguage(String lang) async {
    _language = lang;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }
}
