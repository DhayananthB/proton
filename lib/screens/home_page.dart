//home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../screens/chatbot_page.dart';
import '../screens/weather_page.dart';
import '../screens/disease_tracking_page.dart';
import '../screens/farmer_registration.dart';
import '../screens/insurance_page.dart';
import '../services/farmer_service.dart';
import '../models/farmer_model.dart';
import '../utils/translations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Farmer? _farmer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    try {
      final farmer = await FarmerService.getFarmer();
      if (mounted) {
        setState(() {
          _farmer = farmer;
          _isLoading = false;
        });
        
        // If farmer data is missing, redirect to registration page
        if (farmer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/profile');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // On error, redirect to registration page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/profile');
        });
      }
      // print("Error loading farmer data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Agriculture-themed background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E6F30), Color(0xFF3CAF50)], // Natural green tones
              ),
            ),
          ),

          // Decorative patterns representing crop rows
          Positioned(
            top: screenSize.height * 0.15,
            left: 0,
            right: 0,
            child: _buildCropPattern(15),
          ),
          
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            child: _buildCropPattern(10, reversed: true),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom app bar with agriculture styling
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(70),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0F7FA)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Text(
                              'PROTON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'RobotoMono',
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4.0,
                                    color: Color(0x99000000),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/language');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(70),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.language,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Farmer welcome card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withAlpha(230),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                radius: 24,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.green.shade700,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 100,
                                    child: LinearProgressIndicator(
                                      backgroundColor: Colors.green,
                                      color: Colors.lightGreen,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _farmer != null
                                            ? '${languageProvider.language == 'ta' ? 'வணக்கம்' : 'Welcome'}, ${_farmer!.name}!'
                                            : languageProvider.language == 'ta'
                                            ? 'வணக்கம்!'
                                            : 'Welcome!',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        languageProvider.language == 'ta'
                                            ? 'உங்கள் விவசாய உதவியாளர்'
                                            : 'Your Farming Assistant',
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Services section with stylized heading
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 20, bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grass,
                        color: Colors.white.withAlpha(220),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        languageProvider.language == 'ta' ? 'சேவைகள்' : 'Services',
                        style: TextStyle(
                          color: Colors.white.withAlpha(240),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid items with agriculture-themed icons
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'சாட்பாட்'
                              : 'ChatBot',
                          Icons.chat_bubble_outlined,
                          [const Color(0xFF66BB6A), const Color(0xFF43A047)],
                          const ChatBotPage(),
                          'smart_farm_assistant',
                        ),
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'வானிலை'
                              : 'Weather',
                          Icons.wb_sunny_outlined,
                          [const Color(0xFF29B6F6), const Color(0xFF0288D1)],
                          const WeatherPage(),
                          'weather_forecast',
                        ),
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'நோய் கண்காணிப்பு'
                              : 'Disease Track',
                          Icons.bug_report_outlined,
                          [const Color(0xFFFF7043), const Color(0xFFE64A19)],
                          const DiseaseTrackingPage(),
                          'plant_health',
                        ),
                        _buildGridItem(
                          context,
                          AppTranslations.getText('insurance', languageProvider.language),
                          Icons.shield_outlined,
                          [const Color(0xFF9575CD), const Color(0xFF5E35B1)],
                          const InsurancePage(),
                          'crop_protection',
                        ),
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'விவரங்கள்'
                              : 'Profile',
                          Icons.account_circle_outlined,
                          [const Color(0xFFFFB74D), const Color(0xFFFF9800)],
                          const FarmerRegistrationPage(),
                          'farmer_profile',
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom section with leaf divider and version info
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, color: Colors.white.withAlpha(90), size: 12),
                          const SizedBox(width: 5),
                          Icon(Icons.eco, color: Colors.white.withAlpha(90), size: 12),
                          const SizedBox(width: 5),
                          Icon(Icons.eco, color: Colors.white.withAlpha(90), size: 12),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPattern(int count, {bool reversed = false}) {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Wrap(
          spacing: 10,
          children: List.generate(
            count,
            (index) => Transform.rotate(
              angle: reversed ? 3.14 : 0, // 180 degrees in radians if reversed
              child: Icon(
                Icons.grass,
                color: Colors.white.withAlpha(15 + (index % 3) * 5),
                size: 24 + (index % 4) * 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    Widget page,
    String semanticLabel,
  ) {
    return GestureDetector(
      onTap: () async {
        // print("Grid item tapped: $title");
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
        // print("Returned from $title page");
        if (page is FarmerRegistrationPage && result == true) {
          _loadFarmerData(); // Reload data when returning from registration
          // print("Data reload initiated after $title action");
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withAlpha(60),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
                semanticLabel: semanticLabel,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Color(0x66000000),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
