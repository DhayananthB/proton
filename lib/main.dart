import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/language_provider.dart';
import 'screens/chat_bot.dart';
import 'screens/language_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? language = prefs.getString('language') ?? 'en';

  runApp(MyApp(language: language));
}

class MyApp extends StatelessWidget {
  final String language;
  const MyApp({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(language),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ChatBot App',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: languageProvider.isLanguageSelected
                ? const ChatBotPage()
                : const LanguageSelectionPage(),
          );
        },
      ),
    );
  }
}
