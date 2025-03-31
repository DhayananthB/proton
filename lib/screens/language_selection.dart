import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Language")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLanguageButton(context, 'English', 'en'),
            const SizedBox(height: 20),
            _buildLanguageButton(context, 'தமிழ்', 'ta'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String label, String langCode) {
    return ElevatedButton(
      onPressed: () {
        Provider.of<LanguageProvider>(context, listen: false).setLanguage(langCode);
        Navigator.pop(context); // Go back to ChatBotPage
      },
      child: Text(label),
    );
  }
}
