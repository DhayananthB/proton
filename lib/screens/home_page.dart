import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../screens/chatbot_page.dart';
import '../screens/weather_page.dart';
import '../screens/disease_tracking_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proton'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              Navigator.pushNamed(context, '/language');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildGridItem(
              context,
              languageProvider.language == 'ta' ? 'சாட்பாட்' : 'ChatBot',
              Icons.chat,
              Colors.blue,
              const ChatBotPage(),
            ),
            _buildGridItem(
              context,
              languageProvider.language == 'ta' ? 'வானிலை' : 'Weather',
              Icons.cloud,
              Colors.orange,
              const WeatherPage(),
            ),
            _buildGridItem(
              context,
              languageProvider.language == 'ta'
                  ? 'நோய் கண்காணிப்பு'
                  : 'Disease Track',
              Icons.healing,
              Colors.green,
              const DiseaseTrackingPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
