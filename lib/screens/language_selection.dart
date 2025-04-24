import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.language != 'ta';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  isEnglish ? 'Select Language' : 'மொழி தேர்வு',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEnglish
                      ? 'Choose your preferred language'
                      : 'உங்களுக்கு விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLanguageButton(
                        context,
                        language: 'en',
                        label: 'English',
                        icon: Icons.language,
                        languageProvider: languageProvider,
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageButton(
                        context,
                        language: 'ta',
                        label: 'தமிழ்',
                        icon: Icons.language,
                        languageProvider: languageProvider,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, {
    required String language,
    required String label,
    required IconData icon,
    required LanguageProvider languageProvider,
  }) {
    final isSelected = languageProvider.language == language;

    return GestureDetector(
      onTap: () {
        languageProvider.setLanguage(language);
        // Close the page when language is selected
        Navigator.pop(context);
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue.shade800 : Colors.white,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue.shade800 : Colors.white,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue.shade800,
              ),
          ],
        ),
      ),
    );
  }
}
