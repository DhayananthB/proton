import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/language_provider.dart';
import 'screens/home_page.dart';
import 'screens/language_selection.dart';
import 'screens/farmer_registration.dart';
import 'screens/insurance_page.dart';
import 'services/farmer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String savedLanguage = prefs.getString('language') ?? 'en';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LanguageProvider(savedLanguage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Proton',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/language': (context) => const LanguageSelectionPage(),
        '/profile': (context) => const FarmerRegistrationPage(),
        '/insurance': (context) => const InsurancePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFarmerRegistration();
  }

  Future<void> _checkFarmerRegistration() async {
    try {
      // Check if farmer data exists
      final farmer = await FarmerService.getFarmer();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (farmer != null) {
          // Farmer exists, navigate to home page
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Farmer doesn't exist, navigate to registration page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FarmerRegistrationPage(
                isInitialRegistration: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // On error, go to registration page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const FarmerRegistrationPage(
              isInitialRegistration: true,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.electric_bolt,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Proton',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
