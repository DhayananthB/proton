//home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../screens/chatbot_page.dart';
import '../screens/weather_page.dart';
import '../screens/disease_tracking_page.dart';
import '../screens/farmer_registration.dart';
import '../services/farmer_service.dart';
import '../models/farmer_model.dart';

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
      setState(() {
        _farmer = farmer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // print("Error loading farmer data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
            ),
          ),

          // Background patterns
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom app bar
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
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.electric_bolt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Proton',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
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
                            color: Colors.white.withAlpha(51),
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

                // Welcome text with farmer name if available
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 100,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white24,
                              color: Colors.white70,
                            ),
                          )
                          : Text(
                            _farmer != null
                                ? '${languageProvider.language == 'ta' ? 'வணக்கம்' : 'Welcome'}, ${_farmer!.name}!'
                                : languageProvider.language == 'ta'
                                ? 'வணக்கம்!'
                                : 'Welcome!',
                            style: TextStyle(
                              color: Colors.white.withAlpha(230),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),

                // Show farmer profile card if exists or registration button if not
                if (!_isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child:
                        _farmer != null
                            ? _buildFarmerProfileCard(
                              _farmer!,
                              languageProvider,
                            )
                            : _buildRegistrationButton(languageProvider),
                  ),
                  const SizedBox(height: 20),
                ],

                // Services section
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8, bottom: 16),
                  child: Text(
                    languageProvider.language == 'ta' ? 'சேவைகள்' : 'Services',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Grid items
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
                          Icons.chat_bubble_outline,
                          const [Color(0xFF00C6FB), Color(0xFF005BEA)],
                          const ChatBotPage(),
                        ),
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'வானிலை'
                              : 'Weather',
                          Icons.cloud_outlined,
                          const [Color(0xFFFFA62E), Color(0xFFEA4D2C)],
                          const WeatherPage(),
                        ),
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'நோய் கண்காணிப்பு'
                              : 'Disease Track',
                          Icons.local_hospital_outlined,
                          const [Color(0xFF0ACF83), Color(0xFF0BA360)],
                          const DiseaseTrackingPage(),
                        ),
                        // Registration grid item
                        _buildGridItem(
                          context,
                          languageProvider.language == 'ta'
                              ? 'விவரங்கள்'
                              : 'Profile',
                          Icons.person_outline,
                          const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                          const FarmerRegistrationPage(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom section with version info
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerProfileCard(
    Farmer farmer,
    LanguageProvider languageProvider,
  ) {
    // Now using the full LanguageProvider instead of just the language string
    final String currentLanguage = languageProvider.language;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                farmer.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_android, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                farmer.mobileNumber,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${farmer.village}, ${farmer.block}, ${farmer.district}, ${farmer.state}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              // print("Edit button tapped, language: $currentLanguage");
              // Pass the language provider to ensure language context is maintained
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FarmerRegistrationPage(
                        initialFarmer:
                            farmer, // Pass the current farmer data for editing
                      ),
                ),
              );
              // print("Returned from registration page");
              if (result == true) {
                _loadFarmerData(); // Reload data when returning from the form
                // print("Data reload initiated after successful edit");
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentLanguage == 'ta' ? 'திருத்து' : 'Edit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationButton(LanguageProvider languageProvider) {
    // Now using the full LanguageProvider
    final String currentLanguage = languageProvider.language;

    return GestureDetector(
      onTap: () async {
        // print("Registration button tapped, language: $currentLanguage");
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FarmerRegistrationPage(),
          ),
        );
        // print("Returned from registration page");
        if (result == true) {
          _loadFarmerData(); // Reload data when returning from the form
          // print("Data reload initiated after registration");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white70, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt, color: Color(0xFF6A11CB)),
            const SizedBox(width: 10),
            Text(
              currentLanguage == 'ta'
                  ? 'விவசாயி விவரங்களை சேர்க்கவும்'
                  : 'Add Farmer Details',
              style: const TextStyle(
                color: Color(0xFF6A11CB),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
    List<Color> gradientColors,
    Widget page,
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
              color: gradientColors[0].withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
